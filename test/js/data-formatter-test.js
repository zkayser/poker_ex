import should from 'should';
import {OBJ_SEATING,
        ARRAY_SEATING,
        IDLE_ONE_PLAYER,
        GAME_START_2_P,
        INSUFFICIENT_CHIPS
        } from '../js_support/game-data';
import DataFormatter from '../../web/static/js/data-formatter';

describe("DataFormatter('game')", () => {
  const dataFormatter = new DataFormatter("game");
  
  it("should exist", () => {
    should.exist(dataFormatter);
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
  
  describe(".extractRaiseData()", () => {
    let gameStartRes = dataFormatter.extractRaiseData(GAME_START_2_P);
    
    it("should not be raiseable when in idle state and no active player", () => {
      let result = dataFormatter.extractRaiseData(IDLE_ONE_PLAYER);
      result.raiseable.should.be.false();
    });
    
    it("should be raiseable when the players have enough chips and a game is underway", () => {
      gameStartRes.raiseable.should.be.true();
    });
    
    it("should calculate raiseData.min and subtract away chips paid in the current round", () => {
      gameStartRes.min.should.equal(5);
    });
    
    it("should calculate the max as the current player's chipRoll val plus those already paid in the round", () => {
      gameStartRes.max.should.equal(205);
    });
    
    it("should return a raiseData object", () => {
      let expected = {
        raiseable: true,
        min: 5,
        max: 205
      };
      should.deepEqual(expected, gameStartRes);
    });
    
    describe("when a player does not have enough chips to call", () => {
      let results = dataFormatter.extractRaiseData(INSUFFICIENT_CHIPS);
      
      it("should not be raiseable", () => {
        results.raiseable.should.be.false(`results: ${results.min}`);
      });
    });
  });
});