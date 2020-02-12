defmodule CypherEx.SchemaTest do
  use ExUnit.Case
  import CypherEx.Query

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

  defmodule SecondExample do
    use CypherEx.Schema

    schema "SecondExample", labels: ["SecondExample"] do
      property(:id, :string)
      property(:name, :string)
    end

    relations do
      incoming(:from_example, Example) do
        property(:created_at, :number)
        property(:updated_at, :number)
      end
    end
  end

  defmodule ThirdExample do
    use CypherEx.Schema

    schema "ThirdExample", labels: ["ThirdExample"] do
      property(:id, :string)
      property(:name, :string)
    end

    relations do
      outgoing(:to_example, Example) do
        property(:created_at, :number)
        property(:updated_at, :number)
      end
    end
  end

  test "adds properties to the node representation" do
    match_expr =
      match(
        node(:first_example, Example, id: "test_id")
        |> relation(:test_relationship)
        |> node(:second_example, Example)
      )
      |> return([:first_example])
      |> to_string()

     assert match_expr == "MATCH (first_example:Example { id: \"test_id\" })-[:TEST_RELATIONSHIP]-(second_example:Example) RETURN first_example"
  end

  test "allows multiple nodes and relationships" do
    match_expr =
      match(
        node(:third, ThirdExample, [])
        |> relation(:to_example)
        |> node(:first, Example, id: "test_id")
        |> relation(:from_example)
        |> node(:second, SecondExample, [])
      )
      |> return([:first, :second])
      |> to_string()

    assert match_expr == "MATCH (third:ThirdExample)-[:TO_EXAMPLE]->(first:Example { id: \"test_id\" })-[:FROM_EXAMPLE]->(second:SecondExample) RETURN first, second"
  end

  test "adds properties to the relationship" do
    match_expr =
      match(
        node(:first, SecondExample)
        |> relation(:from_example, created_at: "2010-01-01")
        |> node(:second, Example)
      )
      |> return([:first])
      |> to_string()

    assert match_expr == "MATCH (first:SecondExample)<-[:FROM_EXAMPLE { created_at: \"2010-01-01\" }]-(second:Example) RETURN first"
  end
end
