# ============================================================
# LAB 5.3 — EIP-1559 FEE BREAKDOWN
# ============================================================

from web3 import Web3

try:
    from web3.middleware import ExtraDataToPOAMiddleware
    poa_middleware = ExtraDataToPOAMiddleware
except ImportError:
    from web3.middleware import geth_poa_middleware
    poa_middleware = geth_poa_middleware

RPC_URL = "https://l1testnet.trustkeys.network"

w3 = Web3(Web3.HTTPProvider(RPC_URL))
w3.middleware_onion.inject(poa_middleware, layer=0)

print("Connected:", w3.is_connected())

# Tìm transaction Type-2 gần nhất
tx = None

for block_num in range(w3.eth.block_number, w3.eth.block_number - 200, -1):
    block = w3.eth.get_block(block_num, full_transactions=True)

    for t in block["transactions"]:
        if t["type"] == 2:
            tx = t
            break

    if tx:
        break

if tx is None:
    raise RuntimeError("Không tìm thấy Type-2 transaction trong 200 block gần nhất.")

# Receipt + block chứa transaction
receipt = w3.eth.get_transaction_receipt(tx["hash"])
block = w3.eth.get_block(receipt["blockNumber"])

gas_used = receipt["gasUsed"]
effective_gas_price = receipt["effectiveGasPrice"]
base_fee = block["baseFeePerGas"]

# EIP-1559 fee breakdown
paid = gas_used * effective_gas_price
burned = gas_used * base_fee
tip = paid - burned

print("\n=== TYPE-2 TRANSACTION ===")
print("Tx Hash :", tx["hash"].hex())
print("Block   :", receipt["blockNumber"])
print("Gas Used:", gas_used)

print("\n=== GAS PRICE ===")
print("Base Fee           :", base_fee, "wei")
print("Effective Gas Price:", effective_gas_price, "wei")

print("\n=== FEE BREAKDOWN ===")
print("Paid   :", w3.from_wei(paid, "ether"), "ETH")
print("Burned :", w3.from_wei(burned, "ether"), "ETH")
print("Tip    :", w3.from_wei(tip, "ether"), "ETH")

print("\nCheck paid = burned + tip:", paid == burned + tip)