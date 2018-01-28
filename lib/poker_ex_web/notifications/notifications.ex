defmodule PokerEx.Notifications do
  alias PokerExWeb.Endpoint

  @type options :: [{:owner, String}, {:title, String.t}, {:invitees, list()}]

  # Header
  def notify_invitees(room_data, event \\ :creation)
  @spec notify_invitees(PokerEx.PrivateRoom.t, :creation | :deletion) :: :ok
  def notify_invitees(%PokerEx.PrivateRoom{} = room, event) do
    room = PokerEx.PrivateRoom.preload(room)

    Enum.each(room.invitees,
      fn invitee ->
        Endpoint.broadcast("notifications:" <> "#{invitee.name}", message_for(event),
        %{title: room.title, owner: room.owner.name})
      end)
  end

 	@spec notify_invitees(options, :creation | :deletion) :: :ok
 	def notify_invitees([owner: owner, title: title, invitees: invitees], event) do
 		Enum.each(invitees,
 			fn invitee ->
 				Endpoint.broadcast("notifications:" <> "#{invitee.name}", message_for(event),
 					%{title: title, owner: owner.name})
 			end)
 	end

  defp message_for(:creation), do: "invitation_received"
  defp message_for(:deletion), do: "room_deleted"
end