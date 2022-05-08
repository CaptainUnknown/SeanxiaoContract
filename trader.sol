//SPX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/ERC721.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/access/Ownable.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/utils/Counters.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";


contract saleContract is ERC721, ERC721URIStorage, ERC721Burnable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _tokenIdCounter;

    address public _owner;
    address[] public whiteListedpeeps;
    address public _whitelistpeep;
    
    struct newMintItem {
        string name;
        string symbol;
    }
    mapping(string => uint8) existingURIs;

    constructor() ERC721("name", "symbol") {
        _owner = msg.sender;
    }

    function mintItem(address recipient, string memory metadataURI) public payable returns (uint256) {
        require(existingURIs[metadataURI] != 1, "NFT already Minted");
        require (msg.value > 0 ether, "Please Pay Valid Amount");

        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        existingURIs[metadataURI] = 1;

        _mint(recipient, newItemId);
        _setTokenURI(newItemId, metadataURI);

        return newItemId;
    }

    function count() public view returns (uint256){
        return _tokenIdCounter.current();
    }

    function isItemOwned(string memory uri) public view returns (bool) {
        return existingURIs[uri] == 1;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
     
    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable _owner;
        uint256 price;
        bool isPrivate;
        bool sold;
    }
     
    mapping(uint256 => MarketItem) private idToMarketItem;
    mapping (address => bool) isWhiteListed;
 
    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address _owner,
        uint256 price,
        bool isPrivate,
        bool sold
    );
     
    event MarketItemSold (
        uint indexed itemId,
        address _owner
        );
        
        //-------------->
    function WhitelistAddress(address _whitelistpeep) external returns (bool){
        require (isWhiteListed[_whitelistpeep] == false, "Already whitelisted");
        isWhiteListed[_whitelistpeep] = true;
        whiteListedpeeps.push(_whitelistpeep);
        return true;
    }

    function isAddressWhitelisted(address _whitelistpeep) internal view returns (bool){
        return isWhiteListed[_whitelistpeep];
    }
    
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        bool isPrivate
        ) public payable nonReentrant {
            require(price > 0, "Price must be greater than 0");
            if(isPrivate){
                require(price <= 0.8 ether, "Price must be Equal to or smaller than 0.8 Eth for a Private Sale");
            }
            else{
                require(price <= 1 ether, "Price must be Equal to or smaller than 1 Eth for a Public Sale");
            }

            _itemIds.increment();
            uint256 itemId = _itemIds.current();
  
            idToMarketItem[itemId] =  MarketItem(
                itemId,
                nftContract,
                tokenId,
                payable(msg.sender),
                payable(address(0)),
                price,
                isPrivate,
                false
            );
            
            IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
                
            emit MarketItemCreated(
                itemId,
                nftContract,
                tokenId,
                msg.sender,
                address(0),
                price,
                isPrivate,
                false
            );
        }
        
    function createMarketSale(
        address nftContract,
        uint256 itemId
        ) public payable nonReentrant {
            uint price = idToMarketItem[itemId].price;
            uint tokenId = idToMarketItem[itemId].tokenId;
            bool isPrivate = idToMarketItem[itemId].isPrivate;
            bool sold = idToMarketItem[itemId].sold;
            require(msg.value == price, "Please submit the asking price in order to complete the purchase");
            require(sold != true, "This item has already been Sold!");
            if(isPrivate){
                require(isAddressWhitelisted(_owner), "You are not Whitelisted!");
            }

            emit MarketItemSold(
                itemId,
                msg.sender
                );

            idToMarketItem[itemId].seller.transfer(msg.value);
            IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
            idToMarketItem[itemId]._owner = payable(msg.sender);
            _itemsSold.increment();
            idToMarketItem[itemId].sold = true;
        }
        
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1]._owner == address(0)) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}