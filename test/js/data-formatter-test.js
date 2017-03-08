import should from 'should';
import GameDataFactory from '../js_support/game-data-factory';
import {OBJ_SEATING, ARRAY_SEATING} from '../js_support/game-data-factory';
import DataFormatter from '../../web/static/js/data-formatter';
import Card from '../../web/static/js/card';
import Player from '../../web/static/js/player';

describe("DataFormatter('game')", () => {
  const dataFormatter = new DataFormatter("game");
  
  it("should exist", () => {
    should.exist(dataFormatter);
  });
  
  describe(".format(data)", () => {
    describe("with one player in idle state", () => {
      let onePlayer = new GameDataFactory({active: null}).onePlayer();
      let res = dataFormatter.format(onePlayer);
    
      it("should return data with a blank playerHand, not raiseable, and not have min or max properties", () => {
        should.not.exist(res.playerHand);
        res.should.have.property('playerHand');
        res.raiseable.should.be.false();
        should.not.exist(res.min);
        should.not.exist(res.max);
      });  
    });
    
    describe("with two players when a game is not idle", () => {
      let gameData = new GameDataFactory({});
      let res = dataFormatter.format(gameData);
      
      it("should return results", () => {
        should.exist(res);
      });
      
      it("should return an array of length 2 with Card instances for playerHand", () => {
        should.exist(res.playerHand);
        res.playerHand.should.be.instanceof(Array);
        res.playerHand.length.should.eql(2);
        res.playerHand.forEach((c) => c.should.be.instanceof(Card));
      });
      
      it("should return an array of players", () => {
        should.exist(res.players);
        res.players.length.should.eql(2);
        res.players[0].should.be.instanceof(Player);
      });
    
      it("should return the correct value for min", () => {
        res.min.should.eql(5, `gameData.chip_roll: ${gameData.chip_roll}\ngameData.round: ${gameData.round}`);
      });
      
      it("should return the correct value for max", () => {
        res.max.should.eql(205);
      });
      
      it("should return true for raiseable", () => {
        res.raiseable.should.be.true();
      });
      
      it("should return a blank array for the table property when the state is pre_flop", () => {
        res.table.should.eql([]);
      });
      
      it("should return an object with all of the required properties", () => {
        let props = ['user', 'state', 'active', 'paid', 'round', 'seating', 'to_call', 'player_hands', 'pot', 'table', 'players', 'chip_roll',
                     'playerHand', 'min', 'max', 'raiseable'
                    ];
        props.forEach((prop) => {
          res.should.have.property(prop);
        });
      });
    
      it("should return an array of length 3 populated with Card instances when the state is flop", () => {
        let flopData = new GameDataFactory({}).flopTable();
        let flopRes = dataFormatter.format(flopData);
      
        flopRes.table.should.be.instanceof(Array);
        flopRes.table.length.should.eql(3);
        flopRes.table.forEach((c) => {c.should.be.instanceof(Card)});
      });
    });
    
    describe("when a player does not have enough chips to call", () => {
      let insufficientChips = new GameDataFactory({}).insufficientChips();
      let results = dataFormatter.format(insufficientChips);
      
      it("should not be raiseable", () => {
        results.raiseable.should.be.false(`results: ${results.min}`);
      });
      
      it("should return undefined for min property", () => {
        should.not.exist(results.min);
      });
      
      it("should return undefined for max property", () => {
        should.not.exist(results.max);
      });
    });
  });
  
  describe(".formatSeating()", () => {
    it("should not change the seating received if the seating is an object with names as keys and positions as values", () => {
      let result = dataFormatter.formatSeating(OBJ_SEATING);
      should.deepEqual(result, OBJ_SEATING);
    });
    
    it("should format seating received as an array properly", () => {
      let result = dataFormatter.formatSeating(ARRAY_SEATING);
      should.deepEqual(result, OBJ_SEATING);
    });
    
    it("should return the same result whether given an object or array, provided same values", () => {
      let arrResult = dataFormatter.formatSeating(ARRAY_SEATING);
      let objResult = dataFormatter.formatSeating(OBJ_SEATING);
      should.deepEqual(arrResult, objResult);
    });
  });
});