from brownie import (
    Factory,
    Contract,
    TestVipCappedGuestListBbtcUpgradeable,
)
from setup.config import (
    WRAPPER,
    USER_DEPOSIT_CAP,
    TOTAL_DEPOSIT_CAP,
    GUEST_ROOT
)

def main():
    factory_contract = deploy_factory()
    factory_contract.wait(1)
    guest_list_contract = deploy_guest_list(factory_contract)
    print("Guestlist deployed at: ", guest_list_contract)

def deploy_factory(deployer):
    return Factory.deploy({"from": deployer})

def deploy_guest_list(factory_contract, deployer):

    guestlist_address = factory_contract.createGuestList(
        WRAPPER,
        USER_DEPOSIT_CAP,
        TOTAL_DEPOSIT_CAP,
        GUEST_ROOT,
        deployer,
        {"from": deployer},
    ).return_value

    return Contract.from_abi(
        "Guestlist", guestlist_address, TestVipCappedGuestListBbtcUpgradeable.abi
    )


