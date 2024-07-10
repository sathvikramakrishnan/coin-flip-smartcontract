# Introduction
Hello there!\
This smart contract implements a coin flip game

## Completion status
Pending

## How to play
A user enters this game by paying a specific entrance fee. The owner of the contract pledges the same amount in this contract. Both of their funds become the prize pool.

Essentially, the user is betting this money on the coin landing on heads. The user wins the prize pool money in the contract if it lands on head.

Otherwise the money is transferred to the owner's wallet.

## How it works
This program uses chainlink vrf v2.5 to generate random number that is than mapped to heads and tails.

Chainlink Automation with custom logic is used to start the game and transfer the owner's funds into the contract as soon as a player enters.

## A note on private keys
This contract is not safe to use with legitimate private keys.\
Use only those private keys with no real assets.

## A note on chainlink vrf2.5 scripts
This contract uses chainlink vrf2.5.

A modified version of `VRFCoordinatorV2Mock.sol` is created in the src directory under the name `VRFCoordinatorV2PlusMock.sol`\
They both provide roughly the same functionailties; the newer program has modifications to implement `AddConsumer` function which is not available in the official library.

Shoutout to EngrPips for this code!

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
