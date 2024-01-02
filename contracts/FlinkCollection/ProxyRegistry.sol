// contracts/ProxyRegistry.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
