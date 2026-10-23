# Lab 07 — Trả lời Q1–Q7

Bài làm sử dụng OpenZeppelin 5.0.2, Solidity 0.8.24, EVM paris, Hardhat 2 và ethers v6. Các kiểm thử và demo kèm theo chạy trên Hardhat local; chưa có giao dịch triển khai bằng ví sinh viên trên TrustKeys.

## Q1. Vì sao dùng OpenZeppelin thay vì tự viết ERC-20?

OpenZeppelin cung cấp các triển khai chuẩn đã được sử dụng rộng rãi, kiểm thử và rà soát bảo mật. Kế thừa ERC20 giúp tái sử dụng logic số dư, allowance, sự kiện và lỗi chuẩn; ERC20Capped bổ sung giới hạn cung, ERC20Permit bổ sung chữ ký EIP-2612. Điều này giảm lượng mã tự viết và rủi ro sai chuẩn, nhưng không thay thế việc kiểm thử phần cấu hình và mã mở rộng của chính dự án.

Trong bài này, constructor mint toàn bộ `1_000_000 × 10^18` đơn vị cơ sở cho `initialHolder`. Hàm `_update` gọi `super._update(...)` để giữ kiểm tra cap trong chuỗi kế thừa; gọi thẳng triển khai ERC20 có thể bỏ qua logic ERC20Capped. ClassToken không mở hàm mint công khai sau triển khai.

## Q2. Balance bằng 1000000000000000000 là bao nhiêu CTK? “18” nằm ở đâu?

Số dư đó bằng **1 CTK**:

```text
CTK hiển thị = balance theo đơn vị cơ sở / 10^decimals
             = 10^18 / 10^18
             = 1
```

Số dư và số lượng chuyển được lưu/tính bằng số nguyên trên blockchain. **`decimals()` là hàm metadata on-chain trả về 18**; trong triển khai OpenZeppelin được dùng, 18 là giá trị mặc định trong mã hàm, không cần một ô storage riêng. Ví/UI đọc kết quả này để định dạng số dư; blockchain không sử dụng phép tính số thực cho token.

Vì vậy nói “18 chỉ nằm ở UI” là chưa chính xác: công dụng của decimals là hiển thị, nhưng giá trị được công bố qua hợp đồng. Gửi 100 CTK dùng `ethers.parseUnits("100", 18)`, tương ứng `100000000000000000000` đơn vị cơ sở.

## Q3. Vì sao DEX dùng approve + transferFrom? Infinite approval có rủi ro gì?

Một ERC-20 `transfer` thông thường chỉ cập nhật số dư và phát sự kiện trong hợp đồng token; nó không tự gọi hàm swap hay callback của DEX nhận token. Người dùng gọi `approve` để cho phép router/spender sử dụng một lượng token, sau đó gọi hàm swap; router dùng `transferFrom` để lấy token trong cùng giao dịch thực hiện logic swap. Nếu các bước trong giao dịch swap thất bại, thay đổi trạng thái của chính giao dịch đó được hoàn tác; giao dịch approve trước đó không tự bị hoàn tác theo.

`approve(spender, 2^256−1)` cấp quyền sử dụng gần như không giới hạn. Nếu spender độc hại hoặc bị khai thác, nó có thể chuyển hết số dư của **token đã cấp quyền**, kể cả token nạp vào sau này khi allowance vẫn còn; quyền này không mặc nhiên áp dụng cho mọi token hoặc native coin trong ví. Nên cấp đúng mức cần dùng và thu hồi allowance khi không còn cần thiết. Trong OpenZeppelin, allowance bằng `uint256.max` không bị giảm qua `transferFrom`.

## Q4. JSON và ảnh nằm ở đâu? Không dùng IPFS giúp tránh điều gì?

Tên sinh viên được lưu trong storage của ClassBadge; mẫu JSON/SVG và logic dựng dữ liệu nằm trong mã hợp đồng. Khi gọi `tokenURI`, hợp đồng tạo JSON, nhúng ảnh SVG dạng `data:image/svg+xml;base64,...`, rồi mã hóa toàn bộ JSON thành `data:application/json;base64,...`. Do đó không nhất thiết lưu nguyên chuỗi JSON và ảnh trong từng ô storage: dữ liệu được dựng từ trạng thái và bytecode on-chain tại thời điểm gọi.

