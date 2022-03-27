const { expect } = require("chai");
const hre = require("hardhat");

describe("PersisLend", async () => {
  let DAIContract;
  let HandlerDataStorageContract;
  let marketHandlerContract;
  let tokenProxyContract;
  let Owner;
  let amount;
  describe("", async function () {
    it("Depolyment", async function () {
      [Owner] = await hre.ethers.getSigners();
      // deploy DAI
      const DAI = await hre.ethers.getContractFactory("DAI");
      DAIContract = await DAI.deploy();

      await DAIContract.deployed();
      console.log("DAIContract deployed to:", DAIContract.address);

      // deploy HandlerDataStorageContract
      const borrowLimit = hre.ethers.utils.parseEther("0.75");
      const martinCallLimit = hre.ethers.utils.parseEther("0.93");
      const minimumInterestRate = 0;
      const liquiditySensitive = hre.ethers.utils.parseEther("0.05");
      const HandlerDataStorage = await hre.ethers.getContractFactory(
        "HandlerDataStorage"
      );
      HandlerDataStorageContract = await HandlerDataStorage.deploy(
        borrowLimit,
        martinCallLimit,
        minimumInterestRate,
        liquiditySensitive
      );

      await HandlerDataStorageContract.deployed();
      console.log(
        "HandlerDataStorageContract deployed to:",
        HandlerDataStorageContract.address
      );

      // deploy marketHandler
      const marketHandler = await hre.ethers.getContractFactory(
        "marketHandler"
      );
      marketHandlerContract = await marketHandler.deploy(
        HandlerDataStorageContract.address,
        DAIContract.address
      );

      await marketHandlerContract.deployed();
      console.log(
        "marketHandlerContract deployed to:",
        marketHandlerContract.address
      );

      // deploy tokenProxy
      const tokenProxy = await hre.ethers.getContractFactory("tokenProxy");
      tokenProxyContract = await tokenProxy.deploy(
        marketHandlerContract.address,
        HandlerDataStorageContract.address,
        DAIContract.address
      );

      await tokenProxyContract.deployed();
      console.log(
        "tokenProxyContract deployed to:",
        tokenProxyContract.address
      );
    });

    it("Check user access , should be false", async () => {
      expect(
        await HandlerDataStorageContract.getUserAccessed(Owner.address)
      ).to.equal(false);
    });

    it("Make Deposit", async () => {
      amount = hre.ethers.utils.parseEther("100");
      await DAIContract.approve(tokenProxyContract.address, amount);
      await tokenProxyContract.deposit(amount);
    });

    it("Check some variables after deposit, user and contract balance , user access, deposit and borrow EXR", async () => {
      expect(
        await HandlerDataStorageContract.getIntraUserDepositAmount(
          Owner.address
        )
      ).to.equal(amount);

      expect(await HandlerDataStorageContract.getTotalDepositAmount()).to.equal(
        amount
      );

      expect(
        await HandlerDataStorageContract.getUserAccessed(Owner.address)
      ).to.equal(true);

      expect(await HandlerDataStorageContract.getActionDepositEXR()).to.equal(
        hre.ethers.utils.parseEther("1")
      );

      expect(await HandlerDataStorageContract.getActionBorrowEXR()).to.equal(
        hre.ethers.utils.parseEther("1")
      );
    });

    it("Withdraw", async () => {
      await tokenProxyContract.withdraw(amount);
    });

    it("check deposit amounts after withdraw, should be 0", async () => {
      expect(
        await HandlerDataStorageContract.getIntraUserDepositAmount(
          Owner.address
        )
      ).to.equal(0);
      expect(await HandlerDataStorageContract.getTotalDepositAmount()).to.equal(
        0
      );
    });
  });
});
