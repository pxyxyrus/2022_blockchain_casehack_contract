

library UWUtils {
    
    function courseNameToCourseId(string memory courseName) internal pure returns(bytes32) {
        return keccak256(abi.encode(courseName));
    }
}