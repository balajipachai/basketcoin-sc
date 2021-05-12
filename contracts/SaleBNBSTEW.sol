// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

/// @title SaleBNBSTEW
contract SaleBNBSTEW is Ownable {
    // solhint-disable-next-line var-name-mixedcase
    ERC20 public BNBContract;
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
     * @dev Sets the values for {BNBContract} and {STEWContract}
     *
     * All two of these values are immutable: they can only be set once during
     * construction
     */
    constructor(address bnbContract, address stewContract) public {
        require(isContract(bnbContract), "BNB address can't be EOA");
        require(isContract(stewContract), "STEW address can't be EOA");
        BNBContract = ERC20(bnbContract);
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
        require(!hasSaleStarted, "Can't add whitelist sale started");
        for (uint256 i = 0; i < whiteListAddresses.length; i++) {
            require(
                whiteListAddresses[i] != address(0),
                "Zero address not allowed"
            );
            isAddressWhiteListed[whiteListAddresses[i]] = true;
        }
        hasSaleStarted = true;
    }

    /**
     * @dev Moves `STEW` tokens from `this contract` to `caller{msg.sender}` &
     * `BNB` tokens from `caller{msg.sender}` to `this contract`.
     * `requireBNBs`: Number of BNBs required to buy STEWs
     * During PreSale, trying to buy STEWs less than 15 results in a revert.
     *
     * Requirements:
     * - `isSalePaused` must be false.
     * - already sold STEW tokens + STEW tokens to buy < `STEW_TOKENS_FOR_SALE`.
     * - BNB token balance of `msg.sender` must be greater than `requireBNBs`.
     * - in case of pre-sale only white list address can buy STEW.
     * - STEW token transfer from `this contract` to `msg.sender` must succeed.
     * - BNB token transfer from `msg.sender` to `this contract` must succeed.
     */
    function buySTEWs(uint256 noOfSTEWs) public {
        require(!isSalePaused, "Cannot buy, sale is paused");
        require(!hasSaleEnded, "Sale ended");
        require(hasSaleStarted, "Wait for the sale to start");
        uint256 numSTEWsCallerGets = soldStewTokens + noOfSTEWs;
        // THIS ADDRESES THE SCENARIO OF SAY, STEW_TOKENS_FOR_SALE = 147000,
        // soldStewTokens = 146900, call to buySTEWs(150), here the caller gets,
        // 100 STEWs out of 150 STEWs
        if (numSTEWsCallerGets > STEW_TOKENS_FOR_SALE) {
            numSTEWsCallerGets = STEW_TOKENS_FOR_SALE - soldStewTokens;
            // It implies that all STEWs are sold out, thus set hasSaleEnded to true
            hasSaleEnded = true;
        } else {
            numSTEWsCallerGets = numSTEWsCallerGets;
        }
        uint256 requireBNBs;
        if (isPreSale) {
            // Only white listed address can buy
            require(numSTEWsCallerGets >= 15, "1 BNB minimum criteria fails");
            requireBNBs = numSTEWsCallerGets / STEW_TOKENS_PRE_SALE_PER_BNB;
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
            requireBNBs = numSTEWsCallerGets / STEW_TOKENS_PUBLIC_SALE_PER_BNB;
            require(
                BNBContract.balanceOf(msg.sender) >= requireBNBs,
                "Insufficient BNB balance"
            );
        }
        soldStewTokens += numSTEWsCallerGets;
        require(
            STEWContract.transfer(msg.sender, numSTEWsCallerGets),
            "STEW transfer failed"
        );
        require(
            BNBContract.transferFrom(msg.sender, address(this), requireBNBs),
            "BNB transfer failed"
        );
    }

    /**
     * @dev To move BNB tokens from `this contract` to `owner`
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     * - BNB token transfer from `this contract` to `msg.sender` must succeed.
     */
    function transferBNBs() public onlyOwner {
        uint256 contractBNBBal = BNBContract.balanceOf(address(this));
        require(
            BNBContract.transfer(msg.sender, contractBNBBal),
            "transferBNBs failed"
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
