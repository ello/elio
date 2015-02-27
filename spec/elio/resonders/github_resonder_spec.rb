require 'spec_helper'

describe GithubResponder do
  describe 'listing open pull requests' do
    it 'fetches open PRs with trigger words in comments' do
      VCR.use_cassette('github_issues') do
        described_class::PullRequestCollection.fetch
      end
    end
  end
end
