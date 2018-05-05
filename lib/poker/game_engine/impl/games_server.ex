defmodule PokerEx.GameEngine.GamesServer do
  use GenServer
  require Logger

  ##################
  # INITIALIZATION #
  ##################

  def start_link(initial_games) do
    GenServer.start_link(__MODULE__, initial_games, name: __MODULE__)
  end

  def init(num_games \\ 1) do
    send(self(), {:start_games, num_games})
  end

  ##########
  # CLIENT #
  ##########

  def get_games do
    GenServer.call(__MODULE__, :get_games)
  end

  #############
  # CALLBACKS #
  #############

  def handle_call(:get_games, _from, %{games: games} = state) do
    {:reply, games, state}
  end

  def handle_info({:start_games, num_games}, _state) do
    Logger.info("Starting up #{num_games} initial games...")

    games =
      for x <- 1..num_games do
        game = "game_#{x}"
        PokerEx.GameEngine.GamesSupervisor.find_or_create_process(game)
        game
      end

    {:noreply, %{games: games}}
  end

  def handle_info(msg, state) do
    Logger.warn("GamesServer - Unknown message received: #{inspect(msg)}")
    {:noreply, state}
  end
end
