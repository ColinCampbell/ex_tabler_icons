# TablerIcons

Makes it easier to integrate [tabler_icons](https://github.com/tabler/tabler-icons)
into Elixir apps.

## Using ex_tabler_icons

Add the `:ex_tabler_icons` dependency to your `mix.exs` file:

```
{:ex_tabler_icons, "~> 0.1", runtime: Mix.env() == :dev}
```

You can define `ex_tabler_icons` profiles in your `config/config.exs` file:

    config :ex_tabler_icons,
        version: "1.50.0",
        default: [
          cd: Path.expand("../assets", __DIR__),
          config_file: "tabler_icons.json",
          font_output: "../priv/static/fonts/"
          css_output: "css/"
        ],
        umbrella_default: [
          cd: Path.expand("../apps/my_app/assets", __DIR__),
          config_file: "tabler_icons.json",
          font_output: "../priv/static/fonts/",
          css_output: "css/"
        ]

You can re-run the process to rebuild the iconfont using:

```
mix ex_tabler_icons default
```

Substitute `default` for the profile name you used in the `config.exs` file,
should it be different. If you'd like to rebuild the iconfont whenever you
start your Phoenix server, you can override it in the aliases of your `mix.exs`.
It's also worth overriding your `assets.deploy` alias.

```
  defp aliases do
    [
      # ...
      "phx.server": ["ex_tabler_icons default", "phx.server"],
      # ...
    ]
  end
```

This should generate a `tabler-icons.css` in the CSS folder specified in your
`config.exs`. You can then import that file using `@import` and include your icons
using the CSS classes generated in `tabler-icons.css`.

```
@import url("tabler-icons.css");
```
