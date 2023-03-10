pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {

  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfETH, uint256 amountOfTokens);

  YourToken public yourToken;

  uint256 public constant tokensPerEth = 100;

 constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  // ToDo: create a payable buyTokens() function:
  function buyTokens() public payable {
    require(msg.value > 0, "Send Eth to buy some tokens");
    uint256 buyAmount = msg.value * tokensPerEth;
    uint256 vendorBalance = yourToken.balanceOf(address(this));
    require(vendorBalance >= buyAmount, "Not enough Eth in the vending machine");
    (bool sent) = yourToken.transfer(msg.sender, buyAmount);
    require(sent, "Failed to transfer token to user");
    emit BuyTokens(msg.sender, msg.value, buyAmount);
  }

  // ToDo: create a withdraw() function that lets the owner withdraw ETH
  function withdraw() public onlyOwner {
      uint256 ownerBalance = (address(this).balance);
      require(ownerBalance > 0, "No balance to withdraw");
      (bool sent,) = msg.sender.call{value: address(this).balance}("");
      require(sent, "Failed to send balance to owner");
  }

  // ToDo: create a sellTokens(uint256 _amount) function:
  function sellTokens(uint256 _amount) public {
    //Check amount selling is more than 0
    require(_amount > 0, "No amount of tokens selected to sell");
    //Check users token balance is enough to do swap
    uint256 userBalance = yourToken.balanceOf(msg.sender);
    require(userBalance >= _amount, "Not enough tokens in balance");
    //Check vendor balance is enough for swap
    uint256 amountOfEthToTransfer = _amount / tokensPerEth;
    uint256 vendorBalance = address(this).balance;
    require(vendorBalance >= amountOfEthToTransfer, "Vender doesn't have enough funds to sell");
    //Send tokens from caller to address(this)
    (bool sent) = yourToken.transferFrom(msg.sender, address(this), _amount);
    require(sent, "Failed to transfer tokens");
    //Send ETH from vendor to caller
    (sent,) = msg.sender.call{value: amountOfEthToTransfer}("");
    require(sent, "Failed to send ETH to user");
  }

}
