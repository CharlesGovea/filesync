defmodule Fsync do
  # Auxiliary functions
  defp reverse_join(second, first \\ "~") do
    Path.join(first, second)
  end

  def make_path(message) do
    IO.gets(message)
    |> reverse_join
    |> String.trim_trailing
    |> Path.expand
  end

  # Delete any files not present in the source directory
  defp clean_up([head | tail], path, src) do
    if head not in src do
      File.rm!( Path.join(path, head) )
    end
    clean_up(tail, path, src)
  end

  defp clean_up([], _path, _src) do
    IO.puts("All done!")
  end

  # Main sync funtionality
  defp r_sync(src, dest, [curr | next]) do
    sub = Path.relative_to(curr, src)
    new_path = Path.join(dest, sub)
    case {File.dir?(curr), File.dir?(new_path)} do
      {false, false} ->
        if not File.exists?(new_path) or File.read!(curr) != File.read!(new_path) do
          File.copy!(curr, new_path)
        end

      {_, false} ->
        File.mkdir(new_path)
        sync(curr, new_path)

      {false, _} ->
        File.rm_rf!(new_path)
        File.cp!(curr, new_path)

      _ ->
        sync(curr, new_path)
    end

    r_sync(src, dest, next)
  end

  defp r_sync(_src, dest, []) do
    File.ls!(dest)
    |> Enum.intersperse("\n>> ")
    |> List.insert_at(0, "\nFiles changed in #{dest}: \n>> ")
    |> IO.puts
  end

  def sync(src, dest) do
    files = File.ls!(src)
    if Enum.empty?(files) do
      File.rm_rf!(dest)
      File.mkdir!(dest)
      IO.puts(["All content in '", dest, "' has been removed!"])
    else
      r_sync(src, dest, files |> Enum.map( &(Path.join(src, &1)) ))
      clean_up(File.ls!(dest), dest, files)
    end
  end
end


# Main
src = Fsync.make_path("Insert source path: ")
dest = Fsync.make_path("Insert destination path: ")

case {File.exists?(src) and File.dir?(src), File.exists?(dest) and File.dir?(dest)} do
  {false, false} ->
    IO.puts("Error: Both paths don't exist or are not directories!")
  {false, _} ->
    IO.puts("Error: Source path doesn't exist or isn't a directory!")
  {_, false} ->
    IO.puts("Error: Destination path doesn't exist or isn't a directory!")
  _ ->
    Fsync.sync(src, dest)
end
