require('@nomicfoundation/hardhat-toolbox');
require('dotenv').config();
const { subtask } = require('hardhat/config');
const { TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD } = require('hardhat/builtin-tasks/task-names');

// Use the pinned npm compiler: no additional compiler download after npm ci.
subtask(TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD).setAction(async (args, hre, runSuper) => {
  if (args.solcVersion === '0.8.24') {
    return {
      compilerPath: require.resolve('solc/soljson.js'),
      isSolcJs: true,
      version: '0.8.24',
      longVersion: require('solc').version(),
    };
  }
  return runSuper();
});
const key = (process.env.PRIVATE_KEY || '').trim();
if (key && !/^(0x)?[0-9a-fA-F]{64}$/.test(key)) {
  throw new Error('PRIVATE_KEY must be a 32-byte hex TEST key, or empty for local tests.');
}
module.exports = {
  solidity: {
    version: '0.8.24',
    settings: { optimizer: { enabled: true, runs: 200 }, evmVersion: 'paris' },
  },
  networks: {
    hardhat: { chainId: 31337, hardfork: 'merge' },
    trustkeys: {
      url: process.env.TRUSTKEYS_RPC_URL || 'https://l1testnet.trustkeys.network',
      chainId: 11968,
      accounts: key ? [key.startsWith('0x') ? key : `0x${key}`] : [],
      timeout: 120000,
    },
  },
  mocha: { timeout: 60000 },
};
