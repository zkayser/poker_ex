defmodule PokerExWeb.UserSocket do
  use Phoenix.Socket
  require Logger
  @max_age 2 * 7 * 24 * 60 * 60

  ## Channels
  # channel "room:*", PokerEx.RoomChannel
  channel("players:*", PokerExWeb.PlayersChannel)
  channel("rooms:*", PokerExWeb.RoomsChannel)
  channel("games:*", PokerExWeb.GamesChannel)
  channel("lobby:lobby", PokerExWeb.LobbyChannel)
  channel("private_rooms:*", PokerExWeb.PrivateRoomChannel)
  channel("notifications:*", PokerExWeb.NotificationsChannel)
  channel("player_updates:*", PokerExWeb.PlayerUpdatesChannel)
  channel("online:lobby", PokerExWeb.OnlineChannel)
  channel("online:search", PokerExWeb.OnlineChannel)

  ## Transports
  transport(
    :websocket,
    Phoenix.Transports.WebSocket,
    timeout: 45_000,
    check_origin: [
      "http://localhost:8080",
      "http://localhost:8081",
      "https://ancient-forest-15148.herokuapp.com/",
      "https://poker-ex.herokuapp.com/"
    ]
  )

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
    Logger.debug("Attempting connect...")
    socket = assign(socket, :player_id, name)
    {:ok, socket}
  end

  def connect(%{"token" => token}, socket) do
    Logger.debug("You need a token to connect to the socket...")

    case Phoenix.Token.verify(socket, "user socket", token, max_age: @max_age) do
      {:ok, player_id} -> {:ok, assign(socket, :player_id, player_id)}
      {:error, _reason} -> :error
    end
  end

  def connect(%{"guardian_token" => token}, socket) do
    case Guardian.decode_and_verify(token) do
      {:ok, claims} ->
        Logger.debug("Succesfully authenticated")

        id =
          Regex.named_captures(~r/:(?<id>\d+)/, claims["aud"])
          |> Map.get("id")
          |> String.to_integer()

        {:ok, assign(socket, :player_id, id)}

      {:error, _reason} ->
        :error
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
  #     PokerExWeb.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(socket), do: "users_socket:#{socket.assigns.player_id}"
end
