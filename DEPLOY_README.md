# Steps to use the deployed network
## Set-up
In one terminal window:
```
npx hardhat node
```

In another terminal window:
```
npx hardhat run scripts/deploy.js --network localhost
```

Then:

```
npx hardhat console
```

## Operations on the blockchain

Get accounts:
```
const [deployer, alice] = await ethers.getSigners();
console.log("Deployer:", deployer.address);
console.log("Alice:", alice.address);
```

Create new user:
```
const bobWallet = ethers.Wallet.createRandom();
console.log("Bob (new account):", bobWallet.address);
```

Connect to deployed contracts:
```
const rewardToken = await ethers.getContractAt("MockRewardToken", "<Address from set-up step>");
const consentManager = await ethers.getContractAt("ConsentManager", "<Address from set-up step>");
const dataSharing = await ethers.getContractAt("DataSharing", "<Address from set-up step>");
```

Create data:
```
const dataId = ethers.id("bob-data-001");
await dataSharing.connect(bob).createData(dataId, "Some sensitive info");
console.log("Data created with ID:", dataId);
```

Give consent to other party:
```
await consentManager.connect(bob).setConsent(alice.address, ["email", "phone"], 30);
console.log("Consent given to Alice");
```

Accessing data with consent:
```
const dataId = ethers.id("bob-data-001");  


const hasConsent = await consentManager.connect(alice).checkConsent(bob.address, dataId);
console.log("Alice has consent to access Bob's data?", hasConsent);

if (hasConsent) {
    const retrievedData = await dataSharing.connect(alice).getData(bob.address, dataId);
    console.log("Alice reads Bob's data:", retrievedData);
} else {
    console.log("Access denied: no consent.");
}
```
