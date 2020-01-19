defmodule CypherEx.Examples.Employee do
  use CypherEx.Schema

  schema "Employee", labels: ["Employee"] do
    property(:id, :string)
    property(:email, :string)
    property(:role, :string)
  end

  relations do
    outgoing(:works_at, CypherEx.Examples.Organisation)
  end
end
