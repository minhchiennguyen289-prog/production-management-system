# LAB 05 — Ethereum Accounts, Gas & the EVM

**Họ và tên:** Nguyen Minh Chien  
**MSSV:** 11247146  
**Lớp:** DS66A

## Q1 — Vì sao `chainId` nằm trong giao dịch được ký?

`chainId` được đưa vào dữ liệu ký theo EIP-155 để ràng buộc chữ ký với đúng một blockchain cụ thể. Nhờ đó, một giao dịch đã ký trên mạng này không thể bị lấy nguyên chữ ký để phát lại (replay) trên một mạng khác có cùng định dạng giao dịch.

## Q2 — Vì sao `baseFee` trên TrustKeys L1 gần như đứng ở mức sàn?

Trong lần chạy của em, `baseFeePerGas = 8 wei` và `gasUsedRatio` trung bình chỉ khoảng **0,22%**, thấp hơn rất nhiều so với mức mục tiêu 50% của EIP-1559 (15M gas trên giới hạn 30M gas). Vì block liên tục dưới mức mục tiêu nên công thức EIP-1559 luôn có xu hướng giảm `baseFee`, nhưng khi đã chạm mức tối thiểu của mạng thì nó không thể giảm thêm, nên `baseFee` giữ ở khoảng **8 wei**.

## Q3 — Vì sao `baseFeePerGas` có N+1 phần tử nhưng `gasUsedRatio` chỉ có N?

N phần tử đầu của `baseFeePerGas` tương ứng với N block đã được trả về, còn phần tử thứ N+1 là **base fee dự kiến cho block kế tiếp**. Ví có thể dùng giá trị dự kiến này, cộng thêm một khoảng dự phòng và `maxPriorityFeePerGas`, để đặt `maxFeePerGas` đủ cao nhằm tránh giao dịch bị kẹt khi base fee tăng.

## Q4 — Nếu tăng `maxFee` nhưng giữ nguyên priority fee thì `effectiveGasPrice` có đổi không?

Thông thường **không đổi**, miễn là `maxFeePerGas - baseFee` vẫn lớn hơn hoặc bằng `maxPriorityFeePerGas`. Khi đó:

`effectiveGasPrice = baseFee + maxPriorityFeePerGas`

nên tăng `maxFeePerGas` chỉ làm tăng mức trần mà người gửi chấp nhận trả, chứ không làm tăng số tiền thực tế phải trả; nó chỉ ảnh hưởng khi mức trần trước đó quá thấp.

## Q5 — Vì sao chuyển ETH đơn giản dùng 21.000 gas và giao dịch thất bại vẫn mất gas?

**21.000 gas** là intrinsic gas cơ bản được quy định cho một giao dịch Ethereum đơn giản giữa hai tài khoản EOA, trước khi tính thêm chi phí dữ liệu hay thực thi smart contract. Nếu giao dịch thất bại hoặc bị `revert`, các thay đổi trạng thái bị hoàn tác nhưng lượng gas đã dùng để xử lý và thực thi giao dịch vẫn phải trả cho mạng; chỉ phần gas chưa sử dụng mới không bị tính.

## Q6 — Function selector và ABI

EVM đọc 4 byte đầu của calldata và bộ `dispatcher` trong contract so sánh selector đó với các selector đã biết để nhảy tới đúng hàm cần thực thi. Etherscan cần ABI của contract vì ABI mô tả tên hàm và kiểu dữ liệu của từng tham số, nhờ đó nó mới giải mã được phần calldata còn lại thành các giá trị có ý nghĩa.

---

## Lab 5.2 — Kết quả thực tế

- Chain ID: `11968`
- Head block khi chạy: `717400`
- `baseFeePerGas`: `8 wei`
- `gasUsedRatio` trung bình 20 block: `0,22%`
- Kết luận: **chain is quiet**

## Lab 5.3 — Fee decomposition

- Transaction hash: `25ed0c7daea84c7a56850b4aeb47739aba113cc174db928b7fab0e431041c64e`
- Block: `717400`
- Gas used: `21,000`
- Base fee: `8 wei`
- Effective gas price: `2,000,000,000 wei`
- Paid: `0.000042 ETH`
- Burned: `1.68E-13 ETH`
- Tip: `0.000041999999832 ETH`
- Check: `paid == burned + tip` → **True**

## Lab 5.4 — Sepolia Etherscan

### Screenshot 1 — Decoded Input Data

> Lưu ý: ảnh hiện tại đã thể hiện các tham số được decode, nhưng khi nộp nên chụp rộng hơn để **4-byte function selector / MethodID** cũng xuất hiện trong cùng ảnh, đúng yêu cầu của đề.

![Decoded Input Data](lab54_decoded_input.png)

### Screenshot 2 — Transaction Receipt Event Logs

![Transaction Receipt Event Logs](lab54_logs.png)
