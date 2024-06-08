//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {console} from "../lib/forge-std/src/console.sol";

/**
 * @title A Sample Raffle Contract
 * @author Devansh goel
 * @notice This contract is for creating a sample raffle
 * @dev Implements ChainLink VRFv2
 */

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughEthSent(); //Good Practice to name ur errors with 2 underscores after the Contract name
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpKeepNotNeeded();
    /** Type declarratiosn*/

    enum RaffleState {
        OPEN, // In solidity these can be converted to integers; //0
        CALCULATING //1
        //CLOSE 2
        //MIDWAY 3
    }

    /**State Variables*/
    uint16 private constant REQUEST_CONFIRMTIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee; // Maybe change depending on a contract but fixed for a contract thus of type immutable
    uint256 private immutable i_interval; //@dev duration of lottery in seconds
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players; //This array can be used to store Ethereum addresses that can receive Ether payments.
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    // What data structure should we use? how to keep track of all the players
    /**Events */
    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    //external more gas efficient
    function enterRaffle() external payable {
        //public can be called from within and outside the contract whereas external can be called only from the outside of the contracts
        //require(msg.value >= i_entranceFee, "Not Enough Eth Sent!"); // THis is not gas efficient thus we use Custom Errors
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        console.log(timeHasPassed);
        console.log(isOpen);
        console.log(hasBalance);
        console.log(hasPlayers);
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /*performData*/) external {
        //2. use the random number to pick a player
        //3. Be automatically called
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpKeepNotNeeded();
        }
        s_raffleState = RaffleState.CALCULATING;
        //1. Get a random number
        i_vrfCoordinator.requestRandomWords( //Coordinator is the ChainLink VRF coordinator address
            i_gasLane,
            i_subscriptionId, // Id u have funded to make these requests
            REQUEST_CONFIRMTIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    // CEI: Checks, Effects, Interactions
    //Write ur checks first more gas efficient
    //Effects (Our own contract)
    //Interactions with other contract
    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexofWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexofWinner];
        s_recentWinner = winner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(winner);
    }

    /** Getter Function */

    function getEntranceFees() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
}
