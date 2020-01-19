defmodule CypherEx.Query.Builder.WithExpr do
  defstruct [:bindings]

  def build() do
  end
end

defimpl String.Chars, for: CypherEx.Query.Builder.WithExpr do
  def to_string(%CypherEx.Query.Builder.WithExpr{bindings: bindings}) do
    str = Enum.join(bindings, ", ")
    "WITH #{str}"
  end
end
