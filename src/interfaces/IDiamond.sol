// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// interfaces

// libraries

// contracts

interface IDiamond {
  enum FacetCutAction {
    Add,
    Replace,
    Remove
  }

  struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
  }

  event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}
