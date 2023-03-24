
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../UWID/UWIDUpgradeable.sol";
import "./UWClassesUpgradeable.sol";
import "./UWUtils.sol";



// CourseID is bytes32 but it is also the tokenID of the ERC1155 contract
// so convert bytes32 to uint256 whenever ERC1155 functions are called.
contract UWArchiveUpgradeable is Initializable, OwnableUpgradeable, ERC1155Upgradeable, ERC1155URIStorageUpgradeable {

    using UWUtils for string;
     
    // state variables
    address public UWIDAddress;

    // list of UW Classes NFTs
    address[] public UWClassNFTAddressList;

    // an mapping to record if the given UWClassNFT is in the UWClassNFTAddressList or not.
    mapping(address => bool) isUWClassNFTAddressList;

    // Account, CourseID, Quarter list
    mapping(address => mapping(bytes32 => string[])) public accountCourseQuarterInfo;
    
    // tripple mapping to save if Account, CourseID, Quarter exists
    mapping(address => mapping(bytes32 => mapping(string => bool))) public accountCourseQuarterExists;

    // initializer 
    function __UWArchive_init(address _UWIDAddress) public initializer {
        __ERC1155_init("");
        __UWArchive_init_unchained(_UWIDAddress);
    }

    function __UWArchive_init_unchained(address _UWIDAddress) internal onlyInitializing {
        UWIDAddress = _UWIDAddress;
    }

    function isUWAccount(address to) public view returns (bool) {
        return IERC721Upgradeable(UWIDAddress).balanceOf(to) != 0;
    }

    modifier onlyUWAccounts(address to) {
        require(tx.origin == msg.sender); // only EOA
        require(isUWAccount(to), "Does not have an UW ID.");
        _;
    }


    function archive(address classNFTAddress) external onlyUWAccounts(msg.sender) {
        // CourseID, balance
        _archive(classNFTAddress, msg.sender);
    }

    function _archive(address classNFTAddress, address account) internal onlyUWAccounts(account) {
        require(isUWClassNFTAddressList[classNFTAddress]);
        require(UWClassesUpgradeable(classNFTAddress).quarterEnd());
        string memory quarterName = UWClassesUpgradeable(classNFTAddress).quarterName();
        uint256 classlen = UWClassesUpgradeable(classNFTAddress).numberOfClasses(account);
        uint256 i = 0;
        uint256 classId; // for less variable usage
        bytes32 courseId;

        for (i = 0; i < classlen; i += 1) {
            classId = UWClassesUpgradeable(classNFTAddress).accountClasses(account, i);
            (courseId,,,,,,,,,,) = UWClassesUpgradeable(classNFTAddress).classes(classId);
            if (!accountCourseQuarterExists[account][courseId][quarterName]) {
                accountCourseQuarterExists[account][courseId][quarterName] = true;
                accountCourseQuarterInfo[account][courseId].push(quarterName);
                _mint(account, courseIdToTokenId(courseId), 1, "");
            }
        }
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

    function courseIdToTokenId(bytes32 courseId) public pure returns (uint256) {
        return uint256(courseId);
    }


    function accountHasTakenCourse(address account, bytes32 courseId) public view returns (bool) {
        return (balanceOf(account, courseIdToTokenId(courseId)) != 0);
    }
}