defmodule CypherEx.Query.ValidatorTest do
  use ExUnit.Case

  alias CypherEx.Query.Validator

  describe "validate_properties" do
    test "should pass" do
      assert Validator.validate_properties!([
        {:id, :string},
        {:example, :number},
      ], [id: "example", example: 1])
    end

    test "fails when key is not found" do
      assert_raise CypherEx.InvalidPropertyError, fn ->
        Validator.validate_properties!([
          {:id, :string},
          {:example, :number},
        ], [incorrect: "example", example: 1])
      end
    end

    test "fails when value is the wrong type" do
      assert_raise CypherEx.InvalidPropertyError, fn ->
        Validator.validate_properties!([
          {:id, :string},
          {:example, :number},
        ], [id: 1, example: 1])
      end
    end
  end

  describe "check_path!/1" do
    test "verifies relationship" do
      path = %CypherEx.Query.Builder.PathExpr{
        bindings: nil,
        path: [
          %CypherEx.Query.Builder.NodeExpr{
            properties: [id: "Some ID"],
            schema: CypherEx.Examples.Organisation,
            var: :org
          },
          %CypherEx.Query.Builder.RelationExpr{
            direction: nil,
            labels: [:governs, :child_of],
            properties: [id: "dsf"],
            var: nil
          },
          %CypherEx.Query.Builder.NodeExpr{
            properties: [],
            schema: CypherEx.Examples.Organisation,
            var: :org_1
          },
          %CypherEx.Query.Builder.RelationExpr{
            direction: nil,
            labels: [:works_at],
            properties: [id: "test"],
            var: nil
          },
          %CypherEx.Query.Builder.NodeExpr{
            properties: [],
            schema: CypherEx.Examples.Employee,
            var: :worker
          }
        ]
      }

      expected_path = %CypherEx.Query.Builder.PathExpr{
        bindings: nil,
        path: [
          %CypherEx.Query.Builder.NodeExpr{
            properties: [id: "Some ID"],
            schema: CypherEx.Examples.Organisation,
            var: :org
          },
          %CypherEx.Query.Builder.RelationExpr{
            direction: :bidirectional,
            properties: [id: "dsf"],
            var: nil,
            labels: [
              {:outgoing, :governs, CypherEx.Examples.Organisation,
               [created_at: :number, updated_at: :number]},
              {:incoming, :child_of, CypherEx.Examples.Organisation, [position: :string]}
            ]
          },
          %CypherEx.Query.Builder.NodeExpr{
            properties: [],
            schema: CypherEx.Examples.Organisation,
            var: :org_1
          },
          %CypherEx.Query.Builder.RelationExpr{
            direction: :right_to_left,
            properties: [id: "test"],
            var: nil,
            labels: [{:outgoing, :works_at, CypherEx.Examples.Organisation, []}]
          },
          %CypherEx.Query.Builder.NodeExpr{
            properties: [],
            schema: CypherEx.Examples.Employee,
            var: :worker
          }
        ]
      }

      assert CypherEx.Query.Validator.check_path!(path) == expected_path
    end
  end
end
