// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface CriteriaResolutionErrors {
    /**
     * @dev Revert with an error when providing a criteria resolver that
     *      contains an invalid proof with respect to the given item and
     *      chosen identifier.
     */
    error InvalidProof();
}
