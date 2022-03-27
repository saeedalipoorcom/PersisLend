const hre = require("hardhat");

async function main() {
  // deploy DAI
  const DAI = await hre.ethers.getContractFactory("DAI");
  const DAIContract = await DAI.deploy();

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
  const HandlerDataStorageContract = await HandlerDataStorage.deploy(
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
  const marketHandler = await hre.ethers.getContractFactory("marketHandler");
  const marketHandlerContract = await marketHandler.deploy(
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
  const tokenProxyContract = await tokenProxy.deploy(
    marketHandlerContract.address
  );

  await tokenProxyContract.deployed();
  console.log("tokenProxyContract deployed to:", tokenProxyContract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
