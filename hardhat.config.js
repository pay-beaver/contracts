require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    hardhat: {
      chainId: 80001,
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [
        `0x${process.env.DEPLOYER_PRIVATE_KEY}`,
      ],
    },
    mumbai: {
      url: process.env.MUMBAI_RPC_URL,
      accounts: [
        `0x${process.env.DEPLOYER_PRIVATE_KEY}`,
      ],
    },
    basegoerli: {
      url: "https://rpc.notadegen.com/base/goerli",
      accounts: [
        `0x${process.env.DEPLOYER_PRIVATE_KEY}`,
      ],
      gasPrice: 1 * 10 ** 9 + 100,
    },
    base: {
      url: "https://mainnet.base.org",
      accounts: [
        `0x${process.env.DEPLOYER_PRIVATE_KEY}`,
      ],
    },
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY,
    },
  },
  solidity: {
    version: "0.8.19",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 5000,
      },
    },
  },
};
