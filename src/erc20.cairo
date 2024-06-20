use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC20<TContractState> {
    fn get_name(self: @TContractState) -> felt252;
    fn get_symbol(self: @TContractState) -> felt252;
    fn get_decimals(self: @TContractState) -> u8;
    fn get_total_supply(self: @TContractState) -> felt252;
    fn owner(self: @TContractState) -> ContractAddress; 
    fn balance_of(self: @TContractState, account: ContractAddress) -> felt252;
    fn allowance(
        self: @TContractState, owner: ContractAddress, spender: ContractAddress
    ) -> felt252;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: felt252);
    fn transfer_from(
        ref self: TContractState,
        sender: ContractAddress,
        recipient: ContractAddress,
        amount: felt252
    );
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
    fn mint (ref self: TContractState, recipient: ContractAddress, amount: felt252);
    fn approve(ref self: TContractState, spender: ContractAddress, amount: felt252);
    fn increase_allowance(ref self: TContractState, spender: ContractAddress, added_value: felt252);
    fn decrease_allowance(
        ref self: TContractState, spender: ContractAddress, subtracted_value: felt252
    );
}


#[starknet::contract]
pub mod erc20 {
    use core::num::traits::Zero;
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimals: u8,
        owner: ContractAddress,
        total_supply: felt252,
        balances: LegacyMap::<ContractAddress, felt252>,
        allowances: LegacyMap::<(ContractAddress, ContractAddress), felt252>,
    }

    #[event]
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub enum Event {
        Transfer: Transfer,
        Approval: Approval,
    }
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub struct Transfer {
        pub from: ContractAddress,
        pub to: ContractAddress,
        pub value: felt252,
    }
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub struct Approval {
        pub owner: ContractAddress,
        pub spender: ContractAddress,
        pub value: felt252,
    }

    mod Errors {
        pub const APPROVE_FROM_ZERO: felt252 = 'ERC20: approve from 0';
        pub const APPROVE_TO_ZERO: felt252 = 'ERC20: approve to 0';
        pub const TRANSFER_FROM_ZERO: felt252 = 'ERC20: transfer from 0';
        pub const TRANSFER_TO_ZERO: felt252 = 'ERC20: transfer to 0';
        pub const BURN_FROM_ZERO: felt252 = 'ERC20: burn from 0';
        pub const MINT_TO_ZERO: felt252 = 'ERC20: mint to 0';
        pub const NOT_OWNER: felt252 = 'ERC20: not owner';
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        decimals: u8,
        symbol: felt252
    ) {
        self.name.write(name);
        self.symbol.write(symbol);
        self.decimals.write(decimals);
        self.owner.write(get_caller_address());
       
    }

    #[abi(embed_v0)]
    impl IERC20Impl of super::IERC20<ContractState> {
        fn get_name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        fn get_symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        fn get_decimals(self: @ContractState) -> u8 {
            self.decimals.read()
        }

        fn get_total_supply(self: @ContractState) -> felt252 {
            self.total_supply.read()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> felt252 {
            self.balances.read(account)
        }

        fn owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> felt252 {
            self.allowances.read((owner, spender))
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: felt252) {
            let sender = get_caller_address();
            self._transfer(sender, recipient, amount);
        }

        fn mint(ref self: ContractState, recipient: ContractAddress, amount: felt252) {
            assert(get_caller_address() == self.owner.read(), Errors::NOT_OWNER);
            assert(recipient.is_non_zero(), Errors::MINT_TO_ZERO);
            let supply = self.total_supply.read() + amount;
            self.total_supply.write(supply);
            let balance = self.balances.read(recipient) + amount;
            self.balances.write(recipient, balance);
            self
                .emit(
                    Event::Transfer(
                        Transfer {
                            from: contract_address_const::<0>(), to: recipient, value: amount
                        }
                    )
                );
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: felt252
        ) {
            let caller = get_caller_address();
            self.spend_allowance(sender, caller, amount);
            self._transfer(sender, recipient, amount);
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: felt252) {
            let caller = get_caller_address();
            self.approve_helper(caller, spender, amount);
        }

        fn increase_allowance(
            ref self: ContractState, spender: ContractAddress, added_value: felt252
        ) {
            let caller = get_caller_address();
            self
                .approve_helper(
                    caller, spender, self.allowances.read((caller, spender)) + added_value
                );
        }

        fn decrease_allowance(
            ref self: ContractState, spender: ContractAddress, subtracted_value: felt252
        ) {
            let caller = get_caller_address();
            self
                .approve_helper(
                    caller, spender, self.allowances.read((caller, spender)) - subtracted_value
                );
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            assert(new_owner.is_non_zero(), Errors::APPROVE_TO_ZERO);
            assert(get_caller_address() == self.owner.read(), Errors::NOT_OWNER);
            self.owner.write(new_owner);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _transfer(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: felt252
        ) {
            assert(sender.is_non_zero(), Errors::TRANSFER_FROM_ZERO);
            assert(recipient.is_non_zero(), Errors::TRANSFER_TO_ZERO);
            self.balances.write(sender, self.balances.read(sender) - amount);
            self.balances.write(recipient, self.balances.read(recipient) + amount);
            self.emit(Transfer { from: sender, to: recipient, value: amount });
        }

        fn spend_allowance(
            ref self: ContractState,
            owner: ContractAddress,
            spender: ContractAddress,
            amount: felt252
        ) {
            let allowance = self.allowances.read((owner, spender));
            self.allowances.write((owner, spender), allowance - amount);
        }

        fn approve_helper(
            ref self: ContractState,
            owner: ContractAddress,
            spender: ContractAddress,
            amount: felt252
        ) {
            assert(spender.is_non_zero(), Errors::APPROVE_TO_ZERO);
            self.allowances.write((owner, spender), amount);
            self.emit(Approval { owner, spender, value: amount });
        }

    }
}

#[cfg(test)]
mod tests {
    use snforge_std::{declare, ContractClassTrait};
    use super::{erc20, IERC20Dispatcher, IERC20DispatcherTrait, erc20::{Event, Transfer, Approval}};

    use starknet::{
        ContractAddress, SyscallResultTrait, syscalls::deploy_syscall, get_caller_address,
        contract_address_const
    };
    use core::num::traits::Zero;


    const token_name: felt252 = 'NGN_Token';
    const decimals: u8 = 18;
    const symbols: felt252 = 'NGT';

    fn deploy() -> (IERC20Dispatcher, ContractAddress) {
        // let recipient: ContractAddress = contract_address_const::<'initialzed_recipient'>();

        let contract = declare("erc20").unwrap();
        let args  = array![token_name, decimals.into(), symbols];
        let (contract_address, _) = contract.deploy(@args).unwrap();
        // let deployedAddress: felt252 = contract_address.try_into().unwrap();
        // println!("Contract deployed at address: {}", deployedAddress);

        (IERC20Dispatcher { contract_address }, contract_address)
    }


    #[test]
    fn test_get_name() {
        let (dispatcher, _) = deploy();
        let name = dispatcher.get_name();
        assert(name == token_name, 'wrong token name');
    }

    #[test]
    fn test_get_symbol() {
        let (dispatcher, _) = deploy();
        assert(dispatcher.get_symbol() == symbols, 'wrong symbol');
    }

    #[test]
    fn test_get_decimals() {
        let (dispatcher, _) = deploy();
        assert(dispatcher.get_decimals() == decimals, 'wrong decimals');
    }

    #[test]
    fn test_total_supply() {
        let (dispatcher, _) = deploy();
        assert(dispatcher.get_total_supply() == 0, 'wrong total supply');
    }


    #[test]
    #[should_panic(expected: ('ERC20: approve to 0', ))]
    fn test_approval_spender_is_address_zero() {
        let spender: ContractAddress = Zero::zero();
        let amount = 100;
        let (dispatcher, _) = deploy();
        dispatcher.approve(spender, amount);
    }



    #[test]
    #[should_panic(expected: ('ERC20: approve to 0', ))]
    fn test_should_increase_allowance_with_spender_zero_address() {
        let spender = Zero::zero();
        let amount = 100;
        let (dispatcher, _) = deploy();
        dispatcher.increase_allowance(spender, amount);
    }


    #[test]
    #[should_panic(expected: ('ERC20: approve to 0', ))]
    fn test_should_decrease_allowance_with_spender_zero_address() {
        let spender = Zero::zero();
        let amount = 100;
        let (dispatcher, _) = deploy();
        dispatcher.decrease_allowance(spender, amount);
    }

    #[test]
    #[should_panic(expected: ('ERC20: transfer from 0',))]
    #[should_panic]
    fn test_transferFrom_when_sender_is_address_zero() {
        let sender = Zero::zero();
        let amount = 100;
        let reciever = contract_address_const::<'spender'>();
        let (dispatcher, _) = deploy();
        dispatcher.transfer_from(sender, reciever, amount);
    }

    #[test]
    fn test_mint() {
        let (dispatcher, _) = deploy();
        let amount = 100;
        let reciever = contract_address_const::<'spender'>();
        dispatcher.mint(reciever, amount);
        assert(dispatcher.get_total_supply() == amount, 'wrong total supply');
        assert(dispatcher.balance_of(reciever) == amount, 'wrong balance');
    }

}