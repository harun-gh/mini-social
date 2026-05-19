# QUIC

## Header

### Is this Long Packet?

- `0`: Short Packet
- `1`: 0Long Packet

### Fixed Bit

ちょっと理解できない  
QUICのパケットとして判定するためのフラッグらしいけど...

- `1`: QUIC Packet

### Packet Type

- `00`: Initial
- `01`: 0-RTT
- `10`: Handshake
- `11`: Retry

### Reserved Bits

後に機能を増やしたいときのために、後方互換性を保つための予約済み2桁ビット

- `00`: QUIC Packet

