# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
```

- compile
```shell
npx hardhat compile 
```

- deploy 
```shell
npx hardhat run scripts/deploy.ts --network zKatana

- err 
-- https://portal.thirdweb.com/deploy/faqs
```

- ver
```
- https://docs.astar.network/docs/build/zkEVM/smart-contracts/verify-smart-contract
- sorce verify
- 最適化チェック外す
```

- contract interface
```shell
- interface
-- https://portal.thirdweb.com/contracts/ERC20Vote

``` 
- コード規約
```shell
- comment
-- https://qiita.com/ryu-yama/items/07a348149bcd191c74f0

```

- unit test for remix

-- deploy
```shell
0x3877fc557dd67317094cf67Baf561B22db710858
GrowthUP
GU
0x7EE3CcB05Dae96d7ca2A614545AD16230062DBF9
```

-- propose preProposal
```shell
["0x2B38BA2E0C8251D02b61C4DFBEe161dbb6AE3e66"]
[5]
["0x4554480000000000000000000000000000000000000000000000000000000000"]
test1

- proposalId
15579047777698735748152250923784599393318854168414486894408336291437025742326

```
- proposal2
["0x2B38BA2E0C8251D02b61C4DFBEe161dbb6AE3e66"]
[5]
["0x4554480000000000000000000000000000000000000000000000000000000000"]
test2

- proposalId
22541821618476512592247871283953754658872424520183579749925924091053245247047
```



        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstainVotes;