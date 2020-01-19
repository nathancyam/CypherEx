defmodule CypherEx.PropertyMap do
  def to_props(props) do
    Enum.map(props, fn
      {k, v} when is_binary(v) -> ~s(#{k}: "#{v}")
      {k, v} -> "#{k}: #{v}"
    end)
    |> Enum.join(", ")
    |> (fn props -> " { #{props} }" end).()
  end
end
