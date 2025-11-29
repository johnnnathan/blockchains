import { ethers } from "ethers";
import RewardTokenArtifact from "../artifacts/contracts/RewardToken.sol/RewardToken.json"; // path may vary

const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
const deployer = new ethers.Wallet(PRIVATE_KEY, provider);

async function main() {
  console.log("Deploying with:", await deployer.getAddress());

  // Use ethers.ContractFactory from ethers.js
  const factory = new ethers.ContractFactory(
    RewardTokenArtifact.abi,
    RewardTokenArtifact.bytecode,
    deployer
  );

  const rewardToken = await factory.deploy("RewardToken", "RWT");
  await rewardToken.waitForDeployment();

  console.log("RewardToken deployed at:", rewardToken.target);
}

main().catch(console.error);
