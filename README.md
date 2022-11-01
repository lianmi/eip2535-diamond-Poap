# EIP2535 Diamond Poap

This sample implementation is originally based on Nick Mudgen's [diamon-1-hardhat](https://github.com/mudgen/diamond-1-hardhat) implementation but uses Typescript and goes into further detail about how to deploy, initialize and upgrade.

## flatten
```
npx hardhat flatten ./contracts/Diamond.sol > audit/Diamond.sol
```

## LibAppStorage

Adding `contracts/libraries/LibAppStorage.sol`, gathering all variables used by all facets in a struct in one place

```solidity
pragma solidity ^0.8.0;

struct AppStorage {
    uint256 x;
    uint256 y;
}
```

Used in `Test1Facet`

```solidity
pragma solidity ^0.8.0;

import { AppStorage } from "../libraries/LibAppStorage.sol";

contract Test1Facet {
    event TestEvent(address something);

    AppStorage s;

    function test1Func1() external {}

    function changeX() external {
        s.x += 1;
    }

    function getX() external view returns (uint256) {
        return s.x;
    }
}
```

## Scripts

Providing 2 Typescript functions for deploy and upgrade:

`scripts/deploy/deployDiamond.ts`

```ts
/**
 *  @param facetNames: facetNames to be deployed beside 'DiamondCutFacet' 'DiamondLoupeFacet' 'OwnershipFacet', all selectors will be 'add'
 *  @param init: init function to be invoked in DiamondInit contract
 *  @return Diamond contract address
 */
export async function deployDiamond(facetNames: string[], init = ''): Promise<string>
```

`scripts/deploy/upgradeDiamond.ts`

```ts
/**
 *  @param diamonAddress: deployed diamond address
 *  @param facetNames: facetNames to be upgraded, selectors:
 *    - non-exists: will be 'add'
 *    - exists: will be 'replace'
 *  @param init: init function to be invoked in DiamondInit contract
 *  @return none
 */
export async function upgradeDiamond(diamonAddress: string, facetNames: string[], init = ''): Promise<string>
```

Check usage sample in `test/index.ts`.


## test

