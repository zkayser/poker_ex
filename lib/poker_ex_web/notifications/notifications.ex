defmodule PokerEx.Notifications do
  alias PokerExWeb.Endpoint

  def notify_invitees(room, event \\ :creation) do
    room = PokerEx.PrivateRoom.preload(room)

    Enum.each(room.invitees,
      fn invitee ->
        Endpoint.broadcast("notifications:" <> "#{invitee.name}", message_for(event),
        %{title: room.title, owner: room.owner.name})
      end)
  end

  defp message_for(:creation), do: "invitation_received"
  defp message_for(:deletion), do: "room_deleted"
end