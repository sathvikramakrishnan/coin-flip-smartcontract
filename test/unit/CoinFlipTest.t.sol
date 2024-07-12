// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployCoinFlip} from "../../script/DeployCoinFlip.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CoinFlip} from "../../src/CoinFlip.sol";

contract CoinFlipTest is Test {
    uint256 private constant STARTING_USER_BALANCE = 10 ether;

    address private PLAYER = makeAddr("player");
    address private OWNER;

    uint256 entranceFee;
    uint256 interval;
    // address vrfCoordinator;
    // bytes32 keyHash;
    // uint256 subscriptionId;
    // uint32 callbackGasLimit;
    // address link;
    // uint256 deployerKey;

    CoinFlip coinFlip;
    HelperConfig helperConfig;

    event PlayerEnteredGame(address indexed player);
    event OwnerEnteredGame(address indexed owner);

    modifier GameEnteredAndTimePassed() {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function setUp() external {
        DeployCoinFlip deployer = new DeployCoinFlip();
        (coinFlip, helperConfig) = deployer.run();

        OWNER = coinFlip.getOwner();
        (entranceFee, , , , , , , ) = helperConfig.activeNetworkConfig();

        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testContractStateIsOpen() public view {
        assert(coinFlip.getContractState() == CoinFlip.ContractState.OPEN);
    }

    function testCoinStateIsNA() public view {
        assert(coinFlip.getCoinState() == CoinFlip.CoinState.NA);
    }

    function testOwnerIsMsgSender() public view {
        // doesn't work when the deployerkey is passed into `vm.startBroadcast` in the deploy script
        assertEq(coinFlip.getOwner(), msg.sender);
    }

    function testPlayerEnterRevertsWhenNotEnoughEth() public {
        vm.prank(PLAYER);

        vm.expectRevert(
            abi.encodeWithSelector(
                CoinFlip.CoinFlip__NotEnoughEthSent.selector,
                0
            )
        );
        coinFlip.enterCoinFlipGame();
    }

    function testPlayerRecorded() public {
        vm.prank(PLAYER);
        coinFlip.enterCoinFlipGame{value: entranceFee}();
        assertEq(coinFlip.getPlayer(), PLAYER);
    }

    function testPlayerEnteredEmitsEvent() public {
        vm.prank(PLAYER);

        vm.expectEmit(true, false, false, false, address(coinFlip));
        emit PlayerEnteredGame(PLAYER);
        coinFlip.enterCoinFlipGame{value: entranceFee}();
    }

    function testRevertIfNotOwner() public {
        vm.prank(PLAYER);
        vm.expectRevert(
            abi.encodeWithSelector(
                CoinFlip.CoinFlip__NotTheOwner.selector,
                PLAYER
            )
        );
        coinFlip.OwnerEntersCoinFlipGame{value: entranceFee}();
    }

    function testOwnerEnterRevertsWhenNotEnoughEth() public {
        vm.prank(OWNER);

        vm.expectRevert(
            abi.encodeWithSelector(
                CoinFlip.CoinFlip__NotEnoughEthSent.selector,
                0
            )
        );
        coinFlip.OwnerEntersCoinFlipGame();
    }

    function testOwnerEnteredEmitsEvent() public {
        vm.prank(OWNER);

        vm.expectEmit(true, false, false, false, address(coinFlip));
        emit OwnerEnteredGame(OWNER);
        coinFlip.OwnerEntersCoinFlipGame{value: entranceFee}();
    }

    function testNoRevertIfUpkeepNeeded() public GameEnteredAndTimePassed {
        coinFlip.performUpkeep("");
    }

    function testRevertIfUpkeepNotNeeded() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                CoinFlip.CoinFlip__UpkeepNotNeeded.selector,
                address(coinFlip).balance,
                uint256(coinFlip.getContractState())
            )
        );
        coinFlip.performUpkeep("");
    }
}
