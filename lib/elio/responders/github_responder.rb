class GithubResponder < Bitbot::Responder
  category 'Development'
  help 'pulls', description: 'Finds open PRs with the absence of "LGTM" or "looks good to me" in a comment.'

  route :pulls, /^pulls$/ do
    respond_with "I don't know how to do this yet"
  end

  class PullRequestCollection
    include Enumerable

    def self.fetch
      new.tap(&:fetch)
    end

    def initialize
      @client = Octokit::Client.new(:access_token => ENV['ELIO_GITHUB_OAUTH_TOKEN'])
    end

    def fetch
      @issues = @client.issues(nil, filter: 'all')
    end

    def each(&block)
      @issues.each(&block)
    end
  end
end
