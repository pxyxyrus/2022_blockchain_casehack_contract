
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./UWID.sol";

// interface UWID {
//     function accountTokenId(address) external view returns(uint256);
// }




contract Registration is Ownable, ERC1155, ERC1155URIStorage {

    address public UWIDContractAddress;

    uint256 public maxAllowedCredits = 20;

    struct Class {
        uint256 classId;
        string className;
        uint256 enrollCapacity;
        uint256 credits;
        string creditType;
        // account lists
        address[] classAccounts;
        //MajorNFT addresses
        address[] classMajorRestrictions;
        uint256 startTime;
        uint256 endTime;
    }

    // ClassId to Class
    mapping(uint256 => Class) public classes;

    // account to credits
    mapping(address => uint) public accountCredits;
    mapping(address => uint[]) public accountClasses;

    uint256[3] public registrationPeriod;

    constructor(address _UWIDContractAddress) ERC1155("") {
        UWIDContractAddress = _UWIDContractAddress;
    }

    modifier onlyUWAccounts(address to) {
        require(tx.origin == msg.sender); // only EOA
        require(IERC721(UWIDContractAddress).balanceOf(to) != 0, "Does not have an UW ID.");
        _;
    }

    function registered(address account, uint256 classId) public view returns (bool) {
        bool b = false;
        uint i = 0;
        for (; i < classes[classId].classAccounts.length; i += 1) {
            if (classes[classId].classAccounts[i] == account) {
                b = true;
                break;
            }
        }
        return b;
    }

    function classFull(uint256 classId) public view returns (bool) {
        return classes[classId].classAccounts.length >= classes[classId].enrollCapacity;
    }

    function majorRestricted(address account, uint256 classId) public view returns (bool) {
        bool b = true;
        uint i = 0;
        for (; i < classes[classId].classMajorRestrictions.length; i += 1) {
            if (IERC721(classes[classId].classMajorRestrictions[i]).balanceOf(account) != 0) {
                b = false;
                break;
            }
        }
        return b;
    }

    function exceedsMaxCredit(address account, uint256 classId) public view returns (bool) {
        return accountCredits[account] + classes[classId].credits >= maxAllowedCredits;
    }

    function isRegistrationPeriod(address account) public view returns (bool) {
        uint256 id = UWID(UWIDContractAddress).accountTokenId(account);
        bool b = false;

        if (UWID(UWIDContractAddress).credits(id) < 45) {
            b = block.timestamp >= registrationPeriod[2];
        } else if (UWID(UWIDContractAddress).credits(id) < 90) {
            b = block.timestamp >= registrationPeriod[1];
        } else if (UWID(UWIDContractAddress).credits(id) < 135) {
            b = block.timestamp >= registrationPeriod[0];
        } else {
            b = true;
        }
        return b;
    }

    function timeConflict(address account, uint256 classId) public view returns (bool) {
        uint i = 0;
        uint registeredClassId;
        bool b = false;
        for (; i < accountClasses[account].length; i += 1) {
            registeredClassId = accountClasses[account][i];
            if (classes[classId].startTime < classes[registeredClassId].startTime ) {
                if(classes[classId].endTime > classes[registeredClassId].startTime) {
                    b = true;
                }
            } else {
                if (classes[registeredClassId].endTime < classes[classId].startTime) {
                    b = true;
                } 
            }
        }
        return b;
    }

    function canEnroll(address account, uint256 classId) public view returns (bool) {
        return !exceedsMaxCredit(account, classId) &&
        !majorRestricted(account, classId) &&
        !classFull(classId) &&
        !registered(account, classId) &&
        isRegistrationPeriod(account) && 
        timeConflict(account, classId);
    }



    function _registerClass(
        address account,
        uint256 classId
    ) internal {
        _mint(account, classId, 1, "");
        classes[classId].classAccounts.push(account);
        accountClasses[account].push(classId);
        accountCredits[account] += classes[classId].credits;
    }

    function registerClass(
        uint256 classId
    ) public onlyUWAccounts(msg.sender) {
        require(canEnroll(msg.sender, classId));
        _registerClass(msg.sender, classId);
    }

    function _dropClass(address account, uint256 classId) internal {
        _burn(account, classId, 1);
        accountCredits[account] -= classes[classId].credits;
        uint i = 0;
        uint j;
        for (; i < accountClasses[account].length; i += 1) {
            if (accountClasses[account][i] == classId) {
                delete accountClasses[account][i];
                break;
            }
        }
    }

    function dropClass(uint256 classId) public onlyUWAccounts(msg.sender) {
        require(registered(msg.sender, classId));
        _dropClass(msg.sender, classId);
    }

    function registerMultipleClasses(uint256[] memory classIds) public onlyUWAccounts(msg.sender) {
        uint classId;
        uint i = 0;
        for (; i < classIds.length; i += 1) {
            classId = classIds[i];
            if(canEnroll(msg.sender, classId)) {
                registerClass(classId);
            }
        }
    }

    function updateClassURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        _setURI(tokenId, tokenURI);
    }

    function updateBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function uri(uint256 tokenId) public view override(ERC1155, ERC1155URIStorage) returns (string memory) {
        return ERC1155URIStorage.uri(tokenId);
    }

    function addClass(
        uint256 classId,
        string memory className,
        uint256 enrollCapacity,
        uint256 credits,
        string memory creditType,
        uint256 startTime,
        uint256 endTime
    ) public onlyOwner {
        require(classes[classId].classId == 0);
        Class memory class;
        class.classId = classId;
        class.className = className;
        class.enrollCapacity = enrollCapacity;
        class.credits = credits;
        class.creditType = creditType;
        class.startTime = startTime;
        class.endTime = endTime;
        classes[classId] = class;
    }

    function closeClass(uint256 classId) public onlyOwner {
        uint i = 0;
        for (; i < classes[classId].classAccounts.length; i += 1) {
            _dropClass(classes[classId].classAccounts[i], classId);
        }
        classes[classId].classId = 0;
        classes[classId].className = "";
        classes[classId].enrollCapacity = 0;
        classes[classId].credits = 0;
        classes[classId].creditType = "";
        classes[classId].startTime = 0;
        classes[classId].endTime = 0;
        delete classes[classId].classAccounts;
        delete classes[classId].classMajorRestrictions;
    }

    function changeMaxAllowedCredits(uint256 num) public onlyOwner {
        maxAllowedCredits = num;
    }

    function setRegistrationPeriod(uint256 period1, uint256 period2, uint256 period3) public onlyOwner {
        registrationPeriod[0] = period1;
        registrationPeriod[1] = period2;
        registrationPeriod[2] = period3;
    }

}