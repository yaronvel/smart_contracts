# Simple Decentralized Ether Mixer (with a caveat)
**Table of Contents**
- [Introduction](##Introduction)
- [Short explanation](##Short explanation)
- [Detailed explanation](##Detailed explanation)
- [Contract overview](##Contract overview)
- [Comparison with non-simple mixer](##Comparison with non-simple mixer)
- [Disclaimer](##Disclaimer)
- [About the author](##About the author)

## Introduction
We implement a decentralized Ether mixer contract.
The contract allows multiple parities to deposit funds and to withdraw the same amount with multiple anonymous addresses.

**The caveat of the protocol is that the anonymous addresses should already contain small amount of Ethers.**
This is possible e.g., by mining, [faucets](https://cryptojunction.com/top-10-ethereum-faucets-2016/), [centralized Ether mixers](https://ethermixer.com/) or by converting the Ethers to bitcoins, mixing them, and convert them back to Ethers.

This protocol simplifies the [previous suggestion](https://github.com/yaronvel/smart_contracts/tree/master/mixer) and also improves privacy gaurantees.
For a complete comarison see Section 5.

A DAPP implementation of the protocol for ETH and ETC is [online](https://dmixer.github.io/).
## Short explanation
In this section we give a short explanation on the protocol.
We consider the case where Bob and Alice each have 1000 Ether in their public account and 10 Ether in their secret account.
In day 1: Bob and Alice register a 1000 Ether *claim* via their secret account and pay 10 Ether collateral with their secret account.
In day 2: Bob and Alice should *deposit* 1000 Ether via their public account.
In day 3: * If deposited sum matches claimed sum, then each secret account that made a claim *withdraws* 1010 Ether (1000 Ether deposit + 10 Ether collateral). 
	  * Otherwise, only users who made a deposit can *withdraw* their public deposit and collaterals sum is divided equally among all depositors.

The contract guarantees that Bob and Alice will not lose their money and gives a negative incentive (lost of claim registration collateral) for them or for a third parity to be dishonest.
Moreover, if one of the parties is dishonest, then the honest parties are making some profit by sharing his collateral (for security reasons, only half of his collateral is shared, and the rest is destroyed).

## Detailed explanation
In this section we extend the explanation to the case where multiple parties are participating and each has multiple secret accounts for which he wishes to transfer his funds.

In every mixing deal, the amount that a single secret account can claim is fixed and the collateral value is also fixed.
The protocol has three phase:
1. *Claim phase*: In this phase every secret account registers a claim (for the fixed amount value).
2. *Deposit phase*: In this phase every user should finance his claims by deposit enough funds that will cover his claims.
3. *Withdraw phase*: If all the claims are fully covered, then the secret accounts can withdraw their claim (and collateral). Otherwise, the collateral is divided proportionally among all users who made a public deposit.

### Anlaysis
If all the parties are honest and cover they claims, then the Ether is transfered from public accounts to secret accounts.
Otherwise, it is gauranteed that if a user only covered X fraction of his claim, then he will lose (1-X) of his collateral.
Moreover, (1-X) of his collateral will be given to the honest parties.
Hence, honest parties will not lose their funds (and even earn some), and their privacy is maintened also in the presence of dishonest parties.

To prevent the corner case where most of the dishonest party collateral is given back to a dishonest party (who made the vast majority of the deposits) we only share half of the uncovered claims collateral.

##Contract overview
The [contract](https://github.com/yaronvel/smart_contracts/blob/master/mixer/mix.sol) has 6 main API functions:
1. `create_new_deal`. This function can be called by anyone. It defines parameters for a new mixing deals. The parameters are: minimal number of participants, registration deposit size and duration of each phase (i.e., how many minutes a *day* last).
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

The contract was deployed and partially tested in Ethereum's testnet.
An honest deal with three parties who deposit 0.01, 0.02 and 0.04 Ether can be viewed [here](http://testnet.etherscan.io/address/0x69959957894d25adac7ca8ebe65ada16d85072be) (note that the contract balance is 0).
A dishonest deal can be viewed [here](http://testnet.etherscan.io/address/0x9315e8f087b9a4df0ea1dc8e19ec641de4c19c03) (note that the contract balance is positive).

## Disclaimer
This project is a proof of concept as part of the author's academic research and it is presented only to raise academic discussion on the subject.
The author never fully tested the correctness of the suggested protocol and/or code.
I am not responsible for any consequences of any use of the code or protocol that is suggested here.

##About the author
Yaron Velner is a postdoctoral researcher in the Hebrew University of Jerusalem.
He holds a Ph.d in computer science from Tel Aviv University.
His current research interests are formal methods in game theory with applications to smart contracts.
You can contact Yaron at yaron.welner@mail.huji.ac.il.

