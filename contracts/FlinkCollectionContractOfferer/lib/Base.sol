// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title ConsiderationBase
 * @author 0age
 * @notice ConsiderationBase contains all storage, constants, and constructor
 *         logic.
 */
contract Base {
    // Declare constants for name, version, and reentrancy sentinel values.
    string internal constant _NAME = "Base";
    string internal constant _VERSION = "1.1";

    // Precompute hashes, original chainId, and domain separator on deployment.
    bytes32 internal immutable _NAME_HASH;
    bytes32 internal immutable _VERSION_HASH;
    bytes32 internal immutable _EIP_712_DOMAIN_TYPEHASH;
    bytes32 internal immutable _OFFER_ITEM_TYPEHASH;
    bytes32 internal immutable _CONSIDERATION_ITEM_TYPEHASH;
    bytes32 internal immutable _ORDER_TYPEHASH;
    uint256 internal immutable _CHAIN_ID;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     */
    constructor() {
        // Derive name and version hashes alongside required EIP-712 typehashes.
        (
            _NAME_HASH,
            _VERSION_HASH,
            _EIP_712_DOMAIN_TYPEHASH,
            _OFFER_ITEM_TYPEHASH,
            _CONSIDERATION_ITEM_TYPEHASH,
            _ORDER_TYPEHASH,
            _DOMAIN_SEPARATOR
        ) = _deriveTypehashes();

        // Store the current chainId and derive the current domain separator.
        _CHAIN_ID = block.chainid;
    }

    /**
     * @dev Internal pure function to derive required EIP-712 typehashes and
     *      other hashes during contract creation.
     *
     * @return nameHash                  The hash of the name of the contract.
     * @return versionHash               The hash of the version string of the
     *                                   contract.
     * @return eip712DomainTypehash      The primary EIP-712 domain typehash.
     * @return offerItemTypehash         The EIP-712 typehash for OfferItem
     *                                   types.
     * @return considerationItemTypehash The EIP-712 typehash for
     *                                   ConsiderationItem types.
     * @return orderTypehash             The EIP-712 typehash for Order types.
     * @return domainSeparator           The domain separator.
     */
    function _deriveTypehashes()
        internal
        view
        returns (
            bytes32 nameHash,
            bytes32 versionHash,
            bytes32 eip712DomainTypehash,
            bytes32 offerItemTypehash,
            bytes32 considerationItemTypehash,
            bytes32 orderTypehash,
            bytes32 domainSeparator
        )
    {
        // Derive hash of the name of the contract.
        nameHash = keccak256(bytes(_NAME));

        // Derive hash of the version string of the contract.
        versionHash = keccak256(bytes(_VERSION));

        // Construct the OfferItem type string.
        bytes memory offerItemTypeString = abi.encodePacked(
            "OfferItem(",
            "uint8 itemType,",
            "address token,",
            "uint256 identifierOrCriteria,",
            "uint256 startAmount,",
            "uint256 endAmount",
            ")"
        );

        // Construct the ConsiderationItem type string.
        bytes memory considerationItemTypeString = abi.encodePacked(
            "ConsiderationItem(",
            "uint8 itemType,",
            "address token,",
            "uint256 identifierOrCriteria,",
            "uint256 startAmount,",
            "uint256 endAmount,",
            "address recipient",
            ")"
        );

        // Construct the OrderComponents type string, not including the above.
        bytes memory orderComponentsPartialTypeString = abi.encodePacked(
            "OrderComponents(",
            "address offerer,",
            "address zone,",
            "OfferItem[] offer,",
            "ConsiderationItem[] consideration,",
            "uint8 orderType,",
            "uint256 startTime,",
            "uint256 endTime,",
            "bytes32 zoneHash,",
            "uint256 salt,",
            "bytes32 conduitKey,",
            "uint256 counter",
            ")"
        );

        // Construct the primary EIP-712 domain type string.
        eip712DomainTypehash = keccak256(
            abi.encodePacked(
                "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );

        // Derive the OfferItem type hash using the corresponding type string.
        offerItemTypehash = keccak256(offerItemTypeString);

        // Derive ConsiderationItem type hash using corresponding type string.
        considerationItemTypehash = keccak256(considerationItemTypeString);

        // Derive OrderItem type hash via combination of relevant type strings.
        orderTypehash = keccak256(
            abi.encodePacked(
                orderComponentsPartialTypeString,
                considerationItemTypeString,
                offerItemTypeString
            )
        );

        // Derive the initial domain separator using the domain typehash, the
        // name hash, and the version hash.
        domainSeparator = _deriveInitialDomainSeparator(
            eip712DomainTypehash,
            nameHash,
            versionHash
        );
    }

    /**
     * @dev Internal view function to derive the initial EIP-712 domain
     *      separator.
     *
     * @param _eip712DomainTypeHash      The primary EIP-712 domain typehash.
     * @param _nameHash                  The hash of the name of the contract.
     * @param _versionHash               The hash of the version string of the
     *                                   contract.
     *
     * @return domainSeparator           The derived domain separator.
     */
    function _deriveInitialDomainSeparator(
        bytes32 _eip712DomainTypeHash,
        bytes32 _nameHash,
        bytes32 _versionHash
    ) internal view virtual returns (bytes32 domainSeparator) {
        return
            _deriveDomainSeparator(
                _eip712DomainTypeHash,
                _nameHash,
                _versionHash
            );
    }

    /**
     * @dev Internal view function to derive the EIP-712 domain separator.
     *
     * @return The derived domain separator.
     */
    function _deriveDomainSeparator(
        bytes32 _eip712DomainTypeHash,
        bytes32 _nameHash,
        bytes32 _versionHash
    ) internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _eip712DomainTypeHash,
                    _nameHash,
                    _versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }
}
