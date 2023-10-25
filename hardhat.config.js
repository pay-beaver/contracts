require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-web3");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    hardhat: {
      chainId: 80001,
    },
    tenderly: {
      url: "https://rpc.vnet.tenderly.co/devnet/beaver-router/d9f401d0-8dd3-4453-bd4e-0542404488b6",
      accounts: [
        `0x${process.env.DEPLOYER_PRIVATE_KEY}`,
        `0x${process.env.RANDOM_PRIVATE_KEY}`,
      ],
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [
        `0x${process.env.DEPLOYER_PRIVATE_KEY}`,
      ],
    },
    mumbai: {
      url: "https://rpc.ankr.com/polygon_mumbai",
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
      polygonMumbai:
        process.env.POLYGON_ETHERSCAN_API_KEY,
      basegoerli:
        process.env.BASE_ETHERSCAN_API_KEY,
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
