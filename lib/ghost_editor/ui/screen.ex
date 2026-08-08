defmodule GhostEditor.UI.Screen do
  import Ratatouille.View
  use GhostEditor.Constants.Colors
  use GhostEditor.Constants.Paths
  alias GhostEditor.AdjustSize
  alias GhostEditor.UI.CursorBar
  import GhostEditor.Utils.FunctionName, only: [name: 0]

  @spec render(
          %{
            window: any(),
            text: String.t(),
            displays: %{
              screen: %{size: number()},
              menu: %{
                focussed_file: String.t()
              }
            }
          },
          any()
        ) :: any()

  def render(model, menu) do
    %{
      window: window,
      text: text
    } =
      model

    height = window.height - 2

    size = AdjustSize.adjust(:screen, %{model: model})

    data = File.read!(@focussed_file_path)

    element =
      cond do
        File.dir?(data) || archived_file?(data) ->
          files =
            cond do
              archived_file?(data) ->
                list_archived_files(data)

              true ->
                files = Path.wildcard("#{data}/**")
                files
            end

          view(bottom_bar: CursorBar.render(%{model | displays: %{cursor_bar: %{size: 2}}})) do
            overlay(padding: 0) do
              row do
                menu

                column(size: size) do
                  panel(
                    height: height + 2,
                    border: %{color: @default_border_color},
                    padding: 0
                  ) do
                    directory_tree(files)
                  end
                end
              end
            end
          end

        dump_file?(data) ->
          view(bottom_bar: CursorBar.render(%{model | displays: %{cursor_bar: %{size: 2}}})) do
            overlay(padding: 0) do
              row do
                menu

                column(size: size) do
                  panel(
                    height: height + 2,
                    border: %{color: @default_border_color},
                    padding: 0
                  ) do
                    label(
                      content: text <> "|" <> "#{data}",
                      attributes: [:bold],
                      color: @default_text_color
                    )
                  end
                end
              end
            end
          end

        true ->
          data = File.read!(data)

          view(bottom_bar: CursorBar.render(%{model | displays: %{cursor_bar: %{size: 2}}})) do
            overlay(padding: 0) do
              row do
                menu

                column(size: size) do
                  panel(
                    height: height + 2,
                    border: %{color: @default_border_color},
                    padding: 0
                  ) do
                    label(
                      content: text <> "|" <> "#{data}",
                      attributes: [:bold],
                      color: @default_text_color
                    )
                  end
                end
              end
            end
          end
      end

    element
  end

  defp archived_file?(file_name),
    do:
      Path.extname(file_name) == ".zip" || Path.extname(file_name) == ".tar" ||
        Path.extname(file_name) == ".gz"

  defp list_archived_files(file_name) do
    file_extension = Path.extname(file_name)

    case file_extension do
      ".zip" ->
        {:ok, files} = file_name |> to_charlist() |> :zip.unzip()
        File.rm_rf!(hd(String.split(file_name, ".zip")))
        files

      ".tar" ->
        {:ok, files} = :erl_tar.table(file_name)
        files

      ".gz" ->
        {:ok, files} = :erl_tar.table(file_name, [:compressed])
        files

      _ ->
        raise "#{file_extension} is not implemented for #{name()}"
    end
  end

  defp dump_file?(file_name), do: Path.extname(file_name) == ".dump"

  defp directory_tree(files) do
    dirs =
      for file <- files do
        if is_list(file) do
          List.to_string(file) |> String.split("/")
        else
          String.split(file, "/")
        end
      end

    dirs = dirs |> List.flatten() |> Enum.uniq()

    cond do
      Enum.count(dirs) == 1 ->
        tree do
          tree_node(content: hd(dirs))
        end

      true ->
        [_ | rest_dirs] = dirs

        tree do
          tree_node(content: hd(dirs)) do
            for dir <- rest_dirs do
              tree_node(content: dir) do
              end
            end
          end
        end
    end
  end
end
