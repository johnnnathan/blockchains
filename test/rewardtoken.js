const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RewardToken", function () {
    let token, consentManager, user1, user2;

    beforeEach(async function () {
        const signers = await ethers.getSigners();
        consentManager = signers[0];
        user1 = signers[1];
        user2 = signers[2];

        const RewardToken = await ethers.getContractFactory("RewardToken");
        token = await RewardToken.deploy(
            "Reward",
            "RWD",
            18,
            consentManager.address
        );
        await token.waitForDeployment();
    });

    it("should mint tokens by manager", async function () {
        await token.connect(consentManager).mint(user1.address, ethers.parseEther("5"));
        expect(await token.balanceOf(user1.address)).to.equal(ethers.parseEther("5"));
    });

    it("should fail minting when caller is not manager", async function () {
        await expect(
            token.connect(user1).mint(user1.address, 1)
        ).to.be.revertedWith("NotConsentManager()");
    });

    it("should transfer tokens", async function () {
        await token.connect(consentManager).mint(user1.address, ethers.parseEther("10"));
        await token.connect(user1).transfer(user2.address, ethers.parseEther("3"));

        expect(await token.balanceOf(user1.address)).to.equal(ethers.parseEther("7"));
        expect(await token.balanceOf(user2.address)).to.equal(ethers.parseEther("3"));
    });

    it("should fail transfer when insufficient balance", async function () {
        await expect(
            token.connect(user1).transfer(user2.address, 1)
        ).to.be.revertedWith("InsufficientBalance()");
    });

    it("should fail transferring to zero address", async function () {
        await token.connect(consentManager).mint(user1.address, 1);

        await expect(
            token.connect(user1).transfer(ethers.ZeroAddress, 1)
        ).to.be.revertedWith("ZeroAddress()");
    });
});
