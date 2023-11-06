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
  const experiment =
    await hre.ethers.deployContract("Experiment");
  console.log(
    `Experiment contract deployed to: ${await experiment.getAddress()}`
  );

  // const experiment =
  //   await hre.ethers.getContractAt(
  //     "Experiment",
  //     "0xc824Cb40e4253Ae1A7C024eFc20eD9f788645b9a"
  //   );

  // experiment.setAB(3, 4);
  // experiment.setLol(true);
  experiment.setProduct(
    1000, // productId
    "0x4bBa290826C253BD854121346c370a9886d1bC26",
    "0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0",
    2, // amount
    3, // period
    4, // freeTrialLength
    5, // paymentPeriod
    "0x455e4d92c5de1bb7bcf28c4768d4d9e1d076b69a980d3db2870558985a03be5c"
  );

  experiment.loadProduct(1000);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
