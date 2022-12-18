
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../UWID/UWIDUpgradeable.sol";

contract UWMajorUpgradeable is Initializable, OwnableUpgradeable, ERC721Upgradeable {

    // state variables
    address public UWIDContractAddress;


    // initializer
    function __UWMajor_init(string memory name_, string memory symbol_, address _UWIDContractAddress) public initializer {
        __ERC721_init_unchained(name_, symbol_);
        __UWMajor_init_unchained(_UWIDContractAddress);
    }

    function __UWMajor_init_unchained(address _UWIDContractAddress) internal onlyInitializing {
        UWIDContractAddress = _UWIDContractAddress;
    }

    

    // functions  
    modifier onlyUWAccounts(address to) {
        require(IERC721Upgradeable(UWIDContractAddress).balanceOf(to) != 0, "Does not have an UW ID.");
        _;
    }

    modifier onlyNotInThisMajor(address to) {
        require(balanceOf(to) == 0, "The student is already in the major.");
        _;
    }

    function mint(address to) external onlyOwner onlyUWAccounts(to) onlyNotInThisMajor(to) {
        _safeMint(to, UWIDUpgradeable(UWIDContractAddress).accountTokenId(to));
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
