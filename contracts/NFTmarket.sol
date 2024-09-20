// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721, Ownable {
    uint256 public tokenCounter;

    struct NFT {
        uint256 tokenId;
        uint256 price;
        address owner;
        bool listedForSale;
    }

    // Mapping tokenId to NFT details
    mapping(uint256 => NFT) public nfts;

    // Events
    event NFTMinted(uint256 tokenId, address owner);
    event NFTListed(uint256 tokenId, uint256 price);
    event NFTPurchased(uint256 tokenId, address newOwner, uint256 price);

    // Constructor with parameters for ERC721 (name and symbol)
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        tokenCounter = 0;
    }

    // Minting NFTs
    function mintNFT() public {
        uint256 newTokenId = tokenCounter;
        _safeMint(msg.sender, newTokenId);
        nfts[newTokenId] = NFT({
            tokenId: newTokenId,
            price: 0,
            owner: msg.sender,
            listedForSale: false
        });
        tokenCounter++;
        emit NFTMinted(newTokenId, msg.sender);
    }

    // Listing an NFT for sale
    function listNFTForSale(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        require(price > 0, "Price must be greater than zero");

        NFT storage nft = nfts[tokenId];
        nft.price = price;
        nft.listedForSale = true;

        emit NFTListed(tokenId, price);
    }

    // Buy an NFT
    function buyNFT(uint256 tokenId) public payable {
        NFT storage nft = nfts[tokenId];
        require(nft.listedForSale, "NFT not listed for sale");
        require(msg.value >= nft.price, "Insufficient funds to purchase the NFT");

        address previousOwner = nft.owner;
        nft.owner = msg.sender;
        nft.listedForSale = false;

        _transfer(previousOwner, msg.sender, tokenId);
        payable(previousOwner).transfer(msg.value);

        emit NFTPurchased(tokenId, msg.sender, nft.price);
    }

    // Override the transfer function to ensure NFT ownership in the marketplace
    function _transfer(address from, address to, uint256 tokenId) internal override {
        super._transfer(from, to, tokenId);
        nfts[tokenId].owner = to;
    }

    // Only owner can withdraw contract balance
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
