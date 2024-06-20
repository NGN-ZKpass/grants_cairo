use snforge_std::{declare, ContractClassTrait };
use core::traits::TryInto;
use starknet::{ ContractAddress, SyscallResultTrait, syscalls::deploy_syscall, 
    get_caller_address,contract_address_const, get_block_timestamp
};
use zk_nimc::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
use zk_nimc::nimc_grants::{Inimc_grantsDispatcher, Inimc_grantsDispatcherTrait};

fn deployERC20() -> (IERC20Dispatcher, ContractAddress){
    let token_name: felt252 = 'NGN_Token';
    let decimals: u8 = 18;
    let symbols: felt252 = 'NGT';

    let token_contract = declare("erc20").unwrap();
    let erc_args  = array![token_name, decimals.into(), symbols];
    let (contract_address, _) = token_contract.deploy(@erc_args).unwrap();

    println!("token_contract deployed at address: {:?}", contract_address);

    (IERC20Dispatcher { contract_address }, contract_address)
}   



fn deploy_zknimc() -> (Inimc_grantsDispatcher, ContractAddress, IERC20Dispatcher, ContractAddress){
    let (erc20Dispatcher, erc20Address) = deployERC20();

    println!("---------deploying zk_nimc contract-------------" );
    let admin: ContractAddress = contract_address_const::<'initialzed_recipient'>();
    let duration: u64 = 86400 ;
    let startDate: u64 = get_block_timestamp() + 86400;
    // let tokenAddress: ContractAddress = contract_address_const::<'token'>();

    let contract = declare("nimc_grants").unwrap(); 
    let args  = array![admin.into(), duration.into(), startDate.into(), erc20Address.into()];

    let (contract_address, _) = contract.deploy(@args).unwrap();
    println!("zk_nimc_address deployed at address: {:?}", contract_address);

    erc20Dispatcher.transfer_ownership(contract_address);

    assert(erc20Dispatcher.owner() == contract_address,'ownership transfer failed');

    (Inimc_grantsDispatcher { contract_address }, contract_address, erc20Dispatcher, erc20Address)

}


#[test]
fn test_get_name() {
    let (_, _, erc20Dispatcher, _) = deploy_zknimc();
    let name = erc20Dispatcher.get_name();
    assert(name == 'NGN_Token', 'wrong token name');
}

#[test]
#[should_panic(expected: ('Claim period has not started',))]
#[should_panic]
fn test_claim_when_claiming_time_has_not_reached() {
    let (zknimcDispatcher, _, erc20Dispatcher, _) = deploy_zknimc();
    let amount = 100;
    let recipient: ContractAddress = contract_address_const::<'initialzed_recipient'>();
    zknimcDispatcher.claim();
    let balance = erc20Dispatcher.balance_of(recipient);
    assert(balance == amount, 'wrong balance');
}


// #[test]
// fn test_claim_when_claiming_time_reached() {
//     let (zknimcDispatcher, contract_address, erc20Dispatcher, _) = deploy_zknimc();
//     let amount = 100;
//     let recipient: ContractAddress = contract_address_const::<'initialzed_recipient'>();
//     zknimcDispatcher.claim();
//     let balance = erc20Dispatcher.balance_of(recipient);
//     assert(balance == amount, 'wrong balance');
// }