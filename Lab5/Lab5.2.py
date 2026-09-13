# ============================================================
# LAB 5.2 — READ TRUSTKEYS L1
# ============================================================

from web3 import Web3

# Hỗ trợ web3.py v6 / v7
try:
    from web3.middleware import ExtraDataToPOAMiddleware
    poa_middleware = ExtraDataToPOAMiddleware
except ImportError:
    from web3.middleware import geth_poa_middleware
    poa_middleware = geth_poa_middleware

RPC_URL = "https://l1testnet.trustkeys.network"

w3 = Web3(Web3.HTTPProvider(RPC_URL))
w3.middleware_onion.inject(poa_middleware, layer=0)

# 1. Kiểm tra kết nối
print("Connected:", w3.is_connected())
print("Chain ID :", w3.eth.chain_id)
print("Head block:", w3.eth.block_number)

# 2. Block mới nhất
blk = w3.eth.get_block("latest")

base_fee = blk["baseFeePerGas"]
gas_used = blk["gasUsed"]
gas_limit = blk["gasLimit"]

print("\n[LATEST BLOCK]")
print("Block          :", blk["number"])
print("Gas Used       :", gas_used)
print("Gas Limit      :", gas_limit)
print("Gas Used Ratio :", f"{gas_used / gas_limit:.2%}")
print("Base Fee       :", base_fee, "wei")
print("Base Fee       :", base_fee / 1e9, "gwei")

# 3. Fee history 20 block gần nhất
fh = w3.eth.fee_history(
    20,
    "latest",
    [10, 50, 90]
)

print("\n[LAST 20 BLOCKS]")
print("Block | Base Fee (wei) | Gas Used Ratio")

ratios = []

for i, base in enumerate(fh["baseFeePerGas"][:-1]):
    block_number = fh["oldestBlock"] + i
    ratio = fh["gasUsedRatio"][i]
    ratios.append(ratio)

    print(
        f"{block_number} | "
        f"{base} | "
        f"{ratio:.2%}"
    )

# 4. Base fee dự kiến block tiếp theo
next_base_fee = fh["baseFeePerGas"][-1]

print("\nNext projected base fee:",
      next_base_fee, "wei")

# 5. Đánh giá chain busy / quiet
avg_ratio = sum(ratios) / len(ratios)

print("Average gasUsedRatio:",
      f"{avg_ratio:.2%}")

if avg_ratio >= 0.50:
    print("Verdict: chain is BUSY")
else:
    print("Verdict: chain is quiet")