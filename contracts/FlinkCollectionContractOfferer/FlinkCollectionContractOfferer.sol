// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20Interface, ERC721Interface, ERC1155Interface} from "./interfaces/AbridgedTokenInterfaces.sol";

import {ContractOffererInterface} from "./interfaces/ContractOffererInterface.sol";

import {ItemType} from "./lib/ConsiderationEnums.sol";

import {ReceivedItem, Schema, SpentItem} from "./lib/ConsiderationStructs.sol";

/**
 * @title FlinkCollectionContractOfferer
 * @author 0age
 * @notice FlinkCollectionContractOfferer is a maximally simple contract offerer. It offers
 *         a single item and expects to receive back another single item, and
 *         ignores all parameters supplied to it when previewing or generating
 *         an order. The offered item is placed into this contract as part of
 *         deployment and the corresponding token approvals are set for Seaport.
 */
abstract contract FlinkCollectionContractOfferer is ContractOffererInterface {
    error OrderUnavailable();

    address public immutable _SEAPORT;
    address public immutable _FLINKCOLLECTION;

    enum Side {
        list,
        offer
    }

    struct ContextData {
        address receiver;
        Side side;
        bytes[] uri;
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
        // decode context
        ContextData memory contextData = abi.decode(context, (ContextData));

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
    }

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

        return ("TestContractOfferer", schemas);
    }
}
