# ReqGitHubOAuth

[Req](https://github.com/wojtekmach/req) plugin for GitHub authentication.

The plugin authenticates requests to GitHub using [GitHub OAuth Device Flow](https://docs.github.com/en/developers/apps/building-oauth-apps/authorizing-oauth-apps#device-flow).
The GitHub OAuth it uses is: <https://github.com/apps/reqgithuboauth>.

## Usage

```elixir
Mix.install([
  {:req, "~> 0.3.0"},
  {:req_github_oauth, "~> 0.1.0"}
])

req = Req.new(http_errors: :raise) |> ReqGitHubOAuth.attach()
Req.get!(req, url: "https://api.github.com/user").body["login"]
# Outputs:
# paste this user code:
#
#   6C44-30A8
#
# at:
#
#   https://github.com/login/device
#
# open browser window? [Yn]
# 15:22:28.350 [info] response: authorization_pending
# 15:22:33.519 [info] response: authorization_pending
# 15:22:38.678 [info] response: success
#=> "wojtekmach"

Req.get!(req, url: "https://api.github.com/user").body["login"]
#=> "wojtekmach"
```
