from brownie import accounts
from scripts.deploy import deploy_factory


def test_get_correct_lp_price_tricrypto():
    # TODO: Bind to etherscan API
    lp_price_expected = 1581152090295707346810  # https://etherscan.io/address/0xE8b2989276E2Ca8FDEA2268E3551b2b4B2418950#readContract
    dev = accounts[0]

    factory_contract = deploy_factory(dev)
    lp = factory_contract.getCurveTriCryptoLPQuote(
        "0xc4AD29ba4B3c580e6D59105FFf484999997675Ff"
    )

    assert lp_price_expected * 1.2 >= lp >= lp_price_expected * 0.8
