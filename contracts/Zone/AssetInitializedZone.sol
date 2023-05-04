// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ZoneParameters, Schema} from "./lib/ConsiderationStructs.sol";

import {ZoneInterface} from "./interfaces/ZoneInterface.sol";

contract TestZone is ZoneInterface {
    address immutable flinkCollection;

    constructor(address _flinkCollection) {
        flinkCollection = _flinkCollection;
    }

    // Called by Consideration whenever any extraData is provided by the caller.
    function validateOrder(
        ZoneParameters calldata
    ) external pure returns (bytes4 validOrderMagicValue) {
        return ZoneInterface.validateOrder.selector;
    }
}
