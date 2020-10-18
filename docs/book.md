# Book

## Book の構造
| Field | Type | Description |
|-------|------|-------------|
| id | string | 本のID |
| title | string | 本の題名 |
| author | string | 本の著者 |
| status | string | 本の状態 |

## URL

### Post: /books/
---

新たな本を作成する．

Post data:

| Field | Type | Description |
|-------|------|-------------|
| title | string | 本の題名 |
| author | string | 本の著者 |

Return data: [Book | Error]

### Get: /books/:book.id
---

book を返す．

Return data: [Book | Error]

### Delete: /books/:book.id
---

book を削除する．

Return data: [Book | Error]
