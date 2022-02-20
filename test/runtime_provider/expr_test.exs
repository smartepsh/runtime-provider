defmodule RuntimeProvider.ExprTest do
  use ExUnit.Case, async: true

  alias RuntimeProvider.Expr

  describe "cast literal value(s)" do
    test "without options" do
      assert %Expr{expr: "test_value"} = Expr.cast("test_value")
    end

    test "validate default options" do
      assert %Expr{required?: false, fallback: nil, type: :self} = Expr.cast("test_value")
    end

    test "with options" do
      assert %Expr{
               expr: "test_value",
               required?: true,
               fallback: [:another_app, :another_key],
               type: :integer
             } =
               Expr.cast(
                 {"test_value",
                  required?: true, fallback: [:another_app, :another_key], type: :integer}
               )
    end
  end

  describe "cast keys value(s)" do
    test "without options" do
      assert %Expr{expr: ["key_1", "key_2"]} = Expr.cast(["key_1", "key_2"])
    end

    test "validate default options" do
      assert %Expr{required?: false, fallback: nil, type: :self} = Expr.cast(["key_1", "key_2"])
    end

    test "with options" do
      assert %Expr{
               expr: ["key_1", "key_2"],
               required?: true,
               fallback: [:another_app, :another_key],
               type: :integer
             } =
               Expr.cast(
                 {["key_1", "key_2"],
                  required?: true, fallback: [:another_app, :another_key], type: :integer}
               )
    end
  end

  describe "cast keyword value(s)" do
    test "with keys" do
      data = [test_key: ["key_1", "key_2"]]
      assert %Expr{expr: [test_key: %Expr{expr: ["key_1", "key_2"]}]} = Expr.cast(data)
    end

    test "without options" do
      data = [test_key: "test_value"]
      assert %Expr{expr: [test_key: %Expr{expr: "test_value"}]} = Expr.cast(data)
    end

    test "validate default options" do
      data = [test_key: "test_value"]
      assert %Expr{required?: false, fallback: nil, type: :self} = Expr.cast(data)
    end

    test "with options" do
      data = [
        test_key:
          {"test_value", required?: true, fallback: [:another_app, :another_key], type: :integer}
      ]

      assert %Expr{
               expr: [
                 test_key: %Expr{
                   expr: "test_value",
                   required?: true,
                   fallback: [:another_app, :another_key],
                   type: :integer
                 }
               ]
             } = Expr.cast(data)
    end

    test "for nested values" do
      data = [first_key: [second_key: [third_key: {"test_value", required?: true}]]]

      assert %Expr{
               expr: [
                 first_key: [
                   second_key: [
                     third_key: %Expr{
                       expr: "test_value",
                       required?: true
                     }
                   ]
                 ]
               ]
             } = Expr.cast(data)
    end
  end

  describe "cast options" do
    test "raises when value type is invalid" do
      assert_raise ArgumentError, fn ->
        Expr.cast({"test_value", type: :another_type})
      end
    end

    test "raises when fallback is not list" do
      assert_raise ArgumentError, fn ->
        Expr.cast({"test_value", fallback: :not_list})
      end
    end

    test "raises when fallback is not atom list" do
      assert_raise ArgumentError, fn ->
        Expr.cast({"test_value", fallback: ["first", :second]})
      end
    end
  end
end
