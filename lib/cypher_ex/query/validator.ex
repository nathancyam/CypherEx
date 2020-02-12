defmodule CypherEx.Query.Validator do
  alias CypherEx.Query.Builder.{NodeExpr, PathExpr, RelationExpr}

  def check_node_relations!(schema, relationships) when is_list(relationships) do
    invalid_rel_labels =
      Enum.filter(relationships, fn
        {_direction, rel, _props} ->
          schema.__relations__(rel) == nil

        rel when is_atom(rel) ->
          schema.__relations__(rel) == nil
      end)

    unless Enum.empty?(invalid_rel_labels) do
      raise CypherEx.InvalidLabelsError,
        message: "Invalid labels #{inspect(invalid_rel_labels)} against #{inspect(schema)}"
    end

    :ok
  end

  def check_properties!(props) do
    Enum.each(props, fn
      {_key, val} when is_binary(val) ->
        :ok

      {_key, val} when is_number(val) ->
        :ok

      {_key, val} when is_boolean(val) ->
        :ok

      {key, val} ->
        raise CypherEx.InvalidPropertyError,
          message: "Invalid property type given: #{key}: #{val}"
    end)

    props
  end

  def validate_properties!(schema_properties, properties) do
    valid_keys = Keyword.keys(schema_properties)

    with_validator = for {k,v} <- schema_properties, into: %{} do
      case v do
        :string -> {k, &(is_bitstring/1)}
        :number -> {k, &(is_number/1)}
      end
    end

    unless Enum.all?(properties, fn
      {given_key, given_value} ->
        Enum.member?(valid_keys, given_key) && Map.get(with_validator, given_key).(given_value)
    end) do
      raise CypherEx.InvalidPropertyError
    end

    properties
  end

  def check_path!(%PathExpr{path: path} = expr) do
    chunks = Enum.chunk_every(path, 3, 2, :discard)

    new_path =
      for [source_node, relation, target_node] <- chunks, into: [] do
        verify_path(source_node, relation, target_node)
      end
      |> List.flatten()
      |> Enum.dedup()

    %{expr | path: new_path}
  end

  defp verify_path(
         %NodeExpr{} = source_node,
         %RelationExpr{labels: rels} = relation,
         %NodeExpr{} = target_node
       ) do
    source_rels = source_node.schema.__relations__(rels)
    target_rels = target_node.schema.__relations__(rels)

    new_rel =
      cond do
        Enum.empty?(source_rels) && Enum.empty?(target_rels) ->
          raise CypherEx.BadQueryError,
            message:
              "No valid relationship exists between #{inspect(source_node.schema)} and #{
                inspect(target_node.schema)
              }. Labels provided were: #{rels}"

        Enum.empty?(source_rels) ->
          %{relation | labels: target_rels, direction: label_direction(target_rels, :right)}

        Enum.empty?(target_rels) ->
          %{relation | labels: source_rels, direction: label_direction(source_rels, :left)}

        true ->
          rels = Enum.uniq(source_rels ++ target_rels)
          %{relation | labels: rels, direction: :bidirectional}
      end

    [source_node, new_rel, target_node]
  end

  defp label_direction(labels, :left) do
    # if the node is to the left, outgoing relationships go :left_to_right
    #                             incoming relationships go :right_to_left
    #                             relationships go :bidirectional

    case label_directions(labels) do
      :bidirectional -> :bidirectional
      :outgoing -> :left_to_right
      :incoming -> :right_to_left
    end
  end

  defp label_direction(labels, :right) do
    # if the node is to the right, outgoing relationships go :right_to_left
    #                              incoming relationships go :left_to_right
    #                              relationships go :bidirectional

    case label_directions(labels) do
      :bidirectional -> :bidirectional
      :outgoing -> :right_to_left
      :incoming -> :left_to_right
    end
  end

  defp label_directions(labels) do
    labels
    |> Enum.map(fn {dir, _, _, _} -> dir end)
    |> Enum.uniq()
    |> to_rel_repl()
  end

  defp to_rel_repl(directions) when length(directions) == 2,
    do: :bidirectional

  defp to_rel_repl([:outgoing]), do: :outgoing
  defp to_rel_repl([:incoming]), do: :incoming
end
