// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract TokenInfoValidityCheckerV1 {
    uint256 constant version = 1;

    struct TokenInfo {
        address author;
        string fictionName;
        string volumeName;
        string chapterName;
        uint256 volumeNo;
        uint256 chapterNo;
    }

    function checkTokenInfoValidity(
        uint256 _version,
        bytes memory data
    ) external pure returns (bool) {
        if (_version != version) {
            return false;
        }

        abi.decode(data, (TokenInfo));

        return true;
    }
}
