# Lab 07 — Trạng thái và checklist nộp bài

## Đã hoàn thành và kiểm chứng

| Yêu cầu worksheet | Bằng chứng / vị trí |
| --- | --- |
| Solidity 0.8.24, optimizer 200, EVM paris, OZ 5.0.2 | hardhat.config.js, package.json, package-lock.json |
| ERC20 + ERC20Capped + ERC20Permit; tên/symbol/cap đúng | ClassToken.sol và 9 test ERC-20 |
| Mint full cap cho initialHolder; override _update | Constructor, override; test holder khác deployer và test cap |
| Transfer, lỗi insufficient balance, approve/transferFrom, invariant | ClassToken.test.js |
| ERC721 + Ownable; safeMint, onlyOwner, return ID | ClassBadge.sol, ClassBadge.test.js |
| JSON/SVG data URI; EmptyName; nonexistent token | 13 test badge, gồm JSON tiếng Việt và receiver |
| Bonus permit: relayer, nonce, expiry, replay | 5 test EIP-2612 |
| Q1–Q7 | answers.md |
| npx hardhat test xanh toàn bộ | evidence/tests.txt: 27 passing |
| Luồng deploy -> transfer -> decode trên local | evidence/local-demo.txt: LOCAL END-TO-END DEMO OK |
| RPC TrustKeys phản hồi chainId đúng | Đã đọc eth_chainId: 0x2ec0 = 11968; chỉ chứng minh kết nối RPC |

## Cần hoàn tất bằng ví sinh viên trên TrustKeys

- [ ] Nhập tên sinh viên thật, dùng ví TEST được cấp gas.
- [ ] Deploy ClassToken lên chain 11968, lưu địa chỉ và receipt status 1.
- [ ] Deploy ClassBadge, mint badge với tên sinh viên, lưu receipt.
- [ ] Import ClassToken vào MetaMask trên TrustKeys.
- [ ] Chuyển 100 CTK cho bạn học và xác minh receipt/log/số dư.
- [ ] Chạy read-badge trên TrustKeys, trình JSON và SVG cho trợ giảng.
- [ ] Lưu bằng chứng công khai `evidence/trustkeys-*` và màn hình MetaMask nếu lớp yêu cầu.
- [ ] Đẩy repository của lớp; kiểm tra không đưa khóa riêng/.env lên GitHub.

**Chưa có địa chỉ contract hoặc transaction hash TrustKeys của sinh viên trong gói này.** Các địa chỉ và hash `hardhat-*` là dữ liệu local, không được dùng làm bằng chứng đã deploy TrustKeys. Mạng Hardhat mặc định của `npm run demo` là tạm thời và được tạo mới mỗi lần chạy; các địa chỉ local trong log không thể tra qua TrustKeys.

## Môi trường đã kiểm thử

- Node.js 24.19.0; npm 11.9.0.
- Hardhat 2.28.6; hardhat-toolbox 5.0.0; ethers v6 (phiên bản chính xác trong lockfile).
- OpenZeppelin contracts 5.0.2; solc 0.8.24; optimizer 200; EVM paris.
- 27 test đạt; demo local đạt. Chưa thực hiện thao tác ví MetaMask hoặc giao dịch TrustKeys.
