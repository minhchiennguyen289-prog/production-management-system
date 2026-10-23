const { ethers, context, run } = require('./helpers');
async function main() {
  const { chainId, signer, network } = await context();
  const balance = await ethers.provider.getBalance(signer.address);
  console.log('Network:', network, '| chainId:', chainId.toString());
  console.log('Test account:', signer.address);
  console.log('Native gas balance (base units):', balance.toString());
  if (balance === 0n) throw new Error('Ask the instructor to fund this TEST address before deployment.');
  console.log('CHECK chain and funded account OK (gas sufficiency still depends on actual fees)');
}
if (require.main === module) run(main);
