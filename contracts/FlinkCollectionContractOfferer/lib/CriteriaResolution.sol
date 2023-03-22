// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ItemType, Side} from "./ConsiderationEnums.sol";

import {AdvancedOrderWithTokenInitializeInfo, ConsiderationItem, CriteriaResolver, OfferItem, OrderParametersWithTokenInitializeInfo, ReceivedItem, SpentItem} from "./ConsiderationStructs.sol";

import {CriteriaResolutionErrors} from "../interfaces/CriteriaResolutionErrors.sol";

/**
 * @title CriteriaResolution
 * @author 0age
 * @notice CriteriaResolution contains a collection of pure functions related to
 *         resolving criteria-based items.
 */
contract CriteriaResolution is CriteriaResolutionErrors {
    /**
     * @dev Internal pure function to apply criteria resolvers containing
     *      specific token identifiers and associated proofs to order items.
     *
     * @param advancedOrderWithTokenInitializeInfo      The order to apply criteria resolvers to.
     * @param criteriaResolvers  An array where each element contains a
     *                           reference to a specific order as well as that
     *                           order's offer or consideration, a token
     *                           identifier, and a proof that the supplied token
     *                           identifier is contained in the order's merkle
     *                           root. Note that a root of zero indicates that
     *                           any transferable token identifier is valid and
     *                           that no proof needs to be supplied.
     */
    function _applyCriteriaResolversAdvanced(
        AdvancedOrderWithTokenInitializeInfo
            memory advancedOrderWithTokenInitializeInfo,
        CriteriaResolver[] memory criteriaResolvers
    ) internal pure {
        // Retrieve length of criteria resolvers array and place on stack.
        uint256 arraySize = criteriaResolvers.length;

        // Retrieve the parameters for the order.
        OrderParametersWithTokenInitializeInfo memory orderParameters = (
            advancedOrderWithTokenInitializeInfo
                .orderParametersWithTokenInitializeInfo
        );

        // Iterate over each criteria resolver.
        for (uint256 i = 0; i < arraySize; ++i) {
            // Retrieve the criteria resolver.
            CriteriaResolver memory criteriaResolver = (criteriaResolvers[i]);

            // Read the order index from memory and place it on the stack.
            uint256 orderIndex = criteriaResolver.orderIndex;

            if (orderIndex != 0) {
                revert OrderCriteriaResolverOutOfRange(criteriaResolver.side);
            }

            // Read component index from memory and place it on the stack.
            uint256 componentIndex = criteriaResolver.index;

            // Declare values for item's type and criteria.
            ItemType itemType;
            uint256 identifierOrCriteria;

            // If the criteria resolver refers to an offer item...
            if (criteriaResolver.side == Side.OFFER) {
                // Ensure that the component index is in range.
                if (componentIndex >= orderParameters.offer.length) {
                    revert OfferCriteriaResolverOutOfRange();
                }

                // Retrieve relevant item using order and component index.
                OfferItem memory offer = (
                    orderParameters.offer[componentIndex]
                );

                // Read item type and criteria from memory & place on stack.
                itemType = offer.itemType;
                identifierOrCriteria = offer.identifierOrCriteria;

                // Optimistically update item type to remove criteria usage.
                if (itemType == ItemType.ERC721_WITH_CRITERIA) {
                    offer.itemType = ItemType.ERC721;
                } else {
                    offer.itemType = ItemType.ERC1155;
                }

                // Optimistically update identifier w/ supplied identifier.
                offer.identifierOrCriteria = criteriaResolver.identifier;
            } else {
                // Otherwise, the resolver refers to a consideration item.
                // Ensure that the component index is in range.
                if (componentIndex >= orderParameters.consideration.length) {
                    revert ConsiderationCriteriaResolverOutOfRange();
                }

                // Retrieve relevant item using order and component index.
                ConsiderationItem memory consideration = (
                    orderParameters.consideration[componentIndex]
                );

                // Read item type and criteria from memory & place on stack.
                itemType = consideration.itemType;
                identifierOrCriteria = consideration.identifierOrCriteria;

                // Optimistically update item type to remove criteria usage.
                if (itemType == ItemType.ERC721_WITH_CRITERIA) {
                    consideration.itemType = ItemType.ERC721;
                } else {
                    consideration.itemType = ItemType.ERC1155;
                }

                // Optimistically update identifier w/ supplied identifier.
                consideration.identifierOrCriteria = (
                    criteriaResolver.identifier
                );
            }

            // Ensure the specified item type indicates criteria usage.
            if (!_isItemWithCriteria(itemType)) {
                revert CriteriaNotEnabledForItem();
            }

            // If criteria is not 0 (i.e. a collection-wide offer)...
            if (identifierOrCriteria != uint256(0)) {
                // Verify identifier inclusion in criteria root using proof.
                _verifyProof(
                    criteriaResolver.identifier,
                    identifierOrCriteria,
                    criteriaResolver.criteriaProof
                );
            } else if (criteriaResolver.criteriaProof.length != 0) {
                // Revert if a proof is supplied for a collection-wide item.
                revert InvalidProof();
            }
        }

        // Validate Criteria on order has been resolved

        // Read consideration length from memory and place on stack.
        uint256 totalItems = (
            advancedOrderWithTokenInitializeInfo
                .orderParametersWithTokenInitializeInfo
                .consideration
                .length
        );

        // Iterate over each consideration item on the order.
        for (uint256 i = 0; i < totalItems; ++i) {
            // Ensure item type no longer indicates criteria usage.
            if (
                _isItemWithCriteria(
                    advancedOrderWithTokenInitializeInfo
                        .orderParametersWithTokenInitializeInfo
                        .consideration[i]
                        .itemType
                )
            ) {
                revert UnresolvedConsiderationCriteria(0, i);
            }
        }

        // Read offer length from memory and place on stack.
        totalItems = advancedOrderWithTokenInitializeInfo
            .orderParametersWithTokenInitializeInfo
            .offer
            .length;

        // Iterate over each offer item on the order.
        for (uint256 i = 0; i < totalItems; ++i) {
            // Ensure item type no longer indicates criteria usage.
            if (
                _isItemWithCriteria(
                    advancedOrderWithTokenInitializeInfo
                        .orderParametersWithTokenInitializeInfo
                        .offer[i]
                        .itemType
                )
            ) {
                revert UnresolvedOfferCriteria(0, i);
            }
        }
    }

    /**
     * @dev Internal pure function to check whether a given item type represents
     *      a criteria-based ERC721 or ERC1155 item (e.g. an item that can be
     *      resolved to one of a number of different identifiers at the time of
     *      order fulfillment).
     *
     * @param itemType The item type in question.
     *
     * @return withCriteria A boolean indicating that the item type in question
     *                      represents a criteria-based item.
     */
    function _isItemWithCriteria(
        ItemType itemType
    ) internal pure returns (bool withCriteria) {
        // ERC721WithCriteria is item type 4. ERC1155WithCriteria is item type
        // 5.
        withCriteria = uint256(itemType) > 3;
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
        uint256 leaf,
        uint256 root,
        bytes32[] memory proof
    ) internal pure {
        // Hash the supplied leaf to use as the initial proof element.
        bytes32 computedHash = keccak256(abi.encodePacked(leaf));

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
        if (computedHash != bytes32(root)) {
            revert InvalidProof();
        }
    }
}
