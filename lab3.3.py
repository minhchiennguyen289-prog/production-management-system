from eth_account import Account
from eth_account.messages import encode_defunct

# Tạo một tài khoản (ví) mới ngẫu nhiên
acct = Account.create()
print("address:", acct.address)
# NEVER use this key for real funds
# TUYỆT ĐỐI không dùng khóa này cho tiền thật

msg = encode_defunct(text="I attended Session 3 / Toi da hoc Buoi 3")
sig = Account.sign_message(msg, acct.key)
print("r,s,v:", hex(sig.r), hex(sig.s), sig.v)

# Khôi phục địa chỉ chỉ từ chữ ký và thông điệp gốc
who = Account.recover_message(msg, signature=sig.signature)
print("recovered:", who, "| match:", who == acct.address)

# Cố tình sửa 1 ký tự trong thông điệp gốc (Session 3 -> Session 4)
bad = encode_defunct(text="I attended Session 3 / Toi da hoc Buoi 4")
print("tampered ->", Account.recover_message(bad, signature=sig.signature))