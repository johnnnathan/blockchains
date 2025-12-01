# Financial Record Exchange Blockchain System

## Description

As part of our blockchains course, we had to implement a blockchain ourselves. Our team created a record exchange system that allows users to create data packages and provide access to auditors, which simplifies the process by removing intermediary steps, and allows the auditing to happen with minimal effort and external communication.

## System

Our blockchain is built on a few different frameworks. We used the solidity programming language to create the contracts, on which the blockchain is based, and the tests which are used to check the validity of the system. A few javascript scripts were also written, that handle operations such as deployment of the blockchain. 

## Project Structure

.
├── contracts/            # Solidity smart contracts
├── hardhat.config.ts     # Hardhat configuration 
├── package.json          # Project dependencies & npm scripts
├── scripts/              # Deployment & interaction scripts
├── test/                 # Smart contract tests (JS/TS)
└── tsconfig.json         # TypeScript configuration

## How to use

Due to conflicts in the versioning of dependencies, the project has been divided into three main branches:
1. main: Includes all files at their latest version, might result in conflicts when executing
2. Tests: Includes the project structure that allows for the tests to be run
3. deploy: Doesn't have the test files, and uses hardhat v2.x, is able to deploy the blockchain to a local test network

### How to use (Tests)

Move to the Tests branch:
```
git checkout Tests
```
Install npm dependencies:
```
npm install -y
```
Run the tests:
```
npx hardhat test
```
The tests should all be run, with their result being logged to the terminal.

### How to use (deploy)
```
git checkout Tests
```
Install npm dependencies:
```
npm install -y
```
Initialize network
```
npx hardhat node
```
Deploy blockchain
```
npx hardhat run scripts/deploy.js --network localhost
```

## 👥 Contributors

Group 06:
| Name               | Student ID |
|--------------------|------------|
|   Dimitrios Tsiplakis     |  i6357626  |
|       |    |
|           |    |
|      |    |
|     |    |


