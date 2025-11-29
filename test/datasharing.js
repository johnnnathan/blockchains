const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DataSharing", function () {
    let owner, requester, otherUser;
    let rewardToken, consentManager, dataSharing;

    beforeEach(async function () {
        [owner, requester, otherUser] = await ethers.getSigners();

        // 1. Setup dependency: RewardToken and ConsentManager
        // must ensure the RewardToken trusts the ConsentManager address.
        const RewardToken = await ethers.getContractFactory("RewardToken");
        const ConsentManager = await ethers.getContractFactory("ConsentManager");
        const DataSharing = await ethers.getContractFactory("DataSharing");

        const nonce = await owner.getNonce();
        // Predict the address where ConsentManager will be deployed (+1 because RewardToken is next)
        const consentManagerAddress = ethers.getCreateAddress({ from: owner.address, nonce: nonce + 1 });

        // Deploy RewardToken passing the future ConsentManager address
        rewardToken = await RewardToken.deploy("Reward", "RWD", 18, consentManagerAddress);
        await rewardToken.waitForDeployment();

        // Deploy ConsentManager
        consentManager = await ConsentManager.deploy(rewardToken.target);
        await consentManager.waitForDeployment();

        // 2. Deploy DataSharing
        dataSharing = await DataSharing.deploy(consentManager.target);
        await dataSharing.waitForDeployment();
    });

    it("should allow access and log success when valid consent exists", async function () {
        // Setup: Owner grants consent to Requester for "CREDIT"
        await consentManager.connect(owner).setConsent(requester.address, ["CREDIT"], 30);

        await expect(dataSharing.connect(requester).accessData(owner.address, "CREDIT"))
            .to.emit(dataSharing, "AccessAttempt")
            .withArgs(1, owner.address, requester.address, "CREDIT", true, (val) => val > 0);

        // Verification: Check the stored audit log
        const log = await dataSharing.getAuditLog(1);
        expect(log.granted).to.equal(true);
        expect(log.requester).to.equal(requester.address);
        expect(log.owner).to.equal(owner.address);
        expect(log.dataType).to.equal("CREDIT");
    });

    it("should deny access and log failure when no consent exists", async function () {
        // Action: Requester tries to access without prior consent
        await expect(dataSharing.connect(requester).accessData(owner.address, "INCOME"))
            .to.emit(dataSharing, "AccessAttempt")
            .withArgs(1, owner.address, requester.address, "INCOME", false, (val) => val > 0);

        // Verification: Check the stored audit log
        const log = await dataSharing.getAuditLog(1);
        expect(log.granted).to.equal(false);
    });

    it("should deny access and log failure when data type is not allowed", async function () {
        // Setup: Consent only for "CREDIT"
        await consentManager.connect(owner).setConsent(requester.address, ["CREDIT"], 30);

        // Action: Requester asks for "INCOME"
        await dataSharing.connect(requester).accessData(owner.address, "INCOME");

        // Verification
        const log = await dataSharing.getAuditLog(1);
        expect(log.granted).to.equal(false);
        expect(log.dataType).to.equal("INCOME");
    });

    it("should deny access and log failure when consent is revoked", async function () {
        // Setup: Grant then Revoke
        await consentManager.connect(owner).setConsent(requester.address, ["CREDIT"], 30);
        const consentId = 1;
        await consentManager.connect(owner).revokeConsent(consentId);

        // Action: Access attempt
        await dataSharing.connect(requester).accessData(owner.address, "CREDIT");

        // Verification
        const log = await dataSharing.getAuditLog(1);
        expect(log.granted).to.equal(false);
    });

    it("should increment log IDs correctly for multiple attempts", async function () {
        await consentManager.connect(owner).setConsent(requester.address, ["CREDIT"], 30);

        // Attempt 1: Success
        await dataSharing.connect(requester).accessData(owner.address, "CREDIT");
        
        // Attempt 2: Fail (Different user)
        await dataSharing.connect(otherUser).accessData(owner.address, "CREDIT");

        const log1 = await dataSharing.getAuditLog(1);
        const log2 = await dataSharing.getAuditLog(2);

        expect(log1.logId).to.equal(1);
        expect(log1.granted).to.equal(true);

        expect(log2.logId).to.equal(2);
        expect(log2.granted).to.equal(false); // Other user has no consent
        expect(log2.requester).to.equal(otherUser.address);
    });
});