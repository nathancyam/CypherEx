defmodule CypherEx.Examples.Organisation do
  use CypherEx.Schema

  schema "Organisation", labels: ["Organisation"] do
    property(:id, :string)
    property(:email, :string)
    property(:type, :string)
    property(:visible, :boolean)
  end

  relations do
    outgoing(:governs, __MODULE__)
    incoming(:child_of, __MODULE__)
  end
end
