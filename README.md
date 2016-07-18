# Smart Contract - send me my EZchip T-shirt
**Table of Contents**
- [Introduction](##Introduction)
- [Smart contracts](##Smart contracts)
- [The contract](##The contract)
- [Installation](##Installation)
- [How to run](##How to run)
- [FAQ](##FAQ)
- [Disclaimer](##Disclaimer)

## Introduction
We demonstrate how to use [Ethereum](http://ethereum.org/) smart contracts platform to make an agreement between two parties.
In the agreement the first party *pays* in exchange for a (physical) mail delivery from the second party.
The *payment* is done with Ethereum crypto-currency ([ETH](http://coinmarketcap.com/currencies/ethereum/)). See [USD-ETH exchange rate](http://coinmarketcap.com/currencies/ethereum/).
In addition, upon a successful delivery, a special (virtual) token, "The king of returning shirts", is assigned to the sender. The token serves as a certificate that indicates the sender name and it is also tradable. That is, the sender may trade the certificate in exchange to ethers (ETHs).

**For the purpose of this demonstration we use _testnet_  ethers that have no value what so ever. The certificate resides over the _testnet_ network, and as a consequence there is no guarantee that it will last forever.**

## Smart contracts
*Smart contracts* are account holding objects on a blockchain. They contain code functions and can interact with other contracts, make decisions, store data, and send ether to others. Contracts are defined by their creators, but their execution, and by extension the services they offer, is provided by the (ethereum) blockchain itself. They will exist and be executable as long as the whole network exists, and will only disappear if they were programmed to self destruct.

**TL;DR: a smart contract is an immutable and _unstoppable_ piece of software that can pay**
## The contract
The contract code is deposit in [post_contract.sol](https://github.com/yaronvel/smart_contracts/blob/master/post_contract.sol). The interesting functionality resides in `submit` and `__callback`.
In `submit` the sender gives the Israeli post office confirmation string (for example "RR12345IL") the date of delivery and his name.
The method invokes an [oraclize.it](http://oraclize.it/) oracle that queries the [Israeli post office JSON api](http://www.israelpost.co.il/itemtrace.nsf/trackandtraceJSON) on the specific confirmation string and returns the data to the `__callback` function.
In `__callback` the contract verifies that the destination of the mail is correct and that the date is as stated (the date is needed to verify that this is a recent mail delivery).
Once the details are correctly verified, a *payment* is sent to the sender and the token is assigned after his name.
Then, he can trade the token with `set_for_sale` and `buy_king` methods.

## Installation
To make the contract truly unstoppable one has to install an [Ethereum client](https://ethcore.io/parity.html), [setup an account](https://github.com/ethereum/go-ethereum/wiki/Managing-your-accounts) and [purchase ethers](https://www.weusecoins.com/how-to-buy-ether/).

However, to simplify the demonstration we implemented a python user-interface that is using a *centralized* (and thus stoppable) [Etherscan Ethereum client](https://testnet.etherscan.io/) and predefined accounts that hold some *testnet* ethers.
Hence, all that is need is to download the contract user-interface file [post_contract_ui.py](https://github.com/yaronvel/smart_contracts/blob/master/post_contract_ui.py) and install its dependencies [pycoin](https://github.com/richardkiss/pycoin) and [pyethereum](https://github.com/ethereum/pyethereum).


## How to run
First you will have to obtain a private key that corresponds to an account.
Run:
```
python contract_ui.py --suggest-private-key
```
Select (copy-paste) one of the keys and use it in all next calls.
To submit the delivery confirmation run:
```
python contract_ui.py --private-key=your_key --submit="confirmation date name"
```
For example:
```
python contract_ui.py --private-key=0xa8eac651502c4efcd704218afec63cbecfe75ae89302a0ed6e8fb3449e02acb1 --submit="RR663423191IL 23/05/2016 David"
```
The mail must be sent via registered mail (DOAR RASHUM), and the call must be done after the confirmation appears in the Israeli post office system (you can check it [here](http://www.israelpost.co.il/itemtrace.nsf/mainsearch?OpenForm)).

To see the holder of the token run:
```
python contract_ui.py --show-king
```
If you have the private key that holds the token (i.e., the key you used to submit the confirmation), then you can change the content of the token by calling:
```
python contract_ui.py --private-key=your_key --change-name=new_name
```
To offer the token for sale run:
```
python contract_ui.py --private-key=your_key --set-price=price_in_ether
```
Note that the key must be the key of the token holder and that once the price is set it cannot be changed. The price need not be an integer.
Finally, to buy the token (will work only if it was set for sale) call:
```
python contract_ui.py --private-key=new_key --buy=price
```
Note that the new key must be different that the key who currently hold the token and hold sufficient amount of funds.

**The trade is with _testnet_ ethers that worth nothing**
## Attack vectors
1. The contract only verifies that a mail was sent to the right destination at a date subsequent to 18/07/2016. Due to the limitations of the post office web api it cannot verify the content of the mail. I.e., the envelope could be empty. Moreover, only the destination city is checked, and to save computation costs the contract will also accept deliveries where the expected destination is actually the source of the delivery.
2. The contract is using the services of [Oraclize.it](http://oraclize.it/) and the [Israeli post office JSON api](http://www.israelpost.co.il/itemtrace.nsf/trackandtraceJSON). These services are run by central entities and thus stoppable (e.g., by a court of law or DDOS attacks), or might simply stop working at will.
3. The contract could be subject to a denial of service attack. The call to the oracle is asynchronous and thus the contract must reject all submissions until the oracle returns the answer for the last query. A malicious attacker might send bogus submissions for a long period of time and prevent honest senders from submitting their proof.
However, if the contract is deployed over real Ethereum network, then every submission costs around 20 cents of a USD. Hence, in the long run, such an attack is very expensive.

## FAQ
### Do I really get paid? If not why should I send you the shirt?
You are **not** paid. You get *testnet* coins that worth nothing.
You do get a token but it might not be persistent.
You should participate for fun.

### How can I know that the user-interface really runs the contract you say it runs?
In [post_contract_ui.py](https://github.com/yaronvel/smart_contracts/blob/master/post_contract_ui.py) you can see a reference to the *contract hash*
```
contract_hash = "ccf06b3bcebe61c5294995804fe5de724e56a680"
```
You can see the code of the contract in the testnet network [here](http://testnet.etherscan.io/address/0xccf06b3bcebe61c5294995804fe5de724e56a680#code).
Note that the code presented there is flat, i.e., it cannot use `import`. Hence, you should search for
```
/////////// my code starts here ///////////////////
```
and read it from there.

In the real world the user interacts with contracts via dedicated clients who make sure that the right contract is called.
### Can you change the contract or delete it?
No.

### What is the purpose of this project
1. Learn how to make smart contracts.
2. Learn how to use github.
3. Get my shirt.

### Did you get your shirt?
Not yet.

## Disclaimer
**The contract pays with _testnet_ coins that worth nothing.** I repeat: **you are _not_ getting paid!**

This project is part of the author's academic research that is held in the Hebrew university of Jerusalem.
If there is any potential violation of user terms w.r.t the Israel post office, or any violations of the contract law in Israel, it is done only for the sake of academic research and not for any profit purposes (though I am not aware of any such violations).


