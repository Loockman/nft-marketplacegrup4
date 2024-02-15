// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "nftmarketplace.sol";

contract NFTFactory is Ownable {

    function createNFT(address _nftMarketplace, uint _initialPrice, string memory _tokenURI) external onlyOwner {
    NFTMarketplace nftMarketplace = NFTMarketplace(_nftMarketplace);
    nftMarketplace.createNFT(_initialPrice, _tokenURI);
}
}
