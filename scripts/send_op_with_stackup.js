// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const BigNumber = require("@ethersproject/bignumber").BigNumber;
const userop = require("userop");

const FACTORY_ADDRESS = "0x1F4e471f0aA399399Da43dA39D49c9f999271847";
const FACTORY_ABI = [
  {
    inputs: [
      {
        internalType: "contract IEntryPoint",
        name: "_entryPoint",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [],
    name: "accountImplementation",
    outputs: [
      { internalType: "contract SimpleAccount", name: "", type: "address" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "owner", type: "address" },
      { internalType: "uint256", name: "salt", type: "uint256" },
    ],
    name: "createAccount",
    outputs: [
      { internalType: "contract SimpleAccount", name: "ret", type: "address" },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "owner", type: "address" },
      { internalType: "uint256", name: "salt", type: "uint256" },
    ],
    name: "getAddress",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
];

const WALLET_ADDRESS = "0x83F252b3eC42E85A9eb62993e570238eE477Ea92";
const WALLET_ABI = [
  {
    inputs: [
      {
        internalType: "contract IEntryPoint",
        name: "anEntryPoint",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "previousAdmin",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "newAdmin",
        type: "address",
      },
    ],
    name: "AdminChanged",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "beacon",
        type: "address",
      },
    ],
    name: "BeaconUpgraded",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: "uint8", name: "version", type: "uint8" },
    ],
    name: "Initialized",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "contract IEntryPoint",
        name: "entryPoint",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
    ],
    name: "SimpleAccountInitialized",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "implementation",
        type: "address",
      },
    ],
    name: "Upgraded",
    type: "event",
  },
  {
    inputs: [],
    name: "addDeposit",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "entryPoint",
    outputs: [
      { internalType: "contract IEntryPoint", name: "", type: "address" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "dest", type: "address" },
      { internalType: "uint256", name: "value", type: "uint256" },
      { internalType: "bytes", name: "func", type: "bytes" },
    ],
    name: "execute",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address[]", name: "dest", type: "address[]" },
      { internalType: "uint256[]", name: "value", type: "uint256[]" },
      { internalType: "bytes[]", name: "func", type: "bytes[]" },
    ],
    name: "executeBatch",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "getDeposit",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getNonce",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "address", name: "anOwner", type: "address" }],
    name: "initialize",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "", type: "address" },
      { internalType: "address", name: "", type: "address" },
      { internalType: "uint256[]", name: "", type: "uint256[]" },
      { internalType: "uint256[]", name: "", type: "uint256[]" },
      { internalType: "bytes", name: "", type: "bytes" },
    ],
    name: "onERC1155BatchReceived",
    outputs: [{ internalType: "bytes4", name: "", type: "bytes4" }],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "", type: "address" },
      { internalType: "address", name: "", type: "address" },
      { internalType: "uint256", name: "", type: "uint256" },
      { internalType: "uint256", name: "", type: "uint256" },
      { internalType: "bytes", name: "", type: "bytes" },
    ],
    name: "onERC1155Received",
    outputs: [{ internalType: "bytes4", name: "", type: "bytes4" }],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "", type: "address" },
      { internalType: "address", name: "", type: "address" },
      { internalType: "uint256", name: "", type: "uint256" },
      { internalType: "bytes", name: "", type: "bytes" },
    ],
    name: "onERC721Received",
    outputs: [{ internalType: "bytes4", name: "", type: "bytes4" }],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [],
    name: "owner",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "proxiableUUID",
    outputs: [{ internalType: "bytes32", name: "", type: "bytes32" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "bytes4", name: "interfaceId", type: "bytes4" }],
    name: "supportsInterface",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "", type: "address" },
      { internalType: "address", name: "", type: "address" },
      { internalType: "address", name: "", type: "address" },
      { internalType: "uint256", name: "", type: "uint256" },
      { internalType: "bytes", name: "", type: "bytes" },
      { internalType: "bytes", name: "", type: "bytes" },
    ],
    name: "tokensReceived",
    outputs: [],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "newImplementation", type: "address" },
    ],
    name: "upgradeTo",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "newImplementation", type: "address" },
      { internalType: "bytes", name: "data", type: "bytes" },
    ],
    name: "upgradeToAndCall",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        components: [
          { internalType: "address", name: "sender", type: "address" },
          { internalType: "uint256", name: "nonce", type: "uint256" },
          { internalType: "bytes", name: "initCode", type: "bytes" },
          { internalType: "bytes", name: "callData", type: "bytes" },
          { internalType: "uint256", name: "callGasLimit", type: "uint256" },
          {
            internalType: "uint256",
            name: "verificationGasLimit",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "preVerificationGas",
            type: "uint256",
          },
          { internalType: "uint256", name: "maxFeePerGas", type: "uint256" },
          {
            internalType: "uint256",
            name: "maxPriorityFeePerGas",
            type: "uint256",
          },
          { internalType: "bytes", name: "paymasterAndData", type: "bytes" },
          { internalType: "bytes", name: "signature", type: "bytes" },
        ],
        internalType: "struct UserOperation",
        name: "userOp",
        type: "tuple",
      },
      { internalType: "bytes32", name: "userOpHash", type: "bytes32" },
      { internalType: "uint256", name: "missingAccountFunds", type: "uint256" },
    ],
    name: "validateUserOp",
    outputs: [
      { internalType: "uint256", name: "validationData", type: "uint256" },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address payable",
        name: "withdrawAddress",
        type: "address",
      },
      { internalType: "uint256", name: "amount", type: "uint256" },
    ],
    name: "withdrawDepositTo",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  { stateMutability: "payable", type: "receive" },
];

