# CypherEx

A proof of concept library inspired by Ecto that adds a object mapper to the Cypher query language used by graph databases such as Neo4J. While the feature set is extremely limited, it mainly attempts to add some kind of structure between nodes and their relationships which can get out of hand in complex graph schemas.

This is _absolutely_ not for production usage in the slightest.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `cypher_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cypher_ex, "~> 0.1.0"},
    // {:cypher_ex, git: "git://github.com/nathancyam/cypher_ex.ex"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/cypher_ex](https://hexdocs.pm/cypher_ex).

## Usage

At the heart of a graph database are nodes that typically represent entities which are related to each other via edges. A node is given its own module and uses the `CypherEx.Schema` macro.

```elixir
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
```

This declares the expected properties as well as relations between each node. With this constraint, we can use the `CypherEx.Query` functions to generate Cypher queries that ensure that these rules from the schema are valid.

```elixir
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
```

If the relationship between nodes is invalid, the query will fail at _runtime_ and inform you that aspects of the query are incorrect. Piping this query into `to_string()` will return the Cypher string back in case inspection is required.

### Todo

- [x] Add properties to relationships.
- [ ] Add validations on relationships properties.
- [ ] Add create function to generate nodes.
- [ ] Add proper variable binding support.