Thiết kế này tránh phải tải metadata/ảnh lên IPFS, duy trì pinning và phụ thuộc gateway IPFS để lấy ảnh. Đây là lựa chọn thiết kế, không có nghĩa EVM của TrustKeys cấm IPFS. Đổi lại, lưu dữ liệu và logic on-chain làm tăng chi phí triển khai/mint; dữ liệu vẫn cần được đọc qua node/RPC, và tên sinh viên là dữ liệu công khai.

Trong bài làm, ảnh hiển thị mã badge, còn tên sinh viên nằm trong trait `Student`. Tên được escape JSON để dấu ngoặc kép, dấu gạch chéo ngược, ký tự điều khiển và tiếng Việt không làm hỏng metadata; tên không được chèn trực tiếp vào mã SVG.

## Q5. “Safe” trong _safeMint / safeTransferFrom kiểm tra gì?

Nếu địa chỉ nhận có mã hợp đồng, ERC-721 gọi `onERC721Received(operator, from, tokenId, data)` và yêu cầu hàm trả đúng selector `0x150b7a02`. Nếu receiver không hỗ trợ, trả sai giá trị hoặc làm lời gọi thất bại, thao tác mint/transfer bị revert. Với địa chỉ EOA không có code, không có callback này.

Mục đích là xác nhận hợp đồng nhận chủ động chấp nhận ERC-721, giảm nguy cơ gửi NFT vào hợp đồng không hỗ trợ nhận. Kiểm tra này **không bảo đảm** hợp đồng nhận có chức năng rút NFT an toàn hoặc không có lỗi; một receiver vẫn có thể trả đúng selector rồi giữ NFT mãi mãi.

## Q6. Không có explorer thì xác nhận giao dịch 100 CTK thế nào?

Sau khi gửi, lấy `transaction hash` và chờ `tx.wait(1)` hoặc đọc receipt qua RPC. Kiểm tra `receipt.status === 1`, block number, và log `Transfer` phát ra từ **đúng địa chỉ ClassToken**, có `from`, `to` mong đợi và `value = 100 × 10^18`. Tiếp theo gọi `balanceOf` của hai địa chỉ tại block đã chứa giao dịch; xem thêm số dư trên MetaMask đã chọn đúng mạng và đúng contract.

Script `interact-token.js` gửi đúng 100 CTK và thực hiện các kiểm tra này. Nếu chuyển bằng MetaMask, dùng `verify-transfer.js` với `TOKEN`, `TO`, `TX_HASH` để xác minh bằng RPC, không cần private key. Sự xuất hiện trong mempool hoặc chỉ có transaction hash chưa chứng minh thành công; một confirmation chứng minh đã được đưa vào block, không đồng nghĩa bất biến tuyệt đối trước mọi reorg.

**Trạng thái thực tế:** quy trình đã được kiểm chứng local, có receipt/log/số dư trong `evidence/hardhat-*`. Chưa có receipt chuyển 100 CTK trên TrustKeys bằng ví của sinh viên; phải chạy bước này trước khi báo hoàn thành điều kiện trình diễn của đề.

## Q7. Điều gì ngăn replay chữ ký permit trên chain khác hoặc lần thứ hai?

Permit dùng chữ ký EIP-712 với domain gồm tên token, version, **chainId** và **verifyingContract**. Vì vậy chữ ký gắn với chain và hợp đồng cụ thể; thay chainId hoặc địa chỉ hợp đồng làm xác minh chữ ký không còn hợp lệ.

Thông điệp còn chứa `owner`, `spender`, `value`, **nonce** và **deadline**. Khi permit thành công, nonce của owner tăng nên chữ ký cũ không dùng lại được; deadline giới hạn thời gian có thể nộp chữ ký. Deadline không thay thế nonce và không tự làm allowance đã được cấp hết hiệu lực sau thời điểm đó.

“Gasless approval” nghĩa là owner có thể ký off-chain mà không gửi giao dịch approve; **relayer vẫn trả gas** khi nộp permit. Permit chỉ đặt allowance, không tự chuyển token. Các test bonus đã kiểm allowance, nonce, chuyển bằng allowance mới, hết hạn, replay, sai chainId và sai verifyingContract.

## Nguồn kỹ thuật

- Đề Lab 07 do giảng viên cung cấp.
- Mã phiên bản dùng trong bài: https://github.com/OpenZeppelin/openzeppelin-contracts/tree/v5.0.2/contracts
- ERC-20: https://eips.ethereum.org/EIPS/eip-20
- ERC-721: https://eips.ethereum.org/EIPS/eip-721
- Permit: https://eips.ethereum.org/EIPS/eip-2612
- Hardhat 2 configuration: https://v2.hardhat.org/hardhat-runner/docs/config
