from math import fabs
import pytest
from brownie import Factory, accounts, Contract, TestVipCappedGuestListBbtcUpgradeable
from dotmap import DotMap
from setup.config import WRAPPER, USER_DEPOSIT_CAP, TOTAL_DEPOSIT_CAP, GUEST_ROOT


@pytest.fixture
def deployed():
    dev = accounts[0]
    factory_contract = Factory.deploy({"from": dev})

    guestlist_address = factory_contract.createGuestList(
        WRAPPER,
        USER_DEPOSIT_CAP,
        TOTAL_DEPOSIT_CAP,
        GUEST_ROOT,
        dev,
        {"from": dev},
    ).return_value
    guestlist_contract = Contract.from_abi(
        "Guestlist", guestlist_address, TestVipCappedGuestListBbtcUpgradeable.abi
    )

    return DotMap(factory=factory_contract, guestlist=guestlist_contract, deployer=dev)


@pytest.fixture
def factory(deployed):
    return deployed.factory


@pytest.fixture
def guestlist(deployed):
    return deployed.guestlist


@pytest.fixture
def deployer(deployed):
    return deployed.deployer
