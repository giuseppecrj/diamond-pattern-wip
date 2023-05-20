// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// interfaces
import { IDiamond } from "./IDiamond.sol";

// libraries

// contracts

interface IDiamondCut is IDiamond {
  /// @notice Add/replace/remove any number of functions and and optionally execute a function with a delegatecall
  /// @param _diamondCut Contains the facet addresses and function selectors
  /// @param _init The address of the contract or facet to execute _calldata
  /// @param _calldata A function call, including function selector and arguments
  function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}
