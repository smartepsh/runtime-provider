defmodule RuntimeProvider.ParserTest do
  use ExUnit.Case, async: true

  alias RuntimeProvider.Expr
  alias RuntimeProvider.Parser

  describe "convert_to/2" do
    test "nil -> nil" do
      for type <- [:self, :integer, :string, :atom] do
        assert is_nil(Parser.convert_to(nil, type))
      end
    end

    test "for :self" do
      assert "value" = Parser.convert_to("value", :self)
      assert 1 = Parser.convert_to(1, :self)
      assert 1.0 = Parser.convert_to(1.0, :self)
      assert [key: :value] = Parser.convert_to([key: :value], :self)
      assert %{key: :value} = Parser.convert_to(%{key: :value}, :self)
    end

    test "for :string" do
      assert "value" = Parser.convert_to("value", :string)
      assert "1" = Parser.convert_to(1, :string)
      assert "1.0" = Parser.convert_to(1.0, :string)

      assert_raise FunctionClauseError, fn ->
        Parser.convert_to([key: :value], :string)
      end
    end

    test "for :integer" do
      assert 1 = Parser.convert_to(1, :integer)
      assert 1 = Parser.convert_to("1", :integer)
      assert 1 = Parser.convert_to("1.0", :integer)
      assert 1 = Parser.convert_to("1.1", :integer)
      assert 1 = Parser.convert_to("1.6", :integer)

      assert_raise ArgumentError, fn ->
        Parser.convert_to("not number", :integer)
      end

      assert_raise FunctionClauseError, fn ->
        Parser.convert_to([key: :value], :integer)
      end
    end

    test "for :atom" do
      assert :"1" = Parser.convert_to("1", :atom)

      assert_raise FunctionClauseError, fn ->
        Parser.convert_to(1, :atom)
      end

      assert_raise FunctionClauseError, fn ->
        Parser.convert_to([key: :value], :atom)
      end
    end
  end

  describe "parse expr" do
    test "raises if required and no value" do
      expr = %Expr{expr: ["key_1", "key_2"], required?: true}

      assert_raise ArgumentError, fn ->
        Parser.parse_value(expr, %{}, [])
      end
    end

    test "success fetch value from fallback" do
      expr = %Expr{expr: ["key_1", "key_2"], fallback: [:key_1, :key_2]}
      assert "value" = Parser.parse_value(expr, %{}, [{:key_1, [{:key_2, "value"}]}])
    end

    test "success fetch value from content" do
      expr = %Expr{expr: ["key_1", "key_2"], fallback: [:key_1, :key_2]}

      assert "value_1" =
               Parser.parse_value(expr, %{"key_1" => %{"key_2" => "value_1"}}, [
                 {:key_1, [{:key_2, "value_2"}]}
               ])
    end

    # when fetch from content, the expr must be a keys list, not single value.
    test "success fetch the origin value directly" do
      expr = %Expr{expr: "key_1"}
      assert "key_1" = Parser.parse_value(expr, %{"key_1" => "value"}, [])
    end

    test "for nested keyword list" do
      expr = %Expr{
        expr: [
          key_1: %Expr{expr: ["key_1"]},
          key_2: [key_3: %Expr{expr: ["key_2", "key_3"]}],
          key_4: %Expr{expr: "value_4"}
        ]
      }

      assert [key_1: "value_1", key_2: [key_3: "value_3"], key_4: "value_4"] =
               Parser.parse_value(
                 expr,
                 %{"key_1" => "value_1", "key_2" => %{"key_3" => "value_3"}},
                 []
               )
    end
  end
end
