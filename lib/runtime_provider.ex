defmodule RuntimeProvider do
  @moduledoc """
  Defines a ConfigProvider with validation.

  Only `yaml` and `yml` are supported now.
  """

  # 这里有两种实现方式，我们选择了第 2 种：
  # 1. 优先获取 path ，读取文件后，使用 DSL 直接拿到 config
  # 2. 使用 DSL 保存定义，最终读取 path ，整体解析
  # 理由是因为想要从 provider 中提前获取 path 信息，需要使用一些 trick 。
  # 如下链接代码可知，需要用到代码里定义的 private key ，比较抵触。
  # https://github.com/elixir-lang/elixir/blob/b63f8f541e9d8951dbbcb39a8551bd74a3fe9a59/lib/elixir/lib/config/provider.ex#L187

  @doc """
  Defines a ConfigProvier.

  Ignored if there is no file on the path.
  """
  defmacro __using__(_opts) do
    quote do
      import RuntimeProvider.Definition

      @definitions []

      @before_compile RuntimeProvider
    end
  end

  defmacro __before_compile__(_env) do
    quote generated: true do
      @behaviour Config.Provider

      @impl true
      def init(path), do: path

      @impl true
      def load(config, path) do
        if File.exists?(path) do
          content = read_file!(path)
          file_config = RuntimeProvider.Parser.parse(content, @definitions)
          Config.Reader.merge(config, file_config)
        else
          IO.puts(
            "Could not read file #{IO.chardata_to_string(path)}: no such file or directory. Ignore runtime configuration."
          )

          config
        end
      end

      defp read_file!(path) do
        case Path.extname(path) do
          ext when ext in [".yml", ".yaml"] ->
            {:ok, _} = Application.ensure_all_started(:yaml_elixir)
            YamlElixir.read_from_file!(path)
        end
      end
    end
  end
end
