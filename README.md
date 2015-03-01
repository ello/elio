# Elio

Utility bot for Ello. http://en.wikipedia.org/wiki/A_Tale_of_Time_City

Elio is responsible for Ello-related tasks that don't need direct access to the
master Ello database. Things like:

- Assisting in the PR review process
- ???

## Development

#### Setup

For the `GithubResponder`, you'll need to set an environment variable called `ELIO_GITHUB_OAUTH_TOKEN` that has access to all  the desired applications. I recommend [direnv](http://direnv.net/).

#### REPL

Running `rake console` will get you a custom Pry session with Elio and its dependencies loaded and ready.
