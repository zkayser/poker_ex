defmodule PokerEx.Notifications do
  alias PokerExWeb.Endpoint

  def notify_invitees(room) do
    room = PokerEx.PrivateRoom.preload(room)

    Enum.each(room.invitees,
      fn invitee ->
        Endpoint.broadcast("notifications:" <> "#{invitee.name}", "invitation_received",
        %{title: room.title, owner: room.owner.name})
      end)
  end
end