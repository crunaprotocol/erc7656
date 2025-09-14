# ERC-7656

This is a reference implementation for the [ERC-7656](https://eips.ethereum.org/EIPS/eip-7656) standard. Most of the code is mutuated from [ERC-6551 reference implementation](https://github.com/erc6551/reference).

The following bytecode:

```
0x608060405234801561001057600080fd5b5061030b806100206000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c806301ffc9a7146100465780632ae81fb11461006e578063b4cb3cbb14610099575b600080fd5b61005961005436600461021a565b6100ac565b60405190151581526020015b60405180910390f35b61008161007c366004610267565b6100e3565b6040516001600160a01b039091168152602001610065565b6100816100a7366004610267565b610152565b60006001600160e01b03198216634f11918560e11b14806100dd57506001600160e01b031982166301ffc9a760e01b145b92915050565b600060406024608c376e5af43d82803e903d91602b57fd5bf3606c5286605d52733d60ad80600a3d3981f3363d3d373d3d3d363d7360495282841760cc528160ec5260ff60005360b76055206035523060601b6001528560155260556000208060601b60601c60005260206000f35b600060406024608c376e5af43d82803e903d91602b57fd5bf3606c5286605d52733d60ad80600a3d3981f3363d3d373d3d3d363d7360495282841760cc528160ec5260ff60005360b76055206035523060601b600152856015526055600020803b61020a578660b760556000f5806101d25763d786d3936000526004601cfd5b80606c52508460cc528284897f5d6f1b27222bf34d576ad575c1c8749e981db502da9cd2e96e6e5258938099056080606ca46020606cf35b8060601b60601c60005260206000f35b60006020828403121561022c57600080fd5b81356001600160e01b03198116811461024457600080fd5b9392505050565b80356001600160a01b038116811461026257600080fd5b919050565b60008060008060008060c0878903121561028057600080fd5b6102898761024b565b9550602087013594506040870135935060608701356001600160a01b0319811681146102b457600080fd5b92506102c26080880161024b565b915060a08701359050929550929550929556fea2646970667358221220a95345c2c3cc528a43338da1b7fd0be8b9ba8af6c1e486ed761e02824da252ce64736f6c63430008160033
```

will be deployed asap to erc7656.eth, i.e.:

```
0x76565d90eeB1ce12D05d55D142510dBA634a128F
```

via Nick's Factory using the following salt:

```
0x7656000000000000000000000000000000000000000000000000000000001688
```

on primary mainnets and same selected testnets.

Look at `contracts/bytecode.json` for the details.

## Usage

Install it as a dependency
```
npm i erc7656 @openzeppelin/contracts
```

To make your service extend `erc7656/ERC7656Service.sol` or `erc7656/extensions/ERC7656ServiceExt.sol`.

Look at the examples in the `/examples` directory for implementation references.

## Examples

The repository includes example implementations that demonstrate different use cases of ERC-7656:

- `BadgeCollectorService.sol` (currently in `/mocks`): A simple example showing how to create a service that collects badges for an NFT. This should be moved to `/examples` as it's a proper example rather than a mock.
- `SimpleInheritanceService.sol`: A basic inheritance service that allows NFT owners to designate beneficiaries who can claim the NFT if the owner doesn't provide a proof of life within a specified timeframe.

Each example includes comprehensive tests in the `test` directory that demonstrate how to interact with the services and verify their functionality.

---

Notice that anyone can deploy a service owned by a specific contract or token, using whatever salt they prefer. To avoid troubles and security issues, any initial setup must be designed so that, despite who is the deployer, the result is what is expected to be. For example, if a service must get some information from a token, it should be the service the one that queries the token, not the other way around. In other words, passing any parameter to the service during the deploying opens to the possibility of a malicious deployer to pass a different set of data causing the service to behave unexpectedly. 

## Note about the tests

This repo has 100% test coverage.

## License

MIT

Copyright (C) 2023+ Cruna
