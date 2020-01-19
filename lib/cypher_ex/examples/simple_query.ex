defmodule CypherEx.Examples.SimpleQuery do
  import CypherEx.Query

  alias CypherEx.Examples.{Employee, Organisation}

  def test() do
    match(
      node(:org, Organisation, id: "Some ID")
      |> relation([:governs, :child_of], id: "dsf")
      |> node(:org_1, Organisation)
      |> relation([:works_at], id: "test")
      |> node(:worker, Employee)
    )
    |> where(worker.role == "Developer")
    |> return([:org_1, :worker])
  end
end
