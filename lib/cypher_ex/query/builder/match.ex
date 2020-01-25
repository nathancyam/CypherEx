defmodule CypherEx.Query.Builder.MatchExpr do
  alias CypherEx.Query.Builder.PathExpr

  defstruct [:where, :optional?, :returns, paths: []]

  def append_match(%__MODULE__{} = match, %PathExpr{} = path) do
    %{match | paths: match.paths ++ [path]}
  end
end

defimpl String.Chars, for: CypherEx.Query.Builder.MatchExpr do
  def to_string(%CypherEx.Query.Builder.MatchExpr{paths: paths, where: nil, optional?: false}) do
    ps = Enum.join(paths, "\n")
    "MATCH #{ps}"
  end

  def to_string(%CypherEx.Query.Builder.MatchExpr{paths: paths, where: nil, optional?: true}) do
    ps = Enum.join(paths, "\n")
    "OPTIONAL MATCH #{ps}"
  end

  def to_string(%CypherEx.Query.Builder.MatchExpr{paths: paths, where: where, optional?: false}) do
    ps = Enum.join(paths, "\n")
    "MATCH #{ps} #{String.Chars.to_string(where)}"
  end

  def to_string(%CypherEx.Query.Builder.MatchExpr{paths: paths, where: where, optional?: true}) do
    ps = Enum.join(paths, "\n")
    "OPTIONAL MATCH #{ps} #{String.Chars.to_string(where)}"
  end
end
