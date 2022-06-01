defmodule ReqGitHubOAuth do
  require Logger

  @moduledoc """
  `Req` plugin for GitHub authentication.

  The plugin authenticates requests to GitHub using [GitHub OAuth Device Flow](https://docs.github.com/en/developers/apps/building-oauth-apps/authorizing-oauth-apps#device-flow).
  The GitHub OAuth it uses is: <https://github.com/apps/reqgithuboauth>.
  """

  @doc """
  Runs the plugin.

  ## Examples

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
  """
  def attach(request, opts \\ []) do
    request
    |> Req.Request.register_options([:gh_token_cache_fs_path])
    |> Req.Request.merge_options(opts)
    |> Req.Request.append_request_steps(req_github_oauth: &auth/1)
  end

  defp auth(%{url: %URI{scheme: "https", host: "api.github.com", port: 443}} = request) do
    opts = request.options
    token = read_memory_cache() || read_fs_cache(opts) || request_token(opts)
    update_in(request.headers, &[{"authorization", "Bearer #{token}"} | &1])
  end

  defp auth(request) do
    request
  end

  defp read_memory_cache do
    :persistent_term.get({__MODULE__, :token}, nil)
  end

  defp write_memory_cache(token) do
    :persistent_term.put({__MODULE__, :token}, token)
  end

  defp read_fs_cache(opts) do
    case File.read(token_fs_path(opts)) do
      {:ok, token} ->
        :persistent_term.put({__MODULE__, :token}, token)
        token

      {:error, :enoent} ->
        nil
    end
  end

  defp token_fs_path(opts) do
    Path.join(
      opts[:gh_token_cache_fs_path] || :filename.basedir(:user_config, "req_github_oauth"),
      "token"
    )
  end

  defp write_fs_cache(token, opts) do
    path = token_fs_path(opts)
    Logger.debug(["writing ", path])
    File.mkdir_p!(Path.dirname(path))
    File.touch!(path)
    File.chmod!(path, 0o600)
    File.write!(path, token)
  end

  defp request_token(opts) do
    # https://github.com/apps/reqgithuboauth
    client_id = "Iv1.c8e56bdb5de5b9d7"
    url = "https://github.com/login/device/code"
    result = Req.post!(url, form: [client_id: client_id]).body |> URI.decode_query()

    IO.puts([
      "paste this user code:\n\n  ",
      result["user_code"],
      "\n\nat:\n\n  ",
      result["verification_uri"],
      "\n"
    ])

    if Mix.shell().yes?("open browser window?") do
      browser_open(result["verification_uri"])
    end

    token = attempt(client_id, result["device_code"])
    write_memory_cache(token)
    write_fs_cache(token, opts)
    token
  end

  defp browser_open(url) do
    {_, 0} =
      case :os.type() do
        {:win32, _} -> System.cmd("cmd", ["/c", "start", url])
        {:unix, :darwin} -> System.cmd("open", [url])
        {:unix, _} -> System.cmd("xdg-open", [url])
      end
  end

  defp attempt(client_id, device_code) do
    url = "https://github.com/login/oauth/access_token"

    params = [
      client_id: client_id,
      device_code: device_code,
      grant_type: "urn:ietf:params:oauth:grant-type:device_code"
    ]

    result = Req.post!(url, form: params).body |> URI.decode_query()

    if result["error"] do
      Logger.info(["response: ", result["error"]])
      Process.sleep(5000)
      attempt(client_id, device_code)
    else
      Logger.info("response: success")
      result["access_token"]
    end
  end
end
