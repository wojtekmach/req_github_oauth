defmodule ReqGitHubOAuthTest do
  use ExUnit.Case, async: true

  test "it works" do
    Req.get!("https://api.github.com/user", steps: [ReqGitHubOAuth]).body["login"]
    |> IO.inspect()

    # Req.get!("https://api.github.com/user", steps: [ReqGitHubOAuth]).body["login"]
    # |> IO.inspect()
  end
end
