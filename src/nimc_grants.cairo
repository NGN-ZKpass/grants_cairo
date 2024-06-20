use starknet::ContractAddress;
use zk_nimc::erc20;

#[starknet::interface]
pub trait Inimc_grants<TContractState> {
    fn claim(ref self: TContractState) -> bool;
    fn registerProof(ref self: TContractState, proof: felt252);
}

#[starknet::interface]
trait IERC20DispatcherTrait<TContractState> {
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
}

#[starknet::contract]
pub mod nimc_grants {
    use core::starknet::event::EventEmitter;
    use starknet::{get_caller_address, get_block_timestamp};
    use core::array::ArrayTrait;
    use starknet::ContractAddress;
    use starknet::contract_address_const;
    use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};


    #[storage]
    struct Storage {
        admin: ContractAddress,
        claimers_count: u32,
        claimed: LegacyMap::<ContractAddress, bool>,
        hasProof: LegacyMap::<ContractAddress, bool>,
        proof: LegacyMap::<ContractAddress, felt252>,
        candidateVotes: LegacyMap::<ContractAddress, u32>,
        duration: u64,
        startDate: u64,
        endtime: u64,
        token: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Claimed: Claimed,
    }

    #[derive(Drop, starknet::Event)]
    struct Claimed {
        #[key]
        claimer: ContractAddress,
        #[key]
        counter: u32
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        _admin: ContractAddress,
        _duration: u64,
        _startDate: u64,
        _token: ContractAddress
    ) {
        assert(_duration > 0, 'Duration must be greater than 0');
        assert(_startDate > get_block_timestamp(), 'Start date must be in future');
        self.admin.write(_admin);
        self.duration.write(_duration);
        self.startDate.write(_startDate);
        self.endtime.write(_startDate + _duration);
        self.token.write(_token);
    }

    #[abi(embed_v0)]
    impl Inimc_grantsImpl of super::Inimc_grants<ContractState> {
        fn claim(ref self: ContractState) -> bool {
            assert(get_block_timestamp() < self.endtime.read(), 'Claim period is over');
            assert(get_block_timestamp() > self.startDate.read(), 'Claim period has not started');
            let claimer: ContractAddress = get_caller_address();
            self.claimCheck(claimer);
            self.proofCheck(claimer);
            self.claimed.write(claimer, true);
            self.claimers_count.write(self.claimers_count.read() + 1);
            let tokenAddress: ContractAddress = self.token.read(); // get token address
            ERC20ABIDispatcher { contract_address: tokenAddress }.transfer(claimer, 1000);
            self.emit(Claimed { claimer: claimer, counter: self.claimers_count.read() });
            true
        }

        fn registerProof(ref self: ContractState, proof: felt252) {
            let claimer: ContractAddress = get_caller_address();
            self.hasProof.write(claimer, true);
            self.proof.write(claimer, proof);
        // EventEmitter::emit(proof{candidate: candidate});
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn adminCheck(self: @ContractState) {
            let caller = get_caller_address();
            assert(caller == self.admin.read(), 'Only admin function');
        }

        fn claimCheck(self: @ContractState, claimer: ContractAddress) {
            assert(!self.claimed.read(claimer), 'Already claimed');
        }

        fn proofCheck(self: @ContractState, claimer: ContractAddress) {
            assert(self.hasProof.read(claimer), 'No proof');
        }
    }
}


