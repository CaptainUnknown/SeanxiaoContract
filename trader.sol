//SPX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";

contract saleContract is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    
    address public owner;
    address[] public whiteListedpeeps;
    address public _whitelistpeep;
     
    constructor() {
        owner = msg.sender;
    }
     
    struct MarketItem {
        uint itemId;                   //Generates a new Market item ID
        address nftContract;           //Store NFT Status -->
        uint256 tokenId;
        address payable seller;
        address payable owner;
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
        address owner,
        uint256 price,
        bool isPrivate,
        bool sold
    );
     
    event MarketItemSold (
        uint indexed itemId,
        address owner
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
                require(isAddressWhitelisted(owner), "You are not Whitelisted!");
            }

            emit MarketItemSold(
                itemId,
                msg.sender
                );

            idToMarketItem[itemId].seller.transfer(msg.value);
            IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
            idToMarketItem[itemId].owner = payable(msg.sender);
            _itemsSold.increment();
            idToMarketItem[itemId].sold = true;
        }
        
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}