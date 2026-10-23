const { expect } = require('chai');
const { ethers } = require('hardhat');
describe('Lab 08.4 - ownership properties over local signers', function () {
  it('vulnerable: each of 19 non-owner signers can seize ownership', async function () {
    const [owner,...others] = await ethers.getSigners();
    const bank = await ethers.deployContract('EtherBankVulnerable',[],owner);
    for (const caller of others) {
      expect(await bank.owner()).not.to.equal(caller.address);
      await bank.connect(caller).setOwner(caller.address);
      expect(await bank.owner()).to.equal(caller.address);
    }
  });
  it('secure: all 19 non-owners are rejected and owner stays unchanged', async function () {
    const [owner,...others] = await ethers.getSigners();
    const bank = await ethers.deployContract('EtherBank',[],owner);
    for (const caller of others) {
      await expect(bank.connect(caller).setOwner(caller.address)).to.be.revertedWith('only owner');
      expect(await bank.owner()).to.equal(owner.address);
    }
  });
  it('secure: zero owner rejected; event and transfer enforced; former owner loses permission', async function () {
    const [owner,next,third] = await ethers.getSigners();
    const bank = await ethers.deployContract('EtherBank',[],owner);
    await expect(bank.setOwner(ethers.ZeroAddress)).to.be.revertedWith('zero owner');
    expect(await bank.owner()).to.equal(owner.address);
    await expect(bank.setOwner(next.address)).to.emit(bank,'OwnerChanged').withArgs(owner.address,next.address);
    await expect(bank.setOwner(third.address)).to.be.revertedWith('only owner');
    await expect(bank.connect(next).setOwner(third.address)).to.emit(bank,'OwnerChanged').withArgs(next.address,third.address);
    expect(await bank.owner()).to.equal(third.address);
  });
});
