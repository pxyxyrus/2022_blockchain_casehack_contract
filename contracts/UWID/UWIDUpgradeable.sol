
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UWIDUpgradeable is Initializable, OwnableUpgradeable, ERC721Upgradeable {

    // state variables
    mapping(uint256 => string) public campus;
    uint256 private _id;
    mapping(uint256 => uint256) public credits;
    mapping(address => uint256) public accountTokenId;


    // initializer
    function __UWID__init(string memory name_, string memory symbol_) public initializer {
        __Ownable_init();
        __ERC721_init(name_, symbol_);
        __UWID__init__unchained();
    }

    function __UWID__init__unchained() internal onlyInitializing {
        _id = 1;
    }



    // functions
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
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    
}
