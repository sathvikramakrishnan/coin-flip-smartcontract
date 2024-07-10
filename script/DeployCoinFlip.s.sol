// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {CoinFlip} from "src/CoinFlip.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployCoinFlip is Script {
    function run() external returns (CoinFlip, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        var () = helperConfig.activeNetworkConfig();
    }
}
