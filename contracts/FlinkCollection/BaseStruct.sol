// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

struct TokenInitializationInfo {
    uint256 tokenId;
    uint256 version;
    bytes data;
    string tokenUri;
    uint256 nonce;
    bytes signature;
}

struct TokenInfo {
    uint256 version;
    bytes data;
    bool initialized;
}

struct SignatureStatus {
    bool used;
    bool cancelled;
}
