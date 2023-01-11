defmodule Db do
  def query(sql) when sql != "" do
    cond do
      String.match?(sql, ~r/select.*/) -> select(sql)
      String.match?(sql, ~r/insert.*/) -> insert(sql)
      String.match?(sql, ~r/update.*/) -> update(sql)
      String.match?(sql, ~r/delete.*/) -> delete(sql)
    end
  end
  def select(sql) do
    Regex.named_captures(~r/select( *)(?<columns>.*)( *)from( *)(?<tables>.*)/, sql)["tables"]
    |> DbMnesia.select
  end
  def insert(sql) do
       parsed_map = 
         ~r/insert( *)into( *)(?<tables>.*)( *)values\(( *)(?<values>.*)( *)\)/
         |> Regex.named_captures(sql)
       DbMnesia.insert(
         parsed_map["tables"]  |> string_to_list |> List.first, 
         [], 
         parsed_map["values"]  |> string_to_list)
     end
      def update(sql) do
         parsed_map = 
           ~r/update( *)(?<tables>.*)( *)set( *)(?<sets>.*)( *)where( *)(?<wheres>.*)/
           |> Regex.named_captures(sql)
         DbMnesia.update(
           parsed_map["tables"] |> string_to_list |> List.first, 
           parsed_map["sets"  ] |> string_to_list, 
           parsed_map["wheres"] |> string_to_list)
       end
      
       def delete(sql) do
         parsed_map = 
          ~r/delete( *)from( *)(?<tables>.*)( *)where( *)(?<wheres>.*)/
          |> Regex.named_captures(sql)
        DbMnesia.delete(
          parsed_map["tables"] |> string_to_list |> List.first, 
          parsed_map["wheres"] |> string_to_list)
      end 
   
     @doc """
     String to list(item trimmed)
    
     ## Examples
         iex> Db.string_to_list("id = 123, name = 'hoge'")
         ["id = 123", "name = 'hoge'"]
         iex> Db.string_to_list("team = 'foo'")
         ["team = 'foo'"]
         iex> Db.string_to_list("")
         [""]
     """
     def string_to_list(string), do: string |> String.split(",") |> Enum.map(& String.trim(&1))
      def columns_rows(result) do
    result
    |> rows
    |> Enum.map(fn row -> Enum.into(List.zip([columns(result), row]), %{}) end)
  end
  def rows(%{rows: rows} = _result), do: rows
  def columns(%{columns: columns} = _result), do: columns
end
