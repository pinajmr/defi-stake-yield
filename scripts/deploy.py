from scripts.helpful_scripts import get_account, get_contract
from brownie import config, PinaToken, TokenFarm, network
from web3 import Web3

KEPT_BALANCE = Web3.toWei(100, "ether")


def deploy_token_farm_and_pina_token(front_end_update=False):
    account = get_account()
    pina_token = PinaToken.deploy({"from": account})
    token_farm = TokenFarm.deploy(
        pina_token.address,
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify"),
    )
    tx = pina_token.transfer(
        token_farm.address, pina_token.totalSupply() - KEPT_BALANCE, {"from": account}
    )
    tx.wait(1)
    fau_token = get_contract("fau_token")
    weth_token = get_contract("weth_token")

    add_allowed_tokens(
        token_farm,
        {
            pina_token: get_contract("dai_usd_price_feed"),
            fau_token: get_contract("dai_usd_price_feed"),
            weth_token: get_contract("eth_usd_price_feed"),
        },
        account,
    )
    # if update_front_end_flag:
    #     update_front_end()
    return token_farm, pina_token


def add_allowed_tokens(token_farm, dict_of_allowed_token, account):
    for token in dict_of_allowed_token:
        token_farm.addAllowedTokens(token.address, {"from": account})
        tx = token_farm.setPriceFeedContract(
            token.address, dict_of_allowed_token[token], {"from": account}
        )
        tx.wait(1)
    return token_farm


def main():
    deploy_token_farm_and_pina_token()
