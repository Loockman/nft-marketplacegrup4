// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is Ownable, ERC721URIStorage, ReentrancyGuard {

    struct NFT {
        uint256 id;
        address owner;
        uint256 price;
    }

    mapping(uint256 => NFT) public nfts;
    uint256 public nftCount;
    uint256 private _tokenIdCounter;

    IERC721 public immutable nft;
    uint public immutable nftId;
    address payable public immutable seller;
    uint32 public endAuction;
    bool public hasStarted;
    bool public hasEnded;
    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public totalBids;

    constructor(address _nft, uint _nftId, uint _startingPrice) ERC721("NFTMarketplace", "NFTM") {
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable(msg.sender);
        highestBid = _startingPrice;
    } 

    function createNFT(uint256 initialPrice, string memory tokenURI) external {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        nfts[tokenId] = NFT(tokenId, msg.sender, initialPrice);
    }

    function listToken(uint256 tokenId, uint256 price) external {
        require(msg.sender == nfts[tokenId].owner, "Only token owner can list");
        nfts[tokenId].price = price;
    }

    //offer system
    function startAuction() external {
        require(msg.sender == seller, "You are unauthorized to start this auction.");
        require(!hasStarted, "The auction has started");
        hasStarted = true;
        endAuction = uint32(block.timestamp + 7 days);
        nft.transferFrom(seller, address(this), nftId);
        emit Start();
    }

    event Start();

    function bidPrice() external payable {
        require(hasStarted, "English auction has not started");
        require(block.timestamp < endAuction, "English auction has ended");
        require(msg.value > highestBid, "You cannot bid a lower amount. This is an English auction");

        if (highestBidder != address(0)){
            totalBids[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;
        emit Bid(msg.sender, msg.value);
    }

    event Bid(address indexed bidder, uint amount);

    function withdrawBids() external {
        uint balances = totalBids[msg.sender];
        totalBids[msg.sender] = 0;
        payable(msg.sender).transfer(balances);
        emit Withdraw(msg.sender, balances);
    }

    event Withdraw(address indexed bidder, uint amount);

    function end() external {
        require(hasStarted, "The auction has not started yet");
        require(!hasEnded, "The auction is still in progress");
        require(block.timestamp >= endAuction);
        hasEnded = true;
        if(highestBidder != address(0)){
            nft.transferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }

    event End(address highestBidder, uint amount);
}

contract NFTFactory is Ownable {

    function createNFT(address _nftMarketplace, uint _initialPrice, string memory _tokenURI) external onlyOwner {
    NFTMarketplace nftMarketplace = NFTMarketplace(_nftMarketplace);
    nftMarketplace.createNFT(_initialPrice, _tokenURI);
}
}
