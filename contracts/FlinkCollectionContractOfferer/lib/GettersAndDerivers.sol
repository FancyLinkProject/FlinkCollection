// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ConsiderationItem, OfferItem, OrderParametersWithTokenInitializeInfo} from "./ConsiderationStructs.sol";

import {Base} from "./Base.sol";

/**
 * @title GettersAndDerivers
 * @author 0age
 * @notice ConsiderationInternal contains pure and internal view functions
 *         related to getting or deriving various values.
 */
contract GettersAndDerivers is Base {
    /**
     * @dev Internal view function to derive the EIP-712 hash for an offer item.
     *
     * @param offerItem The offered item to hash.
     *
     * @return The hash.
     */
    function _hashOfferItem(
        OfferItem memory offerItem
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _OFFER_ITEM_TYPEHASH,
                    offerItem.itemType,
                    offerItem.token,
                    offerItem.identifierOrCriteria,
                    offerItem.startAmount,
                    offerItem.endAmount
                )
            );
    }

    /**
     * @dev Internal view function to derive the EIP-712 hash for a
     *      consideration item.
     *
     * @param considerationItem The consideration item to hash.
     *
     * @return The hash.
     */
    function _hashConsiderationItem(
        ConsiderationItem memory considerationItem
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _CONSIDERATION_ITEM_TYPEHASH,
                    considerationItem.itemType,
                    considerationItem.token,
                    considerationItem.identifierOrCriteria,
                    considerationItem.startAmount,
                    considerationItem.endAmount,
                    considerationItem.recipient
                )
            );
    }

    /**
     * @dev Internal view function to derive the order hash for a given order.
     *      Note that only the original consideration items are included in the
     *      order hash, as additional consideration items may be supplied by the
     *      caller.
     *
     * @param orderParametersWithTokenInitializeInfo The parameters of the order to hash.
     * @param counter           The counter of the order to hash.
     *
     * @return orderHash The hash.
     */
    function _deriveOrderHash(
        OrderParametersWithTokenInitializeInfo
            memory orderParametersWithTokenInitializeInfo,
        uint256 counter
    ) internal view returns (bytes32 orderHash) {
        // Designate new memory regions for offer and consideration item hashes.
        bytes32[] memory offerHashes = new bytes32[](
            orderParametersWithTokenInitializeInfo.offer.length
        );
        bytes32[] memory considerationHashes = new bytes32[](
            orderParametersWithTokenInitializeInfo
                .totalOriginalConsiderationItems
        );

        // Iterate over each offer on the order.
        for (
            uint256 i = 0;
            i < orderParametersWithTokenInitializeInfo.offer.length;
            ++i
        ) {
            // Hash the offer and place the result into memory.
            offerHashes[i] = _hashOfferItem(
                orderParametersWithTokenInitializeInfo.offer[i]
            );
        }

        // Iterate over each consideration on the order.
        for (
            uint256 i = 0;
            i <
            orderParametersWithTokenInitializeInfo
                .totalOriginalConsiderationItems;
            ++i
        ) {
            // Hash the consideration and place the result into memory.
            considerationHashes[i] = _hashConsiderationItem(
                orderParametersWithTokenInitializeInfo.consideration[i]
            );
        }

        // Derive and return the order hash as specified by EIP-712.

        return
            keccak256(
                abi.encode(
                    _ORDER_TYPEHASH,
                    orderParametersWithTokenInitializeInfo.offerer,
                    orderParametersWithTokenInitializeInfo.zone,
                    keccak256(abi.encodePacked(offerHashes)),
                    keccak256(abi.encodePacked(considerationHashes)),
                    orderParametersWithTokenInitializeInfo.orderType,
                    orderParametersWithTokenInitializeInfo.startTime,
                    orderParametersWithTokenInitializeInfo.endTime,
                    orderParametersWithTokenInitializeInfo.zoneHash,
                    orderParametersWithTokenInitializeInfo.salt,
                    orderParametersWithTokenInitializeInfo.conduitKey,
                    counter,
                    orderParametersWithTokenInitializeInfo.tokenInitializeInfo
                )
            );
    }

    /**
     * @dev Internal pure function to efficiently derive an digest to sign for
     *      an order in accordance with EIP-712.
     *
     * @param domainSeparator The domain separator.
     * @param orderHash       The order hash.
     *
     * @return value The hash.
     */
    function _deriveEIP712Digest(
        bytes32 domainSeparator,
        bytes32 orderHash
    ) internal pure returns (bytes32 value) {
        value = keccak256(
            abi.encodePacked(uint16(0x1901), domainSeparator, orderHash)
        );
    }

    /**
     * @dev Internal view function to get the EIP-712 domain separator. If the
     *      chainId matches the chainId set on deployment, the cached domain
     *      separator will be returned; otherwise, it will be derived from
     *      scratch.
     */
    function _domainSeparator() internal view returns (bytes32) {
        return
            block.chainid == _CHAIN_ID
                ? _DOMAIN_SEPARATOR
                : _deriveDomainSeparator(
                    _EIP_712_DOMAIN_TYPEHASH,
                    _NAME_HASH,
                    _VERSION_HASH
                );
    }

    /**
     * @notice Retrieve configuration information for this contract.
     *
     * @return version           The contract version.
     * @return domainSeparator   The domain separator for this contract.
     */
    function _information()
        internal
        view
        returns (string memory version, bytes32 domainSeparator)
    {
        version = _VERSION;
        domainSeparator = _domainSeparator();
    }

    /**
     * @notice Retrieve the name of this contract.
     *
     * @return The name of this contract.
     */
    function _name() internal pure returns (string memory) {
        // Return the name of the contract.
        return _NAME;
    }
}
