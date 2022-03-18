from scripts.deploy import deploy_factory
from brownie import accounts
import requests
import json
from dotenv import load_dotenv
import os

load_dotenv()

# Checks 1USD worth of LINK with 20% margin
# Add your `COVALENT_API_KEY` to .env otherwise test will fail
# https://www.covalenthq.com/platform/#/auth/register/
def test_get_price_covalent():
    api_key = os.getenv("COVALENT_API_KEY")
    dev = accounts[0]
    token = "0x514910771AF9Ca656af840dff83E8264EcF986CA"  # LINK

    factory_contract = deploy_factory(dev)
    response = requests.get(
        f"https://api.covalenthq.com/v1/pricing/historical_by_addresses_v2/1/USD/{token}/?quote-currency=USD&format=JSON&key={api_key}"
    )
    parsed = json.loads(response.text)
    covalent_token_price = 1 / float((parsed["data"][0]["prices"][0]["price"]))
    covalent_token_decimals = int((parsed["data"][0]["contract_decimals"]))
    contract_token_decimals = factory_contract.STABLECOIN_DECIMALS()
    contract_token_price = factory_contract.getAverageTokenPrice(
        token, 1 * (10**contract_token_decimals)
    ) / (10**covalent_token_decimals)
    covalent_plus_20 = covalent_token_price * (1.2)
    covalent_minus_20 = covalent_token_price * (0.8)

    assert covalent_plus_20 >= contract_token_price >= covalent_minus_20
