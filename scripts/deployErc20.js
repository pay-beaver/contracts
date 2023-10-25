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
  const ndCoin = await hre.ethers.deployContract(
    "NDCoinERC20",
    [(10 ** 20).toString()]
  );

  console.log(
    `NDCoin deployed to: ${await ndCoin.getAddress()}`
  );

  const ndCoin = await hre.ethers.getContractAt(
    "NDCoinERC20",
    "0xc824Cb40e4253Ae1A7C024eFc20eD9f788645b9a",
    owner
  );

  // ndCoin.approve(
  //   "0xc824Cb40e4253Ae1A7C024eFc20eD9f788645b9a", // router
  //   500000000000 // amount
  // );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
