// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  let [owner] = await hre.ethers.getSigners();
  console.log(
    `Working with signer: ${await owner.getAddress()}`
  );
  const router = await hre.ethers.deployContract(
    "BeaverRouter",
    [
      "0x4bBa290826C253BD854121346c370a9886d1bC26", // owner
      "0x6Ef7cAADbc1E82cf288D756E42481Cb8Dce9B827", // default initiator
    ]
  );
  console.log(
    `Router deployed to: ${await router.getAddress()}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
