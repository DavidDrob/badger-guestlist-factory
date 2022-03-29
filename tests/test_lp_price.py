from brownie import accounts
from scripts.deploy import deploy_factory

def test_get_correct_lp_price():
    # TODO: Bind to etherscan API
    lp_price_expected = 61437447556  # https://etherscan.io/address/0xE8b2989276E2Ca8FDEA2268E3551b2b4B2418950#readContract
    dev = accounts[0]

    factory_contract = deploy_factory(dev)
    lp = factory_contract.getLPQuote(
        "0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58"
    ) / (10 ** 18)

    assert lp_price_expected * 1.2 >= lp >= lp_price_expected * 0.8
