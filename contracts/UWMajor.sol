
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract UWMajor is Ownable, ERC721 {

    address public UWIDContractAddress;

    constructor(string memory name_, string memory symbol_, address _UWIDContractAddress) ERC721(name_, symbol_) {
        UWIDContractAddress = _UWIDContractAddress;
    }

    modifier onlyUWAccounts(address to) {
        require(IERC721(UWIDContractAddress).balanceOf(to) != 0, "Does not have an UW ID.");
        _;
    }

    modifier onlyNotInThisMajor(address to) {
        require(balanceOf(to) == 0, "The student is already in the major.");
        _;
    }

    function mint(address to, uint256 uwid) external onlyOwner onlyUWAccounts(to) onlyNotInThisMajor(to) {
        _safeMint(to, uwid);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        revert("Cannot transfer UW Major.");
    }

    /**
     burns the UWMajor
     */
    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

}
