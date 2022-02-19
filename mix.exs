defmodule RuntimeProvider.MixProject do
  use Mix.Project

  def project do
    [
      app: :runtime_provider,
      version: "0.0.1",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      name: "RuntimeProvider",
      source_url: github_url()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:yaml_elixir, "~> 2.5"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"Github" => github_url()}
    ]
  end

  defp description, do: "Make ConfigProvider easier to use with validation."

  defp github_url do
    "https://github.com/smartepsh/runtime-provider.git"
  end
end
