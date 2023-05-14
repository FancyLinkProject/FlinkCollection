// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract TokenInfoDecoderV1 {
    uint256 constant version = 1;

    struct TokenInfo {
        address author;
        string tokenUri;
        bytes32 fictionIdentifier;
        string fictionName;
        bytes32 volumeIdentifier;
        string volumeName;
        string chapterName;
        uint256 volumeNo;
        uint256 chapterNo;
        uint256 wordsAmount;
    }

    function decodeTokenInfo(
        uint256 _version,
        bytes memory data
    ) external pure returns (TokenInfo memory) {
        require(_version == version, "invalid version");

        TokenInfo memory tokenInfo = abi.decode(data, (TokenInfo));

        return tokenInfo;
    }
}
