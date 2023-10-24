PrivateKey set: true
// Sources flattened with hardhat v2.18.2 https://hardhat.org

// SPDX-License-Identifier: MIT

// File contracts/Counter.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.19;

contract Counter {
uint256 currentCount = 0;

    function increment() public {
        currentCount = currentCount + 1;
    }

    function retrieve() public view returns (uint256){
        return currentCount;
    }
}
