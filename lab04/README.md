# Lab 04 — Real Bitcoin Blocks: PoW, Fees & Merkle Root

Bản lời giải được xây dựng từ lab04_worksheet.pdf. File starter và thư mục data gốc của giảng viên chưa được cung cấp; đây là bản độc lập, không phải bản sửa trực tiếp starter gốc.

## Chạy bài

Python 3.9 trở lên. Bản này dùng thư viện chuẩn `urllib.request`, không cần cài thêm requests.

```bash
python3 bitcoin_explorer_starter.py --offline
python3 bitcoin_explorer_starter.py --offline --bonus
```

`data/` chứa phản hồi API thật đã tải khi làm bài. Offline phát lại snapshot, không phải số liệu mempool hiện tại.

Chạy lấy dữ liệu mới và cập nhật cache:

```bash
python3 bitcoin_explorer_starter.py
python3 bitcoin_explorer_starter.py --bonus
python3 bitcoin_explorer_starter.py --height 840001
```

Nếu mạng không cho truy cập API, dùng `--offline` với block 840000 đã đính kèm. Block khác phải chạy online ít nhất một lần trước khi chạy offline.

## Đối chiếu TODO

- TODO 1: `bits_to_target(bits)`; kiểm header 80 byte, double SHA-256, PoW.
- TODO 2: `transaction_fee(tx)`; tổng prevout trừ tổng output; vsize = (weight + 3) // 4.
- TODO 3: `merkle_root(txids)`; đảo byte txid, nhân đôi nút lẻ, double SHA-256, đảo byte kết quả.
- `answers.md`: Q1–Q5, giải thích số liệu và phần so sánh phí.
- `run_online.txt`, `run_offline.txt`: kết quả chạy thực tế.

## Nộp bài

Đọc hiểu `answers.md`, bổ sung họ tên/mã sinh viên nếu lớp yêu cầu. Đưa `bitcoin_explorer_starter.py` và `answers.md` vào repository lớp; nên kèm `data/` nếu cần chạy offline. Chưa thực hiện push vì chưa có URL repository lớp.

```bash
git add bitcoin_explorer_starter.py answers.md data/
git commit -m "Complete Lab 04: Bitcoin PoW, fees and Merkle root"
git push
```

Chạy các lệnh Git trên trong repository lớp đã được cấu hình. Nếu giảng viên yêu cầu giữ nguyên starter gốc, chuyển ba hàm hoàn chỉnh sang vị trí TODO tương ứng và giữ nguyên tên hàm/cấu trúc của starter.

## Giới hạn xác minh

Script tự tính hash header và root từ txids; phí đối chiếu dữ liệu prevout/fee của API. Script không tự tải toàn bộ raw transactions để tính lại từng txid, không xác minh chữ ký/UTXO, quy tắc difficulty theo lịch sử hay tổng phí của mọi giao dịch. Vì vậy đây là các phép kiểm theo phạm vi lab, không thay thế full node.
