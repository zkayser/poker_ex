defmodule PokerEx.UserSocket do
  use Phoenix.Socket
  @max_age 2 * 7 * 24 * 60 * 60

  ## Channels
  # channel "room:*", PokerEx.RoomChannel
  channel "players:*", PokerEx.PlayersChannel
  channel "notifications:*", PokerEx.NotificationsChannel
  channel "online:lobby", PokerEx.OnlineChannel
  channel "online:search", PokerEx.OnlineChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket,
            timeout: 45_000, check_origin: ["https://phoenix-experiment-zkayser.c9users.io", "//ancient-forest-15148.herokuapp.com/"]
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"name" => name}, socket) do
    socket = assign(socket, :player_name, name)
    {:ok, socket}
  end
  
  def connect(%{"token" => token}, socket) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: @max_age) do
      {:ok, player_id} -> {:ok, assign(socket, :player_id, player_id)}
      {:error, _reason} -> :error
    end
  end 
  
  def connect(_params, _socket), do: :error

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     PokerEx.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(socket), do: "users_socket:#{socket.assigns.player_id}"
end
