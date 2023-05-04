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
