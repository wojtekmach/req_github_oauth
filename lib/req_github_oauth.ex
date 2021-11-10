defmodule ReqGitHubOAuth do
  require Logger

  def run(request) do
    token = read_memory_cache() || read_fs_cache() || request_token()
    update_in(request.headers, &[{"authorization", "Bearer #{token}"} | &1])
  end

  defp read_memory_cache do
    :persistent_term.get({__MODULE__, :token}, nil)
  end

  defp write_memory_cache(token) do
    :persistent_term.put({__MODULE__, :token}, token)
  end

  defp read_fs_cache do
    case File.read(token_fs_path()) do
      {:ok, token} ->
        :persistent_term.put({__MODULE__, :token}, token)
        token

      {:error, :enoent} ->
        nil
    end
  end

  defp token_fs_path do
    Path.join(:filename.basedir(:user_config, "req_github_oauth"), "token")
  end

  defp write_fs_cache(token) do
    path = token_fs_path()
    Logger.debug(["writing ", path])
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, token)
  end

  defp request_token do
    client_id = "Iv1.3fc77252cc13a342"
    url = "https://github.com/login/device/code"
    result = Req.post!(url, {:form, client_id: client_id}).body |> URI.decode_query()

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
    write_fs_cache(token)
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

    result = Req.post!(url, {:form, params}).body |> URI.decode_query()

    if result["error"] do
      Logger.info(["response: ", result["error"]])
      Process.sleep(5000)
      attempt(client_id, device_code)
    else
      result["access_token"]
    end
  end
end
