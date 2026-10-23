#!/usr/bin/env python3
"""Lab 04 solution reconstructed from worksheet (original starter not supplied).
Python >= 3.9; standard library only. Online responses are cached for --offline.
This lab verifies selected commitments, not all full-node consensus rules.
"""
import argparse
import hashlib
import json
import math
from datetime import datetime, timezone
from pathlib import Path
import urllib.request
import urllib.error

PINNED_HEIGHT = 840000
API = 'https://blockstream.info/api'
DATA = Path(__file__).resolve().parent / 'data'


def dsha256(data):
    return hashlib.sha256(hashlib.sha256(data).digest()).digest()


def bits_to_target(bits):
    """TODO 1 completed: decode Bitcoin's unsigned compact PoW target."""
    exponent = bits >> 24
    coefficient = bits & 0x007fffff
    if bits & 0x00800000:
        raise ValueError('Negative compact target')
    target = (coefficient >> (8 * (3 - exponent)) if exponent <= 3
              else coefficient << (8 * (exponent - 3)))
    if not 0 < target < 2**256:
        raise ValueError('Zero or overflowing target')
    return target


def transaction_fee(tx):
    """TODO 2 completed. Values are integer satoshis; vsize rounds up."""
    if any(v.get('is_coinbase', False) for v in tx['vin']):
        raise ValueError('Coinbase has no ordinary input-based fee')
    total_in = sum(v['prevout']['value'] for v in tx['vin'])
    total_out = sum(v['value'] for v in tx['vout'])
    fee = total_in - total_out
    vsize = (tx['weight'] + 3) // 4
    if fee < 0 or vsize <= 0:
        raise ValueError('Invalid fee or virtual size')
    return total_in, total_out, fee, vsize, fee / vsize


def merkle_root(txids):
    """TODO 3 completed: internal byte order, odd duplication, double hash."""
    if not txids:
        raise ValueError('Empty transaction list')
    nodes = [bytes.fromhex(txid)[::-1] for txid in txids]
    if any(len(n) != 32 for n in nodes):
        raise ValueError('A txid must have 32 bytes')
    while len(nodes) > 1:
        if len(nodes) % 2:
            nodes.append(nodes[-1])
        nodes = [dsha256(nodes[i] + nodes[i + 1])
                 for i in range(0, len(nodes), 2)]
    return nodes[0][::-1].hex()


def check(label, condition):
    if not condition:
        raise RuntimeError(f'CHECK {label} FAIL')
    print(f'CHECK {label} OK')


class Client:
    def __init__(self, offline):
        self.offline = offline

    def get(self, path, base=API, as_json=True):
        url = base + path
        key = hashlib.sha256(url.encode()).hexdigest() + '.json'
        file = DATA / key
        if self.offline:
            if not file.exists():
                raise FileNotFoundError(f'Missing offline cache: {url}; run online first')
            record = json.loads(file.read_text(encoding='utf-8'))
            if record['url'] != url:
                raise ValueError('Cache URL mismatch')
            body = record['body']
        else:
            with urllib.request.urlopen(url, timeout=30) as response:
                body = response.read().decode('utf-8').strip()
            # Parse before caching so an invalid JSON response is not saved.
            if as_json:
                json.loads(body)
            DATA.mkdir(parents=True, exist_ok=True)
            record = {'url': url, 'retrieved_at_utc': datetime.now(timezone.utc).isoformat(),
                      'body': body}
            file.write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding='utf-8')
        return json.loads(body) if as_json else body


def run(args):
    client = Client(args.offline)
    block_id = client.get(f'/block-height/{args.height}', as_json=False)
    block = client.get(f'/block/{block_id}')
    header = bytes.fromhex(client.get(f'/block/{block_id}/header', as_json=False))
    txids = client.get(f'/block/{block_id}/txids')
    print(f'Block: {args.height}\nBlock id: {block_id}')
    print('Block UTC:', datetime.fromtimestamp(block['timestamp'], timezone.utc).isoformat())
    print('Mode:', 'OFFLINE (saved responses)' if args.offline else 'ONLINE')
    check('header_length_80', len(header) == 80)
    computed_id = dsha256(header)[::-1].hex()
    check('header_hash', computed_id == block_id == block['id'])
    check('block_height', block['height'] == args.height)
    bits = int.from_bytes(header[72:76], 'little')
    check('header_bits', bits == block['bits'])
    target = bits_to_target(bits)
    # Consensus accepts hash <= target; worksheet uses strict < as shorthand.
    check('proof_of_work', int(computed_id, 16) <= target)
    target_hex = f'{target:064x}'
    work = 2**256 / (target + 1)
    print(f'bits: 0x{bits:08x}\nTarget: {target_hex}')
    print('Leading zero hex digits:', len(target_hex) - len(target_hex.lstrip('0')))
    print(f'Expected work: {work:.6e} header trials = 2^{math.log2(work):.4f}')
    check('transaction_count', len(txids) == block['tx_count'])
    if len(txids) < 2:
        raise ValueError('Choose a block with a non-coinbase transaction')
    coinbase = client.get(f'/tx/{txids[0]}')
    tx = client.get(f'/tx/{txids[1]}')
    check('transaction_ids', coinbase['txid'] == txids[0] and tx['txid'] == txids[1])
    check('coinbase_position', coinbase['vin'][0]['is_coinbase'])
    tin, tout, fee, vsize, rate = transaction_fee(tx)
    check('fee_matches_API', fee == tx['fee'])
    print(f'First non-coinbase tx: {txids[1]}\nInputs: {tin} sat\nOutputs: {tout} sat')
    print(f'Fee: {fee} sat = {fee / 100_000_000:.8f} BTC')
    print(f'Weight: {tx["weight"]} WU\nvsize: {vsize} vB\nFee rate: {rate:.6f} sat/vB')
    reward = sum(v['value'] for v in coinbase['vout'])
    halvings = args.height // 210000
    subsidy = (50 * 100_000_000) >> halvings if halvings < 64 else 0
    print(f'Coinbase outputs: {reward} sat\nSubsidy: {subsidy} sat')
    print(f'Coinbase minus subsidy: {reward - subsidy} sat (claimed fees for this block)')
    root = merkle_root(txids)
    print('Computed Merkle root:', root)
    check('merkle_root', root == header[36:68][::-1].hex() == block['merkle_root'])
    if args.height == PINNED_HEIGHT:
        check('anchor_3050_transactions', len(txids) == 3050)
        check('anchor_coinbase', reward == 4075061499 and subsidy == 312500000)
    print('ALL CORE CHECKS OK')
    if args.bonus:
        base = 'https://mempool.space/api'
        print('Fee/mempool snapshot (see data/ for retrieval timestamps):')
        print(json.dumps({'recommended': client.get('/v1/fees/recommended', base),
                          'mempool': client.get('/mempool', base)}, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--offline', action='store_true')
    parser.add_argument('--height', type=int, default=PINNED_HEIGHT)
    parser.add_argument('--bonus', action='store_true')
    args = parser.parse_args()
    try:
        run(args)
    except (urllib.error.URLError, ValueError, KeyError, OSError, RuntimeError) as exc:
        parser.exit(1, f'ERROR: {exc}\n')
