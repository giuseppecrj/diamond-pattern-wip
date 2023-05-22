// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// interfaces
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

// libraries

// contracts

contract DiamondCutFacet is IDiamondCut {
  /// @notice add/replace/remove any number of functions and optionally execute a function with delegatecall
  /// @param _diamondCut array of diamond cut instructions
  /// @param _init The address of the contract or facet to execute _calldata
  /// @param _calldata A function call, including function selector and arguments
  ///          _calldata is executed with delegatecall on _init
  function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {
    LibDiamond.enforceIsContractOwner();
    LibDiamond.diamondCut(_diamondCut, _init, _calldata);
  }
}
