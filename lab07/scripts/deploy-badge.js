const { ethers, required, address, context, evidence, wait, decodedEvents, run } = require('./helpers');
async function main() {
  const studentName = required('STUDENT_NAME');
  const { chainId, signer, network } = await context();
  const recipient = address(process.env.BADGE_TO || signer.address, 'BADGE_TO');
  const badge = await ethers.deployContract('ClassBadge', [signer.address], signer);
  const deployReceipt = await wait(badge.deploymentTransaction());
  await badge.waitForDeployment();
  const contractAddress = await badge.getAddress();
  console.log('ClassBadge:', contractAddress);
  // Save the deployed address first so a later mint failure does not hide it.
  evidence('badge-deployment', { network, chainId, contractAddress, owner: signer.address,
    transactionHash: deployReceipt.hash, blockNumber: deployReceipt.blockNumber, status: deployReceipt.status });
  const receipt = await wait(await badge.mint(recipient, studentName));
  const mint = decodedEvents(badge, receipt, 'Transfer').find(e => e.args.from === ethers.ZeroAddress);
  if (!mint) throw new Error('Mint Transfer event missing.');
  const tokenId = mint.args.tokenId;
  if (await badge.ownerOf(tokenId) !== recipient) throw new Error('Unexpected NFT owner.');
  console.log('Minted badge tokenId:', tokenId.toString());
  evidence(`badge-mint-${tokenId}`, { network, chainId, contractAddress, tokenId, recipient,
    studentName, transactionHash: receipt.hash, blockNumber: receipt.blockNumber, status: receipt.status });
  return badge;
}
if (require.main === module) run(main);
module.exports = main;
