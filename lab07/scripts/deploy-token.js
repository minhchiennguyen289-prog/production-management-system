const { ethers, address, context, evidence, wait, run } = require('./helpers');
async function main() {
  const { chainId, signer, network } = await context();
  const initialHolder = address(process.env.INITIAL_HOLDER || signer.address, 'INITIAL_HOLDER');
  const token = await ethers.deployContract('ClassToken', [initialHolder], signer);
  const receipt = await wait(token.deploymentTransaction());
  await token.waitForDeployment();
  const contractAddress = await token.getAddress();
  if (await ethers.provider.getCode(contractAddress) === '0x') throw new Error('No deployed bytecode.');
  const supply = await token.totalSupply();
  if (supply !== ethers.parseUnits('1000000', 18) || await token.balanceOf(initialHolder) !== supply) {
    throw new Error('Unexpected supply or initial balance.');
  }
  console.log('ClassToken:', contractAddress);
  console.log('Initial holder:', initialHolder);
  console.log('Total supply:', ethers.formatUnits(supply, 18), 'CTK');
  evidence('token-deployment', { network, chainId, contractAddress, deployer: signer.address,
    initialHolder, transactionHash: receipt.hash, blockNumber: receipt.blockNumber,
    status: receipt.status, totalSupply: supply });
  return token;
}
if (require.main === module) run(main);
module.exports = main;
