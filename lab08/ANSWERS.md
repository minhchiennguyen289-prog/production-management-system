# Lab 08 — Reentrancy: exploit then patch

Bài làm theo worksheet đính kèm. Do đề chỉ kèm PDF, dự án này tái dựng hợp đồng theo hành vi mô tả, không giả định có sẵn thư mục starter hay instructor notes. Mọi test dùng Hardhat local.

## Đoạn nộp bài: lỗi và cách vá

Lỗi trong `withdraw()` là thực hiện `(bool ok,) = msg.sender.call{value: bal}("");` khi `balances[msg.sender]` vẫn còn giá trị cũ. Hợp đồng nhận ETH có thể gọi ngược vào `withdraw()` và rút lặp lại cùng một khoản ghi có trước khi lần gọi đầu tiên hoàn tất. Cách sửa trọng tâm là chuyển dòng `balances[msg.sender] = 0;` lên **trước** lời gọi `.call`, theo Checks–Effects–Interactions; đồng thời áp dụng `nonReentrant` và kiểm tra `ok`. Với 30 ETH của ba người gửi và 1 ETH stake, bản lỗi chuyển 31 ETH cho Attacker; bản vá làm cùng cuộc tấn công revert, hoàn tác cả stake và giữ nguyên 30 ETH của người gửi.

## Q0 — Thứ tự sai nằm ở đâu?

Bản lỗi: đọc số dư → kiểm tra số dư → gửi ETH bằng `.call` → kiểm tra kết quả → đặt số dư bằng 0. Khi `.call` chuyển quyền điều khiển sang `Attacker.receive()`, số dư nội bộ của Attacker chưa bị xóa. Vì vậy mỗi lần tái nhập đều thấy cùng số dư 1 ETH và vượt qua kiểm tra. Bản vá xóa ghi có trước khi chuyển quyền điều khiển ra ngoài.

## Q1 — Số lần withdraw và điều kiện dừng

`withdraw()` chạy **31 lần** trong một giao dịch `attack()`: 1 lần gọi ban đầu và 30 lần tái nhập. Sau khi Eve gửi stake, ngân hàng có 30 + 1 = 31 ETH; mỗi lần rút là 1 ETH. Lần nhận ETH thứ 31 thấy `address(bank).balance == 0`, không còn thỏa `>= unit`, nên không gọi tiếp. Test xác nhận `callbacks == 31`; mỗi callback tương ứng một lần ngân hàng trả ETH trong kịch bản này. Đây không phải 31 giao dịch độc lập.

Attacker nhận 31 ETH nhưng có 1 ETH vốn của Eve, nên lợi nhuận trước phí là 30 ETH. Với mốc số dư ví lấy **sau triển khai Attacker, trước attack**, công thức là:

```text
(after - before) + gasAttack + gasCollect = 30 ETH
Lợi nhuận thực tế sau phí = 30 ETH - gasAttack - gasCollect
```

Khoản stake đã nằm trong biến động số dư ví; không trừ 1 ETH thêm lần nữa. Nếu tính từ trước triển khai, phải tính thêm phí triển khai Attacker. Vì có gas, lợi nhuận thực nhận không thể đúng 30 ETH; test hiểu yêu cầu đề là lợi nhuận đã điều chỉnh phí gas.

## Q2 — Nếu thay call bằng transfer?

Cuộc tấn công cụ thể này không chạy thành công với stipend 2.300 gas: callback cần ghi bộ đếm vào storage và thực hiện lời gọi tái nhập, vượt ngân sách đó. Tuy nhiên, `transfer` không sửa thứ tự cập nhật trạng thái và dựa vào hạn mức gas để bảo vệ là không bền vững; thay đổi chi phí opcode có thể khiến hợp đồng nhận hợp lệ không nhận được tiền. Cách vá là CEI, khóa phù hợp và xử lý kết quả lời gọi ngoài. Không suy rộng rằng mọi dạng tái nhập chỉ xảy ra khi chuyển ETH.

## Q3 — CEI đã đủ cho ví dụ, tại sao thêm guard?

