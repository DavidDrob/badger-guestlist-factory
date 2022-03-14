from brownie import (
    Factory,
    accounts,
    interface,
    Contract,
    TestVipCappedGuestListBbtcUpgradeable,
)


def main():
    factory_contract = deploy_factory()
    factory_contract.wait(1)
    guest_list_contract = deploy_guest_list(factory_contract)
    print(guest_list_contract)

def deploy_factory():
    acc = accounts[0]
    return Factory.deploy({"from": acc})

def deploy_guest_list(factory_contract):

    registry = interface.IBadgerRegistry("0xfda7eb6f8b7a9e9fcfd348042ae675d1d652454f")
    acc = accounts[0]

    WRAPPER = "0xE59ca38ffa335c3983D8C9221f225845B5D93671"  ## Vault address
    USER_DEPOSIT_CAP = 2e18
    TOTAL_DEPOSIT_CAP = 2e50
    GUEST_ROOT = "0x1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a"
    GOVERNANCE = registry.get("governance")

    guestlist_address = factory_contract.createGuestList(
        WRAPPER,
        USER_DEPOSIT_CAP,
        TOTAL_DEPOSIT_CAP,
        GUEST_ROOT,
        GOVERNANCE,
        {"from": acc},
    ).return_value

    return Contract.from_abi(
        "Guestlist", guestlist_address, TestVipCappedGuestListBbtcUpgradeable.abi
    )


