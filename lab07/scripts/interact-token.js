const { ethers, required, address, context, wait, run } = require('./helpers');
const verify = require('./verify-transfer');
async function main() {
  const { signer } = await context();
  const tokenAddress = address(required('TOKEN'), 'TOKEN');
  const to = address(required('TO'), 'TO');
  if (to === signer.address) throw new Error('TO must be a classmate, not the sender.');
  const token = await ethers.getContractAt('ClassToken', tokenAddress, signer);
  const amount = ethers.parseUnits('100', await token.decimals());
  if (await token.balanceOf(signer.address) < amount) throw new Error('Sender has less than 100 CTK.');
  console.log(`Sending exactly 100 CTK from ${signer.address} to ${to}`);
  const receipt = await wait(await token.transfer(to, amount));
  return verify(tokenAddress, receipt.hash, to);
}
if (require.main === module) run(main);
module.exports = main;
