from scripts.deploy import deploy_factory
from brownie.network.state import Chain


def test_get_correct_lp_price_tricrypto(factory):
    # TODO: Bind to etherscan API
    lp_expected_prices = {
        1: [
            1652820375627476595144,
            "0xD51a44d3FaE010294C616388b506AcdA1bfAAE46",
            "0xc4ad29ba4b3c580e6d59105fff484999997675ff",
        ],  # https://etherscan.io/address/0xE8b2989276E2Ca8FDEA2268E3551b2b4B2418950#readContract
        137: [
            1682314063324342033381,
            "0x92215849c439E1f8612b6646060B4E3E5ef822cC",
            "0xdAD97F7713Ae9437fa9249920eC8507e5FbB23d3",
        ],  # https://polygonscan.com/address/0xD094fCF9D65341770A2458F38b9010c39C813642#readContract
    }
    chain_id = Chain().id
    factory_contract = factory

    lp = factory_contract.getCurveTriCryptoLPQuote(
        lp_expected_prices[chain_id][1], lp_expected_prices[chain_id][2]
    )

    assert (
        lp_expected_prices[chain_id][0] * 1.3
        >= lp
        >= lp_expected_prices[chain_id][0] * 0.7
    )
