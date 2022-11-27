defmodule Fsync do
  defp reverse_join(second, first \\ "~") do
    Path.join(first, second)
  end

  def make_path(message) do
    IO.gets(message)
    |> reverse_join
    |> String.trim_trailing
    |> Path.expand
  end

  def sync(source, destination) do
    File.cp_r!(source, destination)
    File.ls!(destination)
    |> Enum.intersperse("\n>> ")
    |> List.insert_at(0, "\nCopied files: \n>> ")
    |> IO.puts
  end
end


# Main
src = Fsync.make_path("Insert source path: ")
dest = Fsync.make_path("Insert destination path: ")

case {File.exists?(src) and File.dir?(src), File.exists?(dest) and File.dir?(dest)} do
  {false, false} ->
    IO.puts("Error: Both paths don't exist or are not directories")
  {false, _} ->
    IO.puts("Error: Source path doesn't exist or isn't a directory")
  {_, false} ->
    IO.puts("Error: Destination path doesn't exist or isn't a directory")
  _ ->
    Fsync.sync(src, dest)
end
