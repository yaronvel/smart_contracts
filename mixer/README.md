# Ether Mixer (with caveat)
**Table of Contents**
- [Introduction](##Introduction)
- [Short explanation](##Short explanation)
- [Detailed explanation](##Detailed explanation)
- [Contract overview](##Contract overview)
- [Disclaimer](##Disclaimer)

## Introduction
We implement a decentralized Ether mixer contract.
The contract allows multiple parities to deposit funds and to withdraw the same amount with multiple anonymous addresses.

**The caveat of the protocol is that the anonymous addresses should already contain small amount of Ethers.**
This is possible e.g., by mining, [faucets](https://cryptojunction.com/top-10-ethereum-faucets-2016/), [centralized Ether mixers](https://ethermixer.com/) or by converting the Ethers to bitcoins and back to Ethers.

## Short explanation
In this section we give a short explanation on the protocol.
We consider the case where Bob and Alice each have 1000 Ether in a public address Bob<sub>public</sub> and Alice<sub>public</sub> and they want to transfer their funds to Bob<sub>anonymous</sub> and Alice<sub>anonymous</sub>.
We further assume that Bob<sub>anonymous</sub> and Alice<sub>anonymous</sub> already hold 1 Ether each.

We first describe the simple scenario where all parties are honest.
In day 1, Bob<sub>public</sub> and Alice<sub>public</sub> deposit 1000 Ether in the contract.
In day 2, Bob<sub>anonymous</sub> and Alice<sub>anonymous</sub> register to claim 1000 Ether. The registration requires 1 Ether deposit.
In day 3, the contract enables Bob<sub>anonymous</sub> and Alice<sub>anonymous</sub> to withdraw 1001 Ether (1000 Ether initial deposit + 1 Ether registration deposit).

An dishonest behavior is to register a claim that is not backed up by a deposit.
We handle dishonest behavior in the following way:
Suppose that in day 2.5 Charlie<sub>anonymous</sub> also register a claim for 1000 Ether and make a 1 Ether deposit.
In day 3, the contract detects a violation (sum of claims > sum deposits). In this case a *revealing phase* begins.
In the revealing phase each anonymous registree has to assign his registration deposit to a public address (i.e., Bob<sub>public</sub> or Alice<sub>public</sub>).
In this example each public address can be assigned with at most one registration deposit.
Hence, Bob and Alice can get their full deposit back, and Charlie will lose 1 Ether.
Finally, at day 4 Bob<sub>public</sub> and Alice<sub>public</sub> can withdraw their initial deposit and the registration deposit that was assigned to them.

The contract guarantees that Bob and Alice will not lose their money and gives a negative incentive (lost of registration deposit) for them or for a third parity to be dishonest.
However, if one of the parties (or a third parity) is dishonest, then the honest party might *lose* from the fact that a connection between his public and anonymous addresses was revealed.

## Detailed explanation
In this section we extend the explanation to the case where multiple parties are participating and each have multiple anonymous addresses for which he wishes to transfer his funds.
We describe the general setting as a game with multiple players, where each player has a public address, denoted by player.public and array of anonymous addressed, denoted by player.anonymous[], where initially each anonymous address holds at least 1 Ether.
The player publicly makes a deposit of player.deposit Ether and register anonymous claims denoted as player.claims[], where claim i is of value player.claim[i] and directed to address player.anonymous[i].
When player register a claim it has to deposit 1 Ether (via one of his anonymous addresses).
If the sum of claims of all players does not exceed the sum of the deposits, then the contract enables the anonymous addresses to withdraw their claim (and their registration deposit).
Otherwise, a *revealing phase* begins.
In the revealing phase the registrees can assign their deposit to a public address that made an initial deposit.
After the revealing phase each public address has a list of assigned claims, sorted in an ascending order (w.r.t value of the claim).
The contract assigns to the player N Ether, if the sum of the first N assigned claims do not exceed his initial deposit, and the sum of the first N+1 claims does exceed it.
Finally, the player can withdraw his initial deposit and additional N Ethers.

The revealing phase guarantees that a rational player will get at least the sum of his initial deposit and registration deposits (as he will assign his registrations to himself).
In addition, if all players are rational, then no player can benefit from claiming more than his initial deposit.
Indeed, if player i is dishonest and all other players assigned the claims to their selves, then player i will lose a registration deposit (as he cannot assign all the claims to himself).
We note that this assertion also holds in the particular case where a player initial deposit is 0.

##Contract overview
The contract has 6 main API functions:
1. `create_new_deal`. This function can be called by anyone. It defines a parameters for a new mixing deals. The parameters are: minimal number of participants, registration deposit size and duration of each phase (i.e., how many minutes a *day* last).
If the minimal number of participants is not achieved in the first day, then all participants can withdraw their deposit after that day.
The function returns an identifier for the new deal.
2. `make_initial_deposit`. API for the public deposit. msg.value is the value of the deposit.
3. `make_anonymous_registration`. API for claim registration. The callee specifies the value of the claim. msg.value should be set to the registration deposit value.
4. `make_anonymous_withdraw`. API for withdrawing the claim. This function can be called only if the anonymous claims are valid.
5. `reveal_registration`. API for the revealing phase.
6. `public_withdraw`. Should be used after the reviling phase is over or if there are not enough participants.

In addition there are two constant status functions:
1. `get_deal_state`. Returns the state of the deal (0 if the deal was never created).
2. `get_deal_status`. Returns the parameters of a deal.


## Disclaimer
This project is a proof of concept as part of the author's academic research and it is presented only to raise academic discussion on the subject.
The author never fully tested the correctness of the suggested protocol and/or code.
I am not responsible for any consequences of any use of the code or protocol that is suggested here.



