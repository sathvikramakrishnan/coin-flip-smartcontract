// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

/**
 * @title Coin flip smart contract
 * @author Sathvik
 * @notice A coin flipping smart contract game
 * @notice The user wins of the coin lands on head; the owner wins if it lands on tail.
 * @dev Implements Chainlink vrf2.5 with a custom made mock vrf script
 */
contract CoinFlip is VRFConsumerBaseV2Plus {
    error CoinFlip__NotEnoughEthSent(uint256 value);
    error CoinFlip__GameNotOpen();
    error CoinFlip__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 contractState
    );
    error CoinFlip__TransactionFailed(address winner);
    error CoinFlip__NotTheOwner(address sender);

    /**Type declarations */
    enum CoinState {
        TAIL, // 0
        HEAD, // 1
        NA // 2
    }

    enum ContractState {
        OPEN, // 0
        CALCULATING // 1
    }

    /**State variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    address private i_owner;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    IVRFCoordinatorV2Plus private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address private s_player;
    CoinState private s_coinState;
    ContractState private s_contractState;
    bool private s_ownerHasEntered;

    event EnteredGame(address indexed player);
    event OwnerEnteredGame(address indexed owner);
    event RequestedWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner, CoinState indexed flipOutput);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_owner = msg.sender;

        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = IVRFCoordinatorV2Plus(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_contractState = ContractState.OPEN;
        s_coinState = CoinState.NA;
        s_ownerHasEntered = false;
    }

    function enterCoinFlipGame() external payable {
        if (msg.value < i_entranceFee) {
            revert CoinFlip__NotEnoughEthSent(msg.value);
        }
        if (s_contractState == ContractState.CALCULATING) {
            revert CoinFlip__GameNotOpen();
        }

        s_player = (msg.sender);
        emit EnteredGame(msg.sender);
    }

    function OwnerEntersCoinFlipGame() external payable {
        if (msg.sender != i_owner) {
            revert CoinFlip__NotTheOwner(msg.sender);
        }
        if (msg.value < i_entranceFee) {
            revert CoinFlip__NotEnoughEthSent(msg.value);
        }
        if (s_contractState == ContractState.CALCULATING) {
            revert CoinFlip__GameNotOpen();
        }

        s_ownerHasEntered = true;
        emit OwnerEnteredGame(i_owner);
    }

    /**
     * @dev This function is called by chainlink automation nodes to check if upkeep is needed
     * The following should be true for return value to be true:
     * 1. time interval has passed between 2 contract runs
     * 2. contract has non-zero balance
     * 3. checks if there is a player in the game
     * 4. checks if the owner is in the game
     */
    function checkUpkeep(
        bytes memory /** checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp > i_interval);
        bool isOpen = (ContractState.OPEN == s_contractState);
        bool hasFunds = address(this).balance > 0;
        bool hasPlayer = s_player != address(0);

        upkeepNeeded = (hasPlayer &&
            hasFunds &&
            isOpen &&
            timeHasPassed &&
            s_ownerHasEntered);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /** performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert CoinFlip__UpkeepNotNeeded(
                address(this).balance,
                uint256(s_contractState)
            );
        }

        s_contractState = ContractState.CALCULATING;
        s_coinState = CoinState.NA;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash, // Updated for VRF v2.5
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        emit RequestedWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /** requestId */,
        uint256[] calldata randomWords
    ) internal override {
        address winner;
        uint256 coinState = randomWords[0] % 2;
        if (coinState == 1) {
            winner = s_player;
            s_coinState = CoinState.HEAD;
        } else {
            winner = i_owner;
            s_coinState = CoinState.TAIL;
        }

        // Clean up stuff
        s_recentWinner = winner;
        s_contractState = ContractState.OPEN;
        s_player = address(0);
        s_lastTimeStamp = block.timestamp;
        s_ownerHasEntered = false;

        emit WinnerPicked(winner, s_coinState);

        (bool success, ) = payable(winner).call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert CoinFlip__TransactionFailed(winner);
        }
    }

    /**
     * @dev Getter functions
     */
    function getEntraceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getPlayer() external view returns (address) {
        return s_player;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getCoinState() external view returns (CoinState) {
        return s_coinState;
    }

    function getContractState() external view returns (ContractState) {
        return s_contractState;
    }
}
