from scripts.deploy import deploy_factory
from setup.config import (
    WRAPPER,
)
from brownie import accounts
import requests
import json
from dotenv import load_dotenv
import os
import pytest
load_dotenv()

# Checks 1USD worth of `want` with 20% margin
# Add your `COVALENT_API_KEY` to .env otherwise test will fail
# https://www.covalenthq.com/platform/#/auth/register/
def test_get_price_covalent():
    api_key = os.getenv("COVALENT_API_KEY")
    dev = accounts[0]
    factory_contract = deploy_factory(dev)
    to_token = factory_contract.getVaultTokenAddress(WRAPPER)

    response = requests.get(
        f"https://api.covalenthq.com/v1/pricing/historical_by_addresses_v2/1/USD/{to_token}/?quote-currency=USD&format=JSON&key={api_key}"
    )
    parsed = json.loads(response.text)
    if (parsed["data"][0]["prices"][0]["price"]) == None:
        pytest.skip()
        
    covalent_token_price = 1 / float((parsed["data"][0]["prices"][0]["price"]))
    covalent_token_decimals = int((parsed["data"][0]["contract_decimals"]))
    from_token = factory_contract.STABLECOIN()

    contract_token_price = float(
        factory_contract.getAverageTokenPrice(
            from_token, to_token, 1
        )
        / (10**covalent_token_decimals)
    )
    covalent_plus_20 = float(covalent_token_price * (1.2))
    covalent_minus_20 = float(covalent_token_price * (0.8))

    assert covalent_plus_20 >= contract_token_price >= covalent_minus_20
