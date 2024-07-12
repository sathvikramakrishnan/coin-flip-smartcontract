// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {CoinFlip} from "../src/CoinFlip.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

/**
 * @dev Deploys our contract on the required network
 * @dev Creates and funds a new subscription if the received subId is invalid
 * @dev Adds consumer to the provided subscription ID
 */
contract DeployCoinFlip is Script {
    function run() external returns (CoinFlip, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 keyHash,
            uint256 subscriptionId,
            uint32 callbackGasLimit,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscriptionObj = new CreateSubscription();
            subscriptionId = createSubscriptionObj.createSubscription(
                vrfCoordinator,
                deployerKey
            );

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinator,
                subscriptionId,
                link,
                deployerKey
            );
        }

        vm.startBroadcast();
        CoinFlip coinFlip = new CoinFlip(
            entranceFee,
            interval,
            vrfCoordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            vrfCoordinator,
            subscriptionId,
            deployerKey,
            address(coinFlip)
        );
        return (coinFlip, helperConfig);
    }
}
