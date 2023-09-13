require("dotenv").config();

const { ECDSAProvider } = require("@zerodev/sdk");
const { PrivateKeySigner } = require("@alchemy/aa-core");
const {
  encodeFunctionData,
  parseAbi,
  createPublicClient,
  http,
} = require("viem");
const { polygonMumbai } = require("viem/chains");

// ZeroDev Project ID
const projectId = process.env.ZERODEV_PROJECT_ID;

// The "owner" of the AA wallet, which in this case is a private key
const owner = PrivateKeySigner.privateKeyToAccountSigner(
  `0x${process.env.RANDOM_PRIVATE_KEY}`
);

// The NFT contract we will be interacting with
const contractAddress = "0x34bE7f35132E97915633BC1fc020364EA5134863";
const contractABI = parseAbi([
  "function mint(address _to) public",
  "function balanceOf(address owner) external view returns (uint256 balance)",
]);
const publicClient = createPublicClient({
  chain: polygonMumbai,
  // the API is rate limited and for demo purposes only
  // in production, replace this with your own node provider (e.g. Infura/Alchemy)
  transport: http(
    "https://polygon-mumbai.infura.io/v3/f36f7f706a58477884ce6fe89165666c"
  ),
});

const main = async () => {
  // Create the AA wallet
  const ecdsaProvider = await ECDSAProvider.init({
    projectId,
    owner,
    opts: {
      paymasterConfig: {
        policy: "TOKEN_PAYMASTER",
        gasToken: "USDC",
      },
    },
  });
  const address = await ecdsaProvider.getAddress();
  console.log("My address:", address);

  // Mint the NFT
  const { hash } = await ecdsaProvider.sendUserOperation({
    target: contractAddress,
    data: encodeFunctionData({
      abi: contractABI,
      functionName: "mint",
      args: [address],
    }),
  });
  await ecdsaProvider.waitForUserOperationTransaction(hash);

  // Check how many NFTs we have
  const balanceOf = await publicClient.readContract({
    address: contractAddress,
    abi: contractABI,
    functionName: "balanceOf",
    args: [address],
  });
  console.log(`NFT balance: ${balanceOf}`);
};

main().then(() => process.exit(0));
