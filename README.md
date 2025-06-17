# Compound v2 Liquidation Bot

A sophisticated Solidity-based bot that demonstrates the historical price manipulation vulnerability in Compound v2 during DeFi Summer 2020.

##  Overview

This project replicates the historical exploit where a liquidator gained an edge by manipulating the Open Price Feed in Compound v2. The bot demonstrates how stale but valid signed prices could be used to trigger liquidations before other market participants could react.

### Key Features

- Simulates price manipulation using stale-but-valid signed price data
- Executes `liquidateBorrow()` on undercollateralized accounts
- Built with Foundry for efficient testing and deployment
- Uses mainnet forking for realistic testing conditions
- Demonstrates the exact attack vector used on August 20, 2020

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) (v16 or later)
- [Git](https://git-scm.com/)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/6ixty80/liquidation-bot.git
cd liquidation-bot
```

2. Install dependencies:
```bash
forge install
```

3. Build the project:
```bash
forge build
```

### Testing

Run the test suite:
```bash
forge test
```

For verbose output:
```bash
forge test -vv
```

##  Configuration

The bot can be configured through environment variables:

- `RPC_URL`: Your Ethereum node RPC URL
- `PRIVATE_KEY`: Your wallet's private key
- `GAS_PRICE`: Maximum gas price in wei
- `GAS_LIMIT`: Gas limit for transactions

##  Disclaimer

This project is for educational purposes only. It demonstrates a historical vulnerability that has been patched in newer versions of Compound. Do not use this code for malicious purposes.

##  License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

##  Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.





