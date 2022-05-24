// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require('hardhat');

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // const NftChef = await ethers.getContractAt('NftChef', '0xe6ec1b4C7DC8346456B7f5A56d306CEB22186e7A');
  // await NftChef.setCollection('0x2f577115EA11f89dCc4F7678e8E3210F944f8b27', ethers.utils.parseEther('500'));

  const nftMocks = await ethers.getContractFactory('ERC721mock');
  const tokenMocks = await ethers.getContractFactory('ERC20mock');
  const rewardStore = await ethers.getContractFactory('RewardStore');
  const NftChef = await ethers.getContractFactory('NftChef');
  const NftLocker = await ethers.getContractFactory('NftLocker');
  // 91199518
  console.log('1');
  // const nftMock = await nftMocks.deploy();
  // await nftMock.deployed();
  const tokenMock = await tokenMocks.deploy();
  await tokenMock.deployed();
  const rewardStoreContract = await rewardStore.deploy();
  await rewardStoreContract.deployed();
  console.log('2');
  console.log(rewardStoreContract.address);
  await tokenMock.transfer(rewardStoreContract.address, ethers.utils.parseEther('10000'));

  const nftChef = await NftChef.deploy(rewardStoreContract.address, '91199518');
  await nftChef.deployed();
  // 0xa91b7e5853683cd01db8817d1582db5bb966a162
  // await nftChef.addCollection(nftMock.address, ethers.utils.parseEther('0.0000115740741'));
  await nftChef.addCollection('0xa91b7e5853683cd01db8817d1582db5bb966a162', ethers.utils.parseEther('0.0000115740741'));
  await rewardStoreContract.setMinter(nftChef.address, true);
  await rewardStoreContract.setToken(tokenMock.address);

  const locker = await NftLocker.deploy(nftChef.address);
  await locker.deployed();
  await nftChef.setLocker(locker.address);
  console.log('nftMock', '0xa91b7e5853683cd01db8817d1582db5bb966a162');
  console.log('tokenMock', tokenMock.address);
  console.log('rewardStoreContract', rewardStoreContract.address);
  console.log('nftChef', nftChef.address);
  console.log('locker', locker.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
