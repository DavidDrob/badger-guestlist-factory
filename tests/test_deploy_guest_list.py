from brownie import accounts
from scripts.deploy import deploy_factory, deploy_guest_list
from scripts.get_token_price_covalent import get_token_price_covalent
from setup.config import WRAPPER, USER_DEPOSIT_CAP, TOTAL_DEPOSIT_CAP
import pytest


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


def test_deposit_caps_are_correct():
    dev = accounts[0]

    factory_contract = deploy_factory(dev)
    guest_list_contract = deploy_guest_list(factory_contract, dev)

    token = factory_contract.getVaultTokenAddress(WRAPPER)
    token_price = get_token_price_covalent(token)

    if token_price == 0:
        pytest.skip()

    assert (
        float((USER_DEPOSIT_CAP / token_price) * 1.2)
        >= float(guest_list_contract.userDepositCap() / (10**18))
        >= float((USER_DEPOSIT_CAP / token_price) * 0.8)
    )

    assert (
        float((TOTAL_DEPOSIT_CAP / token_price) * 1.2)
        >= float(guest_list_contract.totalDepositCap() / (10**18))
        >= float((TOTAL_DEPOSIT_CAP / token_price) * 0.8)
    )
