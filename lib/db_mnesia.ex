defmodule DbMnesia do
  def select(table_name) do
    :mnesia.start
    table_atom = String.to_atom(table_name)
    :mnesia.wait_for_tables([table_atom], 1000)
    columns = :mnesia.table_info(table_atom, :attributes) |> Enum.map(& Atom.to_string(&1))
    specs = [table_atom] ++ Enum.map(1..Enum.count(columns), & :"$#{&1}") |> List.to_tuple
    rows = :mnesia.transaction(fn ->
      :mnesia.select(table_atom, [{specs, [], [:"$$"]}]) end) |> elem(1)
    %{
      columns: columns,
      command: :select,
      connection_id: 0,
      num_rows: Enum.count(rows),
      rows: rows
   }
  end
   def insert(table_name, _columns, values) do
       # TODO: 列選択はそのうち
       :mnesia.start
       table_atom = String.to_atom(table_name)
       :mnesia.wait_for_tables([table_atom], 1000)
       result = :mnesia.transaction(fn -> 
         next_id = max_id(table_atom) + 1
         insert_spec = values |> values_value 
           |> Tuple.insert_at(0, next_id) |> Tuple.insert_at(0, table_atom)
         writed = :mnesia.write(insert_spec)
         {writed, next_id}
       end)
       case result do
         {:atomic,  {:ok, id}} -> {:ok,    id }
         {:aborted, {err, _}}  -> {:error, err}
         {_,        {err, _}}  -> {:error, err}
         {err, _}              -> {:error, err}
       end
     end
    
     def max_id(table_atom) do
       {:atomic, keys} = :mnesia.transaction(fn -> :mnesia.all_keys(table_atom) end)
       case keys do
         [] -> -1
         _  -> Enum.max(keys)
       end
     end

     def update(table_name, sets, wheres) do
         :mnesia.start
         table_atom = String.to_atom(table_name)
         :mnesia.wait_for_tables([table_atom], 1000)
         where_value = wheres |> wheres_value |> elem(0)
         update_spec = sets |> sets_value 
           |> Tuple.insert_at(0, where_value) |> Tuple.insert_at(0, table_atom)
         result = :mnesia.transaction(fn -> :mnesia.write(update_spec) end)
         case result do
           {:atomic,  :ok} -> {:ok}
           {:aborted, err} -> {:error, err}
           {_,        err} -> {:error, err}
           err             -> {:error, err}
         end
       end
      
       def delete(table_name, wheres) do
         :mnesia.start
         table_atom = String.to_atom(table_name)
         :mnesia.wait_for_tables([table_atom], 1000)
         where_spec = wheres |> wheres_value |> Tuple.insert_at(0, table_atom)
         result = :mnesia.transaction(fn -> :mnesia.delete(where_spec) end)
         case result do
           {:atomic,  :ok} -> {:ok}
           {:aborted, err} -> {:error, err}
           {_,        err} -> {:error, err}
           err             -> {:error, err}
         end
       end

       def sets_value(sets) do
           sets
           |> Enum.reduce({}, fn set, acc ->
             kv = String.split(set, "=") |> Enum.map(& String.trim(&1))
             v = List.last(kv)
             Tuple.append(acc, raw_value(v))
           end)
         end

         @doc """
     SQL Values strings(list) to value list
    
     ## Examples
       iex> DbMnesia.values_value(["123", "'hoge'"])
       {123, "hoge"} 
       iex> DbMnesia.values_value(["987", "'foo'"])
       {987, "foo"} 
     """
     def values_value(values) do
       values 
       |> Enum.reduce({}, fn v, acc ->
         Tuple.append(acc, raw_value(v))
       end)
     end
    
     @doc """
     String value to raw value
    
     ## Examples
       iex> DbMnesia.raw_value("")
       ""
       iex> DbMnesia.raw_value("123")
       123
       iex> DbMnesia.raw_value("12.34")
       12.34
       iex> DbMnesia.raw_value("'hoge'")
       "hoge"
       iex> DbMnesia.raw_value("foo")
       "foo"
       iex> DbMnesia.raw_value("12ab3")
       "12ab3"
     """
     def raw_value(v) when is_binary(v) do
       case String.match?(v, ~r/^([0-9]|\.)+$/) do
         true -> 
           case String.match?(v, ~r/\./) do
             true -> String.to_float(v)
             _    -> String.to_integer(v)
           end
         _ -> v |> String.trim("'") |> String.trim("\"")
       end
     end
     def raw_value(v) when is_number(v), do: v
     def raw_value(v) when is_boolean(v), do: Atom.to_string(v)
      def wheres_value(wheres) do
         wheres
         |> Enum.reduce({}, fn where, acc ->
           kv = String.split(where, "=") |> Enum.map(& String.trim(&1))
           v = List.last(kv)
           Tuple.append(acc, raw_value(v))
         end)
       end
      
    end
