// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  let [owner, randomSigner] =
    await hre.ethers.getSigners();
  console.log(
    `Working with signer: ${await owner.getAddress()}`
  );
  console.log(
    "RandomSigner address is:",
    randomSigner.address
  );

  const router = await hre.ethers.getContractAt(
    "BeaverRouter",
    "0xc824Cb40e4253Ae1A7C024eFc20eD9f788645b9a"
  );
  await router.createProductAndStartSubscription(
    "0x34207C538E39F2600FE672bB84A90efF190ae4C7", // merchant
    "0x9f0ef6bd5c94780edaa0abbc62a04457d2554aa04d1087b6250d901ca201c4d2", // metadata
    "0x6B175474E89094C44Da98b954EedeAC495271d0F", // token (DAI)
    1000000, // amount
    10, // period
    0, // freeTrialLength
    1000000000, // paymentPeriod
    randomSigner.address // initiator
  );
  // await router.startSubscription(
  //   "0x32818596df7f72d79690bc1d10d2a727947cda1a59e77550ed4c28f0b81ba0f2", // productHash
  //   "0xB38Bb847D9dC852B70d9ed539C87cF459812DA16" // initiator
  // );
  // await router.makePayment(
  //   "0x9e08d57d342df9be7043b80b0ab887697d4f48eddd3531448e983b8b059b2c18", //subscriptionHash
  //   100000 // compensation
  // );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
