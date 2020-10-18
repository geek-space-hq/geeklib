# User

## ユーザーの構造

| Field | Type | Description |
|-------|------|-------------|
| id    | string | ユーザーのID |
| name  | string | ユーザーの名前 |

## URL

### Post: /users/
---

新たなユーザーを作成する．

Post data:
| Field | Type | Description |
|-------|------|-------------|
| name | string | 新しいユーザーの名前 |

Return data: [User | Error]

### Get: /users/:user.id
---

:user のユーザーを返す．

Return data: [User | Error]

### Put: /users/:user.id/name
---
:user のユーザーの name を変更する．

Post data:
| Field | Type | Description |
|-------|------|-------------|
| name | string | 新しいユーザーの名前 |

Return data: [User | Error]

### Delete: /users/:user.id
---

:user のユーザーを削除する．

Return data: [User | Error]

### Post: /users/:user.id/borrow/:book.id
---

:user が :book を借りる．

Return data: [BorrowedLog | Error]

### Post: /users/:user.id/return/:book.id
---

:user が :book を返す．

Return data: [BorrowedLog | Error]
