defmodule CypherEx.Query.Builder.PathExpr do
  defstruct [:path, :bindings]
end

defimpl String.Chars, for: CypherEx.Query.Builder.PathExpr do
  def to_string(%CypherEx.Query.Builder.PathExpr{path: path}) do
    Enum.map_join(path, &String.Chars.to_string/1)
  end
end
