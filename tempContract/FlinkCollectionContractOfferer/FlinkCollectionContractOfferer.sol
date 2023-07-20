// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20Interface, ERC721Interface, ERC1155Interface} from "./interfaces/AbridgedTokenInterfaces.sol";
import {ContractOffererInterface} from "./interfaces/ContractOffererInterface.sol";

import {ItemType} from "./lib/ConsiderationEnums.sol";
import {OrderFulfiller} from "./lib/OrderFulfiller.sol";
import {ReceivedItem, Schema, SpentItem, OrderComponents, AdvancedOrderWithTokenInitializeInfo, OrderParametersWithTokenInitializeInfo, CriteriaResolver, TokenInitializeInfo} from "./lib/ConsiderationStructs.sol";

import {OrderValidator} from "./lib/OrderValidator.sol";
import {CriteriaResolution} from "./lib/CriteriaResolution.sol";

/**
 * @title FlinkCollectionContractOfferer
 * @author Senn
 * @notice FlinkCollectionContractOfferer is a maximally simple contract offerer. It offers
 *         a single item and expects to receive back another single item, and
 *         ignores all parameters supplied to it when previewing or generating
 *         an order. The offered item is placed into this contract as part of
 *         deployment and the corresponding token approvals are set for Seaport.
 */
abstract contract FlinkCollectionContractOfferer is
    ContractOffererInterface,
    OrderValidator,
    CriteriaResolution,
    OrderFulfiller
{
    error OrderUnavailable();

    address public immutable _SEAPORT;
    address public immutable _FLINKCOLLECTION;

    enum Side {
        list,
        offer
    }

    struct ContextData {
        AdvancedOrderWithTokenInitializeInfo advancedOrderWithTokenInitializeInfo;
        CriteriaResolver[] criteriaResolvers;
        address recipient;
        Side side;
    }

    constructor(address seaport, address flinkCollection) {
        // Set immutable values and storage variables.
        _SEAPORT = seaport;
        _FLINKCOLLECTION = flinkCollection;
    }

    receive() external payable {}

    function generateOrder(
        address,
        SpentItem[] calldata offer,
        SpentItem[] calldata consideration,
        bytes calldata context
    )
        external
        virtual
        override
        returns (
            SpentItem[] memory newOffer,
            ReceivedItem[] memory newConsideration
        )
    {
        // offer and consideration are not used, place here to prevent unused warning
        offer;
        consideration;

        // decode context
        ContextData memory contextData = abi.decode(context, (ContextData));
        AdvancedOrderWithTokenInitializeInfo
            memory advancedOrderWithTokenInitializeInfo = contextData
                .advancedOrderWithTokenInitializeInfo;

        OrderParametersWithTokenInitializeInfo
            memory orderParametersWithTokenInitializeInfo = advancedOrderWithTokenInitializeInfo
                .orderParametersWithTokenInitializeInfo;

        TokenInitializeInfo memory tokenInitializeInfo = abi.decode(
            orderParametersWithTokenInitializeInfo.tokenInitializeInfoBytes,
            (TokenInitializeInfo)
        );

        CriteriaResolver[] memory criteriaResolvers = contextData
            .criteriaResolvers;

        // Validate order, update status, and determine fraction to fill.
        (
            bytes32 orderHash,
            uint256 fillNumerator,
            uint256 fillDenominator
        ) = _validateOrderAndUpdateStatus(
                advancedOrderWithTokenInitializeInfo,
                true
            );

        // Apply criteria resolvers using generated orders and details arrays.
        _applyCriteriaResolversAdvanced(
            advancedOrderWithTokenInitializeInfo,
            criteriaResolvers
        );

        SpentItem[] memory spentItems;
        ReceivedItem[] memory receivedItems;

        (spentItems, receivedItems) = _applyFractions(
            orderParametersWithTokenInitializeInfo,
            fillNumerator,
            fillDenominator,
            bytes32(0),
            contextData.recipient
        );

        if (contextData.side == Side.list) {
            //check NFT belongs to flink collection
            for (uint256 i = 0; i < offer.length; i++) {
                require(offer[i].token == _FLINKCOLLECTION, "F200");
            }
            // check signature validity

            // check whether NFT hasn't been minted
            ERC1155Interface flinkCollectionContract = ERC1155Interface(
                _FLINKCOLLECTION
            );
            // transfer all NFT(lazymint)

            // setURI of target NFT

            // transfer remain NFT back to flinkCollection

            // transfer res NFT to this
        } else {}

        // Emit an event signifying that the order has been fulfilled.
        emit OrderFulfilled(
            orderHash,
            advancedOrderWithTokenInitializeInfo
                .orderParametersWithTokenInitializeInfo
                .offerer,
            address(0),
            contextData.recipient,
            spentItems,
            receivedItems
        );
    }

<<<<<<< HEAD
    /**
     * @dev Internal function to validate an order, determine what portion to
     *      fill, and update its status. The desired fill amount is supplied as
     *      a fraction, as is the returned amount to fill.
     *
     * @param advancedOrder   The order to fulfill as well as the fraction to
     *                        fill. Note that all offer and consideration
     *                        amounts must divide with no remainder in order for
     *                        a partial fill to be valid.
     * @param revertOnInvalid A boolean indicating whether to revert if the
     *                        order is invalid due to the time or order status.
     *
     * @return orderHash      The order hash.
     * @return newNumerator   A value indicating the portion of the order that
     *                        will be filled.
     * @return newDenominator A value indicating the total size of the order.
     */
    function _validateOrderAndUpdateStatus(
        AdvancedOrder memory advancedOrder,
        bool revertOnInvalid
    )
        internal
        returns (
            bytes32 orderHash,
            uint256 newNumerator,
            uint256 newDenominator
        )
    {
        // Retrieve the parameters for the order.
        OrderParameters memory orderParameters = advancedOrder.parameters;

        // Ensure current timestamp falls between order start time and end time.
        if (
            !_verifyTime(
                orderParameters.startTime,
                orderParameters.endTime,
                revertOnInvalid
            )
        ) {
            // Assuming an invalid time and no revert, return zeroed out values.
            return (bytes32(0), 0, 0);
        }

        // Read numerator and denominator from memory and place on the stack.
        uint256 numerator = uint256(advancedOrder.numerator);
        uint256 denominator = uint256(advancedOrder.denominator);

        // If the order is a contract order, return the generated order.
        if (orderParameters.orderType == OrderType.CONTRACT) {
            // Ensure that numerator and denominator are both equal to 1.
            if (numerator != 1 || denominator != 1) {
                revert BadFraction();
            }

            return
                _getGeneratedOrder(
                    orderParameters,
                    advancedOrder.extraData,
                    revertOnInvalid
                );
        }

        // Ensure that the supplied numerator and denominator are valid.  The
        // numerator should not exceed denominator and should not be zero.
        if (numerator > denominator || numerator == 0) {
            revert BadFraction();
        }

        // If attempting partial fill (n < d) check order type & ensure support.
        if (
            numerator < denominator &&
            _doesNotSupportPartialFills(orderParameters.orderType)
        ) {
            // Revert if partial fill was attempted on an unsupported order.
            revert PartialFillsNotEnabledForOrder();
        }

        // Retrieve current counter and use it w/ parameters to get order hash.
        orderHash = _assertConsiderationLengthAndGetOrderHash(orderParameters);

        // Retrieve the order status using the derived order hash.
        OrderStatus storage orderStatus = _orderStatus[orderHash];

        // Ensure order is fillable and is not cancelled.
        if (
            !_verifyOrderStatus(
                orderHash,
                orderStatus,
                false, // Allow partially used orders to be filled.
                revertOnInvalid
            )
        ) {
            // Assuming an invalid order status and no revert, return zero fill.
            return (orderHash, 0, 0);
        }

        // If the order is not already validated, verify the supplied signature.
        if (!orderStatus.isValidated) {
            _verifySignature(
                orderParameters.offerer,
                orderHash,
                advancedOrder.signature
            );
        }

        // Read filled amount as numerator and denominator and put on the stack.
        uint256 filledNumerator = uint256(orderStatus.numerator);
        uint256 filledDenominator = uint256(orderStatus.denominator);

        // If order currently has a non-zero denominator it is partially filled.
        if (filledDenominator != 0) {
            // If denominator of 1 supplied, fill all remaining amount on order.
            if (denominator == 1) {
                // Scale numerator & denominator to match current denominator.
                numerator = filledDenominator;
                denominator = filledDenominator;
            }
            // Otherwise, if supplied denominator differs from current one...
            else if (filledDenominator != denominator) {
                // scale current numerator by the supplied denominator, then...
                filledNumerator *= denominator;

                // the supplied numerator & denominator by current denominator.
                numerator *= filledDenominator;
                denominator *= filledDenominator;
            }

            // Once adjusted, if current+supplied numerator exceeds denominator:
            if (filledNumerator + numerator > denominator) {
                // Reduce current numerator so it + supplied = denominator.
                numerator = denominator - filledNumerator;
            }

            // Increment the filled numerator by the new numerator.
            filledNumerator += numerator;

            // Ensure fractional amounts are below max uint120.
            if (
                filledNumerator > type(uint120).max ||
                denominator > type(uint120).max
            ) {
                // Derive greatest common divisor using euclidean algorithm.
                uint256 scaleDown = _greatestCommonDivisor(
                    numerator,
                    _greatestCommonDivisor(filledNumerator, denominator)
                );

                // Scale all fractional values down by gcd.
                numerator = numerator / scaleDown;
                filledNumerator = filledNumerator / scaleDown;
                denominator = denominator / scaleDown;

                // Perform the overflow check a second time.
                uint256 maxOverhead = type(uint256).max - type(uint120).max;
                ((filledNumerator + maxOverhead) & (denominator + maxOverhead));
            }

            // Update order status and fill amount, packing struct values.
            orderStatus.isValidated = true;
            orderStatus.isCancelled = false;
            orderStatus.numerator = uint120(filledNumerator);
            orderStatus.denominator = uint120(denominator);
        } else {
            // Update order status and fill amount, packing struct values.
            orderStatus.isValidated = true;
            orderStatus.isCancelled = false;
            orderStatus.numerator = uint120(numerator);
            orderStatus.denominator = uint120(denominator);
        }

        // Return order hash, new numerator and denominator.
        return (orderHash, uint120(numerator), uint120(denominator));
    }
=======
    // function getNewOfferAndConsideration(
    //     AdvancedOrder memory advancedOrder,
    //     CriteriaResolver[] memory criteriaResolvers
    // )
    //     internal
    //     returns (SpentItem[] memory offer, SpentItem[] memory consideration)
    // {
    //     // Validate order, update status, and determine fraction to fill.
    //     (
    //         bytes32 orderHash,
    //         uint256 fillNumerator,
    //         uint256 fillDenominator
    //     ) = _validateOrderAndUpdateStatus(advancedOrder, true);

    //     // Apply criteria resolvers using generated orders and details arrays.
    //     _applyCriteriaResolversAdvanced(advancedOrder, criteriaResolvers);
    // }
>>>>>>> 4484662fcea89f66179aa1001fe48655c5a42e0b

    function previewOrder(
        address caller,
        address,
        SpentItem[] calldata,
        SpentItem[] calldata,
        bytes calldata context
    )
        external
        view
        override
        returns (SpentItem[] memory offer, ReceivedItem[] memory consideration)
    {}

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return bytes4(0xf23a6e61);
    }

    /**
     * @dev Returns the metadata for this contract offerer.
     */
    function getSeaportMetadata()
        external
        pure
        override
        returns (
            string memory name,
            Schema[] memory schemas // map to Seaport Improvement Proposal IDs
        )
    {
        schemas = new Schema[](1);
        schemas[0].id = 1337;
        schemas[0].metadata = new bytes(0);

        return ("FlinkCollectionContractOfferer", schemas);
    }
}
