const { expect } = require('chai');
const { ethers } = require('hardhat');
const { loadFixture, time } = require('@nomicfoundation/hardhat-network-helpers');
const units = (n) => ethers.parseUnits(String(n), 18);

async function fixture() {
  const [owner, alice, spender, relayer] = await ethers.getSigners();
  const token = await ethers.deployContract('ClassToken', [owner.address]);
  await token.waitForDeployment();
  return { token, owner, alice, spender, relayer };
}
const types = { Permit: [
  { name: 'owner', type: 'address' }, { name: 'spender', type: 'address' },
  { name: 'value', type: 'uint256' }, { name: 'nonce', type: 'uint256' },
  { name: 'deadline', type: 'uint256' },
] };
async function signedPermit(token, owner, spender, value, deadline, override = {}) {
  const { chainId } = await ethers.provider.getNetwork();
  const domain = { name: 'ClassToken', version: '1', chainId,
    verifyingContract: await token.getAddress(), ...override };
  const nonce = await token.nonces(owner.address);
  const signature = await owner.signTypedData(domain, types,
    { owner: owner.address, spender: spender.address, value, nonce, deadline });
  return ethers.Signature.from(signature);
}

describe('ClassToken / ERC-20', function () {
  it('has correct metadata, cap, total supply and initial holder balance', async function () {
    const { token, owner } = await loadFixture(fixture);
    expect(await token.name()).to.equal('ClassToken');
    expect(await token.symbol()).to.equal('CTK');
    expect(await token.decimals()).to.equal(18);
    expect(await token.cap()).to.equal(units(1000000));
    expect(await token.totalSupply()).to.equal(await token.cap());
    expect(await token.balanceOf(owner.address)).to.equal(await token.totalSupply());
  });
  it('mints to initialHolder even when that address is not the deployer', async function () {
    const [deployer, holder] = await ethers.getSigners();
    const token = await ethers.deployContract('ClassToken', [holder.address]);
    expect(await token.balanceOf(holder.address)).to.equal(units(1000000));
    expect(await token.balanceOf(deployer.address)).to.equal(0);
  });
  it('rejects a zero initial holder', async function () {
    const factory = await ethers.getContractFactory('ClassToken');
    await expect(factory.deploy(ethers.ZeroAddress))
      .to.be.revertedWithCustomError(factory, 'ERC20InvalidReceiver').withArgs(ethers.ZeroAddress);
  });
  it('transfers 100 CTK, moves both balances and emits Transfer', async function () {
    const { token, owner, alice } = await loadFixture(fixture);
    await expect(token.transfer(alice.address, units(100)))
      .to.emit(token, 'Transfer').withArgs(owner.address, alice.address, units(100));
    expect(await token.balanceOf(alice.address)).to.equal(units(100));
    expect(await token.balanceOf(owner.address)).to.equal(units(999900));
  });
  it('reverts insufficient balance with exact custom error arguments', async function () {
    const { token, alice, owner } = await loadFixture(fixture);
    await expect(token.connect(alice).transfer(owner.address, 1n))
      .to.be.revertedWithCustomError(token, 'ERC20InsufficientBalance')
      .withArgs(alice.address, 0n, 1n);
  });
  it('approve -> transferFrom spends allowance and updates balances', async function () {
    const { token, owner, alice, spender } = await loadFixture(fixture);
    await expect(token.approve(spender.address, units(150)))
      .to.emit(token, 'Approval').withArgs(owner.address, spender.address, units(150));
    await expect(token.connect(spender).transferFrom(owner.address, alice.address, units(100)))
      .to.emit(token, 'Transfer').withArgs(owner.address, alice.address, units(100));
    expect(await token.allowance(owner.address, spender.address)).to.equal(units(50));
    expect(await token.balanceOf(alice.address)).to.equal(units(100));
    expect(await token.balanceOf(owner.address)).to.equal(units(999900));
  });
  it('reverts when spender exceeds allowance', async function () {
    const { token, owner, alice, spender } = await loadFixture(fixture);
    await token.approve(spender.address, 10n);
    await expect(token.connect(spender).transferFrom(owner.address, alice.address, 11n))
      .to.be.revertedWithCustomError(token, 'ERC20InsufficientAllowance')
      .withArgs(spender.address, 10n, 11n);
  });
  it('preserves total supply and recipient running sum over multiple amounts', async function () {
    const { token, owner, alice } = await loadFixture(fixture);
    const amounts = [0n, 1n, units('0.5'), units(1), units(100), units('1234.56789')];
    const supply = await token.totalSupply();
    let runningSum = 0n;
    for (const amount of amounts) {
      await token.transfer(alice.address, amount);
      runningSum += amount;
      expect(await token.balanceOf(alice.address)).to.equal(runningSum);
      expect(await token.balanceOf(owner.address)).to.equal(supply - runningSum);
      expect(await token.totalSupply()).to.equal(supply);
    }
  });
  it('enforces ERC20Capped via the _update override', async function () {
    const [owner] = await ethers.getSigners();
    const token = await ethers.deployContract('ClassTokenHarness', [owner.address]);
    const cap = await token.cap();
    await expect(token.mintForTest(owner.address, 1n))
      .to.be.revertedWithCustomError(token, 'ERC20ExceededCap').withArgs(cap + 1n, cap);
  });
});

