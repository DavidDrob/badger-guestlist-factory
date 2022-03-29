from brownie import accounts
from scripts.deploy import deploy_factory


def test_get_correct_lp_price_tricrypto():
    # TODO: Bind to etherscan API
    lp_price_expected = 1646249637991119407112  # https://etherscan.io/address/0xE8b2989276E2Ca8FDEA2268E3551b2b4B2418950#readContract
    dev = accounts[0]

    # https://etherscan.io/address/0xc4AD29ba4B3c580e6D59105FFf484999997675Ff
    factory_contract = deploy_factory(dev)
    lp = factory_contract.getCurveTriCryptoLPQuote(
        "0xD51a44d3FaE010294C616388b506AcdA1bfAAE46", "0xc4ad29ba4b3c580e6d59105fff484999997675ff"
    )

    assert lp_price_expected * 1.3 >= lp >= lp_price_expected * 0.7
