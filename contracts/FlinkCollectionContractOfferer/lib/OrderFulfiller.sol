// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ItemType, OrderType} from "./ConsiderationEnums.sol";
import {EventsAndErrors} from "../interfaces/EventsAndErrors.sol";
import {AccumulatorStruct, FractionData, OrderToExecute, OrderParametersWithTokenInitializeInfo, SpentItem, OfferItem, ReceivedItem, ConsiderationItem} from "./ConsiderationStructs.sol";
import {AmountDeriver} from "./AmountDeriver.sol";

/**
 * @title OrderFulfiller
 * @author 0age
 * @notice OrderFulfiller contains logic related to order fulfillment.
 */
contract OrderFulfiller is EventsAndErrors, AmountDeriver {
    /**
     * @dev applying a respective fraction to the amount
     *      being transferred.
     *
     * @param orderParameters     The parameters for the fulfilled order.
     * @param numerator           A value indicating the portion of the order
     *                            that should be filled.
     * @param denominator         A value indicating the total order size.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used (and direct approvals set on
     *                            Consideration).
     * @param recipient           The intended recipient for all received items.
     * @return spentItems         Returns the order of items that are being
     *                            transferred. This will be used for the
     *                            OrderFulfilled Event.
     * @return receivedItems      Returns the order of items that are being
     *                            received. This will be used for the
     *                            OrderFulfilled Event.
     *
     */
    function _applyFractions(
        OrderParametersWithTokenInitializeInfo memory orderParameters,
        uint256 numerator,
        uint256 denominator,
        bytes32 fulfillerConduitKey,
        address recipient
    )
        internal
        view
        returns (
            SpentItem[] memory spentItems,
            ReceivedItem[] memory receivedItems
        )
    {
        // Derive order duration, time elapsed, and time remaining.
        // Store in memory to avoid stack too deep issues.
        FractionData memory fractionData = FractionData(
            numerator,
            denominator,
            fulfillerConduitKey,
            orderParameters.startTime,
            orderParameters.endTime
        );

        // Create the array to store the spent items for event.
        spentItems = new SpentItem[](orderParameters.offer.length);

        // Declare a nested scope to minimize stack depth.
        {
            // Iterate over each offer on the order.
            for (uint256 i = 0; i < orderParameters.offer.length; ++i) {
                // Retrieve the offer item.
                OfferItem memory offerItem = orderParameters.offer[i];

                // Offer items for the native token can not be received outside
                // of a match order function except as part of a contract order.
                if (
                    offerItem.itemType == ItemType.NATIVE &&
                    orderParameters.orderType != OrderType.CONTRACT
                ) {
                    revert InvalidNativeOfferItem();
                }

                // Apply fill fraction to derive offer item amount to transfer.
                uint256 amount = _applyFraction(
                    offerItem.startAmount,
                    offerItem.endAmount,
                    fractionData,
                    false
                );

                // Create Received Item from Offer Item for transfer.
                ReceivedItem memory receivedItem = ReceivedItem(
                    offerItem.itemType,
                    offerItem.token,
                    offerItem.identifierOrCriteria,
                    amount,
                    payable(recipient)
                );

                // Create Spent Item for the OrderFulfilled event.
                spentItems[i] = SpentItem(
                    receivedItem.itemType,
                    receivedItem.token,
                    receivedItem.identifier,
                    amount
                );
            }
        }

        // Create the array to store the received items for event.
        receivedItems = new ReceivedItem[](
            orderParameters.consideration.length
        );

        // Declare a nested scope to minimize stack depth.
        {
            // Iterate over each consideration on the order.
            for (uint256 i = 0; i < orderParameters.consideration.length; ++i) {
                // Retrieve the consideration item.
                ConsiderationItem memory considerationItem = (
                    orderParameters.consideration[i]
                );

                // Apply fraction & derive considerationItem amount to transfer.
                uint256 amount = _applyFraction(
                    considerationItem.startAmount,
                    considerationItem.endAmount,
                    fractionData,
                    true
                );

                // Create Received Item from Offer item.
                ReceivedItem memory receivedItem = ReceivedItem(
                    considerationItem.itemType,
                    considerationItem.token,
                    considerationItem.identifierOrCriteria,
                    amount,
                    considerationItem.recipient
                );
                // Add ReceivedItem to structs array.
                receivedItems[i] = receivedItem;
            }
        }

        // Return the order to execute.
        return (spentItems, receivedItems);
    }
}
