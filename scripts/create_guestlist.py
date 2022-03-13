from brownie import (
    Factory,
    accounts,
    interface,
    Contract,
    TestVipCappedGuestListBbtcUpgradeable,
)


def main():
    acc = accounts[0]
    registry = interface.IBadgerRegistry("0xfda7eb6f8b7a9e9fcfd348042ae675d1d652454f")

    WRAPPER = ""  ## Vault address
    USER_DEPOSIT_CAP = 2e18
    TOTAL_DEPOSIT_CAP = 2e50
    GUEST_ROOT = "0x1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a"
    GOVERNANCE = registry.get("governance")

    factory_contract = Factory.deploy({"from": acc})

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
