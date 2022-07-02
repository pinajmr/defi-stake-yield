//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PinaToken is ERC20 {
    constructor() public ERC20("Pina Token", "PINA") {
        _mint(msg.sender, 10240000000000000000000000);
    }
}
