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

    function run() public returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // กำหนดจำนวนเงินที่ต้องการเติม (3 LINK ในรูปแบบของ wei)

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;

        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address linkToken
    ) public {
        console.log("Funding subscription ID:", subscriptionId);
        console.log("Using VRF Coordinator:", vrfCoordinator);
        console.log("On ChainId:", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            // สำหรับ local network ให้ใช้ฟังก์ชัน fundSubscription ของ VRFCoordinatorV2_5Mock
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            // สำหรับ testnet/mainnet ให้โอน LINK token ไปยัง subscription
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address link = helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator, subscriptionId, link);
    }
}
