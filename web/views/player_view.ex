defmodule PokerEx.PlayerView do
  use PokerEx.Web, :view
  alias PokerEx.Player
  
  # You can just use Phoenix.View.render_many(players, PokerEx.PlayerView, "player.json")
  def render("index.json", %{players: players}) do
    %{
      players: Enum.map(players, &player_json/1)
    }
  end
  
  # TODO: Deprecate and remove
  def render("show.json", %{player: player}) do
    player_json(player)
  end
  
  def render("player.json", %{player: player}) do
    %{
      name: player.name,
      chips: player.chips,
      firstName: player.first_name,
      lastName: player.last_name,
      email: player.email 
    }
  end
  
  def render("player_list.json", %{players: players}) do
    for [id, name, blurb] <- players do
      %{
        name: name,
        id: id,
        blurb: blurb
      }
    end
  end
  
  # TODO: Deprecate and remove
  defp player_json(player) do
    %{
      name: player.name,
      chips: player.chips,
      firstName: player.first_name,
      lastName: player.last_name,
      email: player.email
    }
  end
  
  def render_dynamic_update_form_for(player, attr, opts \\ []) do
    str = Atom.to_string(attr)
    val = Map.get(player, attr)
    display_name = opts[:display_name] || str
    html_attr = to_html_attr(str)
    camel_case = to_camel_case(str)
    ~E"""
      <li>
        <div class="collapsible-header" id="<%= html_attr %>-header"><%= display_name %>: <span id="player-<%= html_attr %>-info"><%= val %></span>
          <span class="right">
            <i class="material-icons">mode_edit</i>
          </span>
        </div>
        <div class="collapsible-body">
          <form name="<%= camel_case %>Form" id="<%= html_attr %>-form">
            <div class="row">
              <div class="input-field col s6 offset-s2">
                <input value="<%= val %>" id="<%= html_attr %>" type="text" class="validate">
                <label for="<%= html_attr %>" class="active"><%= display_name %></label>
              </div>
              <div class="col s4"></div>
              <div class="col s6 offset-s2">
                <button class="btn green disabled" id="<%= html_attr %>-edit" type="submit">Save changes</button>
              </div>
            </div>
          </form>
        </div>
      </li>
    """
  end
  
  def full_name(%Player{first_name: first, last_name: last}) do
    "#{String.capitalize(first)} #{String.capitalize(last)}'s Profile"
  end
  def full_name(%Player{name: name}), do: "#{String.capitalize(name)}'s Profile"
  
  def stats(%Player{} = player, opts \\ []) do
    ~E"""
      <p id="welcome-back">Welcome back to PokerEx, <%= player.name %>!</p>
      <div class="center-align">
        <h3>STATS</h3>
      </div>
      <span class="left">Ongoing Games:</span><span class="right"><%= length(player.participating_rooms) %></span><br/>
      <span class="left">Open Invitations:</span><span class="right"><%= length(player.invited_rooms) %></span><br/>
      Be sure to check out our <%= link("public rooms", to: room_path(opts[:conn], :index)) %>
      <br/>
      <%= link("Go to your profile", to: player_path(opts[:conn], :show, player.id), class: "btn btn-large pink waves-effect") %>
    """
  end
  
  defp to_html_attr(attr) when is_atom(attr) do
    attr
    |> Atom.to_string
    |> to_html_attr
  end
  
  defp to_html_attr(attr) when is_binary(attr) do
    attr
    |> String.replace(~r(_), "-")
  end
  
  defp to_camel_case(str) when is_binary(str) do
    [head|tail] = String.split(str, "_")
    case tail do
      [] -> head
      x when is_list(x) ->
        tail_string =
          x
          |> Enum.drop(1)
          |> Enum.map(&String.capitalize/1)
          |> Enum.join("")
        head <> tail_string
    end
  end
  
  defp pluralize(1, {singular, _}, opts) do
    if opts[:wrap_number] do
      ~E"""
      <span id="<%= singular %>-number">1</span> <span id="<%= singular %>-count"><%= singular %></span>
      """
    else 
      "1 #{singular}"
    end
  end
  defp pluralize(num, {singular, plural}, opts) do
    if opts[:wrap_number] do
      ~E"""
      <span id="<%= singular %>-number"><%= num %></span> <span id="<%= singular %>-count"><%= plural %></span>
      """
    else
        "#{num} #{plural}"
    end
  end
  
  defp pluralize_word(1, {singular, _}) do
    "#{singular}"
  end
  defp pluralize_word(_, {_, plural}) do
    "#{plural}"
  end
  
  defp paginated_entries(list) when is_list(list) do
    Scrivener.paginate(list, page_number: 1, page_size: 10).entries
  end
end