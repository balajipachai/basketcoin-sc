// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

/// @title SaleBNBSTEW
/// @author Balaji Shetty Pachai
contract SaleBNBSTEW is Ownable {
    // solhint-disable-next-line var-name-mixedcase
    ERC20 public BNBContract;
    // solhint-disable-next-line var-name-mixedcase
    ERC20 public STEWContract;

    mapping(address => bool) public isAddressWhiteListed;

    bool public isPreSale = false;
    bool public isSalePaused = false;
    uint256 public soldStewTokens = 0;

    uint256 public constant STEW_TOKENS_FOR_SALE = 147000;
    uint256 public constant STEW_TOKENS_PRE_SALE_PER_BNB = 15;
    uint256 public constant STEW_TOKENS_PUBLIC_SALE_PER_BNB = 12;

    event SalePaused();
    event SaleUnPaused();

    constructor(address bnbContract, address stewContract) public {
        require(isContract(bnbContract), "BNB address can't be EOA");
        require(isContract(stewContract), "STEW address can't be EOA");
        BNBContract = ERC20(bnbContract);
        STEWContract = ERC20(stewContract);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    fallback() external payable {}

    function addWhitelistAddresses(address[] memory whiteListAddresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < whiteListAddresses.length; i++) {
            require(
                whiteListAddresses[i] != address(0),
                "Zero address not allowed"
            );
            isAddressWhiteListed[whiteListAddresses[i]] = true;
        }
    }

    function toggleSale() public onlyOwner {
        isPreSale = !isPreSale;
    }

    function pauseSale() public onlyOwner {
        isSalePaused = true;
        emit SalePaused();
    }

    function unPauseSale() public onlyOwner {
        isSalePaused = true;
        emit SaleUnPaused();
    }

    function buySTEWs(uint256 noOfSTEWs) public {
        require(!isSalePaused, "Cannot buy, sale is paused");
        require(
            (soldStewTokens + noOfSTEWs) <= STEW_TOKENS_FOR_SALE,
            "Sale ended"
        );
        uint256 requireBNBs;
        if (isPreSale) {
            // Only white listed address can buy
            requireBNBs = noOfSTEWs / STEW_TOKENS_PRE_SALE_PER_BNB;
            require(
                BNBContract.balanceOf(msg.sender) >= requireBNBs,
                "Insufficient BNB balance"
            );
            require(
                isAddressWhiteListed[msg.sender],
                "Caller is not white listed"
            );
        } else {
            // Any other address can buy
            requireBNBs = noOfSTEWs / STEW_TOKENS_PUBLIC_SALE_PER_BNB;
            require(
                BNBContract.balanceOf(msg.sender) >= requireBNBs,
                "Insufficient BNB balance"
            );
        }
        soldStewTokens += noOfSTEWs;
        require(
            STEWContract.transfer(msg.sender, noOfSTEWs),
            "STEW transfer failed"
        );
        require(
            BNBContract.transferFrom(msg.sender, address(this), requireBNBs),
            "BNB transfer failed"
        );
    }

    function transferBNBs() public onlyOwner {
        uint256 contractBNBBal = BNBContract.balanceOf(address(this));
        require(
            BNBContract.transfer(msg.sender, contractBNBBal),
            "transferBNBs failed"
        );
    }

    function transferSTEWs() public onlyOwner {
        uint256 contractSTEWBal = STEWContract.balanceOf(address(this));
        require(
            STEWContract.transfer(msg.sender, contractSTEWBal),
            "transferSTEWs failed"
        );
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