describe('ClassToken / EIP-2612 permit (bonus)', function () {
  it('a second account submits permit; allowance is set and nonce increments', async function () {
    const { token, owner, alice, spender, relayer } = await loadFixture(fixture);
    const value = units(100), deadline = (await time.latest()) + 3600;
    const before = await token.nonces(owner.address);
    const { v, r, s } = await signedPermit(token, owner, spender, value, deadline);
    await expect(token.connect(relayer).permit(owner.address, spender.address, value, deadline, v, r, s))
      .to.emit(token, 'Approval').withArgs(owner.address, spender.address, value);
    expect(await token.allowance(owner.address, spender.address)).to.equal(value);
    expect(await token.nonces(owner.address)).to.equal(before + 1n);
    expect(await token.balanceOf(alice.address)).to.equal(0n); // Permit does not transfer.
    await token.connect(spender).transferFrom(owner.address, alice.address, value);
    expect(await token.balanceOf(alice.address)).to.equal(value);
    expect(await token.allowance(owner.address, spender.address)).to.equal(0n);
  });
  it('rejects an expired deadline with ERC2612ExpiredSignature', async function () {
    const { token, owner, spender, relayer } = await loadFixture(fixture);
    const value = units(100), deadline = (await time.latest()) - 1;
    const { v, r, s } = await signedPermit(token, owner, spender, value, deadline);
    await expect(token.connect(relayer).permit(owner.address, spender.address, value, deadline, v, r, s))
      .to.be.revertedWithCustomError(token, 'ERC2612ExpiredSignature').withArgs(deadline);
    expect(await token.nonces(owner.address)).to.equal(0n);
  });
  it('rejects replay of an already-used signature', async function () {
    const { token, owner, spender, relayer } = await loadFixture(fixture);
    const value = units(100), deadline = (await time.latest()) + 3600;
    const { v, r, s } = await signedPermit(token, owner, spender, value, deadline);
    await token.connect(relayer).permit(owner.address, spender.address, value, deadline, v, r, s);
    await expect(token.connect(relayer).permit(owner.address, spender.address, value, deadline, v, r, s))
      .to.be.revertedWithCustomError(token, 'ERC2612InvalidSigner');
    expect(await token.nonces(owner.address)).to.equal(1n);
  });
  it('rejects a signature bound to another chainId', async function () {
    const { token, owner, spender, relayer } = await loadFixture(fixture);
    const value = units(100), deadline = (await time.latest()) + 3600;
    const chainId = (await ethers.provider.getNetwork()).chainId + 1n;
    const { v, r, s } = await signedPermit(token, owner, spender, value, deadline, { chainId });
    await expect(token.connect(relayer).permit(owner.address, spender.address, value, deadline, v, r, s))
      .to.be.revertedWithCustomError(token, 'ERC2612InvalidSigner');
  });
  it('rejects a signature bound to another contract', async function () {
    const { token, owner, spender, relayer } = await loadFixture(fixture);
    const other = await ethers.deployContract('ClassToken', [owner.address]);
    const value = units(100), deadline = (await time.latest()) + 3600;
    const { v, r, s } = await signedPermit(token, owner, spender, value, deadline,
      { verifyingContract: await other.getAddress() });
    await expect(token.connect(relayer).permit(owner.address, spender.address, value, deadline, v, r, s))
      .to.be.revertedWithCustomError(token, 'ERC2612InvalidSigner');
  });
});
