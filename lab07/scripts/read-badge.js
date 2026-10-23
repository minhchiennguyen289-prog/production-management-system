const fs = require('node:fs');
const path = require('node:path');
const { ethers, required, address, context, evidence, stringify, run } = require('./helpers');
async function main() {
  const { chainId, network } = await context(false);
  const registry = address(required('REGISTRY'), 'REGISTRY');
  const id = process.env.TOKEN_ID || '0';
  if (!/^\d+$/.test(id)) throw new Error('TOKEN_ID must be a non-negative integer.');
  const tokenId = BigInt(id);
  const badge = await ethers.getContractAt('ClassBadge', registry, ethers.provider);
  const uri = await badge.tokenURI(tokenId);
  const prefix = 'data:application/json;base64,';
  if (!uri.startsWith(prefix)) throw new Error('Expected base64 JSON data URI.');
  const meta = JSON.parse(Buffer.from(uri.slice(prefix.length), 'base64').toString('utf8'));
  const imagePrefix = 'data:image/svg+xml;base64,';
  if (typeof meta.image !== 'string' || !meta.image.startsWith(imagePrefix)) throw new Error('Expected base64 SVG.');
  if (!Array.isArray(meta.attributes) || !meta.attributes.some(a => a.trait_type === 'Student')) {
    throw new Error('Student trait missing.');
  }
  const svg = Buffer.from(meta.image.slice(imagePrefix.length), 'base64').toString('utf8');
  console.log('Decoded JSON:\n' + stringify(meta));
  console.log('Decoded SVG:\n' + svg);
  evidence(`badge-${tokenId}-decoded`, { network, chainId, registry, tokenId, meta, svg });
  fs.writeFileSync(path.join(__dirname, '..', 'evidence', `${network}-badge-${tokenId}.svg`), svg);
  return { meta, svg };
}
if (require.main === module) run(main);
module.exports = main;
