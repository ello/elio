class GithubResponder < Bitbot::Responder
  category 'Development'
  help 'pulls', description: 'Finds open PRs with the absence of "LGTM" or "looks good to me" in a comment.'

  route :pulls, /^pulls$/ do
    respond_with "I don't know how to do this yet"
  end

  class PullRequest
    def initialize
      @client = Octokit::Client.new(:access_token => ENV['ELIO_GITHUB_OAUTH_TOKEN'])
    end
  end
end
