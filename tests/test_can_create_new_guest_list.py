from brownie import accounts
from scripts.deploy import deploy_factory, deploy_guest_list

# TODO: import wrapper address from setup file

def test_can_create_new_guest_list():
    factory_contract = deploy_factory()
    guest_list_contract = deploy_guest_list(factory_contract)

    expected_wrapper = '0xE59ca38ffa335c3983D8C9221f225845B5D93671'

    assert guest_list_contract # Gueslist exists
    assert guest_list_contract.wrapper() == expected_wrapper # Wrapper was set correctly