```
EIP2535 Diamond Poap Main Test

DiamondCutFacet deployed: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Diamond deployed: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512

Deploying facets
DiamondLoupeFacet deployed: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
signatures: [
  'facetAddress(bytes4)',
  'facetAddresses()',
  'facetFunctionSelectors(address)',
  'facets()',
  'supportsInterface(bytes4)'
]
OwnershipFacet deployed: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
signatures: [ 'owner()', 'transferOwnership(address)' ]
PoapFacet deployed: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
signatures: [
  'addAdmin(address)',
  'addEventMinter(uint256,address)',
  'approve(address,uint256)',
  'balanceOf(address)',
  'burn(uint256)',
  'changeX()',
  'createEvent(uint256,string)',
  'eventHasUser(uint256,address)',
  'eventMetaName(uint256)',
  'getApproved(uint256)',
  'getX()',
  'isAdmin(address)',
  'isApprovedForAll(address,address)',
  'isEventMinter(uint256,address)',
  'mintEventToManyUsers(uint256,string[],address[])',
  'mintToken(uint256,string,address)',
  'mintUserToManyEvents(uint256[],string[],address)',
  'name()',
  'ownerOf(uint256)',
  'pause()',
  'paused()',
  'removeAdmin(address)',
  'removeEventMinter(uint256,address)',
  'renounceAdmin()',
  'renounceEventMinter(uint256)',
  'safeTransferFrom(address,address,uint256)',
  'safeTransferFrom(address,address,uint256,bytes)',
  'setApprovalForAll(address,bool)',
  'setBaseURI(string)',
  'symbol()',
  'tokenDetailsOfOwnerByIndex(address,uint256)',
  'tokenEvent(uint256)',
  'tokenOfOwnerByIndex(address,uint256)',
  'tokenURI(uint256)',
  'totalSupply()',
  'transferFrom(address,address,uint256)',
  'unpause()'
]
执行executeCut...
Diamond Cut: [
  {
    facetAddress: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',
    action: 0,
    functionSelectors: [
      '0xcdffacc6',
      '0x52ef6b2c',
      '0xadfca15e',
      '0x7a0ed627',
      '0x01ffc9a7'
    ]
  },
  {
    facetAddress: '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9',
    action: 0,
    functionSelectors: [ '0x8da5cb5b', '0xf2fde38b' ]
  },
  {
    facetAddress: '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9',
    action: 0,
    functionSelectors: [
      '0x70480275', '0x9cd3cad6', '0x095ea7b3',
      '0x70a08231', '0x42966c68', '0xd3f60097',
      '0xa1d255e1', '0xd6c0756c', '0xbb3b6963',
      '0x081812fc', '0x5197c7aa', '0x24d7806c',
      '0xe985e9c5', '0x28db38b4', '0xabdcf316',
      '0x8da69c84', '0x4c5347e0', '0x06fdde03',
      '0x6352211e', '0x8456cb59', '0x5c975abb',
      '0x1785f53c', '0x166c4b05', '0x8bad0c0a',
      '0x02c37ddc', '0x42842e0e', '0xb88d4fde',
      '0xa22cb465', '0x55f804b3', '0x95d89b41',
      '0x67e971ce', '0x127a5298', '0x2f745c59',
      '0xc87b56dd', '0x18160ddd', '0x23b872dd',
      '0x3f4ba83a'
    ]
  }
]
Diamond cut tx:  0x2efb8ad56eff3c371cd3a5a9237b5e14ff09a87808b08d14c58ef0c039ac650b
Completed diamond cut
x= 100
    √ Should deploy (96ms)
    √ should have 4 facets -- call to facetAddresses function (39ms)
    √ should return correct name (48ms)
    √ Should check POAPs' vars (235ms)
    √ Should check POAPEvent (203ms)
    √ Should check POAPRole (382ms)
    √ Should check POAPPausable (96ms)
    √ Should check POAP mint (858ms)
    √ Should check POAP transforms (170ms)
PoapFacetV2 deployed: 0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB
signatures: [
  'addAdmin(address)',
  'addEventMinter(uint256,address)',
  'approve(address,uint256)',
  'balanceOf(address)',
  'burn(uint256)',
  'changeX()',
  'changeY()',
  'createEvent(uint256,string)',
  'eventHasUser(uint256,address)',
  'eventMetaName(uint256)',
  'getApproved(uint256)',
  'getX()',
  'getY()',
  'isAdmin(address)',
  'isApprovedForAll(address,address)',
  'isEventMinter(uint256,address)',
  'mintEventToManyUsers(uint256,string[],address[])',
  'mintToken(uint256,string,address)',
  'mintUserToManyEvents(uint256[],string[],address)',
  'name()',
  'ownerOf(uint256)',
  'pause()',
  'paused()',
  'removeAdmin(address)',
  'removeEventMinter(uint256,address)',
  'renounceAdmin()',
  'renounceEventMinter(uint256)',
  'safeTransferFrom(address,address,uint256)',
  'safeTransferFrom(address,address,uint256,bytes)',
  'setApprovalForAll(address,bool)',
  'setBaseURI(string)',
  'symbol()',
  'tokenDetailsOfOwnerByIndex(address,uint256)',
  'tokenEvent(uint256)',
  'tokenOfOwnerByIndex(address,uint256)',
  'tokenURI(uint256)',
  'totalSupply()',
  'transferFrom(address,address,uint256)',
  'unpause()'
]
执行executeCut...
Diamond Cut: [
  {
    facetAddress: '0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB',
    action: 0,
    functionSelectors: [ '0xc50e1b70', '0x0b7f1665' ]
  },
  {
    facetAddress: '0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB',
    action: 1,
    functionSelectors: [
      '0x70480275', '0x9cd3cad6', '0x095ea7b3',
      '0x70a08231', '0x42966c68', '0xd3f60097',
      '0xa1d255e1', '0xd6c0756c', '0xbb3b6963',
      '0x081812fc', '0x5197c7aa', '0x24d7806c',
      '0xe985e9c5', '0x28db38b4', '0xabdcf316',
      '0x8da69c84', '0x4c5347e0', '0x06fdde03',
      '0x6352211e', '0x8456cb59', '0x5c975abb',
      '0x1785f53c', '0x166c4b05', '0x8bad0c0a',
      '0x02c37ddc', '0x42842e0e', '0xb88d4fde',
      '0xa22cb465', '0x55f804b3', '0x95d89b41',
      '0x67e971ce', '0x127a5298', '0x2f745c59',
      '0xc87b56dd', '0x18160ddd', '0x23b872dd',
      '0x3f4ba83a'
    ]
  }
]
Diamond cut tx:  0x24e17e719d5d6f40420baf775a578fb5cac7bb976bd3ebc9406d419243e4dffc
Completed diamond cut
y= 200
x2= 111
    √ Should upgrade  (1811ms)


  10 passing (8s)

```