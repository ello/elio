require 'spec_helper'

describe Elio::Responders::GithubResponder do
  describe 'listing open pull requests' do

    # Cassettes
    let(:issue_comment_text) { nil }
    let(:github_oauth_token) { 'abcdef123456789abcdef123456789abcdef1234' }
    let(:issues_cassette_params) do
      { auth: github_oauth_token, repo_name: repo_name, labels: labels }
    end
    let(:comments_cassette_params) do
      { auth: github_oauth_token, comment_text: issue_comment_text, repo_name: repo_name }
    end
    let(:labels) { [] }

    # Bitbot
    let(:message)              { Bitbot::Message.new(text: 'pulls', user_name: 'archer') }
    let(:response)             { subject.respond_to(message) }
    let(:response_text)        { response[:text] }
    let(:response_attachments) { response[:attachments] }

    # Various
    let(:repo_name) { "exampleorg/elio" }
    let(:reviewed_words) { ["lgtm"] }

    before do
      allow_any_instance_of(Elio::Responders::GithubResponder::RedisHelper).
        to receive_messages(get_repos: [repo_name], reviewed_words: reviewed_words)
      set_env_oauth_token
    end

    after do
      clear_env_oauth_token
    end

    context "when the responder doesn't know about any repos" do
      it "provides helpful feedback" do
        allow_any_instance_of(Elio::Responders::GithubResponder::RedisHelper).
          to receive(:get_repos).and_return([])

        expect(response_text).to match /I don't know about any repositories/i
      end
    end

    context "when the responder doesn't know about any reviewed words" do
      it "provides helpful feedback" do
        allow_any_instance_of(Elio::Responders::GithubResponder::RedisHelper).
          to receive(:reviewed_words).and_return([])

        expect(response_text).to match /I don't know what to look for in PR comments/i
      end
    end

    context "when all open PRs have been reviewed" do
      let(:issue_comment_text) { "LGTM" }

      it 'provides helpful feedback' do
        with_cassettes do
          expect(response_text).to match /All open PRs have been reviewed/i
        end
      end
    end

    context 'when there are no open PRs' do
      it 'provides helpful feedback' do
        with_cassettes issues_cassette: :github_no_issues do
          expect(response_text).to match /No open PRs/i
        end
      end
    end

    context "when open PRs exist that haven't been reviewed" do
      let(:issue_comment_text) { "I don't know about these pancakes..." }

      it 'provides a list of PRs to review' do
        with_cassettes do
          expect(response_text).to match /PRs in need of review/
          expect(response_attachments).to include(
            title: "exampleorg/elio #1: Issue w/PR",
            title_link: "https://github.com/exampleorg/elio/pull/1",
            color: "#afafaf",
            text: "by exampleuser"
          )
        end
      end

      context "and the PR has labels" do
        let(:labels) { ["enhancement", "pancakes"] }

        it 'includes the labels in the list' do
          with_cassettes do
            expect(response_text).to match /PRs in need of review/
            expect(response_attachments).to include(
              title: "exampleorg/elio #1: Issue w/PR",
              title_link: "https://github.com/exampleorg/elio/pull/1",
              color: "#afafaf",
              text: "by exampleuser - #enhancement #pancakes"
            )
          end
        end
      end
    end

    context 'when reviewed words contain regex special characters' do
      let(:reviewed_words) { [':+1'] }
      let(:issue_comment_text) { ':+1:' }

      it 'correctly identifies lgtm comments' do
        with_cassettes do
          expect(response_text).to match /All open PRs have been reviewed/i
        end
      end
    end

    def set_env_oauth_token
      ENV['ELIO_GITHUB_OAUTH_TOKEN'] = github_oauth_token
    end

    def clear_env_oauth_token
      ENV.delete('ELIO_GITHUB_OAUTH_TOKEN')
    end

    def with_cassettes(issues_cassette: :github_issues, comments_cassette: :github_issue_comments)
      VCR.use_cassette(issues_cassette, erb: issues_cassette_params) do
        VCR.use_cassette(comments_cassette, erb: comments_cassette_params) do
          yield
        end
      end
    end
  end
end
