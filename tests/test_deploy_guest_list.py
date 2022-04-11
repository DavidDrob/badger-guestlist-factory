from scripts.get_token_price_covalent import get_token_price_covalent
from setup.config import WRAPPER, USER_DEPOSIT_CAP, TOTAL_DEPOSIT_CAP
import pytest

MAX_NUM = 115792089237316195423570985008687907853269984665640564039457584007913129639935


def test_can_create_new_guest_list(guestlist):
    expected_wrapper = WRAPPER
    guest_list_contract = guestlist

    assert guest_list_contract  # Gueslist was deployed
    assert (
        guest_list_contract.wrapper() == expected_wrapper
    )  # Wrapper was set correctly


def test_dev_is_owner(guestlist, deployer):
    guest_list_contract = guestlist

    assert deployer.address == guest_list_contract.owner()


def test_deposit_caps_are_correct(factory, guestlist):

    factory_contract = factory
    guest_list_contract = guestlist

    token = factory_contract.getVaultTokenAddress(WRAPPER)
    covalent_token_price, covalent_token_decimals = get_token_price_covalent(token)

    if (
        covalent_token_price == 0
        or guest_list_contract.userDepositCap() == MAX_NUM
        or guest_list_contract.totalDepositCap() == MAX_NUM
    ):
        pytest.skip()

    assert (
        float((USER_DEPOSIT_CAP / covalent_token_price) * 1.3)
        >= float(guest_list_contract.userDepositCap() / (10**covalent_token_decimals))
        >= float((USER_DEPOSIT_CAP / covalent_token_price) * 0.7)
    )

    assert (
        float((TOTAL_DEPOSIT_CAP / covalent_token_price) * 1.3)
        >= float(
            guest_list_contract.totalDepositCap() / (10**covalent_token_decimals)
        )
        >= float((TOTAL_DEPOSIT_CAP / covalent_token_price) * 0.7)
    )
