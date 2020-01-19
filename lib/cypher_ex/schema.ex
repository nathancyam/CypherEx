defmodule CypherEx.Schema do
  defmacro __using__(_) do
    quote do
      import CypherEx.Schema
      Module.register_attribute(__MODULE__, :properties, accumulate: true)
      Module.register_attribute(__MODULE__, :relationships, accumulate: true)
    end
  end

  defmacro schema(_source, labels, do: block) do
    quote do
      unquote(block)

      def __labels__(), do: Enum.join(Keyword.fetch!(unquote(labels), :labels), ":")

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __properties__(), do: @properties

      def __relations__(), do: @relationships

      def __relations__(labels) when is_list(labels) do
        relations = Enum.map(labels, &__relations__(&1))

        if Enum.all?(relations, &is_nil/1) do
          []
        else
          relations
        end
      end

      def __relations__(label) when is_atom(label),
        do: Enum.find(@relationships, fn {_dir, rel_label, schema} -> rel_label == label end)
    end
  end

  defmacro property(field, type) do
    quote do
      Module.put_attribute(__MODULE__, :properties, {unquote(field), unquote(type)})
    end
  end

  defmacro relations(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro outgoing(rel_name, schema_mod) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :relationships,
        {:outgoing, unquote(rel_name), unquote(schema_mod)}
      )
    end
  end

  defmacro incoming(rel_name, schema_mod) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :relationships,
        {:incoming, unquote(rel_name), unquote(schema_mod)}
      )
    end
  end
end
