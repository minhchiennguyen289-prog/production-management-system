const { expect } = require('chai');
const { ethers } = require('hardhat');
const eth = ethers.parseEther;
async function setup(name) {
  const [owner, alice, bob, carol, eve] = await ethers.getSigners();
  const bank = await ethers.deployContract(name, [], owner);
  await bank.waitForDeployment();
  for (const user of [alice, bob, carol]) await (await bank.connect(user).deposit({value: eth('10')})).wait();
  const attacker = await ethers.deployContract('Attacker', [await bank.getAddress(), eth('1')], eve);
  await attacker.waitForDeployment();
  return { bank, attacker, owner, alice, bob, carol, eve };
}
describe('Lab 08.1 - vulnerable bank', function () {
  it('drains 31 ETH in 31 withdrawals; gas-adjusted Eve profit is exactly 30 ETH', async function () {
    const {bank, attacker, eve, alice} = await setup('EtherBankVulnerable');
    const before = await ethers.provider.getBalance(eve.address);
    const attackReceipt = await (await attacker.connect(eve).attack({value: eth('1')})).wait();
    expect(await attacker.callbacks()).to.equal(31n);
    expect(await ethers.provider.getBalance(bank.target)).to.equal(0n);
    expect(await ethers.provider.getBalance(attacker.target)).to.equal(eth('31'));
    const collectReceipt = await (await attacker.connect(eve).collect()).wait();
    const after = await ethers.provider.getBalance(eve.address);
    const gas = attackReceipt.fee + collectReceipt.fee;
    // Wallet delta already includes the 1 ETH deposit: do not subtract stake twice.
    expect(after - before + gas).to.equal(eth('30'));
    expect(after - before).to.equal(eth('30') - gas);
    expect(await ethers.provider.getBalance(attacker.target)).to.equal(0n);
    expect(await bank.balances(attacker.target)).to.equal(0n);
    expect(await bank.balances(alice.address)).to.equal(eth('10')); // insolvent credit
    console.log('      withdraw executions: 31; bank: 0 ETH; gas-adjusted profit: 30 ETH');
  });
});
describe('Lab 08.2 - patched bank', function () {
  it('same attack reverts; all 30 ETH and honest credits are preserved', async function () {
    const {bank, attacker, eve, alice, bob, carol} = await setup('EtherBank');
    await expect(attacker.connect(eve).attack({value: eth('1')})).to.be.revertedWith('transfer failed');
    expect(await ethers.provider.getBalance(bank.target)).to.equal(eth('30'));
    for (const user of [alice,bob,carol]) expect(await bank.balances(user.address)).to.equal(eth('10'));
    expect(await bank.balances(attacker.target)).to.equal(0n);
    expect(await ethers.provider.getBalance(attacker.target)).to.equal(0n);
    expect(await attacker.callbacks()).to.equal(0n); // callback state rolled back too
    // Prove funds remain usable and the lock was rolled back.
    for (const user of [alice,bob,carol]) {
      await expect(bank.connect(user).withdraw()).to.changeEtherBalances([bank,user],[-eth('10'),eth('10')]);
      expect(await bank.balances(user.address)).to.equal(0n);
    }
    expect(await ethers.provider.getBalance(bank.target)).to.equal(0n);
  });
  it('rejects empty/double withdrawal and supports a later fresh deposit', async function () {
    const {bank,eve,alice} = await setup('EtherBankSecure');
    await expect(bank.connect(eve).withdraw()).to.be.revertedWith('no balance');
    await bank.connect(alice).withdraw();
    await expect(bank.connect(alice).withdraw()).to.be.revertedWith('no balance');
    await bank.connect(alice).deposit({value:eth('2')});
    await expect(bank.connect(alice).withdraw()).to.changeEtherBalances([bank,alice],[-eth('2'),eth('2')]);
  });
});