Trong hàm rút này, CEI làm lần rút tái nhập thấy số dư 0. Guard bổ sung một lớp chặn việc quay lại các đường xử lý đang được khóa, giảm nguy cơ khi hợp đồng mở rộng. Với tái nhập chéo hàm, một callback có thể gọi một hàm khác dùng chung trạng thái. Các entry point liên quan phải dùng **cùng khóa** và duy trì bất biến; khóa riêng `withdraw()` không tự bảo vệ mọi hàm. Bản vá dùng cùng modifier cho `deposit()` và `withdraw()`. Guard không thay thế việc thiết kế trạng thái đúng, cũng không tự giải quyết mọi dạng read-only hoặc cross-contract reentrancy. Ở bản vá này guard kiểm tra trước thân hàm nên lần tái nhập bị chặn trước khi đọc số dư.

## Q4 — Vì sao lỗi ngoài cùng là “transfer failed”?

Chuỗi gọi là `attack → withdraw → call(receive) → withdraw`. Lần `withdraw` thứ hai gặp khóa và revert với `ReentrancyGuard: reentrant call`. Vì `receive()` không bắt lỗi, callback cũng revert. Tuy nhiên lời gọi cấp thấp `.call` ở lần rút đầu tiên trả về `ok == false` và revert data, thay vì tự động truyền lỗi lên. Code bỏ qua revert data và chạy `require(ok, "transfer failed")`, tạo thông báo ngoài cùng. Toàn bộ giao dịch rollback: stake, ghi có, khóa và bộ đếm callback đều trở lại trạng thái trước giao dịch. Đây là hành vi của mã lỗi chuỗi trong dự án, không phải khẳng định mọi thư viện guard dùng cùng thông báo.

## Q5 — low-level-calls trên bản vá có phải lỗ hổng?

Không tự động là lỗ hổng. Detector chỉ ra một điểm chuyển quyền điều khiển cần con người xem xét. Ở đây hợp đồng đặt số dư về 0 trước `.call`, dùng khóa và kiểm tra `ok`; vì thế lời gọi cấp thấp vẫn tồn tại nhưng đường khai thác của đề bị chặn. Không còn `reentrancy-eth` không có nghĩa đã chứng minh hợp đồng an toàn tuyệt đối. Xem log và JSON thực chạy trong `reports/`.

## Q6 — tx.origin và kịch bản phishing owner

Giả sử `onlyOwner` dùng `require(tx.origin == owner)`. Chủ sở hữu gọi một hàm của hợp đồng độc hại; hàm đó gọi tiếp `bank.setOwner(attackerAddress)`. Khi đến ngân hàng, `tx.origin` vẫn là EOA chủ sở hữu nên kiểm tra sai này vượt qua, dù `msg.sender` là hợp đồng độc hại. Dùng `require(msg.sender == owner)` kiểm tra người gọi trực tiếp và chặn chuỗi đó. Test bonus quét 19 signer, xác nhận bản lỗi cho phép chiếm quyền còn bản vá từ chối tất cả non-owner; đây là property test hữu hạn trên tập signer local, không phải chứng minh hình thức cho mọi địa chỉ.

## Đối chiếu yêu cầu

| Mục | Bằng chứng |
| --- | --- |
| 08.1: deposit stake, tái nhập, collect | `contracts/Attacker.sol` |
| Rút cạn và lợi nhuận 30 ETH sau điều chỉnh gas | `test/Reentrancy.test.js` |
| 08.2: CEI + guard, revert, giữ 30 ETH | `contracts/EtherBank.sol`, test cùng attacker |
| Tiền còn rút được sau cuộc tấn công thất bại | Ba người gửi rút đủ trong test bản vá |
| 08.3: đọc cảnh báo trước/sau | `reports/captured-slither-output.txt`, `reports/slither.json` |
| 08.4 bonus: owner, zero-check, event | `test/AccessControl.test.js` |
| Q0–Q6 và đoạn nộp bài | Tài liệu này |

## Tài liệu tham khảo

- Worksheet Lab 08 do người dùng cung cấp (4 trang).
- Solidity, Security Considerations: https://docs.soliditylang.org/en/latest/security-considerations.html
- Slither detector documentation: https://github.com/crytic/slither/wiki/Detector-Documentation
