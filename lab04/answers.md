# Lab 04 — Real Bitcoin Blocks: PoW, Fees & Merkle Root

## Dữ liệu và kết quả thực chạy

Block #840000, thời gian 20/04/2024 00:09:27 UTC (07:09:27 giờ Việt Nam).

- Block ID: `0000000000000000000320283a032748cef8227873ff4872689bf23f1cda83a5`
- Số giao dịch: 3.050, bao gồm coinbase.
- Merkle root: `031b417c3a1828ddf3d6527fc210daafcc9218e81f98257f88d4d43bd7a5894f`
- Đã chạy online và offline: tất cả 12 dòng `CHECK ... OK`, kết thúc phần chính bằng `ALL CORE CHECKS OK`.
- Dữ liệu API được lưu trong `data/`; log đầy đủ tại `run_online.txt` và `run_offline.txt`.

## Q1 — Target có bao nhiêu số 0 đầu? Công việc tương đương 2 mũ bao nhiêu?

Trường bits của block là `0x17034219`, trong đó exponent = `0x17` = 23 và coefficient = `0x034219` = 213529.

```text
target = 0x034219 × 256^(23 - 3)
       = 213529 × 2^160
       = 0x0000000000000000000342190000000000000000000000000000000000000000
```

Target viết đủ 64 chữ số hex có **19 chữ số 0 dẫn đầu**. Tuy nhiên không nên chỉ lấy 19 × 4 = 76 rồi kết luận công việc chính xác là 2^76: phần có nghĩa `34219...` cũng ảnh hưởng xác suất.

Giả sử hash phân bố đều trên 256 bit, với điều kiện hợp lệ hash ≤ target:

```text
p = (target + 1) / 2^256
E[N] = 1/p = 2^256 / (target + 1)
     ≈ 3,710417 × 10^23 lần thử header
     ≈ 2^78,2959
```

Vậy câu trả lời là khoảng **19 số 0 hex**, tương ứng **2^78,3 lần thử**. Đây là kỳ vọng, không phải số lần băm thực tế có thể suy ra từ một block. Mỗi lần thử dùng double SHA-256; nếu đếm riêng từng lời gọi SHA-256 thì số lời gọi xấp xỉ gấp đôi.

Lưu ý kỹ thuật: đề viết hash < target; Bitcoin Core thực tế chấp nhận hash ≤ target. Khác biệt này không ảnh hưởng giá trị xấp xỉ trên.

## Q2 — Vì sao kiểm chứng dễ nhưng tìm PoW khó?

SHA-256 có tính kháng tiền ảnh và đầu ra được mô hình hóa gần như ngẫu nhiên, nên không có cách hiệu quả đã biết để chọn ngược một header sao cho hash rơi vào miền rất nhỏ bên dưới target. Thợ đào phải thay đổi nonce hoặc các dữ liệu hợp lệ khác rồi thử lại rất nhiều lần; biết một hash thất bại không chỉ ra hướng sửa header chắc chắn tốt hơn.

Khi đã có header, người kiểm chứng chỉ cần tính `SHA256(SHA256(header))` rồi so sánh với target. Vì vậy tìm lời giải tốn nhiều lần thử, còn kiểm tra một lời giải chỉ cần hai lời gọi SHA-256 và một phép so sánh.

Con số khoảng 10 phút trong đề là mục tiêu trung bình của mạng, không phải thời gian cố định của mọi block; hashrate 10^20 H/s chỉ là minh họa bậc độ lớn và không được dùng thay cho phép tính xác suất ở Q1.

## Q3 — Vì sao giao dịch trả phí tới 3.600.000 sat/vB?

Giao dịch thường đầu tiên (index 1, vì index 0 là coinbase):

`2bb85f4b004be6da54f766c17c1e855187327112c231ef2ff35ebad0ea67c69e`

| Đại lượng | Giá trị |
| --- | ---: |
| Tổng input, lấy từ vin[].prevout.value | 2.471.128.002 sat |
| Tổng output, lấy từ vout[].value | 1.797.928.002 sat |
| Phí = input − output | 673.200.000 sat = 6,732 BTC |
| Weight | 747 WU |
| vsize = ceil(747/4) | 187 vB |
| Fee rate = 673.200.000 / 187 | 3.600.000 sat/vB |

Block này đánh dấu halving lần thứ tư ngày 20/04/2024 và cũng là block kích hoạt Runes. Theo bối cảnh đề bài, nhu cầu được đưa giao dịch vào những block đầu của Runes làm người dùng cạnh tranh mạnh cho không gian block hữu hạn.

