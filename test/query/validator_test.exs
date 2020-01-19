defmodule CypherEx.Query.ValidatorTest do
  use ExUnit.Case

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
            labels: [
              {:outgoing, :governs, CypherEx.Examples.Organisation},
              {:incoming, :child_of, CypherEx.Examples.Organisation}
            ],
            properties: [id: "dsf"],
            var: nil
          },
          %CypherEx.Query.Builder.NodeExpr{
            properties: [],
            schema: CypherEx.Examples.Organisation,
            var: :org_1
          },
          %CypherEx.Query.Builder.RelationExpr{
            direction: :right_to_left,
            labels: [{:outgoing, :works_at, CypherEx.Examples.Organisation}],
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

      assert CypherEx.Query.Validator.check_path!(path) == expected_path
    end
  end
end
