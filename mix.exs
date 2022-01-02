defmodule TablerIcons.MixProject do
  use Mix.Project

  @source_url "https://github.com/ColinCampbell/ex_tabler_icons"
  @version "0.1.0"

  def project do
    [
      app: :ex_tabler_icons,
      name: "ExTablerIcons",
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp description() do
    """
    Easily integrate tabler icons into your Elixir apps.
    """
  end

  defp package() do
    [
      maintainers: ["Colin Campbell"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "ExTablerIcons",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/ex_tabler_icons",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md", "LICENSE"]
    ]
  end
end
