from itertools import chain
from scripts.deploy import deploy_factory
from brownie.network.state import Chain


def test_get_correct_lp_price(factory):
    # TODO: Bind to etherscan API
    lp_expected_prices = {
        1: [
            61437447556,
            "0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58",
        ],
        137: [
            1682314063324342033381,
            "0xdAD97F7713Ae9437fa9249920eC8507e5FbB23d3",
        ],  # https://polygonscan.com/address/0xD094fCF9D65341770A2458F38b9010c39C813642#readContract
    }
    chain_id = Chain().id
    factory_contract = factory

    if chain_id == 137:
        lp = factory_contract.getCurveTriCryptoLPQuote(
            "0x92215849c439E1f8612b6646060B4E3E5ef822cC",
            lp_expected_prices[chain_id][1],
        )
    else:
        lp = factory_contract.getLPQuote(lp_expected_prices[chain_id][1]) / (10**18)

    assert (
        lp_expected_prices[chain_id][0] * 1.2
        >= lp
        >= lp_expected_prices[chain_id][0] * 0.8
    )
