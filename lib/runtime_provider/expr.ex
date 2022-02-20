defmodule RuntimeProvider.Expr do
  defstruct expr: nil,
            required?: false,
            fallback: nil,
            type: :self

  @type t :: %__MODULE__{
          expr: any,
          required?: boolean,
          fallback: [atom] | nil,
          type: :self | :string | :integer | :atom
        }

  def cast({value, opts}), do: do_cast({value, opts})

  def cast(value) do
    if Keyword.keyword?(value) do
      %__MODULE__{expr: do_cast(value)}
    else
      %__MODULE__{expr: value}
    end
  end

  def do_cast({key, value}) when is_atom(key) do
    {key, do_cast(value)}
  end

  def do_cast({value, opts}) do
    type = cast_type!(opts[:type])
    required = cast_required(opts[:required?])
    fallback = cast_fallback!(opts[:fallback])

    %__MODULE__{expr: value, required?: required, fallback: fallback, type: type}
  end

  def do_cast(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Enum.map(values, &do_cast/1)
    else
      %__MODULE__{expr: values}
    end
  end

  def do_cast(value) do
    %__MODULE__{expr: value}
  end

  defp cast_type!(nil), do: :self

  defp cast_type!(type) when type in [:self, :string, :integer, :atom],
    do: type

  defp cast_type!(_),
    do: raise(ArgumentError, "The value type must be one of :self/:string/:integer/:atom.")

  defp cast_required(nil), do: false
  defp cast_required(required), do: !!required

  defp cast_fallback!(nil), do: nil

  defp cast_fallback!(fallback) when is_list(fallback) do
    if Enum.all?(fallback, &is_atom/1) do
      fallback
    else
      raise ArgumentError, "The fallback must be a atom list."
    end
  end

  defp cast_fallback!(_), do: raise(ArgumentError, "The fallback must be a atom list.")
end
