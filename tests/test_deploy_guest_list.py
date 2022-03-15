from brownie import accounts, interface
from scripts.deploy import deploy_factory, deploy_guest_list
from setup.config import (
    WRAPPER,
    USER_DEPOSIT_CAP,
    TOTAL_DEPOSIT_CAP,
)

def test_can_create_new_guest_list():
    expected_wrapper = WRAPPER
    dev = accounts[0]

    factory_contract = deploy_factory(dev)
    guest_list_contract = deploy_guest_list(factory_contract, dev)

    assert guest_list_contract # Gueslist was deployed
    assert guest_list_contract.wrapper() == expected_wrapper # Wrapper was set correctly

def test_dev_is_owner():
    dev = accounts[0]

    factory_contract = deploy_factory(dev)
    guest_list_contract = deploy_guest_list(factory_contract, dev)

    assert dev.address == guest_list_contract.owner()

def test_caps_are_correct():
    dev = accounts[0]
    expected_user_deposit_cap = USER_DEPOSIT_CAP
    expected_total_deposit_cap = TOTAL_DEPOSIT_CAP

    factory_contract = deploy_factory(dev)
    guest_list_contract = deploy_guest_list(factory_contract, dev)

    assert guest_list_contract.userDepositCap() == expected_user_deposit_cap
    assert guest_list_contract.totalDepositCap() == expected_total_deposit_cap
    
