// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

//interfaces
import { IDiamond } from "../src/interfaces/IDiamond.sol";
import { IDiamondCut } from "../src/interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../src/interfaces/IDiamondLoupe.sol";

//libraries
import { console } from "forge-std/console.sol";

//contracts
import { TestUtils } from "./TestUtils.sol";

import { DiamondCutFacet } from "../src/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../src/facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "../src/facets/OwnershipFacet.sol";
import { Diamond, DiamondArgs } from "../src/Diamond.sol";
import { DiamondInit } from "../src/upgradeInitializer/DiamondInit.sol";

// test contract
import { Test1Facet } from "../src/facets/Test1Facet.sol";

contract DiamondTest is TestUtils {
  Diamond diamond;
  DiamondCutFacet diamondCutFacet;
  DiamondLoupeFacet diamondLoupeFacet;
  OwnershipFacet ownershipFacet;
  DiamondInit diamondInit;

  // interfaces with Facet ABI connected to diamond address
  IDiamondCut diamondCut;
  IDiamondLoupe diamondLoupe;

  string[] facetNames;
  address[] facetAddressList;

  function setUp() external {
    // deploy facet implementations
    diamondCutFacet = new DiamondCutFacet();
    diamondLoupeFacet = new DiamondLoupeFacet();
    ownershipFacet = new OwnershipFacet();
    facetNames = ["DiamondCutFacet", "DiamondLoupeFacet", "OwnershipFacet"];

    // init
    diamondInit = new DiamondInit();

    // diamond args
    DiamondArgs memory _args = DiamondArgs({
      owner: address(this),
      init: address(diamondInit),
      initCalldata: abi.encodeCall(DiamondInit.init, ())
    });

    // FacetCut with CutFacet for initialization
    FacetCut[] memory cut0 = new FacetCut[](1);

    cut0[0] = FacetCut({
      facetAddress: address(diamondCutFacet),
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: generateSelectors("DiamondCutFacet")
    });

    diamond = new Diamond(cut0, _args);

    FacetCut[] memory cut = new FacetCut[](2);

    cut[0] = FacetCut({
      facetAddress: address(diamondLoupeFacet),
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: generateSelectors("DiamondLoupeFacet")
    });

    cut[1] = FacetCut({
      facetAddress: address(ownershipFacet),
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: generateSelectors("OwnershipFacet")
    });

    // initialize interfaces with the diamond address
    // because it is both a diamond loupe and diamond cut
    diamondCut = IDiamondCut(address(diamond));
    diamondLoupe = IDiamondLoupe(address(diamond));

    // upgrade the diamond with the new facets
    diamondCut.diamondCut(cut, address(0), "");

    // get facet addresses
    facetAddressList = diamondLoupe.facetAddresses();
  }

  function test_facetsHaveCorrectSelectors() external {
    for (uint256 i = 0; i < facetAddressList.length; i++) {
      bytes4[] memory fromLoupeFacet = diamondLoupe.facetFunctionSelectors(facetAddressList[i]);
      bytes4[] memory fromGenSelectors = generateSelectors(facetNames[i]);
      assertTrue(sameMembers(fromLoupeFacet, fromGenSelectors));
    }
  }

  function test_selectorsAssociatedWithCorrectFacet() external {
    for (uint256 i = 0; i < facetAddressList.length; i++) {
      bytes4[] memory fromGenSelectors = generateSelectors(facetNames[i]);

      for (uint256 j = 0; j < fromGenSelectors.length; j++) {
        assertEq(facetAddressList[i], diamondLoupe.facetAddress(fromGenSelectors[j]));
      }
    }
  }

  function test_checkOwner() external {
    OwnershipFacet _ownershipFacet = OwnershipFacet(address(diamond));
    assertEq(address(this), _ownershipFacet.owner());
  }

  function testAddFacet1() external {
    Test1Facet test1Facet = new Test1Facet();

    // get function selectors but remove first element (supportsInterface)
    bytes4[] memory fromGenSelectors = removeElement(uint256(0), generateSelectors("Test1Facet"));

    // array of functions to add
    FacetCut[] memory cut = new FacetCut[](1);
    cut[0] = FacetCut({
      facetAddress: address(test1Facet),
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: fromGenSelectors
    });

    diamondCut.diamondCut(cut, address(0x0), "");

    // call function on diamond
    Test1Facet(address(diamond)).test1Func1();
    Test1Facet(address(diamond)).test1Func2();
  }
}
