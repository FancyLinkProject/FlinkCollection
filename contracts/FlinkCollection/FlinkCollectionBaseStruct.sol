// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

struct TokenInitializationInfo {
    address author;
    bytes32 contentDigest;
    uint parentId;
    uint supply;
    uint kind;
    uint version;
    bytes extraData;
    string tokenUri;
    uint256 nonce;
    bytes signature;
}

struct TokenInfo {
    address author;
    bytes32 contentDigest;
    uint parentId;
    uint supply;
    uint kind;
    uint version;
    bytes extraData;
    bool initialized;
}

struct SignatureStatus {
    bool used;
    bool cancelled;
}
