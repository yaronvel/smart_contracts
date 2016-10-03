# Simple Decentralized Ether Mixer (with a caveat)
(Mixer DAPP is [live](https://dmixer.github.io/) in Beta stage)

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

This protocol simplifies the [previous suggestion](https://github.com/yaronvel/smart_contracts/tree/master/mixer) and also improves privacy guarantees.
For a complete comparison see Section 5.

A DAPP implementation of the protocol for ETH and ETC is [online](https://dmixer.github.io/).
## Short explanation
In this section we give a short explanation on the protocol.
We consider the case where Bob and Alice each have 1000 Ether in their public account and 10 Ether in their secret account.

1. In day 1: Bob and Alice register a 1000 Ether *claim* via their secret account and pay 10 Ether collateral with their secret account.

2. In day 2: Bob and Alice should *deposit* 1000 Ether via their public account.

3. In day 3: If deposited sum matches claimed sum, then each secret account that made a claim *withdraws* 1010 Ether (1000 Ether deposit + 10 Ether collateral).
Otherwise, only users who made a deposit can *withdraw* their public deposit and collaterals sum is divided equally among all depositors.


The contract guarantees that Bob and Alice will not lose their money and gives a negative incentive (lost of claim registration collateral) for them or for a third parity to be dishonest.
Moreover, if one of the parties is dishonest, then the honest parties are making some profit by sharing his collateral (for security reasons, only half of his collateral is shared, and the rest is destroyed).

## Detailed explanation
In this section we extend the explanation to the case where multiple parties are participating and each has multiple secret accounts for which he wishes to transfer his funds.

In every mixing deal, the amount that a single secret account can claim is fixed and the collateral value is also fixed.
The protocol has three phase:

1. *Claim phase*: In this phase every secret account registers a claim (for the fixed amount value).

2. *Deposit phase*: In this phase every user should finance his claims by deposit enough funds that will cover his claims.

3. *Withdraw phase*: If all the claims are fully covered, then the secret accounts can withdraw their claim (and collateral). Otherwise, the collateral is divided proportionally among all users who made a public deposit according to the following scheme:
```
uint effectiveNumDeposits = deal.depositSum / deal.claimValueInWei;
uint userEffectiveNumDeposits = depositValue / deal.claimValueInWei;
uint extraBalance = ( deal.numClaims - effectiveNumDeposits ) * deal.claimCollateralInWei;
uint userExtraBalance = userEffectiveNumDeposits * extraBalance / effectiveNumDeposits;

withdrawedValue = depositValue + deal.claimCollateralInWei * userEffectiveNumDeposits + ( userExtraBalance / 2 );
msg.sender.send(withdrawedValue);
```



### Analysis
If all the parties are honest and cover they claims, then the Ether is transfered from public accounts to secret accounts.
Otherwise, it is guaranteed that if a user did not covered even one of his claim, then he will lose at least half of his collateral.
Moreover, the other half of his collateral will be given to the honest parties.
Hence, honest parties will not lose their funds (and even earn some), and their privacy is maintained also in the presence of dishonest parties.


##Contract overview
The [contract](https://github.com/yaronvel/smart_contracts/blob/master/mixer/simple/SimpleMixer.sol) has 4 main API functions:

1. `newDeal`. This function can be called by anyone. It defines parameters for a new mixing deals. The parameters are: minimal number of participants, collateral and fixed claim amount value sizes and duration of each phase.
If the minimal number of participants is not achieved during the claim phase, then all participants can withdraw their deposit.

2. `makeClaim`. API for the claim registration of secret accounts. msg.value should be set to the collateral value.

3. `makeDeposit`. API for public deposit. msg.value should be a multiple of claim value.

4. `withdraw`. API for withdrawing the funds

In addition there is one constant status functions:

1. `dealStatus`. (See contract code).

For details on the deployment of the contract see [DAPP webpage](https://dmixer.github.io).

## Comparison with non-simple mixer
This protocol improves the [previous suggestion](https://github.com/yaronvel/smart_contracts/tree/master/mixer) by allowing simpler user interface and by maintaining privacy even in the presence of malicious parties.
In the previous protocol the connection between secret and public account had to be revealed if one of the parties was dishonest.

On the down side, in this protocol the collateral value has to be proportional to the fixed claim amount.
Whereas the previous protocol allowed fixed size collaterals and varying claim amounts. 

## Disclaimer
This project is beta stage and might contain unknown bugs.
I am not responsible for any consequences of any use of the code or protocol that is suggested here.

##About the author
Yaron Velner holds a Ph.d in computer science from Tel Aviv University.
His current research interests are formal methods in game theory with applications to smart contracts.
You can contact Yaron at yaron.welner@mail.huji.ac.il.

