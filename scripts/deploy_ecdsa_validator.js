// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const [owner] = await hre.ethers.getSigners();
  console.log(`Working with signer: ${await owner.getAddress()}`);
  const validator = await hre.ethers.deployContract("ECDSAValidator");
  console.log(`Validator deployed to: ${await validator.getAddress()}`);

  const ecdsaValidatorStorageSample = await validator.ecdsaValidatorStorage(
    await owner.getAddress()
  );
  console.log(`ecdsaValidatorStorage: ${ecdsaValidatorStorageSample}`);

  // const result = await owner.call({
  //   to: await validator.getAddress(),
  //   data: validator.interface.encodeFunctionData("validateSignature", [
  //     "0xaadfd7f476296ca5018ee0f8a3735440f3fbb3d7d7519b065e1acd48162373ba",
  //     "0x1c70846e4040e275070a233c8602e89f3cf89115917f8705a53f3b8d3fa2124a2a46ea8b71f02c3f6383ca8c7f24d88eb26d3651ef812ae6f6457bd321c347b81c",
  //   ]),
  // });
  // console.log(`Result: ${result}`);
  // ("0x00000002000000000000000000000000306E63F9044886ceD28ED89C1e6001E81b6f3655E0196A80b669Fe9cD70f57C48A768Bf64a1447d2000000000000000000000000000000000000000000000000000000000000001493e5d723902C96D6B8af04cA6F26C9a3EA8b356600000000000000000000000000000000000000000000000000000000000000411c70846e4040e275070a233c8602e89f3cf89115917f8705a53f3b8d3fa2124a2a46ea8b71f02c3f6383ca8c7f24d88eb26d3651ef812ae6f6457bd321c347b81c000064fac933e5252f83b48997e3af94fedea5a4bc579529b5041f87a0e41856cfcffd9086f45db76025623e1836fc1b445538a8afa65b540c2e9513facc9bfce06c5b66e34b1c");
  const computedSignature =
    "0x00000002000000000000000000000000306E63F9044886ceD28ED89C1e6001E81b6f3655E0196A80b669Fe9cD70f57C48A768Bf64a1447d2000000000000000000000000000000000000000000000000000000000000001493e5d723902C96D6B8af04cA6F26C9a3EA8b356600000000000000000000000000000000000000000000000000000000000000411c70846e4040e275070a233c8602e89f3cf89115917f8705a53f3b8d3fa2124a2a46ea8b71f02c3f6383ca8c7f24d88eb26d3651ef812ae6f6457bd321c347b81c000064fac933e5252f83b48997e3af94fedea5a4bc579529b5041f87a0e41856cfcffd9086f45db76025623e1836fc1b445538a8afa65b540c2e9513facc9bfce06c5b66e34b1c";

  let signature = "0x";
  signature += "0".repeat(4 * 2); // mode
  const secondBlock =
    "000000000000000000000000306E63F9044886ceD28ED89C1e6001E81b6f3655"; // validAfter, validUntil, validatorAddress
  signature += secondBlock;
  signature += "E0196A80b669Fe9cD70f57C48A768Bf64a1447d2"; // executor address
  console.log("Signature:", signature);

  // let enableData = "93e5d723902C96D6B8af04cA6F26C9a3EA8b3566";
  // const enableDataLength = enableData.length / 2;
  // signature += enableDataLength.toString(16).padStart(64, "0");
  // signature += enableData;

  // const result = await owner.call({
  //   to: await validator.getAddress(),
  //   data: validator.interface.encodeFunctionData("example", [
  //     "0x40a7be02",
  //     signature,
  //   ]),
  // });
  // console.log(`Result: ${result}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
