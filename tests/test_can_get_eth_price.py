from brownie import accounts
from scripts.deploy import deploy_factory
from brownie.network.state import Chain


def test_can_get_eth_price():
    dev = accounts[0]
    chain_id = Chain().id
    addresses = {
        1: [
            "0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58",  # LP Token
            "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",  # wETH
        ],
        137: [
            "0xF6a637525402643B0654a54bEAd2Cb9A83C8B498",  # LP Token
            "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",  # wETH
        ],
    }

    factory_contract = deploy_factory(dev)

    assert factory_contract.getLPQuote(addresses[chain_id][0]) > 0
    assert (
        factory_contract.getAverageTokenPrice(
            addresses[chain_id][1], factory_contract.STABLECOIN(), 200
        )
        > 0
    )
    assert (
        factory_contract.getAverageTokenPrice(
            factory_contract.STABLECOIN(), addresses[chain_id][1], 200
        )
        > 0
    )
