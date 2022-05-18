// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require('hardhat');
const fs = require('fs');
const list = require('../list.json');
let total = 0;
async function main() {
  const nft = await ethers.getContractAt('ERC721mock', '0xa91b7e5853683cd01db8817d1582db5bb966a162');
  const token = await ethers.getContractAt('KlayLionsCoin', '0x2c201a9cfa4787fdcba2fda98c0f0e5d74d63bfc');
  const batchTransfer = await ethers.getContractAt('BatchTransfer', '0x07ba6889cadba4b8e42788edad78b2536d9bc6a6');

  let _to = [];
  let _value = [];

  Object.keys(list).forEach((key) => {
    _to.push(key);
    _value.push(ethers.utils.parseEther(list[key].toString()));
  });
  const tx = await batchTransfer.batchTransfer(token.address, _to, _value);
  await tx.wait();
  console.log(tx.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
