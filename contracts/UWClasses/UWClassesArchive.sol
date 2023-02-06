
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../UWID/UWIDUpgradeable.sol";
import "./UWClassesUpgradeable.sol";
import "./UWUtils.sol";




contract UWClassesArchive is Initializable, OwnableUpgradeable, ERC1155Upgradeable, ERC1155URIStorageUpgradeable {

    using UWUtils for string;
    
    // state variables
    address public UWIDContractAddress;

    // list of UW Classes NFTs
    address[] public UWClassNFTAddressList;

    // an mapping to record if the given UWClassNFT is in the UWClassNFTAddressList or not.
    mapping(address => bool) isUWClassNFTAddressList;

    // Account, CourseID, Quarter list
    mapping(address => mapping(uint256 => string[])) public accountCourseQuarterInfo;

    // initializer 
    function __UWClasses_init(address _UWIDContractAddress) public initializer {
        __ERC1155_init("");
        __UWClasses_init_unchained(_UWIDContractAddress);
    }

    function __UWClasses_init_unchained(address _UWIDContractAddress) internal onlyInitializing {
        UWIDContractAddress = _UWIDContractAddress;
    }

    function isUWAccount(address to) public view returns (bool) {
        return IERC721Upgradeable(UWIDContractAddress).balanceOf(to) != 0;
    }

    modifier onlyUWAccounts(address to) {
        require(tx.origin == msg.sender); // only EOA
        require(isUWAccount(to), "Does not have an UW ID.");
        _;
    }


    function archiveCourse(address classNFTAddress, uint256 id) external onlyUWAccounts(msg.sender) {
        // CourseID, balance
        _archive(classNFTAddress, id);
    }

    function _archive(address classNFTAddress, uint256 courseId) internal onlyUWAccounts(msg.sender) {
        require(isUWClassNFTAddressList[classNFTAddress]);


        // bytes32 courseId;
        // string memory quarterName;
        // (courseId,,,,,,,,,) = UWClassesUpgradeable(classNFTAddress).classes(
        //     classId
        // );
        // quarterName = UWClassesUpgradeable(classNFTAddress).quarterName();
        // accountCourseQuarterInfo[msg.sender][uint256(courseId)].push(quarterName);
        // _mint(msg.sender, uint256(courseId), 1, "");
    }


    function updateClassURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        _setURI(tokenId, tokenURI);
    }

    function updateBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function uri(uint256 tokenId) public view override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable) returns (string memory) {
        return ERC1155URIStorageUpgradeable.uri(tokenId);
    }

    function addUWClassNFTAddress(address classNFTAddress) external onlyOwner {
        require(!isUWClassNFTAddressList[classNFTAddress]);
        UWClassNFTAddressList.push(classNFTAddress);
        isUWClassNFTAddressList[classNFTAddress] = true;
    }

    function removeUWClassNFTAddress(address classNFTAddress) external onlyOwner {
        require(isUWClassNFTAddressList[classNFTAddress]);
        uint256 i;
        for (i = 0; i < UWClassNFTAddressList.length; i += 1) {
            if (UWClassNFTAddressList[i] == classNFTAddress) {
                UWClassNFTAddressList[i] = UWClassNFTAddressList[UWClassNFTAddressList.length - 1];
                UWClassNFTAddressList.pop();
                break;
            }
        }
        UWClassNFTAddressList.push(classNFTAddress);
        isUWClassNFTAddressList[classNFTAddress] = false;
    }

    function getCourseAccountQuarterInfo(address account, uint256 courseId) external view returns (string[] memory) {
        return accountCourseQuarterInfo[account][courseId];
    }

}