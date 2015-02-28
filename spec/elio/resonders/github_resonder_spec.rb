require 'spec_helper'

describe GithubResponder do
  describe 'listing open pull requests' do
    it 'fetches open PRs with trigger words in comments' do
      collection = nil
      VCR.use_cassette('github_issues') do
        collection = described_class::PullRequestCollection.fetch
        VCR.use_cassette('github_issue_comment') do
          binding.pry
        end
      end
    end
  end
end
