defmodule CypherEx.Query.Properties do
  def to_props(props) do
    Enum.map(props, fn
      {k, v} when is_binary(v) -> ~s(#{k}: "#{v}")
      {k, v} -> "#{k}: #{v}"
    end)
    |> Enum.join(", ")
    |> (fn props -> " { #{props} }" end).()
  end

  def check_properties!(props) do
    Enum.map(props, fn
      {_key, val} when is_binary(val) ->
        :ok

      {_key, val} when is_number(val) ->
        :ok

      {_key, val} when is_boolean(val) ->
        :ok

      {key, val} ->
        raise ArgumentError, message: "Invalid property type given: #{key}: #{val}"
    end)

    props
  end
end
