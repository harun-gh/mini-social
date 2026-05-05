# HTTP

## 問題点？

- headerの最大許容サイズは、8KBなのでオーバーする可能性が否定できない

## メモ

「リソースの食いつぶし(`DoS/DDoS/DRDoS`攻撃等)の対策」及び「パフォーマンス最適化」として、 [`nginx/src/http/ngx_http_parse.c at master · nginx/nginx`](https://github.com/nginx/nginx/blob/master/src/http/ngx_http_parse.c) を参考に以下の思想を取り入れました

- `Zero-Backtracking` (ゼロ・バックトラッキング)
- `Machine State`

また、 [`XST: Cross-Site Tracing`](https://owasp.org/www-community/attacks/Cross_Site_Tracing) の攻撃の危険性があるので、HTTPメソッドのうち `TRACE` を消しました

- `obs-fold`: 複数行ヘッダー は、 `RFC 9110` により禁止されているので実装しません
- HTTPヘッダーの名前と値の間の空白は任意なので注意なのと、空白の個数も任意なのでろくでもないことになる可能性あり