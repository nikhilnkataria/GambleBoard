// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./dep/Arbitrable.sol";

/**
 * @title Gambleboard
 * Create and place decentralized "Back and lay" bets on anything.
 * @dev Parimutuel betting might be useful to be put into another contract.
 * @dev states:
 * Open:              0
 * Voting:            1
 * Agreement:         2
 * Disagreement:      3
 * Disputed:          4
 * Closed:            5
 *
 * @dev voteEvidence bool array holds information on if
 * creator and backer voted and if creator and backer provided evidence
 */
contract GambleBoard is Arbitrable {
    bytes1 private constant CREATOR_VOTED = 0x01;
    bytes1 private constant BACKER_VOTED = 0x02;
    bytes1 private constant CREATOR_PROVIDED_EVIDENCE = 0x04;
    bytes1 private constant BACKER_PROVIDED_EVIDENCE = 0x08;

    enum State {OPEN, VOTING, AGREEMENT, DISAGREEMENT, DISPUTED, CLOSED}
    enum RulingOption {NO_OUTCOME, CREATOR_WINS, BACKER_WINS}

    uint256 private constant ONE_DAY = 86400;

    uint8 private constant MAX_COUNTRIES = 203;

    uint256 public constant RULING_OPTIONS_AMOUNT = 2; // 0 if can't arbitrate

    // Odds with 6 decimals.
    uint256 public constant MIN_ODD = 1000000;
    uint256 public constant MIN_STAKE = 1000000;

    // Indexed params can be filtered in the UI.
    event BetCreated(
        uint256 betID,
        uint8 country,
        string league,
        uint16 category
    );
    event BetPlaced(uint256 betID, address backer, State state);
    event BetStateChanged(uint256 betID, State state);
    event BetVotedOn(uint256 betID);
    event BetRefund(
        uint256 betID,
        State state,
        uint256 backerStake,
        uint256 creatorStake
    );

    modifier onlyPlayer(uint256 betID) {
        require(
            msg.sender == bets[betID].creator ||
                msg.sender == bets[betID].backer,
            "Only a player can interract with a bet!"
        );
        _;
    }

    struct Bet {
        uint256 stakingDeadline;
        uint256 votingDeadline;
        uint256 backerStake; // Arbitration fee is added to the fee payers stake.
        uint256 creatorStake;
        RulingOption outcome;
        State state;
        bytes1 voteEvidenceBools;
        address payable creator;
        address payable backer;
        string description;
        string creatorBetDescription;
    }

    mapping(uint256 => Bet) public bets;
    mapping(uint256 => uint256) public disputeIDToBetID;

    uint256 public betsCreated;

    constructor(Arbitrator _arbitrator, bytes memory _arbitratorExtraData)
        Arbitrable(_arbitrator, _arbitratorExtraData)
    {
        betsCreated = 0;
    }

    /**
     * Creates a new bet. Calculates the amount a backer has to stake from the creators stake and odd.
     * @ dev is payable, meaning the ETH value sent with the transaction is sent to the contract address
     * @ dev emits information about the created bet.
     * @ params:
     * description: String description of the match
     * creatorBetDescription: String description of the creators bet.
     * countryLeagueCategory: Country, Category and League of the bet concatenated into a bytes2
     * stakingDeadline: deadline after which no new bets are accepted. Unix time
     * timeToVote: amount of time to vote after the stakingDeadline. Seconds
     * creatorOdd: The odd of the outcome the creator chose. x.yz e 18
     */
    function createBet(
        string memory description,
        string memory creatorBetDescription,
        string memory league,
        uint8 country,
        uint16 category,
        uint256 stakingDeadline,
        uint256 timeToVote,
        uint256 creatorOdd,
        string memory _metaEvidence
    ) public payable returns (uint256) {
        require(
            msg.value > MIN_STAKE,
            "Creator bet has to be bigger than 1000000 wei"
        );
        require(creatorOdd > MIN_ODD, "Creator odd has to be bigger than 1!");
        require(
            stakingDeadline > block.timestamp,
            "Deadline to place stakes cannot be in the past!"
        );
        require(country <= MAX_COUNTRIES, "Maximum country number is 203");
        require(timeToVote >= ONE_DAY, "Time to vote should be more than 1 day!");
        uint256 betID = betsCreated++;

        Bet storage newBet = bets[betID];

        // Calculate fixed stake for the backer based on the creator odd and stake
        // Always fair odds

        uint256 amountToWinFromBet = (msg.value * creatorOdd) / MIN_ODD;
        newBet.backerStake = amountToWinFromBet - msg.value;
        newBet.creatorStake = msg.value;

        newBet.creator = payable(msg.sender);
        newBet.description = description;
        newBet.creatorBetDescription = creatorBetDescription;
        newBet.stakingDeadline = stakingDeadline;
        newBet.votingDeadline = stakingDeadline + timeToVote;

        emit BetCreated(betID, country, league, category);
        // Has to be done before the dispute is created
        emit MetaEvidence(betID, _metaEvidence);

        return betID;
    }

    function placeBet(uint256 betID) public payable {
        Bet storage placingBet = bets[betID];

        //check that the state is open
        require(placingBet.state == State.OPEN, "The bet is not open!");

        require(
            msg.sender != placingBet.creator,
            "Creator cannot bet on own bet!"
        );

        //make sure that the bet is not done after the Deadline
        require(
            block.timestamp <= placingBet.stakingDeadline,
            "The bet match has expired, we are sorry!"
        );

        //check that no one else betted before
        require(placingBet.backer == address(0x0), "We have a backer already");

        //bet must be equal to the amount specified during the creation for the Bet
        require(
            msg.value == placingBet.backerStake,
            "The amount you staked is not valid!"
        );

        placingBet.backer = payable(msg.sender);
        placingBet.state = State.VOTING;

        emit BetPlaced(betID, msg.sender, State.VOTING);
    }

    function voteOnOutcome(uint256 betID, RulingOption outcome)
        public
        onlyPlayer(betID)
    {
        Bet storage bet = bets[betID];
        require(bet.state == State.VOTING, "State is not on voting");

        if (msg.sender == bet.creator) {
            require(
                (bet.voteEvidenceBools & CREATOR_VOTED) != CREATOR_VOTED,
                "Player can only vote once!"
            );
            bet.voteEvidenceBools = bet.voteEvidenceBools | CREATOR_VOTED;
        } else {
            require(
                (bet.voteEvidenceBools & BACKER_VOTED) != BACKER_VOTED,
                "Player can only vote once!"
            );
            bet.voteEvidenceBools = bet.voteEvidenceBools | BACKER_VOTED;
        }

        if (bet.outcome == RulingOption.NO_OUTCOME) {
            bet.outcome = outcome;
        } else {
            if (bet.outcome == outcome) {
                bet.state = State.AGREEMENT;
            } else {
                bet.state = State.DISAGREEMENT;
            }
        }

        emit BetVotedOn(betID);
    }

    function refund(uint256 betID) public onlyPlayer(betID) {
        // If no players voted in time or if the votes were on NO_OUTCOME, the stakes are refunded.
        Bet storage bet = bets[betID];
        require(bet.outcome == RulingOption.NO_OUTCOME, "Bet outcome defined");
        require(
            (bet.state == State.VOTING &&
                bet.votingDeadline < block.timestamp) ||
                bet.state == State.AGREEMENT,
            "Refund not possible"
        );

        if ((msg.sender) == bet.creator) {
            uint256 amountTransfer = bet.creatorStake;
            bet.creatorStake = 0;
            payable(msg.sender).transfer(amountTransfer);
        } else {
            uint256 amountTransfer = bet.backerStake;
            bet.backerStake = 0;
            payable(msg.sender).transfer(amountTransfer);
        }

        if (bet.backerStake == 0 && bet.creatorStake == 0) {
            bet.state = State.CLOSED;
        }

        emit BetRefund(betID, bet.state, bet.backerStake, bet.creatorStake);
    }

    // If only one player voted within the time to vote, the winner of the bet will be choosen based on the one voting.
    // Player who won the bet can claim winning, but can also be called by loser
    // Function can only be called after voting Deadline
    function claimWinnings(uint256 betID) public onlyPlayer(betID) {
        Bet storage bet = bets[betID];

        require(
            bet.state == State.AGREEMENT ||
                (bet.state == State.VOTING &&
                    bet.votingDeadline < block.timestamp)
        );
        require(bet.outcome != RulingOption.NO_OUTCOME);

        uint256 amountTransfer = bet.creatorStake + bet.backerStake;
        bet.state = State.CLOSED;

        if (bet.outcome == RulingOption.CREATOR_WINS) {
            bet.creator.transfer(amountTransfer);
        } else {
            bet.backer.transfer(amountTransfer);
        }

        emit BetStateChanged(betID, bet.state);
    }

    // @title Creates a dispute in the arbitrator contract
    // Needs to deposit arbitration fee. The fee goes to the winner.
    // One player is enough to send the case to arbitration.
    function createDispute(uint256 betID)
        public
        payable
        onlyPlayer(betID)
        returns (uint256)
    {
        Bet storage bet = bets[betID];
        require(
            bet.state == State.DISAGREEMENT,
            "Bet not in disagreement state!"
        );
        require(
            msg.value >= arbitrator.arbitrationCost("0x0"),
            "Not enough ETH to cover arbitration costs."
        );

        if (msg.sender == bet.creator) {
            bet.creatorStake += msg.value;
        } else {
            bet.backerStake += msg.value;
        }
        bet.state = State.DISPUTED;

        uint256 disputeID =
            arbitrator.createDispute{value: msg.value}(
                RULING_OPTIONS_AMOUNT,
                ""
            );
        disputeIDToBetID[disputeID] = betID;

        emit Dispute(arbitrator, disputeID, betID, betID);
        return disputeID;
    }

    function executeRuling(uint256 _disputeID, uint256 _ruling)
        internal
        override
    {
        bets[disputeIDToBetID[_disputeID]].state = State.AGREEMENT;
        bets[disputeIDToBetID[_disputeID]].outcome = RulingOption(_ruling);
    }

    function provideEvidence(uint256 betID, string memory _evidence)
        public
        onlyPlayer(betID)
    {
        Bet storage bet = bets[betID];

        require(bet.state == State.DISPUTED, "Bet is not in disputed state!");

        if (msg.sender == bet.creator) {
            require(
                (bet.voteEvidenceBools & CREATOR_PROVIDED_EVIDENCE) !=
                    CREATOR_PROVIDED_EVIDENCE,
                "Player can only vote once!"
            );
            bet.voteEvidenceBools =
                bet.voteEvidenceBools |
                CREATOR_PROVIDED_EVIDENCE;
        } else {
            require(
                (bet.voteEvidenceBools & BACKER_PROVIDED_EVIDENCE) !=
                    BACKER_PROVIDED_EVIDENCE,
                "Player can only vote once!"
            );
            bet.voteEvidenceBools =
                bet.voteEvidenceBools |
                BACKER_PROVIDED_EVIDENCE;
        }

        emit Evidence(arbitrator, betID, msg.sender, _evidence);
    }

    function betExists(uint256 betID) public view returns (bool) {
        return bets[betID].creator == address(0x00);
    }

    function getState(uint256 betID) public view returns (uint8) {
        return uint8(bets[betID].state);
    }

    function getOutcome(uint256 betID) public view returns (uint8) {
        return uint8(bets[betID].outcome);
    }

    function getVoteEvidenceBools(uint256 betID) public view returns (bytes8) {
        return bets[betID].voteEvidenceBools;
    }

    //Fallback functions if someone only sends ether to the contract address
    fallback() external payable {
        revert("Cant send ETH to contract address!");
    }

    receive() external payable {
        revert("Cant send ETH to contract address!");
    }
}
