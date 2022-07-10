# Axelrod

Axelrod is a contract built with Cairo to create and manage iterated Prisoner's Dilemma tournaments.

<img src="https://i.imgur.com/5sP5MpO_d.webp?maxwidth=640&shape=thumb&fidelity=medium" data-canonical-src="https://i.imgur.com/5sP5MpO_d.webp?maxwidth=640&shape=thumb&fidelity=medium" width="300" height="300" />

`strategy_manager` is the contract that contains the logic of the tournaments.
A user can create a tournament and let players register their strategies.
Strategies are contracts that implement the `IPlayerStrategy` interface.
The two contracts interact through this interface.

<img src="https://www.americanscientist.org/sites/americanscientist.org/files/20131010231069915-2013-11HayesF1.jpg" data-canonical-src="https://www.americanscientist.org/sites/americanscientist.org/files/20131010231069915-2013-11HayesF1.jpg" width="300" height="300" />

Axelrod implements:
- support for multiple tournaments
- registering
- check that the strategy works
- matchmaking logic
- custom tables
- history of matches
- access control to start the tournament
- template for Finite State Machine strategies 