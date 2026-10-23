# Kết quả xác minh

- Hardhat 2.28.0; ethers 6.15.0; Solidity 0.8.24; Node 24.19.0.
- 6/6 tests passed; log: `test-output.txt`.
- Slither 0.11.6, hai detector `reentrancy-eth,low-level-calls`: 4 findings.
- 1 reentrancy-eth finding ở EtherBankVulnerable.withdraw; không có finding loại này ở EtherBankSecure hoặc alias EtherBank.
- 3 low-level-calls findings: Attacker.collect, EtherBankSecure.withdraw, EtherBankVulnerable.withdraw.
- Đây là log và JSON thực chạy, không phải output mô phỏng.
- Dòng npm warning về http-proxy trong log không ngăn biên dịch hay phân tích.
- Không dùng kết quả này để tuyên bố đã audit toàn diện.
