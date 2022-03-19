from brownie import accounts
from scripts.deploy import deploy_factory, deploy_guest_list
from setup.config import (
    WRAPPER,
)


def test_can_create_new_guest_list():
    expected_wrapper = WRAPPER
    dev = accounts[0]

    factory_contract = deploy_factory(dev)
    guest_list_contract = deploy_guest_list(factory_contract, dev)

    assert guest_list_contract  # Gueslist was deployed
    assert (
        guest_list_contract.wrapper() == expected_wrapper
    )  # Wrapper was set correctly


def test_dev_is_owner():
    dev = accounts[0]

    factory_contract = deploy_factory(dev)
    guest_list_contract = deploy_guest_list(factory_contract, dev)

    assert dev.address == guest_list_contract.owner()
