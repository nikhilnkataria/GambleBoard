import { BigInt } from "@graphprotocol/graph-ts";
import {
  GambleBoard,
  BetCreated,
  BetPlaced,
  BetStateChanged,
  Dispute,
  Evidence,
  Ruling,
  BetRefund,
  BetVotedOn,
  MetaEvidence,
} from "../../generated/GambleBoard/GambleBoard"
import { Bet, Event, League } from "../../generated/schema"

export function handleBetCreated(event: BetCreated): void {
  let betID = event.params.betID

  // Bind the contract and get storage data about the bet
  let betContract = GambleBoard.bind(event.address);
  let betData = betContract.bets(betID);

  let betEntity = new Bet(betID.toHex());
  betEntity.stakingDeadline = betData.value0;
  betEntity.votingDeadline = betData.value1;
  betEntity.backerStake = betData.value2
  betEntity.creatorStake = betData.value3;
  betEntity.outcome = betData.value4;
  betEntity.state = betData.value5;
  betEntity.voteEvidenceBools = betData.value6;
  betEntity.creator = betData.value7;
  betEntity.backer = betData.value8;
  betEntity.description = betData.value9;
  betEntity.creatorBetDescription = betData.value10;

  betEntity.country = event.params.country;
  betEntity.league = event.params.league;
  betEntity.category = event.params.category;

  betEntity.timeCreated = event.block.timestamp;
  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()

  // Events
  ///////////////////
  let eventID = betData.value9 + BigInt.fromI32(event.params.country).toString() + BigInt.fromI32(event.params.category).toString()
  let eventEntity = Event.load(eventID);

  if (eventEntity == null) {
    eventEntity = new Event(eventID);
    eventEntity.description = betData.value9;
    eventEntity.startTime = betData.value0;
    eventEntity.betIDs = [];
  }

  if (eventEntity.startTime > betData.value0) {
    eventEntity.startTime = betData.value0;
  }
  eventEntity.country = event.params.country;
  eventEntity.league = event.params.league;
  eventEntity.category = event.params.category;

  let betIDs = eventEntity.betIDs;
  betIDs.push(betID);
  eventEntity.betIDs = betIDs;

  eventEntity.save();

  //Leagues of CategoryCountry pairs
  //////////////////////
  if (event.params.league !== "") {
    let leagueID = BigInt.fromI32(event.params.country).toString() + BigInt.fromI32(event.params.category).toString() + event.params.league;
    let leagueListEntity = League.load(leagueID);

    if (leagueListEntity == null) {
      leagueListEntity = new League(leagueID);
    }

    leagueListEntity.league = event.params.league;
    leagueListEntity.category = event.params.category;
    leagueListEntity.country = event.params.country;

    leagueListEntity.save();
  }

}

export function handleBetPlaced(event: BetPlaced): void {
  let betID = event.params.betID

  let betEntity = new Bet(betID.toHex());
  betEntity.state = event.params.state;
  betEntity.backer = event.params.backer;

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleBetRefund(event: BetRefund): void {
  let betID = event.params.betID

  let betEntity = new Bet(betID.toHex());
  betEntity.state = event.params.state;
  betEntity.backerStake = event.params.backerStake;
  betEntity.creatorStake = event.params.creatorStake;

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleBetStateChanged(event: BetStateChanged): void {
  let betID = event.params.betID

  let betEntity = new Bet(betID.toHex());
  betEntity.state = event.params.state;

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleBetVotedOn(event: BetVotedOn): void {
  let betID = event.params.betID

  // Bind the contract and get storage data about the bet
  let betContract = GambleBoard.bind(event.address);
  let betData = betContract.bets(betID);
  let betEntity = new Bet(betID.toHex());
  betEntity.outcome = betContract.getOutcome(betID);
  betEntity.state = betContract.getState(betID);
  betEntity.voteEvidenceBools = betContract.getVoteEvidenceBools(betID);

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleRuling(event: Ruling): void {
  let disputeID = event.params._disputeID

  // Bind the contract and get storage data about the bet
  let betContract = GambleBoard.bind(event.address);
  let betID = betContract.disputeIDToBetID(disputeID);

  let betEntity = new Bet(betID.toHex());
  betEntity.state = betContract.getState(betID); // STATE_AGREEMENT
  betEntity.outcome = event.params._ruling.toI32();
}

export function handleDispute(event: Dispute): void {
  let betID = event.params._evidenceGroupID

  // Bind the contract and get storage data about the bet
  let betContract = GambleBoard.bind(event.address);
  let betData = betContract.bets(betID);

  // Creating a new and writing that to store is faster than loading
  // and saving.
  let betEntity = new Bet(betID.toHex());
  betEntity.state = betData.value5
  betEntity.disputeID = event.params._disputeID;
  betEntity.backerStake = betData.value2
  betEntity.creatorStake = betData.value3;

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleEvidence(event: Evidence): void {
  let betID = event.params._evidenceGroupID

  // Bind the contract and get storage data about the bet
  let betContract = GambleBoard.bind(event.address);
  let betEntity = new Bet(betID.toHex());
  betEntity.outcome = betContract.getOutcome(betID);
  betEntity.state = betContract.getState(betID);
  betEntity.voteEvidenceBools = betContract.getVoteEvidenceBools(betID);

  betEntity.timeUpdated = event.block.timestamp;

  // Save the entity to the store
  betEntity.save()
}

export function handleMetaEvidence(event: MetaEvidence): void {
  let betEntity = new Bet(event.params._metaEvidenceID.toHex());

  betEntity._metaEvidence = event.params._evidence;

  betEntity.save();
}