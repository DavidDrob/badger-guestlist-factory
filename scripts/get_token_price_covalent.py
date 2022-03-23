import requests
import json
from dotenv import load_dotenv
import os


def get_token_price_covalent(token):
    load_dotenv()
    api_key = os.getenv("COVALENT_API_KEY")

    response = requests.get(
        f"https://api.covalenthq.com/v1/pricing/historical_by_addresses_v2/1/USD/{token}/?quote-currency=USD&format=JSON&key={api_key}"
    )
    parsed = json.loads(response.text)

    if (parsed["data"][0]["prices"][0]["price"]) == None:
        return 0
    covalent_token_price = float((parsed["data"][0]["prices"][0]["price"]))

    return covalent_token_price
