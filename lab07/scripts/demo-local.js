const assert = require('node:assert/strict');
const { ethers, hre, run } = require('./helpers');
async function main() {
  if (hre.network.name !== 'hardhat') throw new Error('This demo is local only: omit --network.');
  const [, recipient] = await ethers.getSigners();
  console.log('LOCAL DEMO ONLY — these addresses are not TrustKeys deployments.');
  // Clear optional recipient overrides so the demo is deterministic.
  delete process.env.INITIAL_HOLDER;
  delete process.env.BADGE_TO;
  process.env.STUDENT_NAME = 'Sinh viên minh họa';
  const token = await require('./deploy-token')();
  const badge = await require('./deploy-badge')();
  process.env.TOKEN = await token.getAddress();
  process.env.REGISTRY = await badge.getAddress();
  process.env.TO = recipient.address;
  process.env.TOKEN_ID = '0';
  const transfer = await require('./interact-token')();
  assert.equal(transfer.recipientBalance, ethers.parseUnits('100', 18));
  const { meta } = await require('./read-badge')();
  assert.equal(meta.attributes[0].value, process.env.STUDENT_NAME);
  console.log('LOCAL END-TO-END DEMO OK');
}
if (require.main === module) run(main);
