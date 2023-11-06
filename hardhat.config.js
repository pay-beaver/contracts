require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-web3");
require("xdeployer");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    hardhat: {
      chainId: 80001,
    },
    tenderly: {
      url: "https://rpc.vnet.tenderly.co/devnet/beaver-router/4899271c-bd3c-44e7-97ab-893ca2f317bb",
      accounts: [
        `0x${process.env.DEPLOYER_PRIVATE_KEY}`,
        `0x${process.env.RANDOM_PRIVATE_KEY}`,
        `0x${process.env.RANDOM_PRIVATE_KEY_2}`,
      ],
    },
    sepolia: {
      url: "https://eth-sepolia-public.unifra.io",
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
      url: "https://goerli.base.org",
      accounts: [
        `0x${process.env.DEPLOYER_PRIVATE_KEY}`,
      ],
      gasPrice: 1 * 10 ** 9 + 100,
    },
    base: {
      url: "https://mainnet.base.org",
      accounts: [
        `0x${process.env.PRODUCTION_DEPLOYER_PRIVATE_KEY}`,
      ],
    },
    polygon: {
      url: "https://polygon.llamarpc.com",
    },
  },
  xdeploy: {
    contract: "BeaverRouter",
    constructorArgsPath: "./deploymentArgs.js",
    salt: "beaver-v1.1",
    signer: `0x${process.env.PRODUCTION_DEPLOYER_PRIVATE_KEY}`,
    networks: [
      // "sepolia",
      // "baseTestnet",
      // "mumbai",
      // "polygon",
    ],
    rpcUrls: [
      // "https://eth-sepolia-public.unifra.io",
      // "https://goerli.base.org",
      // "https://rpc.ankr.com/polygon_mumbai",
      // "https://polygon.llamarpc.com",
    ],
    gasLimit: 1_500_000, // optional; default value is `1.5e6`
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY,
      polygon:
        process.env.POLYGON_ETHERSCAN_API_KEY,
      polygonMumbai:
        process.env.POLYGON_ETHERSCAN_API_KEY,
      base: process.env.BASE_ETHERSCAN_API_KEY,
      baseGoerli:
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
