defmodule RuntimeProvider.Definition do
  @moduledoc """
  DSLs for defines the configuration with ConfigProvider.
  """
  alias RuntimeProvider.Expr

  defstruct app: nil,
            key: nil,
            required?: false,
            strategy: :all,
            value: nil,
            fallback: nil,
            append: nil

  @type t :: %__MODULE__{
          app: atom,
          key: atom,
          required?: boolean,
          strategy: :one_of | :all,
          value: [Expr.t()],
          fallback: [atom] | nil,
          append: __MODULE__.t() | nil
        }

  @doc """
  Defines a configuration.

      config :app_name, :key, "value"

      config :app_name, :key, sub_key: "value", another_sub_key: "another_value"

      config :app_name, :key, "value", fallback: [:another_app_name, :another_key]

      config :app_name, :key, [sub_key: "value", another_sub_key: "another_value"], fallback: [:another_app_name, :another_value]

      # options for the value, not for the definition
      config :app_name, :key, {"value", required?: true}


  The value type must be one of string, integer or atom. Default to itself.

  ## Options

  - `fallback` - fallback to exist configuration when given values are invalid.

  """
  defmacro config(app, key, value, opts \\ []) do
    quote bind_quoted: [app: app, key: key, value: value, opts: opts] do
      definition = %{
        RuntimeProvider.Definition.common_definition(app, key, opts)
        | value: Expr.cast(value),
          strategy: :all,
          required?: false
      }

      @definitions [definition | @definitions]
    end
  end

  @doc """
  Similar to `config/4` but raises if no configuration was found.
  """
  defmacro config!(app, key, value, opts \\ []) do
    quote bind_quoted: [app: app, key: key, value: value, opts: opts] do
      definition = %{
        RuntimeProvider.Definition.common_definition(app, key, opts)
        | value: Expr.cast(value),
          strategy: :all,
          required?: true
      }

      @definitions [definition | @definitions]
    end
  end

  @doc """
  Similar to `config/4` but will select the first valid configuration from availables.

      config_from :app_name, :key, ["value_1", "value_2"]

      config_from :app_name, :key, ["value_1", "value_2"], append: {:app_name, :key, "append_value"}

      config_from :app_name, :key, ["value_1", "value_2"], append: {:app_name, :key, ["for_value_1", "for_value_2"]}

  ## Options

  - `fallback` - fallback to exist configuration when given values are invalid
  - `append` - `{app, key, value(s)}` tuple. Append another configuration when given values are valid. If the value is a list, it's length must be equal to the availables, we will use index to select append value.

  """
  defmacro config_from(app, key, values, opts \\ []) do
    quote bind_quoted: [app: app, key: key, values: values, opts: opts] do
      definition = %{
        RuntimeProvider.Definition.common_definition(app, key, opts)
        | value: Enum.map(values, &Expr.cast/1),
          strategy: :one_of,
          required?: false
      }

      @definitions [definition | @definitions]
    end
  end

  @doc """
  Similar to `config_from/4` but raises if no configraution was found.
  """
  defmacro config_from!(app, key, values, opts \\ []) do
    quote bind_quoted: [app: app, key: key, values: values, opts: opts] do
      definition = %{
        RuntimeProvider.Definition.common_definition(app, key, opts)
        | value: Enum.map(values, &Expr.cast/1),
          strategy: :one_of,
          required?: true
      }

      @definitions [definition | @definitions]
    end
  end

  def common_definition(app, key, opts \\ []) do
    %RuntimeProvider.Definition{
      app: app,
      key: key,
      strategy: :all,
      fallback: cast_fallback!(opts[:fallback]),
      append: cast_append!(opts[:append])
    }
  end

  def cast_fallback!(nil), do: nil

  def cast_fallback!(fallback) when is_list(fallback) do
    if Enum.all?(fallback, &is_atom/1) do
      fallback
    else
      raise ArgumentError, "The fallback must be a atom list."
    end
  end

  def cast_fallback!(_), do: raise(ArgumentError, "The fallback must be a atom list.")

  def cast_append!(nil), do: nil

  def cast_append!({app, key, value}) when is_atom(app) and is_atom(key) do
    if is_list(value) do
      Enum.map(value, &%{common_definition(app, key) | value: Expr.cast(&1)})
    else
      %{common_definition(app, key) | value: Expr.cast(value)}
    end
  end

  def cast_append!(_),
    do: raise(ArgumentError, "The append configuration must be {atom, atom, value(s)}.")
end
