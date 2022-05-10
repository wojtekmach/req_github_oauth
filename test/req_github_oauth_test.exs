defmodule ReqGitHubOAuthTest do
  use ExUnit.Case, async: true

  test "it works" do
    req = Req.new(http_errors: :raise) |> ReqGitHubOAuth.attach()

    Req.get!(req, url: "https://api.github.com/user").body["login"]
    |> IO.inspect()
  end
end
