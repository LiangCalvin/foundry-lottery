// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {
    VRFConsumerBaseV2Plus
} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {
    VRFV2PlusClient
} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {
    AutomationCompatibleInterface
} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title A sample Raffle Contract
 * @author Patrick Collins
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */
contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State variables */
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    // 2. ต้องเพิ่มตัวแปรที่จำเป็นสำหรับใช้งาน VRF ในระดับสัญญา
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    RaffleState private s_raffleState;

    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId); // ควรมีเอาไว้เก็บค่า log
    event WinnerPicked(address indexed winner); // เพิ่มไว้สำหรับเก็บประวัติผู้ชนะ

    error Raffle__NotEnoughETH();
    error Raffle__TransferFailed();
    error Raffle__UpkeepNotNeeded(
        uint256 contractBalance,
        uint256 playerCount,
        uint256 raffleState
    );
    error Raffle__RaffleNotOpen();

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address _vrfCoordinator,
        bytes32 keyHash,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETH();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen(); // สร้าง Error เพิ่มด้วยนะ
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    function pickWinner() public {
        // check to see if enough time has passed
        if (block.timestamp - s_lastTimeStamp <= i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CALCULATING;

        // Get a random winner v2.5
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: false // เลือกจ่ายเป็น LINK หรือเปลี่ยนเป็น true ถ้าจะใช้ ETH ดิบจ่ายแทน
                    })
                )
            })
        );
        emit RequestedRaffleWinner(requestId);
    }

    // CEI: Checks, Effects, Interactions pattern
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomWords
    ) internal override {
        // Check
        // require or if condition

        // Effects (Internal Contract State)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];

        s_players = new address payable[](0);
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;

        emit WinnerPicked(recentWinner);

        // Interactions (External Contract Calls)
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
    @dev This is the function that the Chainlink Automation nodes call to check if upkeep needs to be performed.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        bool timePassed = (block.timestamp - s_lastTimeStamp) >= i_interval;

        upkeepNeeded = isOpen && hasPlayers && hasBalance && timePassed;
        return (upkeepNeeded, bytes(""));
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        // check to see if enough time has passed
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;

        pickWinner();
    }

    /** Getter Functions */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }
}
