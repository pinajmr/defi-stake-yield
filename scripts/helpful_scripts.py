from brownie import (
    accounts,
    network,
    config,
    Contract,
    MockV3Aggregator,
    MockDAI,
    MockWETH,
)


NON_FORKED_LOCAL_BLOCKCHAIN_ENVIROMENTS = ["hardhat", "ganache", "development"]
LOCAL_BLOCKCHAIN_ENVIRONMENTS = NON_FORKED_LOCAL_BLOCKCHAIN_ENVIROMENTS + [
    "mainnet-fork",
    "mainnet-fork-dev",
    "binance-fork",
    "matic-fork",
]

contract_to_mock = {
    "eth_usd_price_feed": MockV3Aggregator,
    "dai_usd_price_feed": MockV3Aggregator,
    "fau_token": MockDAI,
    "weth_token": MockWETH,
}


INITIAL_PRICE_FEED_VALUE = 2000000000000000000000
DECIMALS = 18


def get_account(index=None, id=None):
    if index:
        return accounts[index]
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        return accounts[0]
    if id:
        return accounts.load(id)
    return accounts.add(config["wallets"]["from_key"])


def get_contract(contract_name):
    contract_type = contract_to_mock[contract_name]
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        if len(contract_type) <= 0:
            deploy_mocks()
        contract = contract_type[-1]
    else:
        try:
            contract_address = config["networks"][network.show_active()][contract_name]
            contract = Contract.from_abi(
                contract_type._name, contract_address, contract_type.abi
            )
        except KeyError:
            print(
                f"{network.show_active()} address not found, perhaps you should add it to the config or deploy mocks?"
            )
            print(
                f"brownie run scripts/deploy_mocks.py --network {network.show_active()}"
            )
    return contract


def deploy_mocks(decimals=DECIMALS, initial_value=INITIAL_PRICE_FEED_VALUE):
    """
    if you want to deploy mocks to a testnet
    """
    print(f"The active network is {network.show_active()}")
    print("Deploying mocks")
    account = get_account()
    print("Deploying Mock Price Feed")
    mock_price_feed = MockV3Aggregator.deploy(
        decimals,
        initial_value,
        {"from": account},
    )
    print(f"Deployed Mock Price Feed at {mock_price_feed.address}")
    print("Deploying Mock DAI . . .")
    mock_dai = MockDAI.deploy({"from": account})
    print(f"Deployed Mock DAI at {mock_dai.address}")
    print("Deploying Mock WETH . . .")
    mock_weth = MockWETH.deploy({"from": account})
    print(f"Deployed Mock WETH at {mock_weth.address}")
    print(f"Mocks Deployed!")
