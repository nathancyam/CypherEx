defmodule CypherEx.Query.Builder.WhereExpr do
  defstruct [:property, :target, :condition]

  def build({:==, _, [{{:., _, [{binding, _, nil}, prop]}, _, _}, val]}) do
    quote do
      %CypherEx.Query.Builder.WhereExpr{
        property: unquote(prop),
        target: unquote(binding),
        condition: %{
          symbol: "==",
          val: unquote(val)
        }
      }
    end
  end
end

defimpl String.Chars, for: CypherEx.Query.Builder.WhereExpr do
  def to_string(%CypherEx.Query.Builder.WhereExpr{
        property: prop,
        target: target,
        condition: condition
      }) do
    "WHERE #{target}.#{prop} #{condition.symbol} #{condition.val}"
  end
end
