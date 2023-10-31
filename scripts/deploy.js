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
      "0xB38Bb847D9dC852B70d9ed539C87cF459812DA16", // default initiator
      10000000000000000, // setting fee to 1%
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
