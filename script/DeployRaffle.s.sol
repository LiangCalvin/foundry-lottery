// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {CreateSubscription, FundSubscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function deployRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local -> deploy mocks, get localconfig
        // sepolia -> get sepolia config from helperconfig
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // if (config.subscriptionId == 0) {
        //     // สร้าง Subscription ID ใหม่
        //     CreateSubscription createSubscription = new CreateSubscription();
        //     (config.subscriptionId, config.vrfCoordinator) = createSubscription
        //         .CreateSubscription(config.vrfCoordinator);

        //     // เติมเงิน LINK เข้า Subscription เพื่อให้มีเงินจ่ายค่าสุ่ม
        //     FundSubscription fundSubscription = new FundSubscription();
        //     fundSubscription.fundSub(
        //         config.vrfCoordinator,
        //         config.subscriptionId,
        //         config.link
        //     ); // (เช็คตัวแปร link ใน config ด้วยนะ)
        // }

        vm.startBroadcast();

        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.keyHash,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        // AddConsumer addConsumer = new AddConsumer();
        // addConsumer.addConsumer(
        //     address(raffle),
        //     config.vrfCoordinator,
        //     config.subscriptionId
        // );

        return (raffle, helperConfig);
    }

    function run() external returns (Raffle, HelperConfig) {
        return deployRaffle();
    }
}
