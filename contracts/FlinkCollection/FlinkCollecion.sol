// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./AssetContractUpgradeable.sol";
import "./TokenIdentifiers.sol";
import "./BaseErrors.sol";
import "./interfaces/TokenInfoValidityCheck.sol";
import "./BaseStruct.sol";
import "./BaseEvents.sol";
import "./lib/BytesLib.sol";

contract FlinkCollection is
    AssetContractUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    BaseErrors,
    BaseEvents
{
    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );
    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH =
        0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    mapping(uint256 => address) tokenInfoValidityChecker;

    mapping(address => bool) public sharedProxyAddresses;

    mapping(uint256 => TokenInfo) public tokenInfo;

    mapping(bytes => SignatureStatus) signatureStatus;

    mapping(uint256 => address) internal _creatorOverride;

    mapping(uint256 => address) internal versionInfoDecoder;

    using TokenIdentifiers for uint256;

    /**
     * @dev Require msg.sender to be the creator of the token id
     */
    modifier creatorOnly(uint256 _id) {
        require(_isCreatorOrProxy(_id, _msgSender()), "FLK 100");
        _;
    }

    /**
     * @dev Require the caller to own the full supply of the token
     */
    modifier onlyFullTokenOwner(uint256 _id) {
        require(
            _ownsTokenAmount(_msgSender(), _id, _id.tokenMaxSupply()),
            "FLK 101"
        );
        _;
    }

    /**
     * @dev Require the caller to own the full supply of the token
     */
    modifier onlyFullTokenOwnerOrNotInitialized(uint256 _id) {
        require(ownFullTokenOrNotInitialized(_msgSender(), _id), "FLK 102");
        _;
    }

    function ownFullTokenOrNotInitialized(
        address _user,
        uint256 _tokenId
    ) private view returns (bool) {
        return
            _ownsTokenAmount(_user, _tokenId, _tokenId.tokenMaxSupply()) ||
            ((!tokenUriSetted(_tokenId)) && (!checkTokenInitialized(_tokenId)));
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory _baseURI
    ) public initializer {
        __AssetContract_init(_name, _symbol, _proxyRegistryAddress, _baseURI);
        __UUPSUpgradeable_init();
    }

    /**
     * @dev Allows owner to change the proxy registry
     */
    function setProxyRegistryAddress(address _address) public onlyOwnerOrProxy {
        proxyRegistryAddress = _address;
    }

    /**
     * @dev Allows owner to add a shared proxy address
     */
    function addSharedProxyAddress(address _address) public onlyOwnerOrProxy {
        sharedProxyAddresses[_address] = true;
    }

    /**
     * @dev Allows owner to remove a shared proxy address
     */
    function removeSharedProxyAddress(
        address _address
    ) public onlyOwnerOrProxy {
        delete sharedProxyAddresses[_address];
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public override nonReentrant creatorOnly(_id) {
        _mint(_to, _id, _quantity, _data);
    }

    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public override nonReentrant {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(_isCreatorOrProxy(_ids[i], _msgSender()), "FLK 100");
        }
        _batchMint(_to, _ids, _quantities, _data);
    }

    /////////////////////////////////
    // CONVENIENCE CREATOR METHODS //
    /////////////////////////////////

    /**
     * @dev Will update the URI for the token
     * @param _id The token ID to update. msg.sender must be its creator, the uri must be impermanent,
     *            and the creator must own all of the token supply
     * @param _uri New URI for the token.
     */
    function setURI(
        uint256 _id,
        string memory _uri
    )
        public
        override
        creatorOnly(_id)
        onlyImpermanentURI(_id)
        onlyFullTokenOwnerOrNotInitialized(_id)
    {
        _setURI(_id, _uri);
    }

    /**
     * @dev setURI, but permanent
     */
    function setPermanentURI(
        uint256 _id,
        string memory _uri
    )
        public
        override
        creatorOnly(_id)
        onlyImpermanentURI(_id)
        onlyFullTokenOwnerOrNotInitialized(_id)
    {
        _setPermanentURI(_id, _uri);
    }

    /**
     * @dev Change the creator address for given token
     * @param _to   Address of the new creator
     * @param _id  Token IDs to change creator of
     */
    function setCreator(uint256 _id, address _to) public creatorOnly(_id) {
        require(_to != address(0), "FLK 103");
        _creatorOverride[_id] = _to;
        emit CreatorChanged(_id, _to);
    }

    /**
     * @dev Get the creator for a token
     * @param _id   The token id to look up
     */
    function creator(uint256 _id) public view returns (address) {
        if (_creatorOverride[_id] != address(0)) {
            return _creatorOverride[_id];
        } else {
            return _id.tokenCreator();
        }
    }

    /**
     * @dev Get the maximum supply for a token
     * @param _id   The token id to look up
     */
    function maxSupply(uint256 _id) public pure returns (uint256) {
        return _id.tokenMaxSupply();
    }

    // Override ERC1155Tradable for birth events
    function _origin(uint256 _id) internal pure override returns (address) {
        return _id.tokenCreator();
    }

    function _requireMintable(address _address, uint256 _id) internal view {
        require(_isCreatorOrProxy(_id, _address), "FLK 100");
    }

    function _remainingSupply(
        uint256 _id
    ) internal view override returns (uint256) {
        return maxSupply(_id) - totalSupply(_id);
    }

    function _isCreatorOrProxy(
        uint256 _id,
        address _address
    ) internal view override returns (bool) {
        address creator_ = creator(_id);
        return creator_ == _address || _isProxyForUser(creator_, _address);
    }

    // Overrides ERC1155Tradable to allow a shared proxy address
    function _isProxyForUser(
        address _user,
        address _address
    ) internal view override returns (bool) {
        if (sharedProxyAddresses[_address]) {
            return true;
        }
        return super._isProxyForUser(_user, _address);
    }

    function checkTokenInitialized(uint256 tokenId) public view returns (bool) {
        return tokenInfo[tokenId].initialized;
    }

    // get batch token's info
    function getBatchTokenInfo(
        uint256[] memory tokenIdLs
    ) public view returns (TokenInfo[] memory, string[] memory) {
        TokenInfo[] memory tokenInfoLs = new TokenInfo[](tokenIdLs.length);
        string[] memory uriLs = new string[](tokenIdLs.length);

        for (uint256 i = 0; i < tokenIdLs.length; i++) {
            tokenInfoLs[i] = tokenInfo[tokenIdLs[i]];
            uriLs[i] = uri(tokenIdLs[i]);
        }

        return (tokenInfoLs, uriLs);
    }

    function initializeTokenInfoPermit(
        TokenInitializationInfo memory tokenInitializationInfo
    ) public returns (bool) {
        uint256 tokenId = tokenInitializationInfo.tokenId;

        require(!checkTokenInitialized(tokenId), "FLK 104");

        require(
            signatureValidity(tokenInitializationInfo.signature),
            "FLK 105"
        );

        // check token info validity
        if (
            tokenInfoValidityChecker[tokenInitializationInfo.version] !=
            address(0)
        ) {
            bool passValidityCheck = TokenInfoValidityCheck(
                tokenInfoValidityChecker[tokenInitializationInfo.version]
            ).checkTokenInfoValidity(
                    tokenInitializationInfo.version,
                    tokenInitializationInfo.data
                );
            require(passValidityCheck, "FLK 106");
        }

        // recover signer
        address signer = recoverSigner(tokenInitializationInfo);

        // signer should be the creator of the tokenId
        require(signer == creator(tokenId), "FLK 107");

        // creator should own the total amount of token, or the token hasn't been initialized
        require(ownFullTokenOrNotInitialized(signer, tokenId), "FLK 102");

        // if creator assigns tokenUri, then set tokenUri
        if (bytes(tokenInitializationInfo.tokenUri).length > 0) {
            require(!isPermanentURI(tokenId), "FLK 108");
            _setURI(tokenId, string(tokenInitializationInfo.tokenUri));
        }

        // set tokenInfo
        tokenInfo[tokenId] = TokenInfo(
            tokenInitializationInfo.version,
            tokenInitializationInfo.data,
            true
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

    function setTokenInfoValidityCheckAddress(
        uint256 version,
        address _tokenInfoValidityCheckAddress
    ) public onlyOwner {
        tokenInfoValidityChecker[version] = _tokenInfoValidityCheckAddress;

        emit TokenInfoValidityCheckerChanged(
            version,
            _tokenInfoValidityCheckAddress
        );
    }

    function setTokenInfoDecoderAddress(
        uint256 version,
        address _tokenDataDecoder
    ) public onlyOwner {
        require(versionInfoDecoder[version] == address(0), "FLK 111");
        versionInfoDecoder[version] = _tokenDataDecoder;
        emit TokenDataDecoderChanged(version, _tokenDataDecoder);
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
                DOMAIN_SEPARATOR_TYPEHASH,
                tokenInitializationInfo.tokenId,
                tokenInitializationInfo.version,
                tokenInitializationInfo.data,
                tokenInitializationInfo.tokenUri,
                tokenInitializationInfo.nonce
            )
        );

        bytes32 dataHash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                domainSeparator(),
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

    function domainSeparator() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), this)
            );
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