Phí Bitcoin do người gửi lựa chọn thông qua chênh lệch input và output, không phải một tỷ lệ cố định trên số BTC chuyển. Thợ đào thường ưu tiên giao dịch hoặc gói giao dịch có mức phí hấp dẫn trên đơn vị không gian block, nên nhu cầu xác nhận gấp có thể đẩy sat/vB lên rất cao. Halving trực tiếp giảm subsidy; không có quy tắc đồng thuận tự động tăng phí lên mức này. Chỉ từ số phí không thể kết luận chắc chắn động cơ của riêng người gửi giao dịch trên.

### So sánh với snapshot khi làm bài

API mempool.space trả về lúc **22:10:32 ngày 23/10/2026, giờ Việt Nam** (15:10:32 UTC):

| Mức ưu tiên | Phí đề xuất |
| --- | ---: |
| High priority / fastestFee | 3 sat/vB |
| Half-hour | 3 sat/vB |
| Hour | 1 sat/vB |
| Economy | 1 sat/vB |
| Minimum | 1 sat/vB |

Mức 3.600.000 sat/vB của giao dịch lịch sử cao gấp **1.200.000 lần** mức high priority trong snapshot này. Đây là kết quả tại thời điểm gọi API, không phải cam kết phí hoặc thời gian xác nhận cho lần chạy sau; hai endpoint được đọc cách nhau vài giây, không phải snapshot nguyên tử.

## Q4 — Chênh lệch giữa coinbase và subsidy đến từ đâu?

```text
Coinbase outputs = 4.075.061.499 sat = 40,75061499 BTC
Subsidy          =   312.500.000 sat =  3,12500000 BTC
Chênh lệch       = 3.762.561.499 sat = 37,62561499 BTC
```

Chênh lệch **37,62561499 BTC** là phí giao dịch được miner thu trong block này. Coinbase nhận cả trợ cấp phát hành mới và phí, vì thế tổng output coinbase lớn hơn rất nhiều so với 3,125 BTC; không phải toàn bộ 40,75061499 BTC đều là tiền mới phát hành.

Quy tắc tổng quát là tổng coinbase output không được vượt quá subsidy cộng tổng phí; miner có thể nhận ít hơn giới hạn. Script tính phần coinbase vượt subsidy của block này, chưa độc lập cộng phí của toàn bộ 3.049 giao dịch thường.

## Q5 — Merkle root khớp header chứng minh điều gì? (3 câu)

Với số lượng giao dịch và cấu trúc cây Bitcoin đã xác định, Merkle root tính từ 3.050 txid theo đúng thứ tự khớp header cho thấy danh sách txid đã lấy phù hợp với cam kết giao dịch trong header. Nhờ tính kháng va chạm và kháng tiền ảnh thứ hai của hàm băm, việc thay một txid hoặc thay đổi thứ tự mà vẫn giữ nguyên root là không khả thi về mặt tính toán trong mô hình này. Kết quả không tự chứng minh tính hợp lệ của chữ ký, UTXO hoặc dữ liệu witness, vì chương trình chỉ kiểm cây từ txid do API cung cấp chứ chưa xác minh toàn bộ giao dịch như một full node.

## Bonus — Mempool

API `/api/mempool` trả về lúc **22:10:37 ngày 23/10/2026, giờ Việt Nam**:

- Số giao dịch chờ: **52.219**.
- Tổng virtual size: **26.428.291 vB**.
- Tổng phí: **7.181.164 sat**.
- `fee_histogram` gồm các cặp `[fee_rate, tổng_vsize_trong_nhóm]`, không phải số lượng giao dịch mỗi nhóm; xem dữ liệu đầy đủ trong log.
- Endpoint phí đề xuất đúng dùng trong bài: `https://mempool.space/api/v1/fees/recommended` (bổ sung `/v1/` so với đường dẫn ghi tắt trong đề).

Chương trình hỗ trợ đổi block bằng `--height`. Bonus “yesterday's tip” không được thực chạy; block #840000 đã được kiểm tra đầy đủ theo phần bắt buộc.

## Nguồn đối chiếu

1. Đề bài `lab04_worksheet.pdf` do người học cung cấp.
2. Blockstream Esplora API: https://github.com/Blockstream/esplora/blob/master/API.md
3. Dữ liệu block: https://blockstream.info/api/block/0000000000000000000320283a032748cef8227873ff4872689bf23f1cda83a5
4. Bitcoin Core, CheckProofOfWorkImpl: https://github.com/bitcoin/bitcoin/blob/master/src/pow.cpp
5. Runes kích hoạt tại block #840000: https://docs.ordinals.com/runes/specification.html
6. Phí đề xuất: https://mempool.space/api/v1/fees/recommended
7. Mempool: https://mempool.space/api/mempool
