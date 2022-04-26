const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('NftStaking', function () {
  let Token;
  let hardhatToken;
  let deployer;
  let addr1;
  let addr2;
  let addrs;

  let Minter;
  let minter;

  let NftChef;
  let nftChef;

  let NftMock;
  let nftMock;

  before(async function () {
    Token = await ethers.getContractFactory('Token');
    Minter = await ethers.getContractFactory('Minter');
    NftChef = await ethers.getContractFactory('NftChef');
    NftMock = await ethers.getContractFactory('ERC721mock');

    [deployer, addr1, addr2, ...addrs] = await ethers.getSigners();

    hardhatToken = await Token.deploy();
    await hardhatToken.deployed();
    minter = await Minter.deploy();
    await minter.deployed();
    nftChef = await NftChef.deploy();
    await nftChef.deployed();
    nftMock = await NftMock.deploy();
    await nftMock.deployed();
  });

  it('Initial Ownable Check', async function () {
    expect(await hardhatToken.owner()).to.equal(deployer.address);
    expect(await minter.owner()).to.equal(deployer.address);
    expect(await nftChef.owner()).to.equal(deployer.address);
  });

  it('Minter check', async function () {
    const tx = await hardhatToken.transferOwnership(minter.address);
    await tx.wait();
    expect(await hardhatToken.owner()).to.equal(minter.address);

    const tx2 = await minter.setToken(hardhatToken.address);
    await tx2.wait();
    expect(await minter.token()).to.equal(hardhatToken.address);
  });

  it('Set Chef as minter', async function () {
    expect(await minter.isMinter(nftChef.address)).to.equal(false);
    const tx = await minter.setMinter(nftChef.address, true);
    await tx.wait();
    expect(await minter.isMinter(nftChef.address)).to.equal(true);
  });

  it('Set Minter Address at Chef', async function () {
    expect(await nftChef.minter()).to.equal('0x0000000000000000000000000000000000000000');

    const tx = await nftChef.setMinter(minter.address);
    await tx.wait();

    expect(await nftChef.minter()).to.equal(minter.address);
  });
});
