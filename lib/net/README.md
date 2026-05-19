# Network

リファクタリング中

- 情報古いけど [HTTP/3入門 記事一覧 | gihyo.jp](https://gihyo.jp/admin/serial/01/http3)

HTTP/3のQUICを実装するに当たって、対話の一番最初に送られてくるUDPパケットには鍵が入ってるので、それを扱うために先にTLS 1.3を実装しなきゃいけないかも？

- zig非同期処理: https://codeberg.org/loftafi/zigtoberfest-async
- [ UDPフラッド攻撃とは？](https://www.cloudflare.com/ja-jp/learning/ddos/udp-flood-ddos-attack/)