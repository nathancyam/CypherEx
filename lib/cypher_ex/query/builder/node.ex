defmodule CypherEx.Query.Builder.NodeExpr do
  alias CypherEx.Query.Builder.{PathExpr, RelationExpr}
  alias CypherEx.Query.Validator

  defstruct [:var, :schema, :properties]

  def build(var_or_path, schema, properties \\ [])

  def build(var, schema, properties) when is_atom(var) do
    %__MODULE__{var: var, schema: schema, properties: properties}
  end

  def build(%PathExpr{} = expr, var, schema) do
    build(expr, var, schema, [])
  end

  def build(%PathExpr{path: path} = expr, var, schema, properties) do
    %RelationExpr{labels: labels} = List.last(path)
    Validator.check_node_relations!(schema, labels)
    Validator.check_properties!(properties)
    %{expr | path: path ++ [build(var, schema, properties)]}
  end
end

defimpl String.Chars, for: CypherEx.Query.Builder.NodeExpr do
  def to_string(%CypherEx.Query.Builder.NodeExpr{var: var, schema: schema, properties: []}) do
    "(#{Atom.to_string(var)}:#{schema.__labels__()})"
  end

  def to_string(%CypherEx.Query.Builder.NodeExpr{var: var, schema: schema, properties: props}) do
    props = CypherEx.PropertyMap.to_props(props)
    "(#{Atom.to_string(var)}:#{schema.__labels__()}#{props})"
  end
end
