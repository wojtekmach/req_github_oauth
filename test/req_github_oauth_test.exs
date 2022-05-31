defmodule ReqGitHubOAuthTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir
  setup %{tmp_dir: tmp} do
    :persistent_term.put({ReqGitHubOAuth, :token}, nil)
    on_exit(fn -> File.rm_rf(tmp) end)
  end

  test "it works", %{tmp_dir: tmp} do
    opts = [gh_token_cache_fs_path: tmp]
    req = Req.new(http_errors: :raise) |> ReqGitHubOAuth.attach(opts)

    Req.get!(req, url: "https://api.github.com/user").body["login"]
    |> IO.inspect()
  end

  test "it caches token with user-only file permissions", %{tmp_dir: tmp} do
    opts = [gh_token_cache_fs_path: tmp]
    req = Req.new(http_errors: :raise) |> ReqGitHubOAuth.attach(opts)

    Req.get!(req, url: "https://api.github.com/user")

    cached_token = Path.join(tmp, "token")
    file_stat = File.stat!(cached_token)
    assert file_stat.mode == 0o00100600
  end
end
