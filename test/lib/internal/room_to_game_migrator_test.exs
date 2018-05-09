defmodule PokerEx.RoomToGameMigratorTest do
  use ExUnit.Case
  alias PokerEx.RoomToGameMigrator, as: Migrator
  alias PokerEx.GameEngine.Impl, as: Game

  @room_data %{
    active: [{"Norris", 1}, {"Zack", 0}],
    all_in: [],
    called: ["Zack"],
    chip_roll: %{"Norris" => 1_000_001_010, "Zack" => 400_165},
    current_big_blind: 1,
    current_small_blind: 0,
    deck: %PokerEx.Deck{
      cards: [
        %PokerEx.Card{rank: :two, suit: :spades},
        %PokerEx.Card{rank: :six, suit: :clubs},
        %PokerEx.Card{rank: :ten, suit: :spades},
        %PokerEx.Card{rank: :seven, suit: :clubs},
        %PokerEx.Card{rank: :five, suit: :diamonds},
        %PokerEx.Card{rank: :seven, suit: :hearts},
        %PokerEx.Card{rank: :six, suit: :spades},
        %PokerEx.Card{rank: :three, suit: :clubs},
        %PokerEx.Card{rank: :four, suit: :clubs},
        %PokerEx.Card{rank: :jack, suit: :spades},
        %PokerEx.Card{rank: :two, suit: :clubs},
        %PokerEx.Card{rank: :king, suit: :spades},
        %PokerEx.Card{rank: :jack, suit: :diamonds},
        %PokerEx.Card{rank: :seven, suit: :spades},
        %PokerEx.Card{rank: :two, suit: :hearts},
        %PokerEx.Card{rank: :four, suit: :diamonds},
        %PokerEx.Card{rank: :king, suit: :clubs},
        %PokerEx.Card{rank: :queen, suit: :diamonds},
        %PokerEx.Card{rank: :five, suit: :hearts},
        %PokerEx.Card{rank: :nine, suit: :diamonds},
        %PokerEx.Card{rank: :king, suit: :hearts},
        %PokerEx.Card{rank: :six, suit: :hearts},
        %PokerEx.Card{rank: :three, suit: :hearts},
        %PokerEx.Card{rank: :three, suit: :diamonds},
        %PokerEx.Card{rank: :queen, suit: :spades},
        %PokerEx.Card{rank: :ace, suit: :hearts},
        %PokerEx.Card{rank: :nine, suit: :hearts},
        %PokerEx.Card{rank: :ten, suit: :hearts},
        %PokerEx.Card{rank: :jack, suit: :hearts},
        %PokerEx.Card{rank: :seven, suit: :diamonds},
        %PokerEx.Card{rank: :eight, suit: :clubs},
        %PokerEx.Card{rank: :ace, suit: :spades},
        %PokerEx.Card{rank: :jack, suit: :clubs},
        %PokerEx.Card{rank: :ten, suit: :clubs},
        %PokerEx.Card{rank: :eight, suit: :diamonds},
        %PokerEx.Card{rank: :two, suit: :diamonds},
        %PokerEx.Card{rank: :five, suit: :spades},
        %PokerEx.Card{rank: :queen, suit: :hearts},
        %PokerEx.Card{rank: :ten, suit: :diamonds},
        %PokerEx.Card{rank: :nine, suit: :clubs},
        %PokerEx.Card{rank: :six, suit: :diamonds},
        %PokerEx.Card{rank: :queen, suit: :clubs},
        %PokerEx.Card{rank: :ace, suit: :clubs},
        %PokerEx.Card{rank: :three, suit: :spades},
        %PokerEx.Card{rank: :ace, suit: :diamonds},
        %PokerEx.Card{rank: :five, suit: :clubs},
        %PokerEx.Card{rank: :four, suit: :hearts},
        %PokerEx.Card{rank: :four, suit: :spades}
      ],
      dealt: [
        [
          %PokerEx.Card{rank: :nine, suit: :spades},
          %PokerEx.Card{rank: :eight, suit: :spades}
        ],
        %PokerEx.Card{rank: :king, suit: :diamonds},
        %PokerEx.Card{rank: :eight, suit: :hearts}
      ]
    },
    folded: [],
    paid: %{"Norris" => 10, "Zack" => 15},
    parent: nil,
    phase: :pre_flop,
    player_hands: [
      {"Zack",
       [
         %PokerEx.Card{rank: :king, suit: :diamonds},
         %PokerEx.Card{rank: :eight, suit: :hearts}
       ]},
      {"Norris",
       [
         %PokerEx.Card{rank: :nine, suit: :spades},
         %PokerEx.Card{rank: :eight, suit: :spades}
       ]}
    ],
    pot: 25,
    rewards: [],
    room_id: "Player_Haters_Ball",
    round: %{"Norris" => 10, "Zack" => 15},
    seating: [{"Zack", 0}, {"Norris", 1}],
    skip_advance?: false,
    stats: [],
    table: [],
    timeout: :infinity,
    timer: nil,
    to_call: 10,
    type: :private,
    winner: nil,
    winning_hand: nil
  }

  test "creates a PokerEx.GameEngine.Impl struct given a map derived from deprecated PokerEx.Room" do
    result = Migrator.transform_data(@room_data)
    assert %Game{} = result
    assert result.player_tracker.active == ["Norris", "Zack"]
    assert result.player_tracker.all_in == []
    assert result.player_tracker.folded == []
    assert result.player_tracker.called == ["Zack"]
    assert result.chips.chip_roll == %{"Norris" => 1_000_001_010, "Zack" => 400_165}
    assert result.roles.big_blind == 1
    assert result.roles.small_blind == 0
    assert result.roles.dealer == :unset
    assert result.cards.deck == @room_data.deck
    assert result.chips.paid == %{"Norris" => 10, "Zack" => 15}
    assert result.phase == :pre_flop

    assert result.cards.player_hands == [
             %{
               player: "Zack",
               hand: [
                 %PokerEx.Card{rank: :king, suit: :diamonds},
                 %PokerEx.Card{rank: :eight, suit: :hearts}
               ]
             },
             %{
               player: "Norris",
               hand: [
                 %PokerEx.Card{rank: :nine, suit: :spades},
                 %PokerEx.Card{rank: :eight, suit: :spades}
               ]
             }
           ]

    assert result.chips.pot == 25
    assert result.scoring.rewards == []
    assert result.game_id == "Player_Haters_Ball"
    assert result.chips.round == %{"Norris" => 10, "Zack" => 15}
    assert result.seating.arrangement == @room_data.seating
    assert result.scoring.stats == []
    assert(result.cards.table == [])
    assert result.type == :private
    assert result.chips.to_call == 10
    assert result.scoring.winners == :none
  end
end
