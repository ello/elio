require 'forwardable'

module Elio
  module Responders
    class GithubResponder < Bitbot::Responder
      category 'Github'
      help 'pulls', description: 'Finds open PRs with the absence of "LGTM" or "looks good to me" in a comment.'
      help 'add repo', description: 'Add a repository to the list of repos I check for open PRs. e.g. "add repo modeset/bitbot"'
      help 'axe repo', description: 'Remove a repository from list of repos I check for open PRs. e.g. "axe repo modeset/bitbot"'
      help 'repos', description: 'List repos I check for open PRs.'
      help 'reviewed words', description: 'List the words I use to check PRs for review status.'
      help 'add reviewed word', description: 'Add a "looks good" word.'
      help 'remove reviewed word', description: 'Remove a "looks good" word.'
      help 'add review tag', description: 'Add a tag to identify PRs that need review (spaces are fine)'
      help 'review tags', description: 'List tags that identify PRs that need review'

      route :review_tags, /^review tags$/ do
        if redis.review_tags.nil? || redis.review_tags.empty?
          respond_with "Looks like you haven't added any. Add some with 'add review tag <tag name>' (spaces are fine)."
        else
          respond_with "Review tags:\n\n```#{redis.review_tags.join("\n")}```"
        end
      end

      route :add_review_tag, /^add review tag (.*)$/ do |tag_name|
        redis.add_review_tag(tag_name)

        respond_with "Okay #{tag_name}, I added '#{tag_name}' to the review tags list."
      end

      route :reviewed_words, /^reviewed words$/ do
        if redis.reviewed_words.nil? || redis.reviewed_words.empty?
          respond_with "Sorry #{message.user_name}, I don't currently know about any words. Add some with 'add reviewed word <WORD>'"
        else
          respond_with "#{message.user_name} - these are the words I look for to tell if a PR has been reviewed:\n```#{redis.reviewed_words.join("\n")}```"
        end
      end

      route :add_reviewed_word, /^add reviewed word (.*)$/ do |word|
        redis.add_reviewed_word(word)

        respond_with "Okay #{message.user_name}, I added '#{word}' to the list."
      end

      route :remove_reviewed_word, /^remove reviewed word (.*)$/ do |word|
        redis.remove_reviewed_word(word)

        respond_with "Okay #{message.user_name}, I removed '#{word}' from the list."
      end

      route :pulls, /^pulls$/ do
        if redis.reviewed_words.nil? || redis.reviewed_words.empty?
          respond_with "Sorry #{message.user_name}, I don't know what to look for in PR comments. Add some words with 'add reviewed word <WORD>'"
        elsif redis.review_tags.nil? || redis.review_tags.empty?
          respond_with "Sorry #{message.user_name}, you need to add at least one review tag for me to look for PRs with. Add one with 'add review tag <tag name>'"
        elsif redis.get_repos.nil? || redis.get_repos.empty?
          respond_with "Sorry #{message.user_name}, I don't know about any repositories yet. Add some with 'add repo <OWNER>/<REPO>'"
        else
          pulls = PullRequestCollection.fetch(redis.get_repos)
          pulls_to_review = pulls.
            reject { |pr| pr.reviewed?(redis.reviewed_words) }.
            select { |pr| pr.matches_at_least_one_tag?(redis.review_tags) }

          if pulls.empty?
            respond_with "There are no open PRs at the moment."
          elsif pulls_to_review.empty?
            respond_with "Congrats, all open PRs have been reviewed."
          else
            message = Bitbot::Message.new(
              text: "PRs in need of review:"
            )

            message.attachments = pulls_to_review.map do |pr|
              text = "by #{pr.author}"
              if !pr.labels.empty?
                label_names = pr.labels.map { |l| "##{l}" }
                text += " - #{label_names.join(" ")}"
              end
              {
                title: "#{pr.repo_name} ##{pr.number}: #{pr.title}",
                title_link: pr.url,
                color: '#afafaf',
                text: text
              }
            end

            respond_with message.to_h
          end
        end
      end

      route :add_repo, /^add repo (.+)$/ do |name|
        redis.add_repo(name)

        respond_with "Okay #{message.user_name}, I added '#{name}' for checking open PRs."
      end

      route :axe_repo, /^axe repo (.+)$/ do |name|
        redis.remove_repo(name)

        respond_with "Okay #{message.user_name}, I removed '#{name}' from the open PR check list."
      end

      route :repos, /^repos$/ do
        respond_with "```\n#{redis.get_repos.join("\n")}\n```"
      end

      def redis
        @redis ||= RedisHelper.new(connection)
      end

      class PullRequestCollection
        include Enumerable
        extend Forwardable

        def_delegators :@pull_requests, :each, :size, :empty?

        def self.fetch(repo_names=nil)
          new(repo_names).tap(&:fetch)
        end

        def initialize(*repo_names)
          @repo_names = repo_names.flatten
          @client = Octokit::Client.new(:access_token => ENV['ELIO_GITHUB_OAUTH_TOKEN'])
        end

        def fetch
          return false if @repo_names.nil? || @repo_names.empty?

          @pull_requests ||= begin
            pull_requests = @client.issues(nil, filter: 'all', state: 'open').
              select(&:pull_request).
              map do |issue|
                PullRequest.new(issue, @client)
              end
            pull_requests.reject! { |issue| !@repo_names.include?(issue.repo_name) }
            pull_requests
          end

          true
        end

        class PullRequest
          extend Forwardable
          def_delegators :@attributes, :repository, :pull_request, :number, :title, :user

          def initialize(attributes, client)
            @attributes, @client = attributes, client
          end

          def comments
            @comments ||= @client.issue_comments(repo_name, number).map do |comment|
              Comment.new(comment)
            end
          end

          def labels
            @attributes.labels.map(&:name)
          end

          def reviewed?(reviewed_words)
            comments.any? { |c| c.lgtm?(reviewed_words) }
          end

          def matches_at_least_one_tag?(tags)
            !(labels & tags).empty?
          end

          def repo_name
            repository.full_name
          end

          def url
            pull_request.html_url
          end

          def author
            user.login
          end

          private

          class Comment
            extend Forwardable
            def_delegators :@attributes, :body

            def initialize(attributes)
              @attributes = attributes
            end

            def lgtm?(reviewed_words)
              reviewed_words.any? do |word|
                !!(body =~ /#{Regexp.quote(word)}/i)
              end
            end
          end
        end
      end

      class RedisHelper
        REPOS_KEY = 'elio:repos'
        REVIEWED_WORDS_KEY = 'elio:reviewed_words'
        REVIEW_TAGS_KEY = 'elio:review_tags'

        def initialize(connection)
          @connection = connection
        end

        def review_tags
          @connection.smembers(REVIEW_TAGS_KEY)
        end

        def add_review_tag(tag)
          @connection.sadd(REVIEW_TAGS_KEY, tag)
        end

        def get_repos
          @connection.smembers(REPOS_KEY)
        end

        def add_repo(name)
          @connection.sadd(REPOS_KEY, name)
        end

        def remove_repo(name)
          @connection.srem(REPOS_KEY, name)
        end

        def reviewed_words
          @connection.smembers(REVIEWED_WORDS_KEY)
        end

        def add_reviewed_word(trigger)
          @connection.sadd(REVIEWED_WORDS_KEY, trigger)
        end

        def remove_reviewed_word(trigger)
          @connection.srem(REVIEWED_WORDS_KEY, trigger)
        end
      end
    end
  end
end
