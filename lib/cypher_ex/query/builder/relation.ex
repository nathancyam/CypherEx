defmodule CypherEx.Query.Builder.RelationExpr do
  alias CypherEx.Query.Builder.{NodeExpr, PathExpr}
  alias CypherEx.Query.Validator

  defstruct [:var, :labels, :properties, :direction]

  def build(%NodeExpr{} = node, labels, properties) when is_list(labels) do
    %PathExpr{
      path: [node, build_from_node(node, labels, properties)]
    }
  end

  def build(%NodeExpr{} = node, label, properties) when is_atom(label) do
    build(node, List.wrap(label), properties)
  end

  def build(%PathExpr{path: path} = expr, label, properties) do
    last_node = List.last(path)

    labels =
      if is_list(label) do
        label
      else
        List.wrap(label)
      end

    %{expr | path: Enum.concat(path, [build_from_node(last_node, labels, properties)])}
  end

  defp build_from_node(%NodeExpr{}, labels, properties) do
    Validator.check_properties!(properties)

    %__MODULE__{
      var: nil,
      labels: labels,
      properties: properties
    }
  end
end

defimpl String.Chars, for: CypherEx.Query.Builder.RelationExpr do
  def to_string(%CypherEx.Query.Builder.RelationExpr{} = expr) do
    labels =
      Enum.map(expr.labels, fn {_dir, label, _schema, _props} ->
        Atom.to_string(label)
        |> (fn l -> ":#{l}" end).()
        |> String.upcase()
      end)
      |> Enum.join("|")

    direction_fn =
      expr.direction
      |> to_rel_repl(expr.properties)

    direction_fn.(labels)
  end

  defp to_rel_repl(:bidirectional, []), do: &"-[#{&1}]-"

  defp to_rel_repl(:bidirectional, props),
    do: &"-[#{&1}#{to_props(props)}]-"

  defp to_rel_repl(:left_to_right, []), do: &"-[#{&1}]->"
  defp to_rel_repl(:left_to_right, props), do: &"-[#{&1}#{to_props(props)}]->"

  defp to_rel_repl(:right_to_left, []), do: &"<-[#{&1}]-"
  defp to_rel_repl(:right_to_left, props), do: &"<-[#{&1}#{to_props(props)}]-"

  defp to_props(props) do
    CypherEx.PropertyMap.to_props(props)
  end
end
