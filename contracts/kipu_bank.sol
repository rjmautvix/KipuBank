// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/**
 * @title KipuBank
 * @author Rodrigo José Malavasi
 * @notice Simple per-user Ether vault with global deposit cap and per-transaction withdrawal limit.
 * @dev Follows checks-effects-interactions; uses custom errors, immutables, events, modifiers and NatSpec.
 */
contract KipuBank {
    /// @notice Emitted when a user deposits ETH into their vault
    /// @param user The depositor address
    /// @param amount Amount of wei deposited
    /// @param totalBankBalance New total bank balance after deposit
    event Deposited(address indexed user, uint256 amount, uint256 totalBankBalance);

    /// @notice Emitted when a user withdraws ETH from their vault
    /// @param user The withdrawer address
    /// @param amount Amount of wei withdrawn
    /// @param totalBankBalance New total bank balance after withdrawal
    event Withdrawn(address indexed user, uint256 amount, uint256 totalBankBalance);


    /// @notice Thrown when deposit would exceed the global bank cap
    error ErrExceedsBankCap(uint256 attempted, uint256 available);

    /// @notice Thrown when the transfer of ETH fails
    error ErrTransferFailed(address to, uint256 amount);

    /// @notice Thrown when user tries to withdraw more than balance
    error ErrInsufficientBalance(uint256 requested, uint256 balance);

    /// @notice Thrown when the requested withdrawal exceeds per-transaction limit
    error ErrExceedsWithdrawalLimit(uint256 requested, uint256 limit);

    /// @notice Thrown when an operation receives zero value where non-zero was expected
    error ErrZeroAmount();

    /// @notice Thrown when the provided bank cap is zero
    error ErrInvalidBankCap();

    /// @notice Thrown when the provided withdrawal limit is zero
    error ErrInvalidWithdrawalLimit();

    /// @notice Thrown when a call is made to a non-existent function
    error ErrInvalidCall();


    /// @notice Global cap for all deposits (in wei). Set at deployment and immutable.
    uint256 public immutable bankCap;

    /// @notice Per-transaction withdrawal limit (in wei). Set at deployment and immutable.
    uint256 public immutable withdrawalLimit;

    /// @notice Mapping of user => balance (in wei)
    mapping(address => uint256) private balances;

    /// @notice Mapping to track number of deposits per user
    mapping(address => uint256) public depositCount;

    /// @notice Mapping to track number of withdrawals per user
    mapping(address => uint256) public withdrawalCount;

    /// @notice Total wei ever deposited into the bank (cumulative)
    uint256 public totalDeposits;

    /// @notice Total wei ever withdrawn from the bank (cumulative)
    uint256 public totalWithdrawals;


    /// @notice Ensures a non-zero amount is provided
    modifier nonZero(uint256 amount) {
        if (amount == 0) revert ErrZeroAmount();
        _;
    }

    /**
     * @param _bankCap The global deposit cap in wei (cannot be changed after deployment)
     * @param _withdrawalLimit The maximum amount (wei) allowed per single withdrawal
     */
    constructor(uint256 _bankCap, uint256 _withdrawalLimit) {
        if (_bankCap == 0) revert ErrInvalidBankCap();
        if (_withdrawalLimit == 0) revert ErrInvalidWithdrawalLimit();

        bankCap = _bankCap;
        withdrawalLimit = _withdrawalLimit;
    }

    /**
     * @notice Deposit native ETH to the caller's personal vault
     * @dev Emits `Deposited` event. Respects the global `bankCap`.
     */
    function deposit() external payable nonZero(msg.value) {
        _deposit(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw `amount` wei from caller's vault. Subject to `withdrawalLimit`.
     * @dev Uses checks-effects-interactions pattern and the private `_sendNative` helper.
     * @param amount Amount in wei to withdraw
     */
    function withdraw(uint256 amount) external nonZero(amount) {
        uint256 bal = balances[msg.sender];
        if (amount > bal) revert ErrInsufficientBalance(amount, bal);
        if (amount > withdrawalLimit) revert ErrExceedsWithdrawalLimit(amount, withdrawalLimit);

        balances[msg.sender] = bal - amount;
        withdrawalCount[msg.sender] += 1;
        totalWithdrawals += amount;
        uint256 newTotalBalance = address(this).balance - amount;

        _sendNative(payable(msg.sender), amount);

        emit Withdrawn(msg.sender, amount, newTotalBalance);
    }

    /**
     * @notice Get the balance of a specific user
     * @param user Address to query
     * @return The user's balance in wei
     */
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    /**
     * @notice Returns the bank's current on-chain balance (sum of all user balances)
     * @return The bank contract balance in wei
     */
    function bankBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Internal deposit logic shared by `deposit()` and receive()
     * @param user The beneficiary of the deposit
     * @param amount The amount in wei
     */
    function _deposit(address user, uint256 amount) private {
        uint256 prevBalance = address(this).balance - amount;
        uint256 available = bankCap - prevBalance;
        if (amount > available) revert ErrExceedsBankCap(amount, available);

        // Effects
        balances[user] += amount;
        depositCount[user] += 1;
        totalDeposits += amount;

        emit Deposited(user, amount, address(this).balance);
    }

    /**
     * @notice Safely send native ETH using `call` and bubble up a clear custom error on failure
     * @param to Recipient address
     * @param amount Amount in wei
     */
    function _sendNative(address payable to, uint256 amount) private {
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert ErrTransferFailed(to, amount);
    }

    /// @notice Accept plain ETH transfers and credit them as deposits to the sender
    receive() external payable nonZero(msg.value) {
        _deposit(msg.sender, msg.value);
    }

    /// @notice Prevent accidental calls to non-existent functions
    fallback() external payable {
        revert ErrInvalidCall();
    }
}
