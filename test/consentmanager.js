const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ConsentManager", function () {
    let owner, requester, attacker;
    let rewardToken, consentManager;
    let allowedTypes;

    beforeEach(async function () {
        [owner, requester, attacker] = await ethers.getSigners();

        // Create a placeholder RewardToken first
        const RewardToken = await ethers.getContractFactory("RewardToken");
        rewardToken = await RewardToken.deploy("Reward", "RWD", 18, owner.address);
        await rewardToken.waitForDeployment();

        // Deploy ConsentManager
        const ConsentManager = await ethers.getContractFactory("ConsentManager");
        consentManager = await ConsentManager.deploy(rewardToken.target);
        await consentManager.waitForDeployment();

        // Rebind reward token minter to ConsentManager
        rewardToken = await RewardToken.deploy("Reward", "RWD", 18, consentManager.target);
        await rewardToken.waitForDeployment();

        allowedTypes = ["CREDIT", "INCOME"];
    });

    it("should create consent", async function () {
        await consentManager.connect(owner).setConsent(requester.address, allowedTypes, 10);

        const consent = await consentManager.getConsent(1);
        expect(consent.owner).to.equal(owner.address);
        expect(consent.requester).to.equal(requester.address);
        expect(consent.active).to.equal(true);

        expect(await rewardToken.balanceOf(owner.address)).to.equal(ethers.parseEther("1"));
    });

    it("should fail with invalid duration", async function () {
        await expect(
            consentManager.connect(owner).setConsent(requester.address, allowedTypes, 0)
        ).to.be.revertedWith("InvalidDuration()");

        await expect(
            consentManager.connect(owner).setConsent(requester.address, allowedTypes, 400)
        ).to.be.revertedWith("InvalidDuration()");
    });

    it("should fail with empty allowed list", async function () {
        await expect(
            consentManager.connect(owner).setConsent(requester.address, [], 10)
        ).to.be.revertedWith("InvalidDuration()");
    });

    it("should revoke consent", async function () {
        await consentManager.connect(owner).setConsent(requester.address, allowedTypes, 10);
        await consentManager.connect(owner).revokeConsent(1);

        const consent = await consentManager.getConsent(1);
        expect(consent.active).to.equal(false);
    });

    it("should fail revoking from non-owner", async function () {
        await consentManager.connect(owner).setConsent(requester.address, allowedTypes, 10);

        await expect(
            consentManager.connect(attacker).revokeConsent(1)
        ).to.be.revertedWith("NotConsentOwner()");
    });

    it("should check consent valid", async function () {
        await consentManager.connect(owner).setConsent(requester.address, allowedTypes, 10);

        const allowed = await consentManager.checkConsent(
            owner.address,
            requester.address,
            "CREDIT"
        );
        expect(allowed).to.equal(true);
    });

    it("should reject wrong data type", async function () {
        await consentManager.connect(owner).setConsent(requester.address, allowedTypes, 10);

        const allowed = await consentManager.checkConsent(
            owner.address,
            requester.address,
            "PAYMENT_HISTORY"
        );
        expect(allowed).to.equal(false);
    });

    it("should reject expired consent", async function () {
        await consentManager.connect(owner).setConsent(requester.address, allowedTypes, 1);

        await ethers.provider.send("evm_increaseTime", [2 * 24 * 3600]);
        await ethers.provider.send("evm_mine");

        const allowed = await consentManager.checkConsent(
            owner.address,
            requester.address,
            "CREDIT"
        );

        expect(allowed).to.equal(false);
    });

    it("should reject revoked consent", async function () {
        await consentManager.connect(owner).setConsent(requester.address, allowedTypes, 10);
        await consentManager.connect(owner).revokeConsent(1);

        const allowed = await consentManager.checkConsent(
            owner.address,
            requester.address,
            "CREDIT"
        );

        expect(allowed).to.equal(false);
    });

    it("getUserConsents should return all IDs", async function () {
        await consentManager.connect(owner).setConsent(requester.address, allowedTypes, 5);
        await consentManager.connect(owner).setConsent(requester.address, allowedTypes, 6);

        const list = await consentManager.getUserConsents(owner.address);
        expect(list.length).to.equal(2);
        expect(list[0]).to.equal(1n);
        expect(list[1]).to.equal(2n);
    });
});
