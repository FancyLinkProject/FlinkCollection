// contracts/FLK.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./common/meta-transactions/ContextMixin.sol";
import "./ERC1155SupplyUriUpgradeable.sol";
import "./BaseErrors.sol";
import "./FlinkCollectionBaseStruct.sol";
import "./BaseEvents.sol";
import "./lib/BytesLib.sol";
import "./ProxyRegistry.sol";
import "./ContractUri.sol";
import "./interfaces/Zone.sol";
import "./common/meta-transactions/EIP712Base.sol";

contract FancyLinkCollection is
    ERC1155SupplyUriUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    BaseErrors,
    BaseEvents,
    ContextMixin,
    ContractUri,
    EIP712Base
{
    address public admin;

    // Proxy registry address
    address public proxyRegistryAddress;

    mapping(address => bool) public sharedProxyAddresses;

    mapping(uint => TokenInfo) public tokenInfo;

    mapping(bytes => SignatureStatus) public signatureStatus;

    mapping(uint => address) private _creatorOverride;

    mapping(uint => mapping(uint => address)) public infoResolver;

    modifier onlyAdmin() {
        require(admin == msg.sender, "FLK: Only Admin");
        _;
    }

    /**
     * @dev Require msg.sender to be the creator of the token id
     */
    modifier creatorOnly(uint256 _id) {
        require(_isCreatorOrProxy(_id, _msgSender()), "FLK 100");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata name,
        address _proxyRegistryAddress
    ) public initializer {
        __ERC1155_init("");
        __ERC1155Supply_init();
        __ERC1155URIStorage_init();
        __Pausable_init_unchained();
        _initializeEIP712(name);
        admin = msg.sender;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function _isCreatorOrProxy(
        uint256 _id,
        address _address
    ) internal returns (bool) {
        address creator_ = tokenInfo[_id].author;
        require(
            creator_ != address(0),
            "FancyLinkCollection#_isCreatorOrProxy:invalid author"
        );
        return creator_ == _address || _isProxyForUser(creator_, _address);
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "FLK: invalid new admin");
        admin = _newAdmin;
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unPause() external onlyAdmin {
        _unpause();
    }

    function mint(
        address receiver,
        uint256 tokenId,
        uint256 value
    ) public onlyAdmin whenNotPaused {
        _mint(receiver, tokenId, value, "");
    }

    /**
     * @dev Set base URI
     */
    function setBaseURI(string memory _baseURI) public onlyAdmin {
        _setBaseURI(_baseURI);
    }

    /**
     * @dev Set specific token's URI
     */
    function setUri(
        uint256 _tokenId,
        string memory _tokenURI
    ) public onlyAdmin {
        _setURI(_tokenId, _tokenURI);
    }

    function setContractURI(
        string memory _contractLevelURI
    ) external onlyAdmin {
        _setContractURI(_contractLevelURI);
    }

    /**
     * @dev Allows owner to change the proxy registry
     */
    function setProxyRegistryAddress(address _address) public onlyAdmin {
        proxyRegistryAddress = _address;
    }

    /**
     * @dev Allows owner to add a shared proxy address
     */
    function updateSharedProxyAddress(
        address _address,
        bool _addr
    ) public onlyAdmin {
        sharedProxyAddresses[_address] = _addr;
    }

    function tokenIdConstruct(
        address author,
        bytes32 contentDigest,
        uint parentId,
        uint supply
    ) public view returns (uint) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        author,
                        contentDigest,
                        getChainId(),
                        address(this),
                        parentId,
                        supply
                    )
                )
            );
    }

    function checkTokenInitialized(uint256 tokenId) public view returns (bool) {
        return tokenInfo[tokenId].initialized;
    }

    function initializeTokenInfoPermit(
        TokenInitializationInfo memory tokenInitializationInfo
    ) public nonReentrant returns (bool) {
        uint256 tokenId = tokenIdConstruct(
            tokenInitializationInfo.author,
            tokenInitializationInfo.contentDigest,
            tokenInitializationInfo.parentId,
            tokenInitializationInfo.supply
        );

        require(!checkTokenInitialized(tokenId), "FLK 104");

        require(
            signatureValidity(tokenInitializationInfo.signature),
            "FLK 105"
        );

        // recover signer
        address signer = recoverSigner(tokenInitializationInfo);

        // signer should be the creator of the tokenId
        require(signer == tokenInitializationInfo.author, "FLK 107");

        address zone = tokenInitializationInfo.zone;
        if (zone != address(0)) {
            bool success = Zone(zone).beforeInitialize(tokenInitializationInfo);
            require(
                success,
                "FancyLinkCollection#initializeTokenInfoPermit:fail beforeInitialize"
            );
        }

        _mint(
            tokenInitializationInfo.author,
            tokenId,
            tokenInitializationInfo.supply,
            ""
        );

        // if creator assigns tokenUri, then set tokenUri
        if (bytes(tokenInitializationInfo.tokenUri).length > 0) {
            _setURI(tokenId, string(tokenInitializationInfo.tokenUri));
        }

        // set tokenInfo
        tokenInfo[tokenId] = TokenInfo(
            tokenInitializationInfo.author,
            tokenInitializationInfo.contentDigest,
            tokenInitializationInfo.parentId,
            tokenInitializationInfo.supply,
            tokenInitializationInfo.kind,
            tokenInitializationInfo.version,
            tokenInitializationInfo.extraData,
            true
        );

        emit TokenInfoInitialization(
            tokenId,
            tokenInitializationInfo.author,
            tokenInitializationInfo.contentDigest,
            tokenInitializationInfo.parentId,
            tokenInitializationInfo.supply,
            tokenInitializationInfo.kind,
            tokenInitializationInfo.version,
            tokenInitializationInfo.extraData
        );

        signatureStatus[tokenInitializationInfo.signature].used = true;

        return true;
    }

    function signatureValidity(
        bytes memory signature
    ) public view returns (bool) {
        return
            signatureStatus[signature].used == false &&
            signatureStatus[signature].cancelled == false;
    }

    function cancelTokenInfoSignature(
        bytes memory data
    ) external returns (bool) {
        TokenInitializationInfo memory tokenInitializationInfo = abi.decode(
            data,
            (TokenInitializationInfo)
        );

        require(
            signatureValidity(tokenInitializationInfo.signature),
            "FLK 109"
        );

        // recover signer
        address signer = recoverSigner(tokenInitializationInfo);

        require(signer == msg.sender, "FLK 110");

        signatureStatus[tokenInitializationInfo.signature].cancelled = true;

        return true;
    }

    function setTokenInfoDecoderAddress(
        uint256 _kind,
        uint256 _version,
        address _resolver
    ) public onlyAdmin {
        infoResolver[_kind][_version] = _resolver;
        emit InfoResolverChanged(_kind, _version, _resolver);
    }

    function recoverSigner(
        TokenInitializationInfo memory tokenInitializationInfo
    ) internal view returns (address) {
        // Declare r, s, and v signature parameters.
        bytes32 r;
        bytes32 s;
        uint8 v;

        bytes32 msgHash = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                tokenInitializationInfo.author,
                tokenInitializationInfo.contentDigest,
                tokenInitializationInfo.parentId,
                tokenInitializationInfo.supply,
                tokenInitializationInfo.kind,
                tokenInitializationInfo.version,
                tokenInitializationInfo.zone,
                tokenInitializationInfo.extraData,
                tokenInitializationInfo.tokenUri,
                tokenInitializationInfo.nonce
            )
        );

        bytes32 dataHash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                getDomainSeperator(),
                msgHash
            )
        );

        bytes32 sigHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)
        );

        if (tokenInitializationInfo.signature.length == 65) {
            (r, s) = abi.decode(
                tokenInitializationInfo.signature,
                (bytes32, bytes32)
            );
            v = uint8(tokenInitializationInfo.signature[64]);

            // Ensure v value is properly formatted.
            if (v != 27 && v != 28) {
                revert BadSignature();
            }
        } else {
            revert BadSignature();
        }

        address signer = ecrecover(sigHash, v, r, s);

        return signer;
    }

    function isContract(address _addr) private returns (bool _isContract) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function _isProxyForUser(
        address _user,
        address _address
    ) internal virtual returns (bool) {
        if (sharedProxyAddresses[_address]) {
            return true;
        }

        if (!isContract(proxyRegistryAddress)) {
            return false;
        }
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        return address(proxyRegistry.proxies(_user)) == _address;
    }
}
