require 'forwardable'

module Elio
  module Responders
    class GithubResponder < Bitbot::Responder
      category 'Development'
      help 'pulls', description: 'Finds open PRs with the absence of "LGTM" or "looks good to me" in a comment.'

      route :pulls, /^pulls$/ do
        pulls_to_review = PullRequestCollection.
          fetch(redis.get_repos).
          reject(&:reviewed?)

        message = Bitbot::Message.new(
          text: "Open PRs:"
        )

        message.attachments = pulls_to_review.map do |pr|
          {
            title: pr.title,
            title_link: pr.url,
            color: '#afafaf',
            text: "by #{pr.author}"
          }
        end

        respond_with message
      end

      route :add_repo, /^add repo (\w+)$/ do |name|
        redis.add_repo(name)

        respond_with "Okay #{message.user_name}, I added '#{name}' for checking open PRs."
      end

      route :axe_repo, /^axe repo (\w+)$/ do |name|
        redis.remove_repo(name)

        respond_with "Okay #{message.user_name}, I removed '#{name}' from the open PR check list."
      end

      def redis
        @redis ||= RedisHelper.new(connection)
      end

      class PullRequestCollection
        include Enumerable

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
            pull_requests = @client.issues(nil, filter: 'all').map do |issue|
              PullRequest.new(issue, @client)
            end
            pull_requests.reject! { |issue| !@repo_names.include?(issue.repo_name) }
            pull_requests
          end

          true
        end

        def each(&block)
          @pull_requests.each(&block)
        end

        class PullRequest
          extend Forwardable
          def_delegators :@attributes, :repository, :pull_request, :number, :title

          def initialize(attributes, client)
            @attributes, @client = attributes, client
          end

          def comments
            @comments ||= @client.issue_comments(repo_name, number).map do |comment|
              Comment.new(comment)
            end
          end

          def reviewed?
            comments.any?(&:lgtm?)
          end

          def repo_name
            repository.full_name
          end

          def url
            pull_request.html_url
          end

          private

          class Comment
            extend Forwardable
            def_delegators :@attributes, :body

            def initialize(attributes)
              @attributes = attributes
            end

            def lgtm?
              !!(body =~ /lgtm/i)
            end
          end
        end

        class RedisHelper
          REPOS_KEY = 'elio:repos'

          def initialize(connection)
            @connection = connection
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
        end
      end
    end
  end
end
