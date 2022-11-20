
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract UWID is Ownable, ERC721 {

    mapping(uint256 => string) public campus;
    uint256 private _id;
    mapping(uint256 => uint256) public credits;
    mapping(address => uint256) public accountTokenId;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _id = 1;
    }

    function mint(address to, string memory campusName) external onlyOwner {
        require(balanceOf(to) == 0, "the account already has an UW ID.");
        _safeMint(to, _id);
        campus[_id] = campusName;
        accountTokenId[to] = _id;
        _id += 1;
    }

    function changeCampus(uint256 studentId, string memory campusName) external onlyOwner {
        campus[studentId] = campusName;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        revert("Cannot transfer UW ID.");
    }

    /**
     burns the UWID
     */
    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    /**
     testnet function
     */
    function setCredits(uint256 tokenId, uint256 creditNum) public onlyOwner {
        credits[tokenId] = creditNum;
    }

    function addCredits(uint256 tokenId, uint256 creditNum) public onlyOwner {
        credits[tokenId] += creditNum;
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    
}
