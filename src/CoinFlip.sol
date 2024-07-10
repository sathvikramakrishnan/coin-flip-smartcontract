// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title Coin flip smart contract
 * @author Sathvik
 * @notice A coin flipping smart contract game
 * @dev Implements Chainlink vrf2.5
 */
contract CoinFlip {
    error CoinFlip__NotEnoughEthSent();
    error CoinFlip__GameNotOpen();
    error CoinFlip__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 contractState
    );

    /**Type declarations */
    enum CoinState {
        HEAD, // 0
        TAIL // 1
    }

    enum ContractState {
        OPEN, // 0
        CALCULATING // 1
    }

    /**State variables */
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;

    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address payable private s_player;
    CoinState private s_coinState;
    ContractState private s_contractState;

    event EnteredGame(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;

        s_lastTimeStamp = block.timestamp;
        s_contractState = ContractState.OPEN;
    }

    function enterCoinFlipGame() external payable {
        if (msg.value < i_entranceFee) {
            revert CoinFlip__NotEnoughEthSent();
        }
        if (s_contractState == ContractState.CALCULATING) {
            revert CoinFlip__GameNotOpen();
        }
        s_player = (payable(msg.sender));
        emit EnteredGame(msg.sender);
    }

    /**
     * @dev This function is called by chainlink automation nodes to check if upkeep is needed
     * The following should be true for return value to be true:
     * 1. time interval has passed between 2 contract runs
     * 2. contract has non-zero balance
     * 3. checks if there is a player in the game
     */
    function checkUpkeep(
        bytes memory /** checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp > i_interval);
        bool isOpen = ContractState.OPEN == s_contractState;
        bool hasFunds = address(this).balance > 0;
        bool hasPlayer = s_player != address(0);

        upkeepNeeded = (hasPlayer && hasFunds && isOpen && timeHasPassed);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /**performData*/) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert CoinFlip__UpkeepNotNeeded(
                address(this).balance,
                uint256(s_contractState)
            );
        }

        s_contractState = ContractState.CALCULATING;
    }

    /**
     * @dev Getter functions
     */
    function getEntraceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer() external view returns (address) {
        return s_player;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
