// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

/// @title SaleBNBSTEW
contract SaleBNBSTEW is Ownable {
    // solhint-disable-next-line var-name-mixedcase
    ERC20 public STEWContract;

    mapping(address => bool) public isAddressWhiteListed;

    bool public isPreSale = false;
    bool public isSalePaused = false;
    bool public hasSaleEnded = false;
    bool public hasSaleStarted = false;
    uint256 public soldStewTokens = 0;

    uint256 public constant STEW_TOKENS_FOR_SALE = 147000;
    uint256 public constant STEW_TOKENS_PRE_SALE_PER_BNB = 15;
    uint256 public constant STEW_TOKENS_PUBLIC_SALE_PER_BNB = 12;

    event SalePaused();
    event SaleUnPaused();

    /**
     * @dev Sets the values {STEWContract}
     *
     * All two of these values are immutable: they can only be set once during
     * construction
     */
    constructor(address stewContract) public {
        require(isContract(stewContract), "STEW address can't be EOA");
        STEWContract = ERC20(stewContract);
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     * The receive function is executed on a call to the contract with empty calldata.
     */
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /**
     * @dev The fallback function is executed on a call to the contract if
     * none of the other functions match the given function signature.
     */
    fallback() external payable {}

    /**
     * @dev Toggles the sale state from pre-sale to public-sale and vice-versa.
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function toggleSalePreToPublic() public onlyOwner {
        isPreSale = !isPreSale;
    }

    /**
     * @dev To pause sale in case of an vulnerable attack.
     *
     * Emits an {SalePaused} event.
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function pauseSale() public onlyOwner {
        isSalePaused = true;
        emit SalePaused();
    }

    /**
     * @dev Starts sale.
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    /**
     * @dev Ends sale.
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function endSale() public onlyOwner {
        hasSaleStarted = false;
    }

    /**
     * @dev To unpause a sale after the attack risks has been addressed.
     *
     * Emits an {SaleUnPaused} event.
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function unPauseSale() public onlyOwner {
        isSalePaused = false;
        emit SaleUnPaused();
    }

    /**
     * @dev Sets isAddressWhiteListed to `true` for the given address.
     *
     * Requirements:
     * - `whiteListAddress[i]` cannot be the zero address.
     * - `i` can range from 0 to n.
     * - invocation can be done, only by the contract owner.
     */
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

    /**
     * @dev Moves `STEW` tokens from `this contract` to `caller{msg.sender}` &
     * `BNB` from `caller{msg.sender}` to `this contract`.
     * During PreSale, trying to buy STEWs less than 15 results in a revert.
     *
     * Requirements:
     * - `isSalePaused` must be false.
     * - already sold STEW tokens + STEW tokens to buy < `STEW_TOKENS_FOR_SALE`.
     * - in case of pre-sale only white list addresses can buy STEW.
     * - STEW token transfer from `this contract` to `msg.sender` must succeed.
     * - BNB transfer from `msg.sender` to `this contract` must succeed.
     */
    function buySTEWs() public payable {
        require(!isSalePaused, "Cannot buy, sale is paused");
        require(!hasSaleEnded, "Sale ended");
        require(hasSaleStarted, "Wait for the sale to start");
        uint256 stewsForBNB = getSTEWsForBNB(msg.value, msg.sender);
        uint256 numSTEWsCallerGets = soldStewTokens + stewsForBNB;
        require(
            numSTEWsCallerGets <= STEW_TOKENS_FOR_SALE,
            "Buying exceeds available STEWs"
        );
        soldStewTokens += stewsForBNB;
        if (soldStewTokens == STEW_TOKENS_FOR_SALE) {
            hasSaleEnded = true;
        }
        require(
            STEWContract.transfer(msg.sender, stewsForBNB),
            "STEW transfer failed"
        );
    }

    /**
     * @dev To transfer all BNBs from `this contract` to `owner`
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     * - BNB token transfer from `this contract` to `msg.sender` must succeed.
     */
    function withdrawBNBs() public onlyOwner {
        require(
            payable(msg.sender).send(address(this).balance),
            "Withdraw BNB failed"
        );
    }

    /**
     * @dev To move STEW tokens from `this contract` to `owner`
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     * - STEW token transfer from `this contract` to `msg.sender` must succeed.
     */
    function transferSTEWs() public onlyOwner {
        uint256 contractSTEWBal = STEWContract.balanceOf(address(this));
        require(
            STEWContract.transfer(msg.sender, contractSTEWBal),
            "transferSTEWs failed"
        );
    }

    /**
     * @dev Returns the number of STEWs a user can get
     *
     * Requirements:
     * - during presale, the caller must be a white listed address
     */
    function getSTEWsForBNB(uint256 noOfBNBs, address caller)
        internal
        view
        returns (uint256)
    {
        if (isPreSale) {
            require(noOfBNBs >= 1e18, "1 BNB minimum criteria fails");
            require(isAddressWhiteListed[caller], "Caller is not white listed");
            return noOfBNBs * STEW_TOKENS_PRE_SALE_PER_BNB;
        }
        return noOfBNBs * STEW_TOKENS_PUBLIC_SALE_PER_BNB;
    }

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
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
