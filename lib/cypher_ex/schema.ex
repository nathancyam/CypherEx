defmodule CypherEx.Schema do
  defmacro __using__(_) do
    Module.register_attribute(__CALLER__.module, :relationships, accumulate: true)
    Module.register_attribute(__CALLER__.module, :node_properties, accumulate: true)

    quote do
      import CypherEx.Schema
    end
  end

  defmacro schema(_source, labels, do: block) do
    record_node_properties(__CALLER__, labels, block)

    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    relationships =
      Module.get_attribute(__CALLER__.module, :relationships, [])
      |> generate_relationships()
      |> Macro.escape()

    [{[labels: labels], {:__block__, [], properties}}] =
      Module.get_attribute(__CALLER__.module, :node_properties)

    labels =
      Enum.join(labels, ":")
      |> Macro.escape()

    node_properties =
      Enum.map(properties, fn
        {:property, _, [field, type]} -> {field, type}
      end)
      |> Macro.escape()

    quote do
      def __labels__(), do: unquote(labels)

      def __properties__(), do: unquote(node_properties)

      def __relations__(), do: unquote(relationships)

      def __relations__(labels) when is_list(labels) do
        relations = Enum.map(labels, &__relations__(&1))

        if Enum.all?(relations, &is_nil/1) do
          []
        else
          relations
        end
      end

      def __relations__(label) when is_atom(label),
        do:
          Enum.find(unquote(relationships), fn {_dir, rel_label, schema, _props} ->
            rel_label == label
          end)
    end
  end

  defmacro relations(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro outgoing(rel_name, schema_mod) do
    record_relationship(__CALLER__, :outgoing, rel_name, schema_mod)
  end

  defmacro outgoing(rel_name, schema_mod, do: block) do
    record_relationship(__CALLER__, :outgoing, rel_name, schema_mod, block)
  end

  defmacro incoming(rel_name, schema_mod) do
    record_relationship(__CALLER__, :incoming, rel_name, schema_mod)
  end

  defmacro incoming(rel_name, schema_mod, do: block) do
    record_relationship(__CALLER__, :incoming, rel_name, schema_mod, block)
  end

  defp record_node_properties(env, labels, block) do
    Module.put_attribute(env.module, :node_properties, {
      labels,
      block
    })
  end

  defp record_relationship(env, direction, rel_name, schema_mod, block \\ nil) do
    Module.put_attribute(env.module, :relationships, {
      direction,
      rel_name,
      Macro.expand(schema_mod, env),
      block
    })
  end

  defp generate_relationships(relationships) do
    Enum.map(relationships, fn
      {direction, rel_name, schema_mod, nil} ->
        {direction, rel_name, schema_mod, []}

      {direction, rel_name, schema_mod, {:property, _, [prop_name, prop_type]}} ->
        {direction, rel_name, schema_mod, [{prop_name, prop_type}]}

      {direction, rel_name, schema_mod, {:__block__, _, property_list}} ->
        to_pair =
          for {:property, _pos, [prop_name, prop_type]} <- property_list do
            {prop_name, prop_type}
          end

        {direction, rel_name, schema_mod, to_pair}
    end)
  end
end
