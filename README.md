# BiFi-staking-protocol

## Introduction
This smart contract implements a token staking service. Two types of tokens are involved in the staking service: (1) Contribution Token and (2) Reward Token. When a user deposits his or her Contribution Tokens to our smart contract, the user can earn Reward Tokens relative to the deposited amount and the length of deposit. Both the Contribution Tokens and Reward Tokens are ERC-20 tokens.

## Architecture
![architecture](./assets/staking-protocol-architecture-for-github.png)

## Installation
`npm install truffle -g`

## Usage
`truffle compile`

## Structure of Project
```
contracts
├── DistributionModelV3.sol
├── ERC20.sol
└── module
    ├── eventModule.sol
    ├── externalModule.sol
    ├── internalModule.sol
    ├── safeMath.sol
    ├── storageModule.sol
    └── viewModule.sol
docs
├── distribution-model-contract.pdf
├── reward-distribution-model-ver-1.0.pdf
├── theori-audit-rev-1.0.pdf
└── theori-audit-rev-2.0.pdf
```
1. `contracts`: solidity contracts
2. `contracts/DistributionModelV3`: Model wrapper contract
3. `contracts/ERC20.sol`: ERC20 mockup
4. `contracts/module/eventModule.sol`: Define events
5. `contracts/module/externalModule.sol`: Implements external function for users action and admin
6. `contracts/module/internalModule.sol`: Implements interanl function for model logics
7. `contracts/module/safeMath.sol`: Implements safe-math for uint256 and fixed point calculation
8. `contracts/module/storageModule.sol`: Define contract storage
9. `contracts/module/viewModule.sol`: Implements view function for support front-end
10. `docs`: Document
11. `docs/distribution-model-contract.pdf`: Documents for contract implementations
12. `docs/reward-distribution-model-ver-1.0.pdf`: Document for rewarding algorithms
13. `docs/theori-audit-rev-1.0.pdf`: Audit review of Theori
14. `docs/theori-audit-rev-2.0.pdf`: Audit revision of Theori
