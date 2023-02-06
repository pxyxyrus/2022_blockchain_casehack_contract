
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../UWID/UWIDUpgradeable.sol";
import "./UWClassesArchive.sol";
import "./UWUtils.sol";





contract UWClassesUpgradeable is Initializable, OwnableUpgradeable, ERC1155Upgradeable, ERC1155URIStorageUpgradeable {

    using UWUtils for string;

    address public UWIDContractAddress;

    address public UWClassesArchiveAddress;

    uint256 public maxAllowedCredits = 20;

    string public quarterName;

    struct Class {
        bytes32 courseId; // unique for each course ex) CSE 121 or ARCH 152
        uint256 classId; // sln
        uint256 currentlyEnrolled;
        uint256 enrollCapacity;
        uint256 credits;
        bytes30 weekdayTime;
        bytes12 weekendTime;
        bytes20 sectionType;
        string creditType;
        string courseName;
        bytes data;
    }

    // Class mappings
    // classId(sln) to Class
    mapping(uint256 => Class) public classes;
    
    // classId(sln) to major restrictions(Major NFT)
    mapping(uint256 => address[]) public classMajorRestrictions;

    // courseId to two dim array that contains prereq courseIds
    // first index of array are or requirements
    // second index of array are and requirements
    mapping(bytes32 => bytes32[][]) public coursePrerequisites;

    // courseId to classGroupRequirements
    // if courseId => 3, meaning 3 classes has to be registered to take that course,
    // then three bits in course section info has to be 1 in a row.
    // ex) like 0x00...111 or 0x00...111000 and 0x00...111000000 so on...
    mapping(bytes32 => uint8) public courseSectionRequirements;

    // Account mappings
    // account to credits
    mapping(address => uint256) public accountCredits;

    // account to classId(sln)
    mapping(address => uint256[]) public accountClasses;

    // account to courseId
    mapping(address => mapping(bytes32 => bool)) public accountCourses;

    // account to weekdaytime
    mapping(address => bytes30) public accountWeekdayTime;

    // account to weekendtime
    mapping(address => bytes12) public accountWeekendTime;

    // account to courseId to courseSectionInfo;
    mapping(address => mapping(bytes32 => bytes20)) public accountCourseSectionInfo;
    
    // three timestamps in milliseconds
    uint256[] public registrationPeriods;

    // total number of nfts minted
    uint256 public currentSupply;

    // initializer 
    function __UWClasses_init(address _UWIDContractAddress, string memory _quarterName) public initializer {
        __ERC1155_init("");
        __UWClasses_init_unchained(_UWIDContractAddress, _quarterName);
    }

    function __UWClasses_init_unchained(address _UWIDContractAddress, string memory _quarterName) internal onlyInitializing {
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
        uint256 i = 0;
        for (; i < ids.length; i += 1) {
            if (to != address(0)) {            
                if (isUWAccount(to)) {
                    require(canEnroll(to, ids[i]));
                } // else { 
                    // revert();
                // }
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
        uint256 i;
        uint256 j;
        bytes30 classWeekdaySchedule;
        bytes12 classWeekendSchedule;
        for (i = 0; i < ids.length; i += 1) {
            classWeekdaySchedule = classes[ids[i]].weekdayTime;
            classWeekendSchedule = classes[ids[i]].weekendTime;
            
            // not burning but transferring in
            if (to != address(0)) {
                accountCredits[to] += classes[ids[i]].credits;
                accountWeekdayTime[to] = accountWeekdayTime[to] | classWeekdaySchedule;
                accountCourses[to][classes[ids[i]].courseId] = true;
                accountCourseSectionInfo[to][classes[ids[i]].courseId] =
                    accountCourseSectionInfo[to][classes[ids[i]].courseId] | classes[ids[i]].sectionType;
            }

            // not minting but transferring out
            if (from != address(0)) {
                accountCredits[from] -= classes[ids[i]].credits;
                accountWeekendTime[from] = accountWeekendTime[from] & (~classWeekendSchedule);
                accountCourses[from][classes[ids[i]].courseId] = false;
                accountCourseSectionInfo[to][classes[ids[i]].courseId] =
                    accountCourseSectionInfo[to][classes[ids[i]].courseId] & (~classes[ids[i]].sectionType);
            }
            
            accountClasses[to].push(ids[i]);
            for (j = 0; j < accountClasses[from].length; j += 1) {
                if (accountClasses[from][j] == ids[i]) {
                    accountClasses[from][j] = accountClasses[from][accountClasses[from].length - 1];
                    accountClasses[from].pop();
                    break;
                }
            }

            // minted
            if (from == address(0)) {
                classes[ids[i]].currentlyEnrolled += 1;
                currentSupply += 1;
            }

            // burned
            if (to == address(0)) {
                classes[ids[i]].currentlyEnrolled -= 1;
                currentSupply -= 1;
            }
        }
        
        for (i = 0; i < ids.length; i += 1) {
            accountRegisteredAllCourseSections(to, classes[ids[i]].courseId);
            accountDroppedAllCourseSections(from, classes[ids[i]].courseId);
        }

    }

    function isUWAccount(address to) public view returns (bool) {
        return IERC721Upgradeable(UWIDContractAddress).balanceOf(to) != 0;
    }

    // precondition
    modifier onlyUWAccounts(address to) {
        require(tx.origin == msg.sender); // only EOA
        require(isUWAccount(to), "Does not have an UW ID.");
        _;
    }

    // precondition
    function classRegistered(address account, uint256 classId) public view returns (bool) {
        return balanceOf(account, classId) != 0;
    }

    // precondition
    function classFull(uint256 classId) public view returns (bool) {
        return classes[classId].currentlyEnrolled >= classes[classId].enrollCapacity;
    }

    // precondition
    function majorRestriction(address account, uint256 classId) public view returns (bool) {
        if (classMajorRestrictions[classId].length == 0) {
            return false;
        }
        uint256 i = 0;
        for (; i < classMajorRestrictions[classId].length; i += 1) {
            if (IERC721Upgradeable(classMajorRestrictions[classId][i]).balanceOf(account) != 0) {
                return false;
            }
        }
        return true;
    }

    // precondition
    function meetsPrerequisite(address account, uint256 classId) public view returns (bool) {
        bool meet;
        uint256 i = 0;
        uint256 j = 0;
        bytes32 courseId = classes[classId].courseId;
        for (i = 0; i < coursePrerequisites[courseId].length; i++) {
            meet = true;
            for (j = 0; i < coursePrerequisites[courseId][i].length; i++) {
                if (UWClassesArchive(UWClassesArchiveAddress).balanceOf(account, uint256(coursePrerequisites[courseId][i][j])) == 0) {
                    meet = false;
                    break;
                }
            }
            if (meet) {
                return true;
            }
        }

        return false;
    }

    // precondition
    function exceedsMaxCredit(address account, uint256 classId) public view returns (bool) {
        return accountCredits[account] + classes[classId].credits > maxAllowedCredits;
    }

    // precondition
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

    // precondition
    function hasTimeConflict(address account, uint256 classId) public view returns (bool) {
        bytes30 classWeekdaySchedule = classes[classId].weekdayTime;
        bytes12 classWeekendSchedule = classes[classId].weekendTime;
        return ((accountWeekdayTime[account] & classWeekdaySchedule != bytes30(0)) ||
            (accountWeekendTime[account] & classWeekendSchedule != bytes12(0)));
    }

    function canEnroll(address account, uint256 classId) public view returns (bool) {
        return !exceedsMaxCredit(account, classId) &&
        !majorRestriction(account, classId) &&
        !classFull(classId) &&
        !classRegistered(account, classId) &&
        isRegistrationPeriod(account) && 
        !hasTimeConflict(account, classId) &&
        meetsPrerequisite(account, classId);
    }

    // postcondition
    function accountDroppedAllCourseSections(address account, bytes32 courseId) public view returns (bool) {
        return accountCourseSectionInfo[account][courseId] == bytes20(0);
    }


    // postcondition
    function accountDroppedAllCourseSections(address account, string memory courseName) external view returns (bool) {
        return accountDroppedAllCourseSections(account, courseName.courseNameToCourseId());
    }



    // postcondition
    function accountRegisteredAllCourseSections(address account, bytes32 courseId) public view returns (bool) {
        //


        intentional error to remember that I need to implement this function


        return ;
    }

    // postcondition
    function accountRegisteredAllCourseSections(address account, string memory courseName) external view returns (bool) {
        return accountRegisteredAllCourseSections(account, courseName.courseNameToCourseId());
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
    ) external onlyUWAccounts(msg.sender) {
        require(canEnroll(msg.sender, classId));
        _registerClass(msg.sender, classId);
    }

    function registerMultipleClasses(uint256[] memory classIds) external onlyUWAccounts(msg.sender) {
        uint256 classId;
        uint256 i = 0;
        for (; i < classIds.length; i += 1) {
            classId = classIds[i];
            if(canEnroll(msg.sender, classId)) {
                _registerClass(msg.sender, classId);
            }
        }
    }

    function registerCourse(uint256[] memory classIds) external onlyUWAccounts(msg.sender) {
        uint256 i = 0;
        uint256[] memory amounts = new uint256[](classIds.length);
        for (; i < classIds.length; i += 1) {
        }
        _mintBatch(msg.sender, classIds, amounts, "");

        // implement using batchMint
    }

    function _dropClass(address account, uint256 classId) internal {
        _burn(account, classId, 1);
    }

    function dropClass(uint256 classId) external onlyUWAccounts(msg.sender) {
        require(classRegistered(msg.sender, classId));
        _dropClass(msg.sender, classId);
    }

    function dropCourse(uint256[] memory classIds) external onlyUWAccounts(msg.sender) {
        // implement using batchburn
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
        string memory courseName,
        uint256 enrollCapacity,
        uint256 credits,
        string memory creditType,
        bytes30 weekdayTime,
        uint8 sectionRequirements,
        bytes12 weekendTime,
        bytes20 sectionType
    ) external onlyOwner {
        require(classes[classId].classId == 0);
        classes[classId].courseId = courseName.courseNameToCourseId();
        classes[classId].classId = classId;
        classes[classId].courseName = courseName;
        classes[classId].enrollCapacity = enrollCapacity;
        classes[classId].credits = credits;
        classes[classId].creditType = creditType;
        classes[classId].weekdayTime = weekdayTime;
        classes[classId].weekendTime = weekendTime;
        classes[classId].sectionType = sectionType;
        courseSectionRequirements[
            classes[classId].courseId
        ] = sectionRequirements;
    }

    function setMajorRestriction(
        uint256 classId,
        address majorAddress
    ) external onlyOwner {
        require(classes[classId].classId != 0);
        classMajorRestrictions[classId].push(majorAddress);
    }

    function removeMajorRestriction(
        uint256 classId,
        address majorAddress
    ) external onlyOwner {
        require(classes[classId].classId != 0);
        uint256 i;
        for (; i < classMajorRestrictions[classId].length; i += 1) {
            if (classMajorRestrictions[classId][i] == majorAddress) {
                classMajorRestrictions[classId][i] = classMajorRestrictions[classId][classMajorRestrictions[classId].length - 1]; 
                classMajorRestrictions[classId].pop();
                break;
            }
        }
    }

    function setPrerequisite(uint256 classId, string[] memory courseList) external onlyOwner {
        bytes32 courseId = classes[classId].courseId;
        bytes32[] memory courseIds = new bytes32[](courseList.length);
        uint256 i = 0;
        for (; i < courseList.length; i++) {
            courseIds[i] = courseList[i].courseNameToCourseId();
        }
        coursePrerequisites[courseId].push(courseIds);
    }

    function removePrerequisite(uint256 classId, uint256 index) external onlyOwner {
        bytes32 courseId = classes[classId].courseId;
        require(index < coursePrerequisites[courseId][index].length);
        coursePrerequisites[courseId][index] = coursePrerequisites[courseId][coursePrerequisites[courseId].length - 1]; 
        coursePrerequisites[courseId].pop();
    }

    function setCourseSectionRequirements(string memory courseName, uint8 sectionRequirements) external onlyOwner {
        courseSectionRequirements[courseName.courseNameToCourseId()] = sectionRequirements;
    }

    // closeClassHas implementation issues
    // function closeClass(uint256 classId) public onlyOwner {
    //     classes[classId].courseId = bytes32(0);
    //     classes[classId].classId = 0;
    //     classes[classId].courseName = "";
    //     classes[classId].currentlyEnrolled = 0;
    //     classes[classId].enrollCapacity = 0;
    //     classes[classId].credits = 0;
    //     classes[classId].creditType = "";
    //     classes[classId].weekdayTime = bytes30(0);
    //     classes[classId].weekendTime = bytes12(0);
    //     classes[classId].sectionType = bytes20(0);
    //     classes[classId].data = "";
    //     delete classMajorRestrictions[classId];
    // }

    function changeMaxAllowedCredits(uint256 num) public onlyOwner {
        maxAllowedCredits = num;
    }


    function setRegistrationPeriod(uint256 period1, uint256 period2, uint256 period3) public onlyOwner {
        require(registrationPeriods.length >= 3);
        registrationPeriods[0] = period1;
        registrationPeriods[1] = period2;
        registrationPeriods[2] = period3;
    }

    function getClassesOfAccount(address account) external view returns (uint256[] memory) {
        return accountClasses[account];
    }

}