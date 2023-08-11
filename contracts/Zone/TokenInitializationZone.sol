// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ZoneParameters, Schema, SpentItem, ReceivedItem} from "./lib/ConsiderationStructs.sol";

import {ZoneInterface} from "./interfaces/ZoneInterface.sol";
import {BytesLib} from "./lib/BytesLib.sol";
import {CriteriaResolutionErrors} from "./interfaces/CriteriaResolutionErrors.sol";
import {ZeroBytes} from "./lib/ZoneConstants.sol";

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
        TokenInitializationInfo memory tokenInitializationInfo
    ) external returns (bool);

    function tokenInfo(uint256 tokenId) external returns (TokenInfo memory);

    function getBatchTokenInfo(
        uint256[] memory tokenIdLs
    ) external view returns (TokenInfo[] memory, string[] memory uriLs);

    function uri(uint256 tokenId) external view returns (string memory);
}

contract TokenInitializationZone is ZoneInterface, CriteriaResolutionErrors {
    IFlinkCollection immutable flinkCollection;

    constructor(IFlinkCollection _flinkCollection) {
        flinkCollection = _flinkCollection;
    }

    // Called by Consideration whenever any extraData is provided by the caller.
    function validateOrder(
        ZoneParameters calldata zoneParameters
    ) external returns (bytes4 validOrderMagicValue) {
        //decode zoneData.extraData to TokenInitializationInfo[]
        (
            TokenInitializationInfo[] memory tokenInitializationInfoLs,
            bytes32[][] memory proofs
        ) = abi.decode(
                zoneParameters.extraData,
                (TokenInitializationInfo[], bytes32[][])
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
                    tokenInitializationInfo
                );
                if (!success) {
                    revert("Failed to initialize token info");
                }
            }
        }

        // check whether the token info in the order satisfies the offerer's intention
        if (zoneParameters.zoneHash != ZeroBytes) {
            uint256[] memory flinkCollectionNftIdentifierLs = new uint256[](
                zoneParameters.offer.length +
                    zoneParameters.consideration.length
            );

            uint256 count = 0;
            // loop offer to find all flinkCollection NFT
            for (uint256 i = 0; i < zoneParameters.offer.length; i++) {
                if (zoneParameters.offer[i].token == address(flinkCollection)) {
                    flinkCollectionNftIdentifierLs[count] = zoneParameters
                        .offer[i]
                        .identifier;
                    count++;
                }
            }

            // loop consideration to find all flinkCollection NFT
            for (uint256 i = 0; i < zoneParameters.consideration.length; i++) {
                if (
                    zoneParameters.consideration[i].token ==
                    address(flinkCollection)
                ) {
                    flinkCollectionNftIdentifierLs[count] = zoneParameters
                        .consideration[i]
                        .identifier;
                    count++;
                }
            }

            // there is some flinkCollection NFT
            if (count != 0) {
                // get data of those NFT
                (
                    TokenInfo[] memory tokenInfoLs,
                    string[] memory uriLs
                ) = flinkCollection.getBatchTokenInfo(
                        sliceArray(flinkCollectionNftIdentifierLs, count)
                    );

                require(count == proofs.length, "invalid proof amount");

                // loop each NFT, to verify its data correctness
                for (uint256 i = 0; i < count; i++) {
                    bytes32 leaf = keccak256(
                        abi.encode(
                            flinkCollectionNftIdentifierLs[i],
                            tokenInfoLs[i],
                            uriLs[i]
                        )
                    );

                    _verifyProof(leaf, zoneParameters.zoneHash, proofs[i]);
                }
            }
        }

        return ZoneInterface.validateOrder.selector;
    }

    function sliceArray(
        uint256[] memory arr,
        uint256 l
    ) internal pure returns (uint256[] memory) {
        require(l <= arr.length, "wrong l");
        uint256[] memory slicedArr = new uint256[](l);

        for (uint256 i = 0; i < l; i++) {
            slicedArr[i] = arr[i];
        }
        return slicedArr;
    }

    /**
     * @dev Internal pure function to ensure that a given element is contained
     *      in a merkle root via a supplied proof.
     *
     * @param leaf  The element for which to prove inclusion.
     * @param root  The merkle root that inclusion will be proved against.
     * @param proof The merkle proof.
     */
    function _verifyProof(
        bytes32 leaf,
        bytes32 root,
        bytes32[] memory proof
    ) internal pure {
        // Hash the supplied leaf to use as the initial proof element.
        bytes32 computedHash = leaf;

        // Iterate over each proof element.
        for (uint256 i = 0; i < proof.length; ++i) {
            // Retrieve the proof element.
            bytes32 proofElement = proof[i];

            // Sort and hash proof elements and update the computed hash.
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Ensure that the final derived hash matches the expected root.
        if (computedHash != root) {
            revert InvalidProof();
        }
    }
}
