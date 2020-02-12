defmodule CypherEx.Query.Builder.NodeExprTest do
  use ExUnit.Case
  alias CypherEx.Query.Builder.{NodeExpr, PathExpr, RelationExpr}
  defmodule Example do
    use CypherEx.Schema

    schema "Example", labels: ["Example"] do
      property(:id, :string)
      property(:name, :string)
    end

    relations do
      outgoing(:test_relationship, __MODULE__) do
        property(:created_at, :number)
        property(:updated_at, :number)
      end
    end
  end

  test "builds the node expression struct" do
    assert NodeExpr.build(:example, Example, []) == %CypherEx.Query.Builder.NodeExpr{
             properties: [],
             schema: __MODULE__.Example,
             var: :example
           }
  end

  test "builds the node expression struct with properties" do
    assert NodeExpr.build(:example, Example, [id: "example"]) == %CypherEx.Query.Builder.NodeExpr{
             properties: [id: "example"],
             schema: __MODULE__.Example,
             var: :example
           }
  end

  test "appends the node expression with a path struct is provided" do
    path_expr =
      %PathExpr{ path: [
        %NodeExpr{
          properties: [id: "first_entry"],
          schema: __MODULE__.Example,
          var: :example
        },
        %RelationExpr{
          labels: [:test_relationship]
        },
      ], bindings: []}
      |> NodeExpr.build(:path_example, Example, [id: "example"])

    assert List.last(path_expr.path) == %NodeExpr{
             properties: [id: "example"],
             schema: CypherEx.Query.Builder.NodeExprTest.Example,
             var: :path_example
           }
  end

  test "fails to build when property does not exist in schema" do
    assert_raise CypherEx.InvalidPropertyError, fn ->
      NodeExpr.build(:example, Example, [error: "not_valid"])
    end
  end

  test "fails to build when property is of a wrong type" do
    assert_raise CypherEx.InvalidPropertyError, fn ->
      NodeExpr.build(:example, Example, [id: 1])
    end
  end
end
