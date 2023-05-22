// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// interfaces

// libraries

// contracts

library Test1Lib {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.test.storage");

  struct TestState {
    address myAddress;
    uint256 myUint;
  }

  function diamondStorage() internal pure returns (TestState storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function setMyAddress(address _myAddress) external {
    diamondStorage().myAddress = _myAddress;
  }

  function getMyAddress() external view returns (address) {
    return diamondStorage().myAddress;
  }
}

contract Test1Facet {
  event TestEvent(address something);

  function test1Func1() external {
    Test1Lib.setMyAddress(address(this));
  }

  function test1Func2() external view returns (address) {
    return Test1Lib.getMyAddress();
  }

  function supportsInterface(bytes4 interfaceId) external pure returns (bool) { }
}
