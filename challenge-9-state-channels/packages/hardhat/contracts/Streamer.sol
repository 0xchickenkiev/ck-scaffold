// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

error Streamer__Transfer_failed();
error Streamer__Signer_is_not_running_the_channel();

contract Streamer is Ownable {
    event Opened(address, uint256);
    event Challenged(address);
    event Withdrawn(address, uint256);
    event Closed(address);

    mapping(address => uint256) balances;
    mapping(address => uint256) canCloseAt;

    function fundChannel() public payable {
        require(balances[msg.sender] == 0, "Channel already open!");
        balances[msg.sender] += msg.value;
        emit Opened(msg.sender, msg.value);
    }

    function timeLeft(address channel) public view returns (uint256) {
        require(canCloseAt[channel] != 0, "channel is not closing");
        return canCloseAt[channel] - block.timestamp;
    }

    function withdrawEarnings(Voucher calldata voucher) public onlyOwner {
        bytes32 hashed = keccak256(abi.encode(voucher.updatedBalance));
        bytes memory prefixed = abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            hashed
        );
        bytes32 prefixedHashed = keccak256(prefixed);
        address signer = ecrecover(prefixedHashed, voucher.sig.v, voucher.sig.r, voucher.sig.s);
        if(balances[signer] <= voucher.updatedBalance) revert Streamer__Signer_is_not_running_the_channel();
        uint256 payment = balances[signer] - voucher.updatedBalance;
        balances[signer] -= payment;
        address owner = owner();
        (bool success, ) = owner.call{value: payment}("");
        if(!success) revert Streamer__Transfer_failed();
        emit Withdrawn(owner, payment);
    }

    function challengeChannel() public {
        require(balances[msg.sender] != 0, "No channel for this user is active");
        canCloseAt[msg.sender] = block.timestamp + 30 seconds;
        emit Challenged(msg.sender);
    }

    function defundChannel() public {
        require(canCloseAt[msg.sender] != 0, "Unable to close channel");
        require(canCloseAt[msg.sender] < block.timestamp, "Closing time not reached");
        (bool success, ) = msg.sender.call{value: balances[msg.sender]}("");
        require(success, "Balance not sent!");
        emit Closed(msg.sender);
    }

    struct Voucher {
        uint256 updatedBalance;
        Signature sig;
    }
    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }
}
