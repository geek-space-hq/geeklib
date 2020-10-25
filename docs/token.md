# Token

## トークンの構造

| Field | Type | Description |
|-------|------|-------------|
| token    | string | token |
| user  | User | tokenの持ち主 |

## URL

### Post: /tokens/
---

新しいトークンを作成する．

Post data:
| Field | Type | Description |
|-------|------|-------------|
| name | string | ユーザーの名前 |
| password | string | ユーザーのパスワード |

Return data: [Token | Error]

