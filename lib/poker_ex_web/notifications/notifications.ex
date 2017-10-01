defmodule PokerEx.Notifications do
  alias PokerExWeb.Endpoint
  
  def notify_invitees(room) do
    room = PokerEx.PrivateRoom.preload(room)
    
    Enum.each(room.invitees, 
      fn invitee -> 
        Endpoint.broadcast("notifications:" <> "#{invitee.id}", "invitation_received", 
        %{title: room.title, id: room.id, participants: room.participants, owner: room.owner.name})
      end)
  end
end