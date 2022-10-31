# Fax
A stupid project to learn Tezos development. It's basically a smart contract that implements an on-chain fax network, where users can send faxes to each other. Each user can register a printer, and get jobs sent to them. Users can also add jobs to the queue by paying the printer fee.

### Compilation of randomness contract

This repository provides a Makefile for compiling and testing smart contracts. One can type `make` to display all available rules.
The `make all` command will delete the compiled smart contract, then compile the smart contract and then launch tests.

A makefile is provided to compile the "Fax" smart contract, and to launch tests.

### Deployment

A typescript script for deployment is provided to originate the smart contrat. This deployment script relies on .env file which provides the RPC node url and the deployer public and private key.

```
make deploy
```
