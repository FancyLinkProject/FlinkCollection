// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract BaseEvents {
    event CreatorChanged(uint256 indexed _id, address indexed _creator);
    event SignatureInvalidated(bytes signature);
    event TokenInfoValidityCheckerChanged(uint256 version, address newAddress);
    event InfoResolverChanged(
        uint256 version,
        uint256 kind,
        address newAddress
    );
    event TokenInfoInitialization(
        uint tokenId,
        address author,
        bytes32 contentDigest,
        uint parentId,
        uint supply,
        uint kind,
        uint version,
        bytes extraData
    );
}
