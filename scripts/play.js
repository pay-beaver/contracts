// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  let [owner, randomSigner, randomSigner2] =
    await hre.ethers.getSigners();
  console.log(
    `Working with signer: ${await owner.getAddress()}`
  );
  console.log(
    "RandomSigner addresses are:",
    randomSigner.address,
    randomSigner2.address
  );

  const router = await hre.ethers.getContractAt(
    "BeaverRouter",
    "0x6A490220ee1CcD1A96121EA326c00346b3dEc3Df"
  );
  // await router.setupEnvironmentAndStartSubscription(
  //   randomSigner2.address, // merchant
  //   "0x87A94DC5556D5EBFe5728BA2b09382382a9f8aEf", // token (ND Coin)
  //   1000000, // amount
  //   10, // period
  //   1, // freeTrialLength
  //   1000000000, // paymentPeriod
  //   "0x9f0ef6bd5c94780edaa0abbc62a04457d2554aa04d1087b6250d901ca201c4d2", // productMetadata,
  //   "0x455e4d92c5de1bb7bcf28c4768d4d9e1d076b69a980d3db2870558985a03be5c" // subscriptionMetadata
  // );
  // await router.startSubscription(
  //   "0x32818596df7f72d79690bc1d10d2a727947cda1a59e77550ed4c28f0b81ba0f2", // productHash
  //   "0xB38Bb847D9dC852B70d9ed539C87cF459812DA16" // initiator
  // );
  // await router
  //   .connect(randomSigner2)
  //   .changeInitiator(
  //     randomSigner2.address,
  //     randomSigner.address
  //   );
  const subscriptionData =
    await router.subscriptions(
      "0x66b10fd144f53e62142e96ccbf5d46883d90f4744454930ec09f5cd74cf391e3"
    );
  console.log(
    "subscriptionData",
    subscriptionData
  );
  // const initiator = await router.merchantSettings[]

  await router.connect(randomSigner).makePayment(
    "0x66b10fd144f53e62142e96ccbf5d46883d90f4744454930ec09f5cd74cf391e3", //subscriptionHash
    1000 // compensation
  );
  // await router.terminateSubscription(
  //   "0x0743bca3bd578c952076b2fb7aa6ed9e580d15d58f71909ed406a5cba3b9de41"
  // );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
