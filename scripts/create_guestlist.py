# Use deploy.py instead
from brownie import (
    Factory,
    accounts,
    interface,
    Contract,
    TestVipCappedGuestListBbtcUpgradeable,
)
from scripts.deploy import deploy_factory, deploy_guest_list


def main():
    acc = accounts[0]
    registry = interface.IBadgerRegistry("0xfda7eb6f8b7a9e9fcfd348042ae675d1d652454f")

    WRAPPER = "0xE59ca38ffa335c3983D8C9221f225845B5D93671"  ## Vault address
    USER_DEPOSIT_CAP = 2e18
    TOTAL_DEPOSIT_CAP = 2e50
    GUEST_ROOT = "0x1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a"
    GOVERNANCE = registry.get("governance")

    factory_contract = deploy_factory()

    guestlist_address = factory_contract.createGuestList(
        WRAPPER,
        USER_DEPOSIT_CAP,
        TOTAL_DEPOSIT_CAP,
        GUEST_ROOT,
        GOVERNANCE,
        {"from": acc},
    ).return_value

    guestlist_contract = Contract.from_abi(
        "Guestlist", guestlist_address, TestVipCappedGuestListBbtcUpgradeable.abi
    )

    print(guestlist_contract)
    print(guestlist_address)
