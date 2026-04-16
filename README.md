# mini-social

中央集権型簡易SNS; 昔少し作ったものを改良・続き作成

## メモ

- パスワードハッシュに `Argon2id` を使うのはいいけど、DoS/DDoS/DRDoS攻撃の温床になる(相応のリソースを食う)のでレートリミットを設定
- Cloudflare Turnstileを使う上で留意点: [CAPTCHA回避サービス対策](https://zenn.dev/localer/articles/335602817265d3#captcha%E5%9B%9E%E9%81%BF%E5%AF%BE%E7%AD%96)