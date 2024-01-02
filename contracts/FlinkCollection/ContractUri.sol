// contracts/FLK.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ContractUri {
    string private contractLevelURI;

    function contractURI() public view returns (string memory) {
        return contractLevelURI;
    }

    function _setContractURI(string memory _contractLevelURI) internal virtual {
        contractLevelURI = _contractLevelURI;
    }
}
