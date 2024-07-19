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

## A note on LinkToken contract
The contract `test/mocks/LinkToken.sol` is a modified script used in the tutorial by Patrick Collins.

## A note on private keys
This contract is not safe to use with legitimate private keys.\
Use only those private keys with no real assets.

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
