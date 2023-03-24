pragma solidity ^0.8.9;

library UWUtils {
    
    function courseNameToCourseId(string memory courseName) internal pure returns(bytes32) {
        return keccak256(abi.encode(courseName));
    }
}