## 🌐 General Overview

Welcome to our **MultiVaul**, an innovative system designed to manage digital assets across multiple blockchains while ensuring security, efficiency, and flexibility. This protocol leverages cutting-edge technologies such as **ERC6551** for advanced NFT-based asset ownership, **LayerZero** for omnichain communication, **Chainlink** oracles for reliable price and volatility data, and **Uniswap** for decentralized trading with built-in risk management. Together, these components create a robust framework for seamless cross-chain asset management, tailored to meet the needs of both managers and depositors.

### 🔗 The Hub and Spoke Chain Architecture

At the core of the protocol is a **hub-and-spoke chain model**, which allows vaults to securely manage assets across multiple chains while maintaining centralized control on a hub chain. Here's how it works:

- **Vault Creation**: Every vault is created on the **hub chain**, which serves as the central chain in this multichain system. Upon vault creation, a **Non-Fungible Token (NFT)** is minted on the hub chain. This NFT serves as a digital representation of vault ownership and provides access to manage the vault’s assets.

- **ERC6551 Standard**: To facilitate more advanced NFT functionalities, we utilize the **ERC6551 standard**. This allows the NFT to not only represent ownership but also link to a vault account that holds the assets. When the NFT is minted, it simultaneously creates a **hubchain account**, where the vault’s assets will be stored on the hub chain.

- **Spoke Chains for Asset Extension**: While the assets are initially stored on the hubchain, the protocol enables the vault manager to extend operations across multiple blockchains, known as **spoke chains**. By registering accounts on these spoke chains, the vault can interact with assets on various chains, creating a truly **multichain** management system.

This architecture provides both flexibility and security by allowing assets to be controlled from a central hub chain, while still maintaining the capability to extend and manage assets on other chains.

### 💰 Deposits, Stablecoins, and Position Representation

The vault is designed to handle **deposits** in the form of **stablecoins**. These stablecoins provide a stable asset base for vault management and are key to ensuring predictable and secure operations for depositors. Here’s how the deposit process works:

- **Depositor Interaction**: When a depositor wishes to contribute to the vault, they deposit a **stablecoin**  (the currency of the protocol, USDC for example). However, before the deposit is accepted, the protocol needs to determine the **quota price** of the vault, ensuring that the depositor’s position is accurately valued based on real-time market data.

- **Chainlink Price Feeds**: To ensure accurate pricing, the protocol integrates **Chainlink oracles**. These oracles fetch the latest price data from decentralized sources, ensuring that the vault’s quota price is always up-to-date and tamper-proof. The depositor’s position is then calculated based on the vault’s current value, and they receive **ERC20 tokens** that represent their share or position in the vault.

- **ERC20 Position Tokens**: These ERC20 tokens function as a liquid representation of the depositor’s ownership stake in the vault. As the value of the vault fluctuates, these tokens reflect the current worth of the depositor’s position, providing full transparency and liquidity.

### 🌍 Omnichain Asset Management with LayerZero

One of the key innovations of the protocol is its **omnichain** capability, made possible by **LayerZero**, a decentralized interoperability protocol. LayerZero allows seamless communication between the hub chain and various spoke chains, enabling the vault manager to securely manage assets across multiple chains.

- **Spoke Chain Registration**: In order to extend asset management to a new chain, the vault manager registers a **spoke account** on the desired spoke chain. This process is facilitated by a **LayerZero Omnichain Application (OApp)**, which handles cross-chain messaging and transactions. The OApp consists of two main components:
  - **Factory Contract**: Deployed on the hub chain, this contract serves as the central point for managing vault registrations on spoke chains.
  - **Registry Contract**: Deployed on the spoke chains, this contract interacts with the hubchain’s factory to register the vault’s spoke account. The registry also includes the **_lzReceive** function, which handles incoming cross-chain transactions.

- **Omnichain Transactions**: When the vault manager wants to register a spoke account on a new chain, they initiate a transaction on the **Factory contract** on the hub chain. The Factory then communicates with the **Registry contract** on the spoke chain via **LayerZero** to complete the registration process. This allows the vault to securely hold assets on the spoke chain while still being centrally managed from the hub.

This structure ensures that each vault maintains control over its assets across multiple chains while reducing the risk associated with cross-chain operations.

### 📊 Asset Volatility and Risk Management

Risk management is critical in decentralized finance, especially in multichain environments where assets are spread across different blockchains with varying levels of volatility. The protocol employs a sophisticated risk management strategy powered by **Chainlink oracles** and a custom **Uniswap Hook**.

- **Volatility Tracking**: The protocol continuously tracks the **volatility** of each asset within the vault using data provided by **Chainlink**. This volatility data is used to assess the risk of the assets held in the vault, providing both the manager and depositors with clear insights into the vault’s exposure.

- **Total Value Locked (TVL)**: Each vault tracks its **Total Value Locked (TVL)** in USD, representing the overall value of the assets held. The vault’s volatility is then calculated based on the weighted volatility of each asset divided by the TVL. This provides a clear picture of the vault’s risk profile.

- **Uniswap Hook for Transaction Risk Management**: To further mitigate risk, a custom **Uniswap Hook** is implemented. This hook monitors every transaction involving asset swaps on Uniswap, calculating the **delta volatility** — the difference in volatility between the assets being traded. This ensures that no transaction exceeds the vault’s allowed maximum volatility threshold. Additionally, the hook verifies that all tokens involved in the transaction are **whitelisted**, adding an extra layer of security.

This combination of **Chainlink volatility tracking** and **Uniswap risk management** ensures that the protocol remains secure and that all transactions adhere to predefined risk parameters.

### 🔐 Security and Reliability

Security is at the forefront of the protocol’s design, with several layers of protection in place:

- **Decentralized Ownership**: By leveraging the ERC6551 standard, vault ownership is decentralized and tied to NFTs, ensuring that ownership and control are immutable and secure.
- **Cross-Chain Security**: LayerZero’s omnichain messaging protocol ensures secure communication between chains, reducing the risk of exploits during cross-chain operations.
- **Price and Volatility Oracles**: Chainlink oracles provide tamper-proof price and volatility data, ensuring that the vault’s assets are accurately valued and managed.
- **Risk Management**: The Uniswap Hook enforces strict risk parameters, preventing transactions from exceeding volatility limits and ensuring that only whitelisted tokens are involved.

In summary, this protocol provides a comprehensive, secure, and flexible system for managing assets across multiple blockchains. By leveraging the power of **ERC6551**, **LayerZero**, **Chainlink**, and **Uniswap**, the protocol offers a decentralized solution that prioritizes security, efficiency, and transparency for both managers and depositors.


### 🧪 Testing the Uniswap Hook

To ensure the Uniswap Hook functions as expected, you can build and test it using the following steps:

1. **Navigate to the Project Directory**:
   Open your terminal and navigate to the `hook-risk` folder.

2. **Build the Project**:
   Before running the tests, ensure the project is built by using the `forge` tool:

   ```bash
   forge build

This command will compile all the smart contracts and generate the necessary build artifacts.

Run the Tests: After successfully building the project, run the tests for the Uniswap Hook by executing:

    ```bash
    forge test


### 🧪 Running the LayerZero Tests

To ensure that the LayerZero functionality works as expected, follow these steps to build and run the tests:

1. **Navigate to the Project Directory**:
   Open your terminal and navigate to the root directory of the project.

2. **Run the Tests**:
   To execute the tests for LayerZero integration, use the following command:

   ```bash
   npm run test:forge
