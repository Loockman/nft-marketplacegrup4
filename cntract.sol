// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SimpleNFTMarketplace {
    struct NFTListing {
        address owner;
        address nftContract;
        uint256 tokenId;
        string title;
        string description;
        string imageURI;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => NFTListing) public listings;
    uint256 public listingCounter;

    function listNFT(address _nftContract, uint256 _tokenId, string memory _title, string memory _description,string memory _imageURI, uint256 _price) external {
        require(_price > 0, "Price must be greater than zero");
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "You don't own this NFT");

        listingCounter++;
        listings[listingCounter] = NFTListing({
            owner: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            title: _title,
            description: _description,
            imageURI: _imageURI,
            price: _price,
            sold: false
        });

       
    }

    function buyNFT(uint256 _listingId) external payable {
        NFTListing storage listing = listings[_listingId];
        require(!listing.sold, "NFT is already sold");
        require(msg.value >= listing.price, "Insufficient payment");

        payable (listing.owner).transfer(msg.value);
        IERC721(listing.nftContract).transferFrom(listing.owner, msg.sender, listing.tokenId);

        listing.sold = true;

    }  

    function getListing(uint256 _listingId) external view returns (NFTListing memory) {
        return listings[_listingId];
    }
}
