// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    address[] public allowedTokens;
    IERC20 public pinaToken;
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    address[] public stakers;
    mapping(address => address) public tokenPriceFeedMapping;

    constructor(address _pinaTokenAddress) public {
        pinaToken = IERC20(_pinaTokenAddress);
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "Amount must be more than 0");
        require(tokenIsAllowed(_token), "Token is currectly no allowed");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function unStakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;

        if (uniqueTokensStaked[msg.sender] == 0) {
            for (
                uint256 stakersIndex = 0;
                stakersIndex < stakers.length;
                stakersIndex
            ) {
                if (stakers[stakersIndex] == msg.sender) {
                    stakers[stakersIndex] = stakers[stakers.length - 1];
                    stakers.pop();
                }
            }
        }
    }

    function issueTokens() public onlyOwner {
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            pinaToken.transfer(recipient, userTotalValue);
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        // price of token * stakingBalance[_token][_user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakingBalance[_token][_user] * price) / (10 * decimals));
        // 10000000000000000000 ETH
        // ETH/USD -> 10000000000
        // 10 * 100 = 1,000
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // PriceFeedAddress
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public view returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }
}
