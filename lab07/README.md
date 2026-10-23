# Lab 07 — Token Standards on Hardhat + TrustKeys

Dự án hoàn chỉnh theo worksheet: ClassToken (ERC-20 + Capped + Permit), ClassBadge (ERC-721 + Ownable + metadata on-chain), test, script triển khai/tương tác và trả lời Q1–Q7.

**Đã kiểm chứng: 27/27 test đạt; demo local deploy hai contract, chuyển 100 CTK và giải mã NFT thành công. Chưa triển khai bằng ví sinh viên lên TrustKeys hoặc thao tác MetaMask.** Đây là bản độc lập từ đề PDF, không phải bản đã chỉnh trực tiếp thư mục `lab/solutions/` của giảng viên.

## 1. Cài và chạy ngay

Dùng Node.js 22 hoặc 24; dự án đã chạy với Node 24.19.0. Đề yêu cầu tối thiểu Node 18, nhưng gói công cụ được khóa trong dự án này dùng Node mới hơn để tương thích dependency.

```bash
cd lab07
npm ci
npx hardhat test
npm run demo
```

Kết quả mong đợi: `27 passing` và `LOCAL END-TO-END DEMO OK`. `npm ci` cần mạng để cài package lần đầu. Sau khi cài, compiler `solc@0.8.24` đã có trong npm dependencies nên compile/test local không cần tải compiler từ một máy chủ khác.

Không chạy `npm install hardhat@latest` hoặc nâng OpenZeppelin tùy ý. `package-lock.json` khóa dependency; `hardhat.config.js` đặt rõ `evmVersion: "paris"`, optimizer 200 runs. Hardhat 2 và toolbox 5 được chọn để giữ đúng cấu trúc JavaScript/ethers v6 của đề.

## 2. Nội dung dự án

| File/thư mục | Vai trò |
| --- | --- |
| `contracts/ClassToken.sol` | Mint 1.000.000 CTK cho initialHolder; cap; permit; override _update |
| `contracts/ClassBadge.sol` | Mint chỉ owner, token ID bắt đầu từ 0, JSON và SVG base64 |
| `contracts/test/TestHelpers.sol` | Contract hỗ trợ test cap/receiver; không deploy lên TrustKeys |
| `test/ClassToken.test.js` | 9 test ERC-20 và 5 test permit |
| `test/ClassBadge.test.js` | 13 test ERC-721/metadata/receiver |
| `scripts/` | Preflight, deploy, chuyển token, xác minh receipt và giải mã badge |
| `answers.md` | Q1–Q7: giải thích đúng bản chất, có ví dụ số cụ thể |
| `.env.example` | Biến môi trường mẫu, không chứa khóa |
| `evidence/` | Log test và bằng chứng local; script sẽ thêm bằng chứng TrustKeys khi chạy |
| `SUBMISSION.md` | Đối chiếu điều kiện đạt và các bằng chứng còn cần bổ sung |

## 3. Chuẩn bị ví TrustKeys

Trong MetaMask, dùng **tài khoản TEST riêng**, được giảng viên cấp native coin để trả gas. Tên/symbol native coin lấy theo cấu hình giảng viên; không nhầm CTK với đồng trả gas.

- Network name: `TrustKeys Testnet` (nhãn hiển thị).
- RPC URL: `https://l1testnet.trustkeys.network`.
- Chain ID: `11968`.
- Explorer: để trống theo worksheet.

Tạo file cấu hình trên máy của bạn:

```bash
cp .env.example .env
```

Điền `PRIVATE_KEY` của tài khoản TEST và `STUDENT_NAME` của bạn trong `.env`. Không gửi private key/mnemonic qua chat, không đưa vào GitHub; `.gitignore` đã loại `.env`. Các trường địa chỉ và transaction hash là thông tin công khai. Giữ `INITIAL_HOLDER` và `BADGE_TO` trống để mặc định dùng tài khoản deployer.

```bash
npx hardhat run scripts/preflight.js --network trustkeys
```

Script kiểm chainId, địa chỉ gửi và số dư native coin. Có số dư dương chưa bảo đảm đủ gas cho mọi thao tác; nếu thiếu, nhờ giảng viên nạp thêm đúng địa chỉ.

## 4. Deploy hai hợp đồng và mint badge

```bash
npx hardhat run scripts/deploy-token.js --network trustkeys
npx hardhat run scripts/deploy-badge.js --network trustkeys
```

- Script token in địa chỉ ClassToken và mint toàn bộ cung cho initialHolder.
- Script badge deploy ClassBadge, sau đó mint badge ID 0 với `STUDENT_NAME` đã điền.
- Mỗi giao dịch chờ receipt thành công và lưu bằng chứng công khai vào `evidence/trustkeys-*`.
- Ghi địa chỉ token vào `TOKEN=...`, địa chỉ badge vào `REGISTRY=...` trong `.env`.

