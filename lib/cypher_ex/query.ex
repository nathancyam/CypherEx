defmodule CypherEx.Query do
  alias CypherEx.Query.Builder.{PathExpr, RelationExpr, MatchExpr, NodeExpr}
  alias CypherEx.Query.Validator

  defstruct [:matches, returns: [], withs: []]

  def match(%PathExpr{} = expr),
    do: %__MODULE__{
      matches: [%MatchExpr{paths: [Validator.check_path!(expr)], optional?: false}]
    }

  def match(%__MODULE__{} = query, %MatchExpr{} = second_match),
    do: %{query | matches: query.matches ++ [second_match]}

  def optional_match(%PathExpr{} = expr),
    do: %__MODULE__{
      matches: [%MatchExpr{paths: [expr], optional?: true}]
    }

  def optional_match(%__MODULE__{} = query, %PathExpr{} = second),
    do: match(query, %MatchExpr{paths: [second], optional?: true})

  defmacro where(expr, where_expr) do
    where = CypherEx.Query.Builder.WhereExpr.build(where_expr)

    quote do
      u = unquote(where)
      %CypherEx.Query{matches: matches} = query = unquote(expr)
      %CypherEx.Query.Builder.MatchExpr{paths: paths} = last_match = List.last(matches)
      %{path: path} = hd(paths)

      valid_bindings? =
        Enum.any?(path, fn
          %CypherEx.Query.Builder.NodeExpr{var: path_var, schema: schema} ->
            case Keyword.fetch(schema.__properties__(), u.property) do
              :error ->
                false

              {:ok, val} ->
                path_var == u.target
            end

          %{var: path_var} ->
            path_var == u.target
        end)

      unless valid_bindings? do
        raise CypherEx.NoValidBindingsError,
          message:
            "WHERE statement must references prior bindings to this match clauses and no WITH clauses were included."
      end

      %{
        query
        | matches:
            Enum.map(query.matches, fn
              ^last_match ->
                %{last_match | where: u}

              other ->
                other
            end)
      }
    end
  end

  def node(var_or_path, schema, properties \\ [])

  def node(var, schema, properties) when is_atom(var),
    do: NodeExpr.build(var, schema, properties)

  def node(%PathExpr{} = expr, var, schema), do: NodeExpr.build(expr, var, schema)

  def node(%PathExpr{path: _path} = expr, var, schema, properties) do
    NodeExpr.build(expr, var, schema, properties)
  end

  def relation(%NodeExpr{} = node, labels, properties),
    do: RelationExpr.build(node, labels, properties)

  def relation(%PathExpr{} = path, labels, properties),
    do: RelationExpr.build(path, labels, properties)

  def return(%__MODULE__{returns: []} = query, return) when is_atom(return),
    do: %{query | returns: [return]}

  def return(%__MODULE__{returns: returns} = query, return) when is_list(return),
    do: %{query | returns: List.flatten(returns ++ [return])}

  def with_bind(%__MODULE__{withs: withs} = query, vars) when is_list(vars) do
    %{query | withs: Enum.concat(withs, [%CypherEx.Query.Builder.WithExpr{bindings: vars}])}
  end

  def with_bind(%__MODULE__{withs: withs} = query, vars) when is_atom(vars) do
    %{query | withs: Enum.concat(withs, [%CypherEx.Query.Builder.WithExpr{bindings: [vars]}])}
  end
end

defimpl String.Chars, for: CypherEx.Query do
  def to_string(%CypherEx.Query{matches: matches, withs: withs, returns: returns}) do
    collected_expressions = reduce_matches(matches, withs)
    joined_returns = Enum.join(returns, ", ")

    "#{collected_expressions} RETURN #{joined_returns}"
  end

  defp reduce_matches(result \\ "", matches, with)

  defp reduce_matches(result, matches, []) do
    collected_expressions =
      for match <- matches, into: "" do
        String.Chars.to_string(match)
      end

    "#{result} #{collected_expressions}"
  end

  defp reduce_matches(result, matches, withs) do
    [head_match | tail_matches] = matches
    [head_with | tail_withs] = withs

    res =
      case result do
        "" ->
          "#{String.Chars.to_string(head_match)} #{String.Chars.to_string(head_with)}"

        con ->
          "#{con} #{String.Chars.to_string(head_match)} #{String.Chars.to_string(head_with)}"
      end

    reduce_matches(res, tail_matches, tail_withs)
  end
end
