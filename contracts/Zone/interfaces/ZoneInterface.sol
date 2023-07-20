// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ZoneParameters, Schema} from "../lib/ConsiderationStructs.sol";

/**
 * @title  ZoneInterface
 * @notice Contains functions exposed by a zone.
 */
interface ZoneInterface {
    /**
     * @dev Validates an order.
     *
     * @param zoneParameters The context about the order fulfillment and any
     *                       supplied extraData.
     *
     * @return validOrderMagicValue The magic value that indicates a valid
     *                              order.
     */
    function validateOrder(
        ZoneParameters calldata zoneParameters
    ) external returns (bytes4 validOrderMagicValue);
}
