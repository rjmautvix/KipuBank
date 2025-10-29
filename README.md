# 🏦 KipuBank Smart Contract

## Overview

**KipuBank** is a decentralized smart contract built in Solidity that functions as a secure Ether vault for individual users.  
Each user has their own personal balance and can deposit or withdraw Ether under specific safety rules.

The contract enforces two main limits:
1. A **global deposit cap (`bankCap`)** that restricts the total amount of Ether that can be stored in the vault.
2. A **per-transaction withdrawal limit (`withdrawLimit`)** that prevents users from withdrawing more than a fixed amount in a single operation.

Every deposit and withdrawal triggers an **event** for transparency, and all key actions are protected with **custom errors** instead of `require` messages to improve gas efficiency and clarity.

KipuBank also tracks:
- The total number of deposits and withdrawals made.
- Each user’s current balance in their personal vault.

The contract follows Solidity best practices, such as:
- The **checks-effects-interactions** pattern to prevent reentrancy vulnerabilities.
- Use of **modifiers** for input validation.
- Clean and well-documented state variables using **NatSpec comments**.

In short, KipuBank serves as a simple, transparent, and secure on-chain vault system that demonstrates Solidity fundamentals with production-grade coding standards.

## ⚙️ Deployment Instructions (via Remix IDE)

Follow the steps below to deploy the **KipuBank** smart contract using the [Remix IDE](https://remix.ethereum.org/):

### 1. Open Remix
Go to [https://remix.ethereum.org](https://remix.ethereum.org) and make sure the **Solidity** environment is selected.

### 2. Create a New File
1. In the **File Explorer**, click the **"contracts"** folder.  
2. Create a new file named `KipuBank.sol`.  
3. Paste the full contract code into this file.

### 3. Compile the Contract
1. In the left sidebar, select the **"Solidity Compiler"** tab.  
2. Choose the compiler version **0.8.22**.  
3. Click **Compile KipuBank.sol**.  
   - If everything is correct, you should see a green checkmark next to the file name.

### 4. Deploy the Contract
1. Go to the **"Deploy & Run Transactions"** tab (Ethereum logo).  
2. Set the **Environment** to:
   - **"Injected Provider - MetaMask"** if deploying to a real testnet (like **Sepolia**).  
   - **"Remix VM"** if you only want to test locally.
3. Make sure your MetaMask wallet is connected and has test ETH.  
4. In the **constructor parameters**, provide:
   - `_bankCap`: The total amount of Ether (in wei) that the contract can hold.  
   - `_withdrawalLimit`: The maximum amount (in wei) allowed per withdrawal.
   > Example:  
   > `_bankCap = 10 ether` → `10000000000000000000`  
   > `_withdrawalLimit = 1 ether` → `1000000000000000000`
5. Click **Deploy** and confirm the transaction in MetaMask.

### 5. Verify Deployment
Once deployed:
- The contract will appear under **"Deployed Contracts"** in Remix.  
- You can expand it to view and interact with all available functions (`deposit`, `withdraw`, `getBalance`, etc.).  
- You can also verify the contract on a block explorer (e.g., [Etherscan](https://sepolia.etherscan.io/)) by matching the deployed bytecode and publishing the source.

## 💬 How to Interact with the Contract

Once the **KipuBank** contract is deployed, you can interact with it directly from **Remix**, a **block explorer (like Etherscan)**, or through **web3 scripts** using libraries such as `ethers.js` or `web3.js`.

Below are the main ways to interact with the contract through **Remix**:

---

### 🔹 1. Deposit Ether

**Function:** `deposit()`  
**Type:** `external payable`

1. In Remix, expand your deployed contract under the **"Deployed Contracts"** section.  
2. Select the `deposit` function.  
3. In the **"Value"** field (above the functions list), enter the amount of Ether to deposit — for example, `1 ether`.  
4. Click **transact**, then confirm the transaction in MetaMask.  

✅ **Result:**  
- The Ether is added to your personal vault (`balances[msg.sender]`).  
- The event `Deposited` is emitted.  
- Your `depositCount` increases by one.

---

### 🔹 2. Withdraw Ether

**Function:** `withdraw(uint256 amount)`  
**Type:** `external`

1. Enter the amount (in wei) you wish to withdraw.  
   - Example: To withdraw **0.5 ETH**, input `500000000000000000`.  
2. Click **transact** and confirm the transaction in MetaMask.  

⚠️ **Rules:**
- You cannot withdraw more than your balance.  
- You cannot withdraw more than the `withdrawalLimit` defined at deployment.

✅ **Result:**  
- Ether is transferred to your wallet.  
- The event `Withdrawn` is emitted.  
- Your `withdrawalCount` increases by one.

---

### 🔹 3. Check Your Balance

**Function:** `getBalance(address user)`  
**Type:** `external view`  
**Returns:** The balance (in wei) for the provided address.

To check your own balance:
1. Copy your wallet address.  
2. Paste it into the `user` field.  
3. Click **call**.  

The function will return your vault balance in wei.  
> Tip: 1 ether = 1e18 wei.

---

### 🔹 4. View the Bank’s Total Balance

**Function:** `bankBalance()`  
**Type:** `external view`

This returns the total amount of Ether currently stored in the contract — that is, the sum of all user balances.

---

### 🔹 5. Send ETH Directly (via `receive()`)

You can also deposit by **sending Ether directly to the contract address**, without calling `deposit()`.

For example:
- From MetaMask, click “Send”.
- Paste the contract address.
- Enter the amount of ETH to send.

The contract will automatically process the deposit and emit the `Deposited` event.

---

### 🔹 6. Invalid Calls

If you accidentally call a non-existent function or send a transaction with incorrect data,  
the contract will revert with the custom error `ErrInvalidCall()` — ensuring clarity and preventing misuse.

---

### 🧠 Summary of Available Functions

| Function | Type | Description |
|-----------|------|-------------|
| `deposit()` | `external payable` | Deposit Ether into your personal vault |
| `withdraw(uint256 amount)` | `external` | Withdraw Ether from your vault |
| `getBalance(address user)` | `external view` | View any user's vault balance |
| `bankBalance()` | `external view` | Get total Ether stored in the contract |
| `receive()` | `external payable` | Automatically triggered on direct ETH transfers |
| `fallback()` | `external payable` | Reverts with `ErrInvalidCall()` |

---

KipuBank was designed to be transparent, secure, and educational — showing best Solidity practices in action while maintaining simplicity for easy testing and demonstration.
