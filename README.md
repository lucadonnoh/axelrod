# Axelrod

Axelrod is a contract built with Cairo to create and manage iterated Prisoner's Dilemma tournaments.

`strategy_manager` is the contract that contains the logic of the tournaments.
A user can create a tournament and let players register their strategies.
Strategies are contracts that implement the `IPlayerStrategy` interface.
The two contracts interact through this interface.

Axelrod implements:
- support for multiple tournaments
- registering
- check that the strategy works
- matchmaking logic
- custom tables
- history of matches
- access control to start the tournament
- template for Finite State Machine strategies 