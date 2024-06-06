// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ArtChain is ERC1155, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Mint price for editions
    uint256 public constant EDITION_MINT_PRICE = 0.001 ether;
    uint256 public constant SALES_FEE_PERCENTAGE = 25; // 0.25%
    address public feeRecipient;

    // Mapping from token ID to its creation timestamp, parent ID, and token URI
    mapping(uint256 => uint256) public mintedAt;
    mapping(uint256 => uint256) public parentOf;
    mapping(uint256 => string) private _tokenURIs;

    // Constructor that initializes the ERC1155 token with a base metadata URI
    constructor() ERC1155("https://api.example.com/metadata/") Ownable(msg.sender) {
        _tokenIdCounter.increment(); // Ensure first tokenId starts at 1
    }

    // Function to set or update the fee recipient
    function setFeeRecipient(address _feeRecipient) public onlyOwner {
        feeRecipient = _feeRecipient;
    }

    // Internal function to set the token URI
    function _setTokenURI(uint256 tokenId, string memory tokenURI) private {
        _tokenURIs[tokenId] = tokenURI;
    }

    // Public function to retrieve the token URI
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(bytes(_tokenURIs[tokenId]).length > 0, "URI: nonexistent token");

        return _tokenURIs[tokenId];
    }

    // Function to mint a genesis piece with a specific URI
    function createGenesisPiece(string memory tokenURI) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId, 1, "");
        _setTokenURI(tokenId, tokenURI);
        mintedAt[tokenId] = block.timestamp;
        parentOf[tokenId] = 0; // Genesis piece has no parent
    }

    // Function to create a child piece with a specific URI
    function createChildPiece(uint256 parentTokenId, string memory tokenURI) public {
        require(block.timestamp <= mintedAt[parentTokenId] + 1 days, "Creation window has closed");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId, 1, "");
        _setTokenURI(tokenId, tokenURI);
        mintedAt[tokenId] = block.timestamp;
        parentOf[tokenId] = parentTokenId;
    }

    // Function to mint additional editions
    function mintEditions(uint256 tokenId, uint256 amount) public payable {
        require(msg.value == EDITION_MINT_PRICE * amount, "Incorrect value sent");
        require(block.timestamp <= mintedAt[tokenId] + 1 days, "Minting window has closed");
        _mint(msg.sender, tokenId, amount, "");
    }
}

