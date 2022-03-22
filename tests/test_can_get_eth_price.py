from brownie import accounts
from scripts.deploy import deploy_factory

def test_can_get_eth_price():
    dev = accounts[0]

    factory_contract = deploy_factory(dev)

    assert factory_contract.getLPQuote("0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58") > 0
    assert factory_contract.getAverageTokenPrice("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", factory_contract.STABLECOIN(), 200) > 0
    assert factory_contract.getAverageTokenPrice(factory_contract.STABLECOIN(), "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", 200) > 0