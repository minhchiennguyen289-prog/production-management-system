const { ethers, required, address, context, evidence, decodedEvents, run } = require('./helpers');
async function verify(tokenAddress, txHash, expectedTo) {
  const { chainId, network } = await context(false);
  const token = await ethers.getContractAt('ClassToken', address(tokenAddress, 'TOKEN'), ethers.provider);
  if (!/^0x[0-9a-fA-F]{64}$/.test(txHash)) throw new Error('TX_HASH must be a 32-byte transaction hash.');
  const receipt = await ethers.provider.getTransactionReceipt(txHash);
  if (!receipt) throw new Error('Transaction is not yet mined or was not found on this chain.');
  if (receipt.status !== 1) throw new Error('Transaction reverted.');
  const amount = ethers.parseUnits('100', await token.decimals());
  const events = decodedEvents(token, receipt, 'Transfer');
  const event = events.find(e => e.args.value === amount &&
    (!expectedTo || e.args.to === address(expectedTo, 'TO')) && e.args.from !== ethers.ZeroAddress);
  if (!event) throw new Error('No matching 100-CTK Transfer event from this token contract.');
  const from = event.args.from, to = event.args.to;
  const senderBalance = await token.balanceOf(from, { blockTag: receipt.blockNumber });
  const recipientBalance = await token.balanceOf(to, { blockTag: receipt.blockNumber });
  const proof = { network, chainId, contractAddress: await token.getAddress(),
    transactionHash: receipt.hash, status: receipt.status, blockNumber: receipt.blockNumber,
    from, to, amount, amountCTK: '100', senderBalance, recipientBalance };
  console.log('CHECK receipt status == 1 OK');
  console.log('CHECK matching 100 CTK Transfer log OK');
  console.log('Balances at mined block:', ethers.formatUnits(senderBalance, 18), '/',
    ethers.formatUnits(recipientBalance, 18), 'CTK (sender / recipient)');
  evidence(`transfer-${receipt.hash}`, proof);
  return proof;
}
async function main() { return verify(required('TOKEN'), required('TX_HASH'), process.env.TO); }
if (require.main === module) run(main);
module.exports = verify;
