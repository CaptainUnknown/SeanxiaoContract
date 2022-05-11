//SPX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract JPGO is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(string => uint8) existingURIs;
    
    address[] public whiteListedpeeps;
    address public _whitelistpeep;
    mapping (address => bool) isWhiteListed;

    constructor() ERC721("JPGO", "JPGO") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        existingURIs[uri] = 1;
    }

    // The following functions are overrides required by Solidity.

    function WhitelistAddress(address _whitelistpeep) external returns (bool){
        require (isWhiteListed[_whitelistpeep] == false, "Already whitelisted");
        isWhiteListed[_whitelistpeep] = true;
        whiteListedpeeps.push(_whitelistpeep);
        return true;
    }
    
    function isAddressWhitelisted(address _whitelistpeep) internal view returns (bool){
        return isWhiteListed[_whitelistpeep];
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

    function isContentOwned(string memory uri) public view returns (bool) {
        return existingURIs[uri] == 1;
    }

    function payToMint(address recipient, string memory metadataURI) public payable returns (uint256) {
        require(existingURIs[metadataURI] != 1, 'NFT already minted!');
        if(isAddressWhitelisted(msg.sender)){
            require(msg.value == 0.8 ether, "0.8 Ethereum required to mint");
        }
        else
        {
            require(msg.value == 1 ether, "1 Ethereum required to mint");
        }

        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        existingURIs[metadataURI] = 1;

        _mint(recipient, newItemId);
        _setTokenURI(newItemId, metadataURI);

        return newItemId;
    }

    function count() public view returns (uint256) {
        return _tokenIdCounter.current();
    }


}