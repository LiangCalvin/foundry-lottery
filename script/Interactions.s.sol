// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {console} from "forge-std/console.sol";
import {Raffle} from "../src/Raffle.sol";
// import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {
    VRFCoordinatorV2_5Mock
} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {CodeConstants} from "./HelperConfig.s.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId, ) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint256, address) {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrf = VRFCoordinatorV2_5Mock(vrfCoordinator);
        uint256 subId = vrf.createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription ID is:", subId);
        console.log(
            "Please update your HelperConfig.s.sol file with this subscription ID and rerun the deployment script."
        );

        return (subId, vrfCoordinator);
    }

    function run() external returns (uint64, address) {
        return CreateSubscriptionUsingConfig();
    }
}
