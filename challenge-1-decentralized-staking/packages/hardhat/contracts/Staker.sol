// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  event Stake(address indexed sender, uint256 amount);

  mapping (address => uint) public balances;

  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 50 seconds;
  bool public openForWithDraw;

   modifier notCompleted() {
    require(exampleExternalContract.completed() == false, "Staking Completed");
    _;
  }

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function stake() public payable {
    require(block.timestamp < deadline, "Cannot stake anymore");
    require(address(this).balance <= threshold, "Cannot stake anymore, threshold reached");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);  
    }

  function execute() external notCompleted {
    require(block.timestamp > deadline, "Deadline not reached yet");
    if(address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
      openForWithDraw = false;
    } else {
      openForWithDraw = true;
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() external payable notCompleted {
    require(balances[msg.sender] > 0, "Nothing to withdraw");
    require(openForWithDraw == true, "Cannot withdraw");
    payable(msg.sender).transfer(balances[msg.sender]);
    balances[msg.sender] = 0;   
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }
}
