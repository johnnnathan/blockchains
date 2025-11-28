const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DigitalIdentity", function () {
    let identity, user;

    const hashedIdentity = ethers.keccak256(ethers.toUtf8Bytes("user-identity"));
    const credit = ethers.keccak256(ethers.toUtf8Bytes("A"));
    const income = ethers.keccak256(ethers.toUtf8Bytes("HIGH"));
    const debt = ethers.keccak256(ethers.toUtf8Bytes("LOW"));

    beforeEach(async function () {
        [user] = await ethers.getSigners();

        const DigitalIdentity = await ethers.getContractFactory("DigitalIdentity");
        identity = await DigitalIdentity.deploy();
        await identity.waitForDeployment();
    });

    it("should register user", async function () {
        await identity.connect(user).registerUser(hashedIdentity, credit, income, debt);

        const u = await identity.getUser(user.address);
        expect(u.isRegistered).to.equal(true);
        expect(u.hashedIdentity).to.equal(hashedIdentity);
        expect(u.creditProfile.hashedCreditTier).to.equal(credit);
    });

    it("should fail double registration", async function () {
        await identity.connect(user).registerUser(hashedIdentity, credit, income, debt);

        await expect(
            identity.connect(user).registerUser(hashedIdentity, credit, income, debt)
        ).to.be.revertedWith("AlreadyRegistered()");
    });

    it("should update credit profile", async function () {
        await identity.connect(user).registerUser(hashedIdentity, credit, income, debt);

        const newCredit = ethers.keccak256(ethers.toUtf8Bytes("B"));
        await identity.connect(user).updateCreditProfile(newCredit, income, debt);

        const cp = await identity.getCreditProfile(user.address);
        expect(cp.hashedCreditTier).to.equal(newCredit);
    });

    it("should fail updating when not registered", async function () {
        await expect(
            identity.connect(user).updateCreditProfile(credit, income, debt)
        ).to.be.revertedWith("NotRegistered()");
    });

    it("should add off-chain refs", async function () {
        await identity.connect(user).registerUser(hashedIdentity, credit, income, debt);

        await identity.connect(user).addOffChainRef("ipfs://abc");
        await identity.connect(user).addOffChainRef("ipfs://def");

        const refs = await identity.getOffChainRefs(user.address);
        expect(refs.length).to.equal(2);
        expect(refs[0]).to.equal("ipfs://abc");
    });

    it("should fail adding off-chain ref when not registered", async function () {
        await expect(
            identity.connect(user).addOffChainRef("ipfs://abc")
        ).to.be.revertedWith("NotRegistered()");
    });
});
