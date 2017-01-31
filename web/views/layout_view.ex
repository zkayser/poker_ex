defmodule PokerEx.LayoutView do
  use PokerEx.Web, :view
  
  @doc """
  Generates the name for the JavaScript view module to
  use for this view/template combination.
  """
  def js_view_name(conn, view_template) do
    [view_name(conn), template_name(view_template)]
    |> Enum.reverse
    |> List.insert_at(0, "view")
    |> Enum.map(&String.capitalize/1)
    |> Enum.reverse
    |> Enum.join("")
  end
  
  # Takes the resource name of the view module and
  # removes the ending *_view* string.
  defp view_name(conn) do
    conn
    |> view_module
    |> Phoenix.Naming.resource_name
    |> String.replace("_view", "")
  end
  
  # Removes the extension from the template and
  # returns just the template name.
  defp template_name(template) when is_binary(template) do
    template
    |> String.split(".")
    |> Enum.at(0)
  end
end