const ENTRY_POINT_ADDRESS = "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789";

async function main() {
  // const pimlicoProvider = new hre.ethers.JsonRpcApiProvider(
  //   process.env.PIMLICO_SEPOLIA_RPC_URL
  // );
  const stackupProvider = new hre.ethers.JsonRpcProvider(
    process.env.STACKUP_SEPOLIA_RPC_URL
  );
  const signer = new hre.ethers.Wallet(process.env.DEPLOYER_PRIVATE_KEY);
  const factoryContract = new hre.ethers.Contract(FACTORY_ADDRESS, FACTORY_ABI);
  const walletContract = new hre.ethers.Contract(WALLET_ADDRESS, WALLET_ABI);
  const simpleAccountBuilder = new userop.UserOperationBuilder().useDefaults({
    sender: WALLET_ADDRESS,
  });

  const initCode = hre.ethers.concat([
    FACTORY_ADDRESS,
    factoryContract.interface.encodeFunctionData("createAccount", [
      await signer.getAddress(),
      2, // salt
    ]),
  ]);

  const callData = walletContract.interface.encodeFunctionData("execute", [
    ENTRY_POINT_ADDRESS,
    "1000000000000000",
    "0x",
  ]);

  const fetchGasPrice = async (ctx) => {
    // Fetch the latest gas prices.
    const fee = await stackupProvider.send("eth_maxPriorityFeePerGas");
    const block = await stackupProvider.getBlock("latest");
    const tip = BigNumber.from(fee);
    const buffer = tip.div(100).mul(13);
    const maxPriorityFeePerGas = tip.add(buffer);
    // const maxFeePerGas = block.baseFeePerGas
    //   ? block.baseFeePerGas.mul(2).add(maxPriorityFeePerGas)
    //   : maxPriorityFeePerGas;
    ctx.op.maxFeePerGas = BigNumber.from(block.baseFeePerGas).add(tip);
    ctx.op.maxPriorityFeePerGas = maxPriorityFeePerGas;
  };

  const estimateGasLimiit = async (ctx) => {
    // console.log("aaaa userop", ctx.op);
    console.log("gas limit");
    const est = await stackupProvider.send("eth_estimateUserOperationGas", [
      userop.Utils.OpToJSON(ctx.op),
      ctx.entryPoint,
    ]);
    console.log("gooot");
    ctx.op.preVerificationGas = 3000000;
    ctx.op.verificationGasLimit = 3000000;
    ctx.op.callGasLimit = 3000000;
  };

  const signUserOperation = async (ctx) => {
    console.log("signing");
    console.log(1);
    const arrayed = hre.ethers.toBeArray(ctx.getUserOpHash());
    console.log(2);
    const signature = await signer.signMessage(arrayed);
    console.log(3);
    console.log("aaaa signature", signature);
    ctx.op.signature = signature;
  };

  simpleAccountBuilder
    .useMiddleware(signUserOperation)
    .useMiddleware(fetchGasPrice)
    .useMiddleware(estimateGasLimiit);

  simpleAccountBuilder.setInitCode(initCode).setNonce(0).setCallData("0x");

  const client = await userop.Client.init(process.env.STACKUP_SEPOLIA_RPC_URL);
  console.log("aaaa userop", simpleAccountBuilder.getOp());
  const userOp = await client.buildUserOperation(simpleAccountBuilder);
  console.log("aaaa userOp", userOp);
  const result = await client.sendUserOperation(simpleAccountBuilder);
  console.log("Waiting for transaction...");
  const ev = await result.wait();
  console.log(`Transaction hash: ${ev?.transactionHash ?? null}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
