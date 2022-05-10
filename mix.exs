defmodule ReqGitHubOAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :req_github_oauth,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [
        docs: :docs,
        "hex.publish": :docs
      ],
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.3.0-dev", github: "wojtekmach/req"},
      {:ex_doc, ">= 0.0.0", only: :docs}
    ]
  end
end
