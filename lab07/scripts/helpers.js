const fs = require('node:fs');
const path = require('node:path');
const hre = require('hardhat');
const { ethers } = hre;

function required(name) {
  const value = (process.env[name] || '').trim();
  if (!value) throw new Error(`Set ${name} in .env or as an environment variable.`);
  return value;
}
function address(value, label) {
  if (!ethers.isAddress(value) || value === ethers.ZeroAddress) {
    throw new Error(`${label} must be a non-zero public Ethereum address.`);
  }
  return ethers.getAddress(value);
}
async function context(needsSigner = true) {
  const { chainId } = await ethers.provider.getNetwork();
  if (hre.network.name === 'trustkeys' && chainId !== 11968n) throw new Error('Unexpected chainId.');
  const [signer] = needsSigner ? await ethers.getSigners() : [];
  if (needsSigner && !signer) throw new Error('No signer: configure PRIVATE_KEY locally using a funded TEST account.');
  return { chainId, signer, network: hre.network.name };
}
function stringify(value) {
  return JSON.stringify(value, (_, v) => typeof v === 'bigint' ? v.toString() : v, 2);
}
function evidence(name, data) {
  const dir = path.join(__dirname, '..', 'evidence');
  fs.mkdirSync(dir, { recursive: true });
  const target = path.join(dir, `${hre.network.name}-${name}.json`);
  fs.writeFileSync(target, stringify({ recordedAt: new Date().toISOString(), ...data }) + '\n');
  console.log(`Evidence saved: ${path.relative(process.cwd(), target)}`);
  return target;
}
async function wait(tx) {
  console.log('Transaction hash:', tx.hash);
  const receipt = await tx.wait(1);
  if (!receipt || receipt.status !== 1) throw new Error('Transaction did not succeed.');
  return receipt;
}
function decodedEvents(contract, receipt, name) {
  return receipt.logs.filter(l => l.address.toLowerCase() === contract.target.toLowerCase())
    .map(l => { try { return contract.interface.parseLog(l); } catch { return null; } })
    .filter(e => e && e.name === name);
}
function run(main) {
  main().catch(error => {
    console.error(error.shortMessage || error.message);
    process.exitCode = 1;
  });
}
module.exports = { hre, ethers, required, address, context, stringify, evidence, wait, decodedEvents, run };
