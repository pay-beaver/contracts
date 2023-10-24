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
      5000000000000000, // setting fee to 0.5%
    ]
  );
  console.log(
    `Router deployed to: ${await router.getAddress()}`
  );
  await router.createProduct(
    "0x34207C538E39F2600FE672bB84A90efF190ae4C7", // merchant
    "0x9f0ef6bd5c94780edaa0abbc62a04457d2554aa04d1087b6250d901ca201c4d2", // metadata
    "0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0", // token
    1000000, // amount
    3600 // period
    1800, // freeTrialLength
    1800, // paymentPeriod
    // "0xB38Bb847D9dC852B70d9ed539C87cF459812DA16", // initiator
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
