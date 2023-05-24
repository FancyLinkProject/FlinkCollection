// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ZoneParameters, Schema} from "./lib/ConsiderationStructs.sol";

import {ZoneInterface} from "./interfaces/ZoneInterface.sol";
import {BytesLib} from "./lib/BytesLib.sol";

struct TokenInfo {
    uint256 version;
    bytes data;
    bool initialized;
}

struct TokenInitializationInfo {
    uint256 tokenId;
    uint256 version;
    bytes data;
    string tokenUri;
    uint256 nonce;
    bytes signature;
}

interface IFlinkCollection {
    function initializeTokenInfoPermit(
        bytes memory data
    ) external returns (bool);

    function tokenInfo(uint256 tokenId) external returns (TokenInfo memory);
}

contract TokenInitializationZone is ZoneInterface {
    IFlinkCollection immutable flinkCollection;

    constructor(IFlinkCollection _flinkCollection) {
        flinkCollection = _flinkCollection;
    }

    // Called by Consideration whenever any extraData is provided by the caller.
    function validateOrder(
        ZoneParameters calldata zoneData
    ) external returns (bytes4 validOrderMagicValue) {
        //decode zoneData.extraData to TokenInitializationInfo[]
        TokenInitializationInfo[] memory tokenInitializationInfoLs = abi.decode(
            zoneData.extraData,
            (TokenInitializationInfo[])
        );

        // loop tokenInitializationInfoLs
        for (uint256 i = 0; i < tokenInitializationInfoLs.length; i++) {
            TokenInitializationInfo
                memory tokenInitializationInfo = tokenInitializationInfoLs[i];

            // get tokenInfo of the tokenId specified by tokenInitializationInfo
            TokenInfo memory tokenInfo = flinkCollection.tokenInfo(
                tokenInitializationInfo.tokenId
            );

            // if token hasn't been initialized, initialize it
            // if failed to initialize, then revert
            if (!tokenInfo.initialized) {
                bool success = flinkCollection.initializeTokenInfoPermit(
                    zoneData.extraData
                );
                if (!success) {
                    revert("Failed to initialize token info");
                }
            } else {
                // if token has already been initialized, check whether the token data equals data specified by tokenInitializationInfo
                // if not equal, revert
                if (
                    !BytesLib.equal(
                        tokenInfo.data,
                        tokenInitializationInfo.data
                    )
                ) {
                    revert("Token info doesn't match");
                }
            }
        }

        return ZoneInterface.validateOrder.selector;
    }
}
