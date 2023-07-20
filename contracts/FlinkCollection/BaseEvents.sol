// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract BaseEvents {
    event CreatorChanged(uint256 indexed _id, address indexed _creator);
    event SignatureInvalidated(bytes signature);
    event TokenInfoInitialized(uint256 tokenId);
    event TokenInfoValidityCheckerChanged(uint256 version, address newAddress);
    event TokenDataDecoderChanged(uint256 version, address newAddress);
}
