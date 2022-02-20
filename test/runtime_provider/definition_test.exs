defmodule RuntimeProvider.DefinitionTest do
  use ExUnit.Case

  alias RuntimeProvider.Definition
  alias RuntimeProvider.Expr

  defmodule Example do
    use RuntimeProvider

    config! :os_example, OSExample.Repo,
      url: ["database", "main", "url"],
      pool_size: ["database", "main", "pool_size"]

    config :os_example,
           OSExample.Repo.Replica,
           [
             url: ["database", "read_only", "url"],
             pool_size: 80
           ],
           fallback: [:os_example, OSExample.Repo]

    config :os_example, :analysis_node, {["analysis_node"], type: :atom}

    config :os_example, OSExampleWeb.Endpoint, http: [port: ["port"]]

    config_from :os_example,
                :email,
                [
                  [
                    id: ["email", "aliyun", "id"],
                    secret: ["email", "aliyun", "secret"]
                  ],
                  [
                    user: ["email", "send_cloud", "user"],
                    key: ["email", "send_cloud", "key"]
                  ]
                ],
                append: {:os_example, :email_sender, [[adapter: Aliyun], [adapter: SendCloud]]}

    def definitions do
      @definitions
    end
  end

  describe "definitions" do
    test "value is keyword, required" do
      assert %Definition{
               app: :os_example,
               key: OSExample.Repo,
               required?: true,
               strategy: :all,
               value: value
             } = take_definition(0)

      assert %Expr{
               expr: [
                 url: %Expr{expr: ["database", "main", "url"]},
                 pool_size: %Expr{expr: ["database", "main", "pool_size"]}
               ]
             } = value
    end

    test "value is keyword, not required, has fallback" do
      assert %Definition{
               app: :os_example,
               key: OSExample.Repo.Replica,
               required?: false,
               strategy: :all,
               fallback: [:os_example, OSExample.Repo],
               value: value
             } = take_definition(1)

      assert %Expr{
               expr: [
                 url: %Expr{expr: ["database", "read_only", "url"]},
                 pool_size: %Expr{expr: 80}
               ]
             } = value
    end

    test "with specific value type" do
      assert %Definition{
               app: :os_example,
               key: :analysis_node,
               required?: false,
               value: %Expr{expr: ["analysis_node"], type: :atom}
             } = take_definition(2)
    end

    test "with deep keyword" do
      assert %Definition{
               app: :os_example,
               key: OSExampleWeb.Endpoint,
               value: %Expr{expr: [http: [port: %Expr{expr: ["port"]}]]}
             } = take_definition(3)
    end

    test "with config_from" do
      assert %Definition{
               app: :os_example,
               key: :email,
               value: [value_1, value_2],
               strategy: :one_of,
               append: [append_1, append_2]
             } = take_definition(4)

      assert %Expr{
               expr: [
                 id: %Expr{expr: ["email", "aliyun", "id"]},
                 secret: %Expr{expr: ["email", "aliyun", "secret"]}
               ]
             } = value_1

      assert %Expr{
               expr: [
                 user: %Expr{expr: ["email", "send_cloud", "user"]},
                 key: %Expr{expr: ["email", "send_cloud", "key"]}
               ]
             } = value_2

      assert %Definition{
               app: :os_example,
               key: :email_sender,
               value: %Expr{expr: [adapter: %Expr{expr: Aliyun}]},
               strategy: :all
             } = append_1

      assert %Definition{
               app: :os_example,
               key: :email_sender,
               value: %Expr{expr: [adapter: %Expr{expr: SendCloud}]},
               strategy: :all
             } = append_2
    end
  end

  defp take_definition(pos) do
    Example.definitions() |> Enum.reverse() |> Enum.at(pos)
  end
end
