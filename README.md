# RuntimeProvider

This is an experimental project based on [ConfigProvider](https://hexdocs.pm/elixir/1.13.3/Config.Provider.html).

If you need stability, I recommend another project - [Vapor](https://github.com/elixir-toniq/vapor) .

The first stage only supports YAML files, more files and system ENV may be supported in the future.

## Installation

```elixir
def deps do
  [
    {:runtime_provider, "~> 0.1.0"}
  ]
end
```

## Usage

1. Define provider module with definitions.
An example of how to define a configuration is in [ThisTestFile](test/runtime_provider/definition_test.exs)

```elixir
defmodule Provider do
  use RuntimeProvider

  # define some configurations
end
```

2. In `mix.exs`

```elixir

def project do
  releases: [
    demo: [
      config_providers: [
        {SelfProvider, {:system, "RELEASE_ROOT", "/extra_config.exs"}}
      ]
    ]
  ]
end
```

3. mix release
