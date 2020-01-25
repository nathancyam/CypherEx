defmodule CypherEx.Examples.Organisation do
  use CypherEx.Schema

  schema "Organisation", labels: ["Organisation"] do
    property(:id, :string)
    property(:email, :string)
    property(:type, :string)
    property(:visible, :boolean)
  end

  relations do
    outgoing(:governs, __MODULE__) do
      property(:created_at, :number)
      property(:updated_at, :number)
    end

    incoming(:child_of, __MODULE__) do
      property(:position, :string)
    end

    outgoing(:works, CypherEx.Examples.Employee) do
      property(:started_date, :string)
    end
  end
end
