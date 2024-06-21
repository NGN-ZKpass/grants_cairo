# NIMC Grants Smart Contract - README

## Overview

The NIMC Grants contract is a Cairo 1-based smart contract designed to manage grants on the StarkNet blockchain. It allows users to claim tokens if they provide the necessary proof within a specified time period. The contract includes functionalities for claim registration, proof verification, and token transfer using the ERC20 standard.

## Features

- **Claim Tokens:** Users can claim tokens if they provide valid proof.
- **Register Proof:** Users can register their proof.
- **Token Transfer:** Uses ERC20 interface for token transfer.
- **Event Emission:** Emits events upon successful claims.

## Components

### Interfaces

#### `Inimc_grants`

Defines the following methods:

- `claim() -> bool`: Allows a user to claim tokens.
- `registerProof(proof: felt252)`: Allows a user to register proof.

#### `IERC20DispatcherTrait`

Defines the method:

- `transfer(recipient: ContractAddress, amount: u256)`: Facilitates the transfer of tokens.

### Storage

The storage structure holds essential contract state data:

- `admin`: Address of the contract administrator.
- `claimers_count`: Number of users who have claimed tokens.
- `claimed`: Map to track if an address has claimed tokens.
- `hasProof`: Map to track if an address has provided proof.
- `proof`: Map to store proofs provided by addresses.
- `candidateVotes`: Map to track votes for candidates.
- `duration`: Duration of the claim period.
- `startDate`: Start date of the claim period.
- `endtime`: End time of the claim period.
- `token`: Address of the ERC20 token contract.

### Events

Defines the `Claimed` event to notify about successful claims:

- `claimer`: Address of the claimer.
- `counter`: Updated claimers count.

### Constructor

Initializes the contract with the following parameters:

- `_admin`: Address of the contract administrator.
- `_duration`: Duration of the claim period.
- `_startDate`: Start date of the claim period.
- `_token`: Address of the ERC20 token contract.

### Methods

#### `claim() -> bool`

Checks the current timestamp against the claim period, verifies the user's claim status and proof, and then processes the token transfer.

#### `registerProof(proof: felt252)`

Allows users to register their proof. 

### Internal Functions

#### `adminCheck()`

Ensures that the caller is the admin.

#### `claimCheck(claimer: ContractAddress)`

Ensures that the claimer has not already claimed.

#### `proofCheck(claimer: ContractAddress)`

Ensures that the claimer has provided proof.

## Usage

### Deployment

To deploy the contract, use the `constructor` function with appropriate parameters:

- `_admin`: Admin address.
- `_duration`: Duration for the claim period.
- `_startDate`: Start date for the claim period.
- `_token`: ERC20 token address.

### Interacting with the Contract

1. **Register Proof:**
   ```cairo
   contract_instance.registerProof(proof);
   ```
2. **Claim Tokens:**
   ```cairo
   let success = contract_instance.claim();
   ```

### Example

```cairo
#[starknet::contract]
mod example_usage {
    use starknet::ContractAddress;
    use nimc_grants::Inimc_grants;
    
    fn main() {
        let contract_address = ContractAddress::new(...);
        let proof = felt252::new(...);

        // Register proof
        nimc_grants::registerProof(contract_address, proof);

        // Claim tokens
        let result = nimc_grants::claim(contract_address);
        assert!(result, "Claim failed!");
    }
}
```

## Requirements

- StarkNet environment
- Cairo 1 language support
- ERC20 compatible token

## Conclusion

The NIMC Grants contract offers a robust solution for managing token grants with proof verification on the StarkNet blockchain. By leveraging ERC20 standards and a structured claim process, it ensures secure and efficient token distribution.
