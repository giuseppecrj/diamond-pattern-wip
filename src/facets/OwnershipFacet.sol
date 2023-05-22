// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// interfaces
import { IERC173 } from "../interfaces/IERC173.sol";

// libraries
import { LibDiamond } from "../libraries/LibDiamond.sol";

// contracts

contract OwnershipFacet is IERC173 {
  function transferOwnership(address _newOwner) external override {
    LibDiamond.enforceIsContractOwner();
    LibDiamond.setContractOwner(_newOwner);
  }

  function owner() external view override returns (address owner_) {
    owner_ = LibDiamond.contractOwner();
  }
}
