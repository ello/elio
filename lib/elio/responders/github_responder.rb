class GithubResponder < Bitbot::Responder
  category 'Development'
  help 'pulls', description: 'Finds open PRs with the absence of "LGTM" or "looks good to me" in a comment.'

  route :pulls, /^pulls$/ do
    respond_with "I don't know how to do this yet"
  end

  class PullRequest
    def self.all
      new.all
    end

    def initialize
      # @client = Octokit::Client.new(:access_token => ENV['ELIO_GITHUB_OAUTH_TOKEN'])
      @client = Octokit::Client.new(:access_token => '01c8290e5c7e87b731c84f8843e36ab93bf6dcf5')
    end

    def all
      client.issues
    end
  end
end
