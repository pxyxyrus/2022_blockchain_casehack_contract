
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../UWID/UWIDUpgradeable.sol";





contract UWClassesUpgradeable is Initializable, OwnableUpgradeable, ERC1155Upgradeable, ERC1155URIStorageUpgradeable {

    // state variables
    address public UWIDContractAddress;

    uint256 public maxAllowedCredits = 20;

    string public quarterName;

    struct ClassTime {
        // time/100 = hours time % 100 = minutes
        // example 1430 -> 2:30pm
        uint256 startTime; 
        uint256 endTime;
    }

    struct Class {
        uint256 classId;
        string className;
        uint256 currentlyEnrolled;
        uint256 enrollCapacity;
        uint256 credits;
        string creditType;
        //MajorNFT addresses
        address[] classMajorRestrictions;
        // 0 ~ 6 <-> Monday ~ Sunday
        ClassTime[7] classTimes;
        bytes data;
    }

    // ClassId to Class
    mapping(uint256 => Class) public classes;

    // account to credits
    mapping(address => uint) public accountCredits;
    mapping(address => uint[]) public accountClasses;

    // three timestamps in milliseconds
    uint256[] public registrationPeriods;


    // initializer 
    function __UWClasses__init(address _UWIDContractAddress, string memory _quarterName) public initializer {
        __ERC1155_init("");
        __UWClasses__init__unchained(_UWIDContractAddress, _quarterName);
    }

    function __UWClasses__init__unchained(address _UWIDContractAddress, string memory _quarterName) internal onlyInitializing {
        UWIDContractAddress = _UWIDContractAddress;
        quarterName = _quarterName;
        registrationPeriods.push(0);
        registrationPeriods.push(0);
        registrationPeriods.push(0);
    }

    // functions
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        uint i = 0;
        for (; i < ids.length; i += 1) {
            if (to != address(0)) {            
                if (isUWAccount(to)) {
                    require(canEnroll(to, ids[i]));
                }
            }
        }
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
        uint i;
        uint j;
        for (i = 0; i < ids.length; i += 1) {
            
            if (to != address(0)) {
                accountCredits[to] += classes[ids[i]].credits;
            }
            
            if (from != address(0)) {
                accountCredits[from] -= classes[ids[i]].credits;
            }
            
            accountClasses[to].push(ids[i]);
            for (; j < accountClasses[from].length; j += 1) {
                if (accountClasses[from][j] == ids[i]) {
                    accountClasses[from][j] = accountClasses[from][accountClasses[from].length - 1];
                    accountClasses[from].pop();
                    break;
                }
            }


            if (from == address(0)) {
                classes[ids[i]].currentlyEnrolled += 1;
            }

            if (to == address(0)) {
                classes[ids[i]].currentlyEnrolled -= 1;
            }
        }
            
    }

    function isUWAccount(address to) public view returns (bool) {
        return IERC721Upgradeable(UWIDContractAddress).balanceOf(to) != 0;
    }

    modifier onlyUWAccounts(address to) {
        require(tx.origin == msg.sender); // only EOA
        require(isUWAccount(to), "Does not have an UW ID.");
        _;
    }

    function registered(address account, uint256 classId) public view returns (bool) {
        return balanceOf(account, classId) != 0;
    }

    function classFull(uint256 classId) public view returns (bool) {
        return classes[classId].currentlyEnrolled >= classes[classId].enrollCapacity;
    }

    function majorRestriction(address account, uint256 classId) public view returns (bool) {
        if (classes[classId].classMajorRestrictions.length == 0) {
            return false;
        }
        uint i = 0;
        for (; i < classes[classId].classMajorRestrictions.length; i += 1) {
            if (IERC721Upgradeable(classes[classId].classMajorRestrictions[i]).balanceOf(account) != 0) {
                return false;
            }
        }
        return true;
    }

    function exceedsMaxCredit(address account, uint256 classId) public view returns (bool) {
        return accountCredits[account] + classes[classId].credits > maxAllowedCredits;
    }

    function isRegistrationPeriod(address account) public view returns (bool) {
        uint256 id = UWIDUpgradeable(UWIDContractAddress).accountTokenId(account);

        if (UWIDUpgradeable(UWIDContractAddress).credits(id) < 45) {
            return block.timestamp >= registrationPeriods[2];
        } else if (UWIDUpgradeable(UWIDContractAddress).credits(id) < 90) {
            return block.timestamp >= registrationPeriods[1];
        } else if (UWIDUpgradeable(UWIDContractAddress).credits(id) < 135) {
            return block.timestamp >= registrationPeriods[0];
        } else {
            return true;
        }
    }

    function hasTimeConflict(address account, uint256 classId) public view returns (bool) {
        uint i = 0;
        uint j = 0;
        uint registeredClassId;
        for (; i < accountClasses[account].length; i += 1) {
            registeredClassId = accountClasses[account][i];

            if (registeredClassId == 0) {
                continue;
            }
            // compare classtimes from monday to sunday
            for (; j < 7; j += 1) {
                if (classes[classId].classTimes[j].startTime < classes[registeredClassId].classTimes[j].startTime) {
                    if(classes[classId].classTimes[j].endTime > classes[registeredClassId].classTimes[j].startTime) {
                        return true;
                    }
                } else {
                    if (classes[registeredClassId].classTimes[j].endTime > classes[classId].classTimes[j].startTime) {
                        return true;
                    } 
                }
            }
        }
        return false;
    }

    function canEnroll(address account, uint256 classId) public view returns (bool) {
        return !exceedsMaxCredit(account, classId) &&
        !majorRestriction(account, classId) &&
        !classFull(classId) &&
        !registered(account, classId) &&
        isRegistrationPeriod(account) && 
        !hasTimeConflict(account, classId);
    }



    function _registerClass(
        address account,
        uint256 classId
    ) internal {
        _mint(account, classId, 1, "");
        // classes[classId].currentlyEnrolled += 1;
        // accountClasses[account].push(classId);
        // accountCredits[account] += classes[classId].credits;
    }

    function registerClass(
        uint256 classId
    ) public onlyUWAccounts(msg.sender) {
        require(canEnroll(msg.sender, classId));
        _registerClass(msg.sender, classId);
    }

    function _dropClass(address account, uint256 classId) internal {
        _burn(account, classId, 1);
        // classes[classId].currentlyEnrolled -= 1;
        // accountCredits[account] -= classes[classId].credits;
        // uint i = 0;
        // for (; i < accountClasses[account].length; i += 1) {
        //     if (accountClasses[account][i] == classId) {
        //         delete accountClasses[account][i];
        //         break;
        //     }
        // }
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

    function uri(uint256 tokenId) public view override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable) returns (string memory) {
        return ERC1155URIStorageUpgradeable.uri(tokenId);
    }

    function addClass(
        uint256 classId,
        string memory className,
        uint256 enrollCapacity,
        uint256 credits,
        string memory creditType,
        uint256[7] memory startTimes,
        uint256[7] memory endTimes
    ) public onlyOwner {
        require(classes[classId].classId == 0);
        classes[classId].classId = classId;
        classes[classId].className = className;
        classes[classId].enrollCapacity = enrollCapacity;
        classes[classId].credits = credits;
        classes[classId].creditType = creditType;
        uint i;
        for (; i < 7; i += 1) {
            classes[classId].classTimes[i].startTime = startTimes[i];
            classes[classId].classTimes[i].endTime = endTimes[i];
        }
    }

    function setMajorRestriction(
        uint256 classId,
        address majorAddress
    ) public onlyOwner {
        require(classes[classId].classId != 0);
        classes[classId].classMajorRestrictions.push(majorAddress);
    }

    function removeMajorRestriction(
        uint256 classId,
        address majorAddress
    ) public onlyOwner {
        require(classes[classId].classId != 0);
        uint i;
        for (; i < classes[classId].classMajorRestrictions.length; i += 1) {
            if (classes[classId].classMajorRestrictions[i] == majorAddress) {
                classes[classId].classMajorRestrictions[i] = classes[classId].classMajorRestrictions[classes[classId].classMajorRestrictions.length - 1]; 
                classes[classId].classMajorRestrictions.pop();
                break;
            }
        }
    }


    function closeClass(uint256 classId) public onlyOwner {
        classes[classId].classId = 0;
        classes[classId].className = "";
        classes[classId].currentlyEnrolled = 0;
        classes[classId].enrollCapacity = 0;
        classes[classId].credits = 0;
        classes[classId].creditType = "";
        delete classes[classId].classTimes;
        delete classes[classId].classMajorRestrictions;
    }

    function changeMaxAllowedCredits(uint256 num) public onlyOwner {
        maxAllowedCredits = num;
    }


    function setRegistrationPeriod(uint256 period1, uint256 period2, uint256 period3) public onlyOwner {
        require(registrationPeriods.length >= 3);
        registrationPeriods[0] = period1;
        registrationPeriods[1] = period2;
        registrationPeriods[2] = period3;
    }

}