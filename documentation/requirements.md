# Gambleboard, a decentralized betting app

Martin Frick, Md Rezuanul Haque, Ronin Chellakudam, Lauri Tahvanainen

Department of Informatics IfI University of Zurich UZH, Blockchains and Overlay Networks Spring 2021 Challenge Task


## 1.1 Use case

Our goal is to create a platform (DApp) where players can bet against each other without a centralized provider demanding a commission in between. The type of bets we offer are “back”- and “lay”-bets. (https://www.livetipsportal.com/en/betting-strategies/back-lay/). The players have the possibility to back or to lay a bet which allows them to either offer a bet to other players or to accept a bet another player has offered.

The bet can be almost on any type of event. A champions league football match, a beer league ice hockey match, a political event or even a funny bet with a friend about being able to throw a ping pong ball in to a glass while blind. The way we can achieve having bets of so many types is through having the default situation be that the players agree on the outcome of the event. 
After a bet has been layed, the players stake is frozen until the bet is over or removed. A user who lays a bet also has to decide on some options. These include: the outcomes, the odds, the stake on one outcome from the creator and a description of the bet. By deciding the odds of the outcomes and betting on one of these outcomes the layer also fixes the possible stake on the other outcome. 

There are following options: just upon agreement, one agreement with  (*Opt*) Kleros and an (*Opt*) oracle with Kleros. When the latter is chosen, the users do have to agree on an oracle. When the result is disputed, each player has the ability to provide evidence about the right outcome.

The platform itself offers several kinds of bets which are listed under different categories users are allowed to choose between. 

A bet pool is created by a interaction with a smart contract. In a simple 1v1 pool the creator configures the pool with two outcomes, adds stake on one outcome and waits for someone to agree on the odds and provide their stake. The stakes would then be locked in the pool for a certain time or until both parties vote on the result. When the outcome is known, both parties interact with the contract to broadcast their opinion on the result. If these opinions match the rewards are delegated to the winner accordingly. If Kleros is not used and there are no bets on the winning outcome, the stakes are returned to the players.

### *Optional*
Further the layer of the bet decides between making the bet private or public. Private bets are accessible through invitation. There is also the option that the lay side offers a bet which can be backed by many players with a share of the total bet at the same time. This option increases the chance of a bet with high stakes to come off. The payoffs would then depend on how big the share of the respective player is.

### *Optional*
If there is an dispute on the result, the contract will automatically, or with the interraction of one player, send the dispute to Kleros court for arbitration. At this point both parties could provide evidence or the users could have defined some sources for the events result, which are sent to the Kleros jury. The jury will make a decision and the smart contract will react to the decision awarding the winner and punishing the other. For the pool to use Kleros there needs to be certain amount of stake locked for a possible court case. In addition a percentage of 5% of the stake of the user who is wrong will be charged.

### *Optional*
There are some rules with how to solve disagreement on bets. In a one to one bet the bet will go automatically to Kleros is there is a disagreement. For one to many bet there is the rule that on the many side at least 75% percent of the users have to agree on the outcome, otherwise the case will go to Kleros.

### *Optional*
Furthermore there users will be rated by the system and get ratings from other users. After a bet is over upon agreement, both users get an increase of their rating depending on the stake. On the other hand if the bet is moved to Klerus the user who was wrong will be punishes with a lower rating accordingly. Users with high rating can also be offered to become a moderator which allows them to remove bets with inappropriate content reported by users.

### *Optional*
Private bets are not visible for users without an invitation.

### *Optional*
Parimutual bets
Next step would be to offer Parimutual bets on our platform. Parimutual bets can also be layed and backed. The same rules that are defined for P2P bets apply for Parimutual bets.

## Use case summary
The minimum requirement is thus for the players to be able to create 1v1 "back" and "lay" bets, for which the result is agreed upon between the players. The winning are spread accordingly according to the agreement of the players. Without Kleros, in a case of dispute the players bets are returned. The smart constract allows creation of any kind of bets, but the minimum requirement for the user interface is that there are match templates offered in the UI to the players, and from those matches the players can create bets with their preferred odds. The players can also open a listing of created bets where they can select what match to bet on and with what odds.
All the optional marked use cases will be developed on top of the minimum requirements if there is sufficient time. These include for example the Kleros arbitration for disagreements and the possibility to create any kind of bet in the UI.

## 1.2 Implementation

All bets are placed in ethereum. The Kleros integration is optional.

Players can interact with the smart contract using the following interfaces:


// back and lay
**createBet(description,
            creatorBetDescription,
            country,
            category,
            league,
            stakingDeadline,
            timeToVote,
            creatorOdd)**
- A player creates a bet, giving all the necessary information about the bet. The bet is given an unique ID and it is saved into a mapping with all the necessary information.
- Can be chosen to be not arbitrable. (OPTIONAL)
- Emits a message with indexes on some data, for example the bet ID


**bet(betID, outcome, value)**
- A player buys a bet, saving the value given as parameter under the betID and outcome.

**voteOnOutcome(betID, outcome)**
- A player interacts with the contract to give their suggestion on the outcome of the bet
- If all have given their suggestion the following happens:
    
    a: All players agree and the value is distributed to the winner
    
    b: Players do not agree, the stakes are returned to players.
    
    c: Players do not agree and the bet is moved to dispute state
        - Bet goes into dispute state and one player can send it to Kleros with createDispute, locking a dispute resolution fee.

**createDispute(betID, fee)**
- A player creates a dispute about a bet.

**SubmitEvidence(betID, evidence)**
- A player submits evidence on the dispute of a bet. Is done by emitting.

The smart contract should implement IArbitrable and IEvidence to communicate with Kleros. 
With this the contract has to implement the events

MetaEvidence, Evidence, Dispute and Ruling

And the function

**rule(uint256 _disputeID, uint256 _ruling) external**
- Is called by the arbitrator to give a ruling on the bet
- Distribute value to players of the bet according to the ruling.

## Issues

- Storage: what would not be needed to store in the contract? What could be for example handled with the front-end using events? One possibility would also be to create a new contract for each bet. What is the cheapest option gaswise?
- Can this be expanded to parimutuel betting? I’d say yes, with the exact same interfaces. Bookmaker betting would be another story.
- Category information also for the front end? Private/public value? Somehow the bets should be enumerated for showing in the front-end. Just reading transactions and logs?


## 1.3 Software Architecture

![Smart contract interactions](https://github.com/LauriTahvanainen/GambleBoard/blob/main/documentation/diagram.png)

## 1.4 Front-End / Graphical User Interface

Three pages/interractions: Create bet, list bets, accept bet.
