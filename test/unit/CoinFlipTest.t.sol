// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployCoinFlip} from "../../script/DeployCoinFlip.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CoinFlip} from "../../src/CoinFlip.sol";

contract CoinFlipTest is Test {
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    address public PLAYER = makeAddr("player");

    // uint256 entranceFee;
    // uint256 interval;
    // address vrfCoordinator;
    // bytes32 keyHash;
    // uint256 subscriptionId;
    // uint32 callbackGasLimit;
    // address link;
    // uint256 deployerKey;

    CoinFlip coinFlip;
    HelperConfig helperConfig;

    function setUp() external {
        DeployCoinFlip deployer = new DeployCoinFlip();
        (coinFlip, helperConfig) = deployer.run();
        // (
        //     entranceFee,
        //     interval,
        //     vrfCoordinator,
        //     keyHash,
        //     subscriptionId,
        //     callbackGasLimit,
        //     link,
        //     deployerKey
        // ) = helperConfig.activeNetworkConfig();

        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testContractStateIsOpen() public view {
        assert(coinFlip.getContractState() == CoinFlip.ContractState.OPEN);
    }

    function testCoinStateIsNA() public view {
        assert(coinFlip.getCoinState() == CoinFlip.CoinState.NA);
    }

    function testOwnerIsMsgSender() public view {
        console.log("Owner", coinFlip.getOwner());
        console.log("Sender", msg.sender);
        console.log("This contract", address(this));
        assertEq(coinFlip.getOwner(), msg.sender);
    }
}
