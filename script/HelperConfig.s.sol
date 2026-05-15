// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {
    VRFCoordinatorV2_5Mock
} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public MOCK_BASE_FEE = 0.25 ether;
    uint256 public MOCK_GAS_PRICE_LINK = 1e9;
    uint256 public MOCK_WEI_PER_UNIT_LINK = 1e18;
}

contract HelperConfig is Script, CodeConstants {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) private networkConfigs;

    error HelperConfig__NoConfigForChainId(uint256 chainId);

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(
        uint256 chainId
    ) public view returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert(HelperConfig__NoConfigForChainId(chainId));
        }
    }

    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getOrCreateAnvilEthConfig()
        internal
        returns (NetworkConfig memory)
    {
        // check to see if we have a config for Anvil, if not, create one
        if (localNetworkConfig().vrfCoordinator != address(0)) {
            return localNetworkConfig();
        }
        // deploy the mocks
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock = new VRFCoordinatorV2_5Mock(
                MOCK_BASE_FEE, // base fee
                MOCK_GAS_PRICE_LINK, // gas price link
                MOCK_WEI_PER_UNIT_LINK // wei per unit link
            );
        vm.stopBroadcast();

        localNetworkConfig = new NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, // 30 seconds
            vrfCoordinator: address(vrfCoordinatorV2_5Mock),
            keyHash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4, // Anvil Key Hash
            subscriptionId: 0, // To be set after creating a subscription
            callbackGasLimit: 500000 // Adjust based on your needs
        });

        return localNetworkConfig;
        // if (networkConfigs[LOCAL_CHAIN_ID].vrfCoordinator != address(0)) {
        //     return networkConfigs[LOCAL_CHAIN_ID];
        // }
        // vm.startBroadcast();
        // VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock = new VRFCoordinatorV2_5Mock(
        //     BASE_FEE,
        //     GAS_PRICE_LINK
        // );
        // vm.stopBroadcast();
        // networkConfigs[LOCAL_CHAIN_ID] = NetworkConfig({
        //     entranceFee: 0.01 ether,
        //     interval: 30, // 30 seconds
        //     vrfCoordinator: address(vrfCoordinatorV2_5Mock),
        //     keyHash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4, // Anvil Key Hash
        //     subscriptionId: 0, // To be set after creating a subscription
        //     callbackGasLimit: 500000 // Adjust based on your needs
        // });
        // return networkConfigs[LOCAL_CHAIN_ID];
    }

    function getSepoliaEthConfig()
        internal
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30, // 30 seconds
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B, // Sepolia VRF Coordinator
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // Sepolia Key Hash
                subscriptionId: 0, // To be set after creating a subscription
                callbackGasLimit: 500000 // Adjust based on your needs
            });
    }
}
