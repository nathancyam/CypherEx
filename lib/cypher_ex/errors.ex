defmodule CypherEx.InvalidLabelsError do
  defexception [:message]
end

defmodule CypherEx.InvalidPropertyError do
  defexception [:message]
end

defmodule CypherEx.NoValidBindingsError do
  defexception [:message]
end

defmodule CypherEx.BadQueryError do
  defexception [:message]
end