**Không chạy deploy lại chỉ để tìm địa chỉ.** Mỗi lần deploy tạo contract mới; địa chỉ đã lưu trong `evidence/trustkeys-token-deployment.json` và `evidence/trustkeys-badge-deployment.json`. Nếu deploy badge thành công nhưng mint thất bại, sửa nguyên nhân rồi dùng Hardhat console gọi `mint` trên địa chỉ badge đã có, hoặc nhờ hỗ trợ; không coi receipt deploy là receipt mint.

## 5. Import CTK vào MetaMask và gửi 100 CTK

Trong MetaMask, chọn TrustKeys và tài khoản initialHolder. Chọn **Import tokens**, dán địa chỉ ClassToken; symbol `CTK`, decimals `18`. Số dư ban đầu là **1.000.000 CTK** nếu chưa chuyển.

Chọn một trong hai cách gửi dưới đây; không chạy cả hai nếu bạn chỉ muốn chuyển tổng cộng 100 CTK.

### Cách A — Dùng script như worksheet

Điền `TO=địa_chỉ_công_khai_của_bạn_học` vào `.env`, rồi chạy:

```bash
npx hardhat run scripts/interact-token.js --network trustkeys
```

Script gửi đúng 100 CTK, chờ receipt, kiểm log và đọc số dư. Nếu người gửi bắt đầu từ toàn bộ cung và người nhận chưa có CTK, số dư sau chuyển là 999.900 CTK và 100 CTK. Nếu số dư ban đầu khác, dùng receipt/log và chênh lệch thực tế để đối chiếu.

### Cách B — Gửi trực tiếp bằng MetaMask

Chọn CTK → Send → địa chỉ bạn học → 100 CTK → kiểm tra và xác nhận. Sao chép transaction hash, thêm `TX_HASH=...` vào `.env` và kiểm tra:

```bash
npx hardhat run scripts/verify-transfer.js --network trustkeys
```

Script xác minh không cần khóa riêng, nhưng cần `TOKEN`, `TO`, `TX_HASH`. Đưa receipt thành công, log Transfer và màn hình số dư đúng mạng cho trợ giảng xem. Chỉ có hash giao dịch mà chưa có receipt thành công là chưa đủ.

## 6. Giải mã tokenURI của ClassBadge

Đặt `REGISTRY` là địa chỉ badge và `TOKEN_ID=0` trong `.env`:

```bash
npx hardhat run scripts/read-badge.js --network trustkeys
```

Script in JSON và SVG, đồng thời lưu `evidence/trustkeys-badge-0-decoded.json` và `evidence/trustkeys-badge-0.svg`. Mở SVG bằng trình duyệt để xem ảnh. JSON phải có `name`, `description`, mảng `attributes` với trait `Student` đúng tên bạn, và trường `image` là SVG data URI.

## 7. Bonus permit

```bash
npx hardhat test test/ClassToken.test.js --grep "EIP-2612"
```

5 test bonus dùng tài khoản owner ký EIP-712 và tài khoản relayer khác gửi permit. Chúng xác minh allowance, nonce, expiry và replay protection. Bonus này đã làm và kiểm thử local; không có giao dịch relayer trên TrustKeys trong gói đính kèm.

## 8. Đưa lên GitHub

Đọc `SUBMISSION.md`, hoàn tất bằng chứng TrustKeys trước khi báo đã đáp ứng toàn bộ điều kiện đạt. Trong repository của lớp, chép thư mục này vào `lab07/`, rồi từ thư mục gốc repo:

```bash
git add lab07/
git status --short
git diff --cached --name-only
git commit -m "Complete Lab 07 token contracts, tests and scripts"
git push
```

Kiểm tra `.env`, khóa riêng và `node_modules/` không nằm trong danh sách staged. Nếu dùng `lab07` làm repository riêng, thay `git add lab07/` bằng `git add .`. Gói không chứa `node_modules`, artifact/cache compiler; người chấm tái tạo bằng `npm ci`.

## 9. Lỗi thường gặp

| Hiện tượng | Xử lý |
| --- | --- |
| Không có signer | Điền PRIVATE_KEY của tài khoản TEST trong .env trên máy bạn |
| Insufficient funds | Tài khoản thiếu native coin trả gas; CTK không dùng trả gas |
| Sai chainId | Kiểm tra RPC và mạng MetaMask, dùng 11968 |
| Invalid opcode | Cài đúng lockfile và compiler paris; không nâng OZ tùy ý |
| ERC721NonexistentToken | Kiểm tra đúng địa chỉ badge và giao dịch mint đã thành công |
| ERC20InsufficientBalance | Dùng tài khoản đang giữ CTK, kiểm tra INITIAL_HOLDER |
| EmptyName / thiếu STUDENT_NAME | Điền tên sinh viên trước khi deploy/mint |
| Không thấy CTK trong MetaMask | Import đúng contract trên đúng mạng và chọn đúng tài khoản |

ClassBadge trong đề là NFT có thể chuyển, không phải soulbound token. Không thêm ràng buộc cấm chuyển ngoài yêu cầu bài.
