// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is Ownable, ERC721URIStorage, ReentrancyGuard {

    struct NFT {
        uint256 id;
        address owner;
        uint price;
        uint256 highestBid;
        address highestBidOwner;
    }

    mapping(uint256 => NFT) public nfts;
    uint256 public nftCount;
    uint256 private _tokenIdCounter;

    IERC721 public immutable nft;
    uint public immutable nftId;

    constructor() Ownable()  ERC721("NFTMarketplace", "NFTM") {
        // nft = IERC721(_nft);
        // nftId = _nftId;
        Ownable(msg.sender);
        // highestBid = _startingPrice;
    } 

    function createNFT( uint256 initialPrice , string memory tokenURI) external {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        nfts[tokenId] = NFT(tokenId, msg.sender,initialPrice,0,msg.sender);
        nfts[tokenId].price = initialPrice;

    }

    function listToken(uint256 tokenId, uint256 price) external {
        require(msg.sender == nfts[tokenId].owner, "Only token owner can list");
        nfts[tokenId].price = price;
    }

    //offer system
    function placeBid(uint256 tokenId) external payable {
        require(msg.sender != nfts[tokenId].owner, "Owner cannot place a bid");
        require(msg.value > nfts[tokenId].highestBid, "Bid must be higher than the current highest bid");
        require(msg.value >= nfts[tokenId].price);
        require(msg.sender != nfts[tokenId].highestBidOwner);


        // Eski teklif sahibine ödeme yap
        payable(nfts[tokenId].highestBidOwner).transfer(nfts[tokenId].highestBid);
        
        // Yeni teklifi kaydet
        nfts[tokenId].highestBidOwner = msg.sender;
        nfts[tokenId].highestBid = msg.value;

    // NFT'yi en yüksek teklifi veren kişiye transfer et
    }
    function transferToHighestBidder(uint256 tokenId) external {
        require(msg.sender == nfts[tokenId].owner, "Only token owner can transfer");
        require(nfts[tokenId].highestBid > 0, "No bids have been made for this token");

        address highestBidder = nfts[tokenId].highestBidOwner; 
        
        safeTransferFrom(msg.sender, highestBidder, tokenId);
        nfts[tokenId].owner = highestBidder;
        nfts[tokenId].highestBid = 0;
        nfts[tokenId].highestBidOwner = nfts[tokenId].owner; 
        
        
    }

    
}
