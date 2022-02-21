defmodule RuntimeProvider.Parser do
  alias RuntimeProvider.Definition
  alias RuntimeProvider.Expr

  def parse(file_content, definitions) do
    Enum.reduce(definitions, [], fn definition, acc ->
      case do_parse(definition, file_content, acc) do
        nil -> acc
        configurations when is_list(configurations) -> configurations ++ acc
        configuration -> [configuration | acc]
      end
    end)
  end

  defp do_parse(%Definition{strategy: :all, value: value} = definition, content, fallback_content) do
    value = parse_value(value, content, fallback_content)

    cond do
      is_empty?(value) and definition.required? ->
        raise ArgumentError,
              "No configuration about #{definition.app} -> #{definition.key} in the file"

      is_empty?(value) ->
        nil

      true ->
        value
    end
  end

  defp do_parse(
         %Definition{strategy: :one_of, value: values} = definition,
         content,
         fallback_content
       ) do
    {value, index} =
      Enum.reduce_while(values, {nil, 0}, fn value, {_, index} ->
        value = parse_value(value, content, fallback_content)

        if is_empty?(value) do
          {:cont, {nil, index + 1}}
        else
          {:halt, {value, index}}
        end
      end)
  end

  # fallback_content only for parse value, not definition's fallback.
  @doc false
  def parse_value(%Expr{expr: [{_, _} | _] = expr}, content, fallback_content) do
    Enum.map(expr, fn {key, value} ->
      {key, parse_value(value, content, fallback_content)}
    end)
  end

  def parse_value(%Expr{expr: keys} = expr, content, fallback_content) when is_list(keys) do
    value =
      content |> get_in(keys) |> convert_to(expr.type) ||
        find_fallback(expr.fallback, fallback_content)

    if value do
      value
    else
      if expr.required? do
        raise ArgumentError, "No configuration about #{Enum.join(keys, "->")} in the file."
      end
    end
  end

  def parse_value(%Expr{expr: value, type: type}, _content, _fallback_content),
    do: convert_to(value, type)

  def parse_value(keyword, content, fallback_content) do
    Enum.map(keyword, fn {key, value} ->
      {key, parse_value(value, content, fallback_content)}
    end)
  end

  defp find_fallback(nil, _fallback_content), do: nil

  defp find_fallback(keys, fallback_content) do
    get_in(fallback_content, keys)
  end

  @doc false
  def convert_to(nil, _), do: nil
  def convert_to(value, :self), do: value
  def convert_to(value, :string) when is_binary(value), do: value
  def convert_to(value, :string) when is_number(value), do: "#{value}"

  def convert_to(value, :integer) when is_binary(value) do
    case Integer.parse(value) do
      {integer, _} -> integer
      :error -> raise ArgumentError, "not a textual representation of a number"
    end
  end

  def convert_to(value, :integer) when is_integer(value), do: value
  def convert_to(value, :integer) when is_float(value), do: round(value)

  def convert_to(value, :atom) when is_binary(value), do: String.to_atom(value)
end
