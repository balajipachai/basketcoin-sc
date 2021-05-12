// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

/// @title STEW
/// @author Balaji Shetty Pachai
/// @notice ERC-20 implementation of STEW token
contract STEW is ERC20, Ownable {
    uint256 public tokenDecimals;

    constructor() public ERC20("StewCoin", "STEW") {
        tokenDecimals = 18;
        super._mint(msg.sender, 210000); // Since Total supply 210000
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    fallback() external payable {}

    function decimals(uint256 noOfDecimals) public onlyOwner {
        tokenDecimals = noOfDecimals;
    }

    function withdrawAll() public payable onlyOwner {
        require(
            payable(msg.sender).send(address(this).balance),
            "Withdraw failed"
        );
    }
}
