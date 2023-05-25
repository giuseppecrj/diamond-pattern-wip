// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/libraries/strings.sol";
import "../src/interfaces/IDiamond.sol";
import "../src/interfaces/IDiamondLoupe.sol";

contract TestUtils is IDiamond, IDiamondLoupe, Test {
  using strings for *;

  uint256 private immutable _nonce;

  address public constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  modifier onlyForked() {
    if (block.number > 1e6) {
      _;
    }
  }

  constructor() {
    vm.setEnv("TESTING", "true");
    _nonce = uint256(
      keccak256(abi.encode(tx.origin, tx.origin.balance, block.number, block.timestamp, block.coinbase, gasleft()))
    );
  }

  function _bytes32ToString(bytes32 str) internal pure returns (string memory) {
    return string(abi.encodePacked(str));
  }

  function _randomBytes32() internal view returns (bytes32) {
    bytes memory seed = abi.encode(_nonce, block.timestamp, gasleft());
    return keccak256(seed);
  }

  function _randomUint256() internal view returns (uint256) {
    return uint256(_randomBytes32());
  }

  function _randomAddress() internal view returns (address payable) {
    return payable(address(uint160(_randomUint256())));
  }

  function _randomRange(uint256 lo, uint256 hi) internal view returns (uint256) {
    return lo + (_randomUint256() % (hi - lo));
  }

  function _toAddressArray(address v) internal pure returns (address[] memory arr) {
    arr = new address[](1);
    arr[0] = v;
  }

  function _toUint256Array(uint256 v) internal pure returns (uint256[] memory arr) {
    arr = new uint256[](1);
    arr[0] = v;
  }

  function _expectNonIndexedEmit() internal {
    vm.expectEmit(false, false, false, true);
  }

  function _isEqual(string memory s1, string memory s2) public pure returns (bool) {
    return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
  }

  function _isEqual(bytes32 s1, bytes32 s2) public pure returns (bool) {
    return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
  }

  function _createAccounts(uint256 amount) internal view returns (address[] memory) {
    address[] memory accounts = new address[](amount);

    for (uint256 i = 0; i < amount; i++) {
      accounts[i] = _randomAddress();
    }

    return accounts;
  }

  // ===============
  // Diamond Helpers
  // ===============

  // return array of function selectors for given facet name
  function generateSelectors(string memory _facetName) internal returns (bytes4[] memory selectors) {
    //get string of contract methods
    string[] memory cmd = new string[](4);
    cmd[0] = "forge";
    cmd[1] = "inspect";
    cmd[2] = _facetName;
    cmd[3] = "methods";
    bytes memory res = vm.ffi(cmd);
    string memory st = string(res);

    // extract function signatures and take first 4 bytes of keccak
    strings.slice memory s = st.toSlice();

    // Skip TRACE lines if any
    strings.slice memory nl = "\n".toSlice();
    strings.slice memory trace = "TRACE".toSlice();
    while (s.contains(trace)) {
      s.split(nl);
    }

    strings.slice memory colon = ":".toSlice();
    strings.slice memory comma = ",".toSlice();
    strings.slice memory dbquote = '"'.toSlice();
    selectors = new bytes4[]((s.count(colon)));

    for (uint256 i = 0; i < selectors.length; i++) {
      s.split(dbquote); // advance to next doublequote
      // split at colon, extract string up to next doublequote for methodname
      strings.slice memory method = s.split(colon).until(dbquote);
      selectors[i] = bytes4(method.keccak());
      s.split(comma).until(dbquote); // advance s to the next comma
    }
    return selectors;
  }

  // helper to remove index from bytes4[] array
  function removeElement(uint256 index, bytes4[] memory array) public pure returns (bytes4[] memory) {
    bytes4[] memory newarray = new bytes4[](array.length-1);
    uint256 j = 0;
    for (uint256 i = 0; i < array.length; i++) {
      if (i != index) {
        newarray[j] = array[i];
        j += 1;
      }
    }
    return newarray;
  }

  // helper to remove value from bytes4[] array
  function removeElement(bytes4 el, bytes4[] memory array) public pure returns (bytes4[] memory) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == el) {
        return removeElement(i, array);
      }
    }
    return array;
  }

  function containsElement(bytes4[] memory array, bytes4 el) public pure returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == el) {
        return true;
      }
    }

    return false;
  }

  function containsElement(address[] memory array, address el) public pure returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == el) {
        return true;
      }
    }

    return false;
  }

  function sameMembers(bytes4[] memory array1, bytes4[] memory array2) public pure returns (bool) {
    if (array1.length != array2.length) {
      return false;
    }
    for (uint256 i = 0; i < array1.length; i++) {
      if (containsElement(array1, array2[i])) {
        return true;
      }
    }

    return false;
  }

  function getAllSelectors(address diamondAddress) public view returns (bytes4[] memory) {
    Facet[] memory facetList = IDiamondLoupe(diamondAddress).facets();

    uint256 len = 0;
    for (uint256 i = 0; i < facetList.length; i++) {
      len += facetList[i].functionSelectors.length;
    }

    uint256 pos = 0;
    bytes4[] memory selectors = new bytes4[](len);
    for (uint256 i = 0; i < facetList.length; i++) {
      for (uint256 j = 0; j < facetList[i].functionSelectors.length; j++) {
        selectors[pos] = facetList[i].functionSelectors[j];
        pos += 1;
      }
    }
    return selectors;
  }

  // implement dummy override functions
  function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external { }
  function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_) { }
  function facetAddresses() external view returns (address[] memory facetAddresses_) { }
  function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_) { }
  function facets() external view returns (Facet[] memory facets_) { }
}
