// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployCoinFlip} from "../../script/DeployCoinFlip.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CoinFlip} from "../../src/CoinFlip.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Vm} from "forge-std/Vm.sol";

contract CoinFlipTest is Test {
    uint256 private constant STARTING_USER_BALANCE = 10 ether;

    address private PLAYER = makeAddr("player");
    address private OWNER;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;

    CoinFlip coinFlip;
    HelperConfig helperConfig;

    event PlayerEnteredGame(address indexed player);
    event OwnerEnteredGame(address indexed owner);

    modifier GameEnteredAndTimePassed() {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        vm.prank(PLAYER);
        coinFlip.enterCoinFlipGame{value: entranceFee}();
        vm.prank(OWNER);
        coinFlip.OwnerEntersCoinFlipGame{value: entranceFee}();
        _;
    }

    modifier GameWarpAndRoll() {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier GameHasPlayers() {
        vm.prank(PLAYER);
        coinFlip.enterCoinFlipGame{value: entranceFee}();
        vm.prank(OWNER);
        coinFlip.OwnerEntersCoinFlipGame{value: entranceFee}();
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function setUp() external {
        DeployCoinFlip deployer = new DeployCoinFlip();
        (coinFlip, helperConfig) = deployer.run();

        OWNER = coinFlip.getOwner();
        (entranceFee, interval, vrfCoordinator, , , , , ) = helperConfig
            .activeNetworkConfig();

        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    // initialization tests
    function testContractStateIsOpen() public view {
        assert(coinFlip.getContractState() == CoinFlip.ContractState.OPEN);
    }

    function testCoinStateIsNA() public view {
        assert(coinFlip.getCoinState() == CoinFlip.CoinState.CALCULATING);
    }

    function testOwnerIsMsgSender() public view {
        // doesn't work when the deployerkey is passed into `vm.startBroadcast` in the deploy script
        assertEq(coinFlip.getOwner(), msg.sender);
    }

    // entering the game tests
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

    // performUpkeep tests
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

    function testCantEnterWhenGameCalculating()
        public
        GameEnteredAndTimePassed
    {
        coinFlip.performUpkeep("");

        vm.prank(PLAYER);
        vm.expectRevert(CoinFlip.CoinFlip__GameNotOpen.selector);
        coinFlip.enterCoinFlipGame{value: entranceFee}();
    }

    // checkUpkeep tests
    function testUpkeepFalseWhenNoFunds() public GameWarpAndRoll {
        (bool failed, ) = coinFlip.checkUpkeep("");
        assertEq(failed, false);
    }

    function testUpkeepFalseWhenNoPlayer() public GameWarpAndRoll {
        vm.prank(OWNER);
        coinFlip.OwnerEntersCoinFlipGame{value: entranceFee}();

        (bool failed, ) = coinFlip.checkUpkeep("");
        assertEq(failed, false);
    }

    function testUpkeepFalseWhenNotEnoughTimePassed() public GameHasPlayers {
        vm.roll(block.number + 1);

        (bool failed, ) = coinFlip.checkUpkeep("");
        assertEq(failed, false);
    }

    function testUpkeepFalseWhenGameNotOpen() public GameEnteredAndTimePassed {
        coinFlip.performUpkeep("");

        (bool failed, ) = coinFlip.checkUpkeep("");
        assertEq(failed, false);
    }

    // test event outputs

    function testPerformUpkeepEmitsRequestId() public GameEnteredAndTimePassed {
        vm.recordLogs();
        coinFlip.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 reqId = entries[1].topics[1];

        CoinFlip.ContractState cState = coinFlip.getContractState();
        assert(uint256(reqId) != 0);
        assert(cState == CoinFlip.ContractState.CALCULATING);
    }

    function testFulfilllRandomWordsOnlyAfterPerformUpkeep(
        uint256 reqId
    ) public GameEnteredAndTimePassed skipFork {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            reqId,
            address(coinFlip)
        );
    }

    function testFulfilllRandomWordsPicksWinner()
        public
        GameEnteredAndTimePassed
        skipFork
    {
        vm.recordLogs();
        coinFlip.performUpkeep("");

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 reqId = entries[1].topics[1];

        uint256 prevTimestamp = coinFlip.getLastTimeStamp();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(reqId),
            address(coinFlip)
        );

        address winner = coinFlip.getRecentWinner();
        CoinFlip.CoinState coinState = coinFlip.getCoinState();

        assert(winner != address(0));
        assert(coinState != CoinFlip.CoinState.CALCULATING);
        assert(coinFlip.getPlayer() == address(0));
        assert(prevTimestamp < coinFlip.getLastTimeStamp());
        assert(
            coinFlip.getRecentWinner().balance >=
                STARTING_USER_BALANCE + entranceFee
        );
    }
}
