// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require('hardhat');

const list = 'Array from klayswapscope';
async function main() {
  // const BatchTransferContract = await ethers.getContractFactory('BatchTransfer');
  // const batchTransferContract = await BatchTransferContract.deploy();
  // await batchTransferContract.deployed();
  // console.log('TransferContract', batchTransferContract.address);

  // execute

  const NFT = '';
  const tokenPerNft = 5;
  const addressList = list.map((holder) => holder.address);
  const balanceList = list.map((hodler) => ethers.utils.parseEther(String(hodler.tokenCount * tokenPerNft)).toString());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
