# User stories

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want a Homepage where I can search listed event and bets under those events |Rez||||
- Categories by Country, Sport, League
- Two view levels of an event. There can be many open bets on different outcomes under the same event: e.g. Basel vs Zurich
  - More broad view of only event description: e.g. Zurich vs Basel
  - More specific view of an open bet, possibly many of these under an event e.g. description: Zurich vs Basel, Outcome: Zurich wins, deadline: 20-02-2021 18:30, available stake: 20 eth, odd: 2.5
- Ability to back a bet, playing on the opposite outcome of the outcome description.
  - Clicking on outcomes odd starts the transaction
- On first visit show all (or e.g. max 100) upcoming bets listed.
- Events (Bet descriptions with open bets) listed
  - Clicking on event shows the list of open bets under that event
- Creating a bet saves the description to the UI
  - Other players can create new bets under this saved description 
- Ability to lay a new bet from the listing page completely from scratch, selecting country, category, league.
- Ability to lay a new bet when under a country/category/league. Selects the country/category/league for the new bet.
- Confirmation: bet will be listed under the upcoming bets, so that other users can back the bet.

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want see my Betting history|Ronin||||
- Access from the front page
- Ability to vote on outcome of a bet.
- Ability to dispute a result (Optional)
- See the result

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want to be able to create a “lay” bet pool|Lauri||||
- 1 player / outcome
- Enter amount of ether and outcome selected by the creator
- Fixed odds
- Fixed stake
- Creator defines: Odds, Match description, deadline
- Given by UI: Outcomes, Categories, Type

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want to be able to place a bet on “back” bet pools|Ronin||||
- Display and selection of  a league on which I want to bet
- Odd and fixed stake shown.
- 1 backer / bet.

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want to vote on the outcome|Martin||||
- Receive back the bet-money if dispute without Kleros (or able to claim winning with another transaction)
- If there is not a backer, creator can withdraw own stake.
- Option for voting undecidable e.g. for cancelled matches.
- If disagreement -> contract to dispute state
- Automatical reward distribution in case of agreement or withdraw for winner?


|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want to dispute the result (Optional)|Lauri||||
- Give an evidence of the wrong result
- Only if the player has a bet on the match.
- Ruling done automatically

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want to be able to create a parimutuel bet pool (Optional)|DevX||||
- N players / outcome
- Any amount of stake
- Enter amount of ether and outcome selected by the creator
- Rewards by distribution of bets, dynamic odds
- Creator defines: Outcomes, Match description, deadline
- Given by UI: Categories, Type

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want to be able to place a bet on parimutuel bet pools (Optional)|DevX||||
- Display and selection of  a league on which I want to bet
- Stake given by user.
- Automatic distribution might be a problem with Parimutuel betting when there are many players. Dividing the winnings would have to be done in a costly loop. A claim winnings function in this scenario?

|Goal|Dev|Workload|Deadline|Done|
|----|---|--------|--------|----|
|As a user I want to receive notifications about the status of my bets (Optional)|DevX||||
