//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

/**
 * @title A Sample Raffle Contract
 * @author Devansh goel
 * @notice This contract is for creating a sample raffle
 * @dev Implements ChainLink VRFv2
 */

contract Raffle {
    error Raffle__NotEnoughEthSent(); //Good Practice to name ur errors with 2 underscores after the Contract name

    uint256 private immutable i_entranceFee; // Maybe change depending on a contract but fixed for a contract thus of type immutable
    address payable[] private s_players; //This array can be used to store Ethereum addresses that can receive Ether payments.
    uint256 private immutable i_interval; //@dev duration of lottery in seconds
    uint256 private s_lastTimeStamp;
    // What data structure should we use? how to keep track of all the players
    /**Events */
    event EnteredRaffle(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    //external more gas efficient
    function enterRaffle() external payable {
        //public can be called from within and outside the contract whereas external can be called only from the outside of the contracts
        //require(msg.value >= i_entranceFee, "Not Enough Eth Sent!"); // THis is not gas efficient thus we use Custom Errors
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() external view {
        //2. use the random number to pick a player
        //3. Be automatically called
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        } //1. Get a random number
    }

    /** Getter Function */

    function getEntranceFees() external view returns (uint256) {
        return i_entranceFee;
    }
}
