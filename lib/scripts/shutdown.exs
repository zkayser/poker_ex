alias PokerEx.PrivateRoom
alias PokerEx.RoomsSupervisor, as: RoomSup
alias PokerEx.Repo
require Logger

priv_rooms = Repo.all(PrivateRoom)

for priv_room <- priv_rooms do
  proc_alias = String.to_atom(priv_room.title)
  Logger.info "Shutting down private rooms..."
  if RoomSup.room_process_exists?(proc_alias) do
    pid = Process.whereis(proc_alias)
    Supervisor.terminate_child(RoomSup, pid)
  end
end