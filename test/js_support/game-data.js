export const OBJ_SEATING = {
      A: 1,
      B: 2,
      C: 3
    };
    
export const ARRAY_SEATING = [{name: "A", position: 1}, {name: "B", position: 2}, {name: "C", position: 3}];

export const IDLE_ONE_PLAYER = {
  active: null,
  state: "idle",
  paid: new Object(),
  to_call: 0,
  players: [
    {
      name: "A",
      chips: 200
    }
  ],
  chip_roll: {
    A: 200
  },
  player_hands: {
    
  },
  round: new Object(),
  pot: 0,
  table: []
};

export const GAME_START_2_P = {
  user: "A",
  active: "A",
  state: "pre_flop",
  paid: {
    "A": 5,
    "B": 10
  },
  to_call: 10,
  players: [
    {
      name: "A",
      chips: 200
    },
    {
      name: "B",
      chips: 200
    }
  ],
  chip_roll: {
    "A": 200,
    "B": 200
  },
  player_hands: [
    {
      player: "A",
      hand: [
        {
          suit: "hearts",
          rank: "two"
        },
        {
          suit: "diamonds",
          rank: "three"
        }
      ]
    },
    {
      player: "B",
      hand: [
        {
          suit: "spades",
          rank: "ace"
        },
        {
          suit: "clubs",
          rank: "king"
        }
      ]
    }
  ],
  round: {
    "A": 5,
    "B": 10
  },
  pot: 15,
  table: []
};

export const INSUFFICIENT_CHIPS = {
  user: "A",
  active: "A",
  state: "pre_flop",
  paid: {
    "A": 5,
    "B": 10
  },
  to_call: 10,
  players: [
    {
      name: "A"
    },
    {
      name: "B"
    }
  ],
  chip_roll: {
    "A": 3,
    "B": 200
  },
  player_hands: [
    {
      player: "A",
      hand: [
        {
          suit: "hearts",
          rank: "two"
        },
        {
          suit: "diamonds",
          rank: "three"
        }
      ]
    },
    {
      player: "B",
      hand: [
        {
          suit: "spades",
          rank: "ace"
        },
        {
          suit: "clubs",
          rank: "king"
        }
      ]
    }
  ],
  round: {
    "A": 5,
    "B": 10
  },
  pot: 15,
  table: []
};