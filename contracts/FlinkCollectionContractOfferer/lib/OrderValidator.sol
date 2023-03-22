// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OrderType, ItemType} from "./ConsiderationEnums.sol";
import {Verifier} from "./Verifier.sol";
import {AdvancedOrder, OrderParametersWithTokenInitializeInfo, OrderComponentsWithTokenInitializeInfo, AdvancedOrderWithTokenInitializeInfo, ConsiderationItem, OfferItem, Order, OrderComponents, OrderParameters, OrderStatus, ReceivedItem, SpentItem} from "./ConsiderationStructs.sol";

/**
 * @title OrderValidator
 * @author 0age
 * @notice OrderValidator contains functionality related to validating orders
 *         and updating their status.
 */
contract OrderValidator is Verifier {
    // Track status of each order (validated, cancelled, and fraction filled).
    mapping(bytes32 => OrderStatus) private _orderStatus;

    /**
     * @dev Internal function to validate an order, determine what portion to
     *      fill, and update its status. The desired fill amount is supplied as
     *      a fraction, as is the returned amount to fill.
     *
     * @param advancedOrderWithTokenInitializeInfo The order to fulfill as well as the fraction to
     *                                             fill. Note that all offer and consideration
     *                                             amounts must divide with no remainder in order for
     *                                             a partial fill to be valid.
     * @param revertOnInvalid A boolean indicating whether to revert if the
     *                        order is invalid due to the time or order status.
     *
     * @return orderHash      The order hash.
     * @return newNumerator   A value indicating the portion of the order that
     *                        will be filled.
     * @return newDenominator A value indicating the total size of the order.
     */
    function _validateOrderAndUpdateStatus(
        AdvancedOrderWithTokenInitializeInfo
            memory advancedOrderWithTokenInitializeInfo,
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
        OrderParametersWithTokenInitializeInfo
            memory orderParametersWithTokenInitializeInfo = advancedOrderWithTokenInitializeInfo
                .orderParametersWithTokenInitializeInfo;

        // Ensure current timestamp falls between order start time and end time.
        if (
            !_verifyTime(
                orderParametersWithTokenInitializeInfo.startTime,
                orderParametersWithTokenInitializeInfo.endTime,
                revertOnInvalid
            )
        ) {
            // Assuming an invalid time and no revert, return zeroed out values.
            return (bytes32(0), 0, 0);
        }

        // Read numerator and denominator from memory and place on the stack.
        uint256 numerator = uint256(
            advancedOrderWithTokenInitializeInfo.numerator
        );
        uint256 denominator = uint256(
            advancedOrderWithTokenInitializeInfo.denominator
        );

        // Ensure that the supplied numerator and denominator are valid.  The
        // numerator should not exceed denominator and should not be zero.
        if (numerator > denominator || numerator == 0) {
            revert BadFraction();
        }

        // If attempting partial fill (n < d) check order type & ensure support.
        if (
            numerator < denominator &&
            _doesNotSupportPartialFills(
                orderParametersWithTokenInitializeInfo.orderType
            )
        ) {
            // Revert if partial fill was attempted on an unsupported order.
            revert PartialFillsNotEnabledForOrder();
        }

        // Retrieve current counter and use it w/ parameters to get order hash.
        orderHash = _assertConsiderationLengthAndGetOrderHash(
            orderParametersWithTokenInitializeInfo
        );

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
                orderParametersWithTokenInitializeInfo.offerer,
                orderHash,
                advancedOrderWithTokenInitializeInfo.signature
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

    /**
     * @dev Internal function to cancel an arbitrary number of orders. Note that
     *      only the offerer or the zone of a given order may cancel it. Callers
     *      should ensure that the intended order was cancelled by calling
     *      `getOrderStatus` and confirming that `isCancelled` returns `true`.
     *      Also note that contract orders are not cancellable.
     *
     * @param orders The orders to cancel.
     *
     * @return A boolean indicating whether the supplied orders were
     *         successfully cancelled.
     */
    function _cancel(
        OrderComponentsWithTokenInitializeInfo[] calldata orders
    ) internal returns (bool) {
        // Declare variables outside of the loop.
        OrderStatus storage orderStatus;
        address offerer;
        address zone;

        // Read length of the orders array from memory and place on stack.
        uint256 totalOrders = orders.length;

        // Iterate over each order.
        for (uint256 i = 0; i < totalOrders; ++i) {
            // Retrieve the order.
            OrderComponentsWithTokenInitializeInfo calldata order = orders[i];

            offerer = order.offerer;
            zone = order.zone;

            // Ensure caller is either offerer or zone of the order and that the
            // order is not a contract order.
            if (
                order.orderType == OrderType.CONTRACT ||
                (msg.sender != offerer && msg.sender != zone)
            ) {
                revert CannotCancelOrder();
            }

            // Derive order hash using the order parameters and the counter.
            bytes32 orderHash = _deriveOrderHash(
                OrderParametersWithTokenInitializeInfo(
                    offerer,
                    zone,
                    order.offer,
                    order.consideration,
                    order.orderType,
                    order.startTime,
                    order.endTime,
                    order.zoneHash,
                    order.salt,
                    order.conduitKey,
                    order.consideration.length,
                    order.tokenInitializeInfo
                ),
                order.counter
            );

            // Retrieve the order status using the derived order hash.
            orderStatus = _orderStatus[orderHash];

            // Update the order status as not valid and cancelled.
            orderStatus.isValidated = false;
            orderStatus.isCancelled = true;

            // Emit an event signifying that the order has been cancelled.
            emit OrderCancelled(orderHash, offerer, zone);
        }

        return true;
    }

    /**
     * @dev Internal view function to retrieve the status of a given order by
     *      hash, including whether the order has been cancelled or validated
     *      and the fraction of the order that has been filled.
     *
     * @param orderHash The order hash in question.
     *
     * @return isValidated A boolean indicating whether the order in question
     *                     has been validated (i.e. previously approved or
     *                     partially filled).
     * @return isCancelled A boolean indicating whether the order in question
     *                     has been cancelled.
     * @return totalFilled The total portion of the order that has been filled
     *                     (i.e. the "numerator").
     * @return totalSize   The total size of the order that is either filled or
     *                     unfilled (i.e. the "denominator").
     */
    function _getOrderStatus(
        bytes32 orderHash
    )
        internal
        view
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        )
    {
        // Retrieve the order status using the order hash.
        OrderStatus storage orderStatus = _orderStatus[orderHash];

        // Return the fields on the order status.
        return (
            orderStatus.isValidated,
            orderStatus.isCancelled,
            orderStatus.numerator,
            orderStatus.denominator
        );
    }

    /**
     * @dev Internal function to derive the greatest common divisor of two
     *      values using the classical euclidian algorithm.
     *
     * @param a The first value.
     * @param b The second value.
     *
     * @return greatestCommonDivisor The greatest common divisor.
     */
    function _greatestCommonDivisor(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256 greatestCommonDivisor) {
        while (b > 0) {
            uint256 c = b;
            b = a % c;
            a = c;
        }

        greatestCommonDivisor = a;
    }

    /**
     * @dev Internal pure function to check whether a given order type indicates
     *      that partial fills are not supported (e.g. only "full fills" are
     *      allowed for the order in question).
     *
     * @param orderType The order type in question.
     *
     * @return isFullOrder A boolean indicating whether the order type only
     *                     supports full fills.
     */
    function _doesNotSupportPartialFills(
        OrderType orderType
    ) internal pure returns (bool isFullOrder) {
        // The "full" order types are even, while "partial" order types are odd.
        isFullOrder = uint256(orderType) & 1 == 0;
    }
}
