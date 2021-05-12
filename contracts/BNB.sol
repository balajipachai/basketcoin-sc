// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

/// @title BNB
/// @author Balaji Shetty Pachai
/// @notice ERC-20 implementation of BNB token
contract BNB is ERC20, Ownable {
    uint256 public tokenDecimals;

    constructor(uint256 initialSupply) public ERC20("BNBCoin", "BNB") {
        tokenDecimals = 18;
        super._mint(msg.sender, initialSupply);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    fallback() external payable {}

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

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
