export default class GameDataFactory {
  constructor(dataOpts) {
    this.user = dataOpts.user || 'A';
    this.active = dataOpts.active || 'A';
    this.state = dataOpts.state || "pre_flop";
    this.seating = dataOpts.seating || OBJ_SEATING;
    this.to_call = dataOpts.to_call || 10;
    this.player_hands = dataOpts.player_hands || DEFAULT_PLAYER_HANDS;
    this.paid = dataOpts.paid || DEFAULT_PAID;
    this.round = dataOpts.round || DEFAULT_ROUND;
    this.pot = dataOpts.pot || 15;
    this.table = dataOpts.table || [];
    this.players = dataOpts.players || DEFAULT_PLAYERS;
    this.chip_roll = dataOpts.chip_roll || DEFAULT_CHIP_ROLL;
  }
  
  insufficientChips() {
    this.chip_roll["A"] = 3;
    return this;
  }
  
  onePlayer() {
    this.chip_roll = {"A": 200};
    this.active = null;
    this.player_hands = [];
    this.state = "idle";
    return this;
  }
  
  flopTable() {
    this.state = "flop";
    this.table = [
      {
        suit: "hearts",
        rank: "two"
      },
      {
        suit: "spades",
        rank: "three"
      },
      {
        suit: "diamonds",
        rank: "four"
      }
    ];
    return this;
  }
  
}


export const OBJ_SEATING = {
      A: 1,
      B: 2,
      C: 3
    };
    
export const ARRAY_SEATING = [{name: "A", position: 1}, {name: "B", position: 2}, {name: "C", position: 3}];

const DEFAULT_PAID = {
    "A": 5,
    "B": 10
  };
  
const DEFAULT_ROUND = {
    "A": 5,
    "B": 10
  };
  
const DEFAULT_CHIP_ROLL = {
  A: 200,
  B: 200
};

const DEFAULT_PLAYER_HANDS = [
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
  ];

const  DEFAULT_PLAYERS =  [
    {
      name: "A",
      chips: 200
    },
    {
      name: "B",
      chips: 200
    }
  ];


export const IDLE_ONE_PLAYER = {
  active: null,
  state: "idle",
  paid: new Object(),
  to_call: 0,
  chip_roll: {
    A: 200
  },
  player_hands: new Object(),
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