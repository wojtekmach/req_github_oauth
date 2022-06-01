defmodule ReqGitHubOAuthTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  test "it works", %{tmp_dir: tmp_dir} do
    opts = [gh_token_cache_fs_path: tmp_dir]
    req = Req.new(http_errors: :raise) |> ReqGitHubOAuth.attach(opts)

    Req.get!(req, url: "https://api.github.com/user").body["login"]
    |> IO.inspect()

    cached_token = Path.join(tmp_dir, "token")
    file_stat = File.stat!(cached_token)
    assert file_stat.mode == 0o00100600
  after
    File.rm_rf(tmp_dir)
  end
end
