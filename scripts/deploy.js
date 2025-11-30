// scripts/deploy.js
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // Deploy MockRewardToken
  const RewardToken = await hre.ethers.getContractFactory("MockRewardToken");
  const rewardToken = await RewardToken.deploy();
  await rewardToken.waitForDeployment();

  const rewardTokenAddress = rewardToken.target;
  console.log("MockRewardToken deployed at:", rewardTokenAddress);

  // Deploy ConsentManager
  const ConsentManager = await hre.ethers.getContractFactory("ConsentManager");
  const consentManager = await ConsentManager.deploy(rewardTokenAddress);
  await consentManager.waitForDeployment();

  const consentManagerAddress = consentManager.target;
  console.log("ConsentManager deployed at:", consentManagerAddress);

  // Deploy DataSharing
  const DataSharing = await hre.ethers.getContractFactory("DataSharing");
  const dataSharing = await DataSharing.deploy(consentManagerAddress);
  await dataSharing.waitForDeployment();

  const dataSharingAddress = dataSharing.target;
  console.log("DataSharing deployed at:", dataSharingAddress);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
