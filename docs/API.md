# Shamwari mobile API

Version 1. Base URL `http://<host>:8642`. Every path below is under `/api/v1`.

This is the contract for the Flutter client (Android and iOS). The browser pages are unchanged: they still use a session cookie and a CSRF token. The mobile client uses a bearer token and never sends CSRF.

Money is integer cents. Display strings already include the currency mark and a space, for example `US$ 86.00` and `ZiG 420.00`. Do not reformat those strings if you want them to match the web app. Clients must not depend on JSON key order.

Every row is synthetic. Phones are masked (`0771••••01`). Responses never include a PIN hash, a password hash, or a raw phone number.

## Auth

`POST /api/v1/auth/login` returns a bearer token. Send it on later calls:

```
Authorization: Bearer <token>
Content-Type: application/json
```

A browser that is already signed in may call the API with its session cookie and no bearer token. If both are sent, the bearer token wins. Logout revokes only the bearer token. The web session is unchanged.

Tokens last 14 days (`API_TOKEN_DAYS`). Logout sets `revoked_at`. An expired token returns `token_expired`. An unknown or revoked token returns `unauthorized`.

Demo accounts, same as the login page. These passwords are not the payment PIN.

| Desk | Username | Password | Role |
| --- | --- | --- | --- |
| Rudo Moyo | `rudo` | `rudo-demo` | `customer` |
| Care team | `care` | `care-demo` | `staff` |

The payment PIN for every synthetic customer is `2580`. Send it only to a confirm endpoint, together with a yes word (`yes`, `hongu`, `yebo`, `ewe`, `ehe`). Confirm checks the PIN on the server. It does not call the model, does not write the PIN into the AI log, and does not echo the PIN in the response.

## Roles

Customer (`rudo`): wallet, transactions, activity, contacts, transfers, voice, coach, scam, receipts, accessibility.

Care staff (`care`): pulse, onboarding buddy, ledger, AI log, impact, copilot, and the audit log.

Either signed-in role: health is public, and so is login. Merchants, search, demo progress, `/auth/me`, and `/auth/logout` accept either role.

A customer token that calls a care route gets `403` `forbidden` ("care team"). A care token on a customer route gets the same code ("customer side"). A web session with the guided demo flag still bypasses that split, matching the browser. A bearer token does not.

## Envelope

Success:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {}
}
```

Error:

```json
{
  "ok": false,
  "synthetic": true,
  "error": {
    "code": "validation",
    "message": "Send amount_cents.",
    "details": {}
  }
}
```

`details` is omitted when there is nothing extra. Confirm failures put the still-pending transaction in `error.details.transaction`.

| code | HTTP | When |
| --- | --- | --- |
| `unauthorized` | 401 | Missing, unknown, or revoked token, or a wrong password |
| `token_expired` | 401 | Bearer token past `expires_at` |
| `forbidden` | 403 | Wrong role, or a transfer owned by someone else |
| `not_found` | 404 | Unknown id, sample, or path |
| `validation` | 400 | Missing or unusable fields |
| `transcript_empty` | 400 | Audio produced no text. Unknown bytes do this in mock mode. A known demo clip does not |
| `risk_ack_required` | 400 | High-risk transfer. Send `risk_ack: true`, then the yes word and PIN. Nothing was posted |
| `need_yes` | 400 | Confirm word was not a yes word. Transfer stays pending |
| `bad_pin` | 400 | PIN did not match. Transfer stays pending |
| `insufficient` | 400 | Wallet no longer covers the hold |
| `not_pending` | 409 | Confirm or cancel on a row that is not pending |
| `method_not_allowed` | 405 | Wrong verb |
| `too_large` | 413 | Upload over the 6 MB request cap. Keep files under 5 MB |

`401` responses include `WWW-Authenticate: Bearer realm="shamwari"`.

## CORS

Every `/api/` response sends:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: Authorization, Content-Type, Accept
Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
```

`OPTIONS` on any `/api/` path returns `204` with those headers and does not require a token. HTML pages do not send these headers.

## Reachability

The server binds to `0.0.0.0:8642`.

| Client | Base URL |
| --- | --- |
| This computer | `http://127.0.0.1:8642` |
| Phone on the same Wi-Fi | `http://<lan-ip>:8642` |
| Android emulator | `http://10.0.2.2:8642` |
| iOS simulator | `http://127.0.0.1:8642` |

`127.0.0.1` on a physical phone is the phone, not the laptop. Leave `CAIMEX_API_KEY` empty to stay on the mock provider. Do not put a key in the app binary or the repo.

`GET /health` on the web app is a separate liveness route. Mobile should call `GET /api/v1/health`.

The older `/ecocash/api/*` routes are session-gated helpers for the web ledger. Build the app from this document, not from those routes.

## Public

### POST /api/v1/auth/login

No token. JSON body. CSRF is not required.

Request:

```json
{"username": "rudo", "password": "rudo-demo"}
```

Response `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "token": "example-bearer-token",
    "token_type": "Bearer",
    "expires_at": "2026-11-09T06:46:18Z",
    "user": {
      "id": 1,
      "username": "rudo",
      "role": "customer",
      "display_name": "Rudo Moyo",
      "customer_id": 1
    }
  }
}
```

Care login is the same shape with `"role": "staff"` and `"customer_id": null`.

Errors: `400` `validation` if username or password is empty. `401` `unauthorized` if they do not match. The token is not stored in the clear. Only its SHA-256 hash is kept.

### GET /api/v1/health

No token.

Response `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "version": "v1",
    "ai_mode": "mock",
    "ai_label": "Mock",
    "customers": 8
  }
}
```

`ai_mode` is `caimex` when `CAIMEX_API_KEY` is set, otherwise `mock`.

## Either role

### POST /api/v1/auth/logout

Requires a bearer token. Revokes that token. A later call with it returns `401`.

Response `200`:

```json
{"ok": true, "synthetic": true, "data": {"revoked": true}}
```

A session cookie with no bearer token gets `400` `validation`. Use the web logout form for the browser.

### GET /api/v1/auth/me

Response `200` for Rudo:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "user": {
      "id": 1,
      "username": "rudo",
      "role": "customer",
      "display_name": "Rudo Moyo",
      "customer_id": 1
    },
    "customer": {
      "id": 1,
      "full_name": "Rudo Moyo",
      "short_name": "Rudo Moyo",
      "city": "Harare",
      "language": "en",
      "role": "Tuckshop owner",
      "phone_masked": "0771••••01"
    }
  }
}
```

Care responses omit `customer`.

### GET /api/v1/merchants

Synthetic merchants both roles can pay or display.

Response `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "merchants": [
      {"id": 2, "name": "Mbare Fresh Produce", "category": "Groceries", "city": "Harare"}
    ]
  }
}
```

The list is the full table, ordered by name. Category strings come from the seed.

### GET /api/v1/search

Query `q`. Same role filter as the web command palette. A customer search for `pulse` is empty. A care search for `pulse` includes Customer Pulse.

Response `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "results": [
      {
        "label": "Send money",
        "group": "Actions",
        "hint": "Actions",
        "api_path": "/api/v1/transfers"
      }
    ]
  }
}
```

`api_path` may be `null` if a web-only row has no mobile route. At most 12 rows.

### GET /api/v1/demo

Guided "Walk Rudo's morning" script as data. Progress is stored on the bearer token's preference row, or on the browser session if you called this with a cookie.

Response `200` (before start):

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "active": false,
    "done": false,
    "index": null,
    "total": 7,
    "current": null,
    "demo_pin": "2580",
    "yes_words": ["ehe", "ewe", "hongu", "yebo", "yes"],
    "pin_rule": "The demo PIN is checked only on the confirm endpoint. Do not send it to coach, scam, voice interpret, or onboarding.",
    "steps": [
      {
        "number": 1,
        "slug": "voice",
        "role": "customer",
        "kicker": "About 1 min",
        "title": "Rudo sends twenty dollars in Shona",
        "narration": "Rudo Moyo is packing tomatoes in Mbare. Her mother, Mai Tendai, needs groceries in Chitungwiza. Rudo speaks instead of typing.",
        "action": "Press the Shona send phrase. Shamwari resolves Mai Tendai and speaks a confirmation. Prepare the transfer so it sits as pending, then type hongu and the demo PIN 2580 to post it. The PIN stays in that form. It is not sent to the model.",
        "calls": [
          "GET /api/v1/voice/phrases",
          "POST /api/v1/voice/interpret",
          "POST /api/v1/voice/prepare",
          "POST /api/v1/transfers/{id}/confirm"
        ]
      }
    ]
  }
}
```

Slugs, in order, and the role that must call them:

| number | slug | role |
| --- | --- | --- |
| 1 | `voice` | customer |
| 2 | `access` | customer |
| 3 | `coach` | customer |
| 4 | `scam` | customer |
| 5 | `receipts` | customer |
| 6 | `pulse` | staff |
| 7 | `onboarding` | staff |

The last two steps are the care desk. Call them with the `care` token. Starting the demo as Rudo does not grant pulse or onboarding.

### POST /api/v1/demo/start

Sets progress to step 1. Response is the same object as `GET /api/v1/demo` with `"active": true` and `"current"` set to the voice step.

### POST /api/v1/demo/next

Advances one step. After the last step, `"done": true` and `"current": null`. `400` `validation` if the demo was not started.

### POST /api/v1/demo/back

Moves back one step and not before the first. Starts the demo if it was stopped.

### POST /api/v1/demo/stop

Clears progress. `"active": false`.

## Customer

### GET /api/v1/wallet

Rudo's two wallets, the school-fees goal, and the seven-day USD spend used on the home screen.

Response `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "customer": {
      "id": 1,
      "full_name": "Rudo Moyo",
      "short_name": "Rudo Moyo",
      "city": "Harare",
      "language": "en",
      "role": "Tuckshop owner",
      "phone_masked": "0771••••01"
    },
    "wallets": [
      {
        "currency": "USD",
        "balance_cents": 8600,
        "pending_cents": 0,
        "available_cents": 8600,
        "display_balance": "US$ 86.00",
        "display_available": "US$ 86.00"
      },
      {
        "currency": "ZIG",
        "balance_cents": 42000,
        "pending_cents": 0,
        "available_cents": 42000,
        "display_balance": "ZiG 420.00",
        "display_available": "ZiG 420.00"
      }
    ],
    "goal": {
      "name": "Term 2 school fees",
      "currency": "USD",
      "saved_cents": 4500,
      "target_cents": 15000,
      "display_saved": "US$ 45.00",
      "display_target": "US$ 150.00",
      "due_date": "2026-12-01",
      "expected_cents": 9065,
      "on_track": false,
      "remaining_days": 36,
      "weekly_cents": 2041
    },
    "week": {
      "total_cents": 3800,
      "display": "US$ 38.00",
      "delta_pct": null,
      "days": [
        {
          "label": "Wed",
          "date": "2026-10-21",
          "amount_cents": 1000,
          "display": "US$ 10.00",
          "peak": true
        }
      ]
    },
    "pending_count": 0
  }
}
```

`available_cents` is the posted balance minus pending outgoing holds. A pending transfer does not move `balance_cents` until confirm. `goal` is `null` when the profile has no goal. `delta_pct` is `null` when the previous week has no spend. `expected_cents` and `weekly_cents` move with today's date. The peak day in the seeded window is `US$ 10.00`.

### GET /api/v1/transactions

Query `limit` (default 20, max 50). Rows where this customer is sender or recipient, newest id first.

Response `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "transactions": [
      {
        "id": 31,
        "reference": "SM-100031",
        "kind": "merchant_pay",
        "category": "groceries",
        "status": "posted",
        "amount_cents": 8000,
        "currency": "ZIG",
        "display": "ZiG 80.00",
        "sender_id": 1,
        "recipient_id": null,
        "merchant_id": 2,
        "counterparty": "Mbare Fresh Produce",
        "note": "Synthetic",
        "outgoing": true,
        "created_at": "2026-10-20T09:00:00Z",
        "posted_at": "2026-10-20T09:00:00Z"
      }
    ]
  }
}
```

`status` is `pending`, `posted`, or `cancelled`. `outgoing` is true when `sender_id` is this profile. `kind` is `transfer`, `airtime`, `merchant_pay`, or `cash_in`.

### GET /api/v1/activity

The home-screen activity list (up to 8). Same transaction fields, plus `name` and `initials`.

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "activity": [
      {
        "id": 28,
        "name": "Airtime",
        "initials": "AI",
        "reference": "SM-100028",
        "kind": "airtime",
        "category": "airtime",
        "status": "posted",
        "amount_cents": 500,
        "currency": "USD",
        "display": "US$ 5.00",
        "outgoing": true,
        "counterparty": "Airtime",
        "created_at": "2026-10-24T07:00:00Z",
        "posted_at": "2026-10-24T07:00:00Z"
      }
    ]
  }
}
```

### GET /api/v1/contacts

People Rudo can send to.

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "contacts": [
      {"id": 1, "name": "Mai Tendai", "city": "Chitungwiza", "customer_id": 2},
      {"id": 2, "name": "Farai Ncube", "city": "Bulawayo", "customer_id": 3},
      {"id": 3, "name": "Nomsa Ndlovu", "city": "Bulawayo", "customer_id": 4},
      {"id": 4, "name": "Baba Joseph", "city": "Harare", "customer_id": 5}
    ]
  }
}
```

### POST /api/v1/transfers

Creates a **pending** transfer. Nothing is posted. The model is not called.

Request fields:

| field | required | notes |
| --- | --- | --- |
| `amount_cents` | yes | integer. `amount` as a decimal dollar number is also accepted |
| `currency` | no | `USD` (default) or `ZIG` |
| `kind` | no | `transfer` (default), `airtime`, or `merchant_pay`. Aliases: `send_money`, `buy_airtime`, `pay_merchant` |
| `recipient_name` | for transfer | matched against contacts. `Mai Tendai` resolves |
| `recipient_id` | for transfer | customer id, alternative to the name |
| `merchant_name` or `merchant_id` | for merchant_pay | |

Send twenty dollars to Mai Tendai:

```json
{
  "kind": "transfer",
  "amount_cents": 2000,
  "currency": "USD",
  "recipient_name": "Mai Tendai"
}
```

Response `201`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "outcome": "pending",
    "transaction": {
      "id": 40,
      "reference": "SM-100040",
      "kind": "transfer",
      "category": "family",
      "status": "pending",
      "amount_cents": 2000,
      "currency": "USD",
      "display": "US$ 20.00",
      "sender_id": 1,
      "recipient_id": 2,
      "merchant_id": null,
      "counterparty": "Mai Tendai",
      "note": "Created pending by the mobile API. Synthetic.",
      "outgoing": true,
      "created_at": "2026-10-26T06:46:18Z",
      "posted_at": null
    }
  }
}
```

`400` `validation` if the contact is unknown, the amount is above the demo cap, the currency is not USD or ZiG, or available balance does not cover the hold. Airtime cap is `10000` cents. Transfer cap is `1000000` cents. Merchant pay cap is `200000` cents.

### GET /api/v1/transfers/{txn_id}

One transfer this profile sent or received. `404` `not_found` otherwise.

Response `200`: `{"ok": true, "synthetic": true, "data": {"transaction": { }}}` with the transaction object above.

### POST /api/v1/transfers/{txn_id}/confirm

Posts a pending transfer. **This route never calls the AI provider.** The PIN is checked with the same hash the web confirm uses (`shamwari:{customer_id}:{pin}`) and then discarded.

Request:

```json
{"confirm_word": "hongu", "pin": "2580"}
```

Response `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "outcome": "posted",
    "pin_checked_locally": true,
    "pin_sent_to_model": false,
    "transaction": {
      "id": 40,
      "status": "posted",
      "amount_cents": 2000,
      "currency": "USD",
      "display": "US$ 20.00",
      "reference": "SM-100040"
    }
  }
}
```

The response does not contain the PIN. After this example, Rudo's USD balance is `6600` (`US$ 66.00`) and Mai Tendai's USD wallet increases by `2000`.

`outcome` `already` is also `200` if the row was already posted.

Failures keep the row pending and return the transaction under `error.details`:

```json
{
  "ok": false,
  "synthetic": true,
  "error": {
    "code": "bad_pin",
    "message": "That PIN does not match the synthetic demo PIN. Nothing was posted.",
    "details": {
      "outcome": "bad_pin",
      "pin_checked_locally": true,
      "pin_sent_to_model": false,
      "transaction": {"id": 40, "status": "pending"}
    }
  }
}
```

| outcome | HTTP | code |
| --- | --- | --- |
| posted, already | 200 | (success envelope) |
| need_yes | 400 | `need_yes` |
| bad_pin | 400 | `bad_pin` |
| insufficient | 400 | `insufficient` |
| not_pending | 409 | `not_pending` |
| forbidden | 403 | `forbidden` |
| missing row | 404 | `not_found` |

Yes words: `yes`, `hongu`, `yebo`, `ewe`, `ehe`.

### POST /api/v1/transfers/{txn_id}/cancel

Cancels a pending transfer this customer created. No money moves.

Response `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {"outcome": "cancelled", "transaction": {"id": 40, "status": "cancelled"}}
}
```

`404` if the id is unknown. `409` `not_pending` if it is not pending or it is not theirs.

### GET /api/v1/voice/phrases

Locked Shona, Ndebele, and English lines. A model cannot change these amounts.

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "demo_pin": "2580",
    "yes_words": ["ehe", "ewe", "hongu", "yebo", "yes"],
    "pin_rule": "Send the PIN only to a confirm endpoint, together with a yes word. Interpret, coach, and scam must not receive it.",
    "phrases": [
      {
        "language": "sn",
        "label": "Shona",
        "text": "tumira madhora makumi maviri kuna Mai Tendai",
        "hint": "Send twenty dollars to Mai Tendai"
      },
      {
        "language": "sn",
        "label": "Shona",
        "text": "ndiratidze mari yangu",
        "hint": "Show my balance"
      },
      {
        "language": "sn",
        "label": "Shona",
        "text": "tenga airtime yemadhora mashanu",
        "hint": "Buy five dollars of airtime"
      },
      {
        "language": "nd",
        "label": "Ndebele",
        "text": "thumela amadola angamatshumi amabili ku Mai Tendai",
        "hint": "Send twenty dollars to Mai Tendai"
      },
      {
        "language": "nd",
        "label": "Ndebele",
        "text": "ngibonise imali yami",
        "hint": "Show my balance"
      },
      {
        "language": "nd",
        "label": "Ndebele",
        "text": "thenga airtime yamadola amahlanu",
        "hint": "Buy five dollars of airtime"
      },
      {
        "language": "en",
        "label": "English",
        "text": "send twenty dollars to Mai Tendai",
        "hint": "Send twenty dollars to Mai Tendai"
      },
      {
        "language": "en",
        "label": "English",
        "text": "check my balance",
        "hint": "Show both wallets"
      },
      {
        "language": "en",
        "label": "English",
        "text": "buy airtime for five dollars",
        "hint": "Buy five dollars of airtime"
      }
    ]
  }
}
```

### POST /api/v1/voice/interpret

Accepts a transcript or an audio upload.

JSON transcript:

```json
{"text": "tumira madhora makumi maviri kuna Mai Tendai"}
```

Or `multipart/form-data` with a file field `audio` (`speech.webm`, `wav`, `m4a`, or `mp3`) and optional `language` of `sn`, `nd`, or `en`. If both `text` and `audio` are sent, `text` wins.

The Shona send line returns `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "transcript": "tumira madhora makumi maviri kuna Mai Tendai",
    "transcript_note": "",
    "balances": [],
    "plan": {
      "intent": "send_money",
      "amount_cents": 2000,
      "currency": "USD",
      "language": "sn",
      "recipient_id": 2,
      "recipient_name": "Mai Tendai",
      "merchant_id": null,
      "missing": [],
      "ambiguous": [],
      "unknown_name": "",
      "locked": true,
      "confidence": 0.99,
      "sentence": "Ndichatumira madhora makumi maviri kuna Mai Tendai. Hongu here?",
      "source": "phrase",
      "redacted": false,
      "provider_note": "",
      "transcript": "tumira madhora makumi maviri kuna Mai Tendai",
      "available_cents": 8600
    }
  }
}
```

`balances` is the same wallet array as `GET /api/v1/wallet`. `intent` `check_balance` has `amount_cents: null` and a Shona sentence such as `Ndiri kukuona mari yenyu.` Pass `plan` unchanged to prepare when `missing` is empty and the intent is a payment.

Mock speech cannot hear audio. An upload with no transcript returns `400`:

```json
{
  "ok": false,
  "synthetic": true,
  "error": {
    "code": "transcript_empty",
    "message": "Offline mock cannot hear audio. Use a demo phrase, or a browser with speech recognition."
  }
}
```

With a CAIMEX key, the same upload is sent to `language_labs/stt`. Shona and Ndebele speech on that model is not confirmed. PIN-like text is scrubbed before interpret. `400` `validation` if the text is empty or over 400 characters.

### POST /api/v1/voice/prepare

Turns a payment plan into a pending transfer. Same ledger as `POST /api/v1/transfers`. Does not call confirm and does not take a PIN.

```json
{"plan": {"intent": "send_money", "amount_cents": 2000, "currency": "USD", "recipient_id": 2, "recipient_name": "Mai Tendai", "merchant_id": null, "missing": []}}
```

The plan may also be the top-level JSON object. Response `201` matches transfer create, with `"message": "Prepared as pending. Nothing has been posted. Confirm with a yes word and the PIN."`

`400` `validation` if `intent` is not `send_money`, `buy_airtime`, or `pay_merchant`, if `missing` is non-empty, or if the ledger rejects the amount.

### POST /api/v1/voice/confirm

Same checker as `POST /api/v1/transfers/{txn_id}/confirm`. The id is in the body because the voice screen may not have put it in the path.

```json
{"txn_id": 40, "confirm_word": "yebo", "pin": "2580"}
```

Success and failure envelopes match the path confirm route, including `pin_sent_to_model: false`. The PIN is not forwarded to a model.

### GET /api/v1/coach

WhatsApp-style coach state: suggestions, warnings from the synthetic ledger, category totals in cents, the goal, and the thread.

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "suggestions": [
      "Can I still make my school fees goal?",
      "Where is my airtime money going?",
      "What should I worry about this week?",
      "What is my balance?"
    ],
    "warnings": [
      "Airtime is 33% of USD spending in this ledger. It is the largest outflow.",
      "Transport is 21% of spending. Together with airtime, small taps are the leak.",
      "The savings mark for “Term 2 school fees” is behind a straight-line pace. About US$ 91 would have been marked by today. US$ 45 is marked."
    ],
    "categories": [
      {
        "key": "airtime",
        "label": "Airtime",
        "amount_cents": 4800,
        "display": "US$ 48.00",
        "share": 0.3333
      }
    ],
    "goal": {"name": "Term 2 school fees", "saved_cents": 4500, "target_cents": 15000, "on_track": false},
    "messages": [
      {
        "id": 1,
        "role": "assistant",
        "content": "A short note already on Rudo's thread.",
        "created_at": "2026-10-01T09:00:00Z"
      }
    ]
  }
}
```

`share` is a fraction from 0 to 1. Warning percentages and category cents come from the seeded ledger and can differ slightly from the illustration above. `role` on a message is `user` or `assistant`, not the sign-in role.

### POST /api/v1/coach/messages

```json
{"text": "Can I still make my school fees goal?"}
```

The figures are computed in pandas. The model only phrases them. In mock mode the reply is the local narration, which states the goal is behind and quotes US$ amounts. PIN-like and phone-like tokens are replaced with `[redacted]` or `[phone]` before the text is saved or sent to the provider.

Response `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "reply": {
      "id": 3,
      "role": "assistant",
      "content": "Rudo, the “Term 2 school fees” mark is US$ 45 of US$ 150, due 2026-12-01. That is behind the straight-line pace. A steady catch-up is about US$ 20 a week. The mark is a note on this demo, not a separate wallet, and nothing moves until you add to it.",
      "created_at": "2026-10-26T06:50:00Z"
    },
    "note": "",
    "messages": []
  }
}
```

`messages` is the full thread after the new pair. `note` explains a provider fallback or that a secret was scrubbed. `400` `validation` if the text is empty or over 2000 characters.

Do not send the PIN here. `my pin is 2580` is stored as `my pin [redacted]`.

### GET /api/v1/scam/samples

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "samples": [
      {"id": "reversal", "title": "Fake reversal", "text": "EcoCash: reversal of USD 20.00 to Mai Tendai failed. I am an agent. Send your PIN within 15 minutes or the wallet will be blocked."},
      {"id": "prize", "title": "Prize bait", "text": "CONGRATULATIONS you have won USD 500 airtime..."},
      {"id": "agent", "title": "Fake agent", "text": "Good morning, this is Agent Tafadzwa from EcoCash Copacabana..."},
      {"id": "family", "title": "Ordinary family note", "text": "Mai Tendai: ndasvika kuChitungwiza. Please send twenty dollars when you can. Love, Amai."},
      {"id": "pressure", "title": "Pressure, no PIN yet", "text": "Your EcoCash wallet will be suspended within 10 minutes. Call this agent now to avoid a block."}
    ]
  }
}
```

The prize, agent, and pressure strings above are shortened in this example. The live payload is the full sample text.

### POST /api/v1/scam/check

Pass `sample` or `text`. Sample ids win over free text.

```json
{"sample": "reversal"}
```

```json
{"text": "Mai Tendai: ndasvika kuChitungwiza. Please send twenty dollars when you can. Love, Amai."}
```

Response `200` for the ordinary family note:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "report": {
      "verdict": "looks_safe",
      "label": "Looks safe",
      "rules_verdict": "looks_safe",
      "rules_label": "Looks safe",
      "ai_verdict": "looks_safe",
      "ai_confidence": 0.86,
      "source": "rules",
      "patterns": [],
      "steps": [
        "No known scam pattern matched this wording.",
        "This is a pattern check on a short local list, not a guarantee.",
        "If the conversation later asks for a PIN, stop. That part is never safe."
      ],
      "note": "",
      "error_detail": ""
    }
  }
}
```

The reversal sample's `rules_verdict` is `likely_scam`. The final `verdict` is never softer than the rules. If CAIMEX refuses the text, the pattern list still answers and `note` says the filter stood down. Verdicts are `looks_safe`, `suspicious`, and `likely_scam`.

`404` `not_found` for an unknown sample id. `400` `validation` if both sample and text are empty, or the text is over 2000 characters.

### GET /api/v1/receipts

Till slips saved against Rudo's Tuckshop.

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "merchant": {"id": 1, "name": "Rudo's Tuckshop", "city": "Harare"},
    "entries": []
  }
}
```

An entry:

```json
{
  "id": 1,
  "merchant_id": 1,
  "merchant": "Rudo's Tuckshop",
  "vendor": "Mbare Fresh Produce",
  "receipt_date": "2026-10-20",
  "total_cents": 550,
  "currency": "USD",
  "display": "US$ 5.50",
  "items": [
    {"description": "Tomatoes 2kg", "amount_cents": 400},
    {"description": "Onions 1kg", "amount_cents": 150}
  ],
  "notes": "",
  "source_name": "mobile api",
  "created_at": "2026-10-26T06:50:00Z"
}
```

### GET /api/v1/receipts/samples

Sample slips and the two QR payloads. No image bytes.

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "samples": [
      {
        "filename": "mbare-fresh.png",
        "vendor": "Mbare Fresh Produce",
        "date": "2026-10-20",
        "currency": "USD",
        "note": "Synthetic till slip for the tuckshop ledger."
      },
      {
        "filename": "green-basket.png",
        "vendor": "Green Basket Grocer",
        "date": "2026-10-18",
        "currency": "USD",
        "note": "Synthetic till slip. Not a real grocer."
      },
      {
        "filename": "qr-till.png",
        "title": "Till slip QR",
        "payload": "SYNTHETIC TILL SLIP\nVendor: Mbare Fresh Produce\nDate: 20 Oct 2026\nTomatoes 2kg USD 4.00\nOnions 1kg USD 1.50\nTotal USD 5.50"
      },
      {
        "filename": "qr-pay.png",
        "title": "Merchant pay QR",
        "payload": "SHAMWARI-PAY\nmerchant=Mbare Fresh Produce\namount=5.50\ncurrency=USD"
      }
    ]
  }
}
```

The pay QR only identifies a merchant and an amount. It does not send money. Prepare a review with voice or transfers, then confirm.

### GET /api/v1/receipts/samples/{sample_name}

`sample_name` is a filename from the list above, including the `.png`.

Response `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "filename": "mbare-fresh.png",
    "media_type": "image/png",
    "base64": "<standard base64 of the PNG bytes>"
  }
}
```

The live `base64` value is the whole file (PNG magic decodes to bytes starting `89 50 4E 47`). It is thousands of characters. `404` `not_found` for any other name.

### POST /api/v1/receipts/read

JSON sample name, or a multipart image.

```json
{"sample": "mbare-fresh.png"}
```

Multipart: file field `image`, PNG or JPEG, under 5 MB.

Response `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "extraction": {
      "vendor": "Mbare Fresh Produce",
      "date": "2026-10-20",
      "currency": "USD",
      "total_cents": 550,
      "display": "US$ 5.50",
      "items": [
        {"description": "Tomatoes 2kg", "amount_cents": 400},
        {"description": "Onions 1kg", "amount_cents": 150}
      ],
      "note": "Synthetic till slip for the tuckshop ledger.",
      "source": "sample"
    }
  }
}
```

`source` is `sample` when the bytes match a generated slip, `caimex` when a key is set and the vision chat read the image, or `manual` when the form should be filled in by hand. Unknown photos in mock mode come back with empty fields. `404` for an unknown sample name. `400` `validation` if no sample and no image, or the upload is not an image.

### POST /api/v1/receipts

Saves a reviewed slip onto Rudo's Tuckshop. Edit the extraction first if a line is wrong.

```json
{
  "vendor": "Mbare Fresh Produce",
  "receipt_date": "2026-10-20",
  "currency": "USD",
  "total_cents": 550,
  "notes": "",
  "items": [
    {"description": "Tomatoes 2kg", "amount_cents": 400},
    {"description": "Onions 1kg", "amount_cents": 150}
  ]
}
```

`amount` as a decimal is accepted on each item as well as `amount_cents`. `total_cents` may be sent as `amount_cents`. Response `201` is `{"entry": { ... }}` using the entry shape from `GET /api/v1/receipts`. `400` `validation` without a vendor or a positive total.

### GET /api/v1/receipts/export

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "filename": "rudo-tuckshop-ledger.csv",
    "media_type": "text/csv",
    "csv": "vendor,receipt_date,currency,total,items,notes\nMbare Fresh Produce,2026-10-20,USD,5.50,..."
  }
}
```

The CSV header and columns are whatever `ledger_csv` writes for the tuckshop. Save `csv` as a file named `filename`.

### GET /api/v1/accessibility

Large type, high contrast, and whether the balance script should be spoken. Defaults are `large_type: false`, `high_contrast: false`, `speak_balances: true`. Settings are stored per user, not in the browser `localStorage` the web app uses. The web accessibility class is still local to the browser.

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "settings": {
      "large_type": false,
      "high_contrast": false,
      "speak_balances": true
    },
    "spoken": "You are acting as Rudo Moyo in Harare. Available US dollars: 86.00. Posted balance 86.00. Pending hold 0.00.",
    "balances": [],
    "qr_samples": [
      {
        "filename": "qr-till.png",
        "title": "Till slip QR",
        "payload": "SYNTHETIC TILL SLIP\nVendor: Mbare Fresh Produce\nDate: 20 Oct 2026\nTomatoes 2kg USD 4.00\nOnions 1kg USD 1.50\nTotal USD 5.50"
      }
    ]
  }
}
```

`balances` matches the wallet array. `spoken` is empty when `speak_balances` is false. Speak `qr_samples[].payload` for the till slip. The pay QR payload is a review only.

### PUT /api/v1/accessibility

Send any subset of the three booleans, either at the top level or under `settings`.

```json
{"large_type": true, "high_contrast": true, "speak_balances": true}
```

Response `200`: `{"ok": true, "synthetic": true, "data": {"settings": {"large_type": true, "high_contrast": true, "speak_balances": true}}}`.

`400` `validation` if a provided value is not `true` or `false`.

## Care team

### GET /api/v1/pulse

Live customer pulse as chart series, not Plotly HTML. There is no `plotly` string in the body.

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "points": [
      "The loudest theme is Reversal scam."
    ],
    "complaints": [
      {
        "theme": "reversal_scam",
        "label": "Reversal scam",
        "region": "Harare",
        "count": 8,
        "sample": "Harare: a reversal SMS asked a customer for a PIN. This looks like a scam."
      }
    ],
    "series": {
      "daily": [{"date": "2026-10-26", "total": 4, "negative": 3}],
      "themes": [{"label": "Reversal scam", "count": 8}],
      "regions": [
        {"region": "Harare", "negative": 6, "neutral": 1, "positive": 0}
      ]
    },
    "feed": [
      {
        "id": 58,
        "source": "ticket",
        "text": "Harare: a reversal SMS asked a customer for a PIN. This looks like a scam.",
        "theme": "reversal_scam",
        "theme_label": "Reversal scam",
        "sentiment": "negative",
        "region": "Harare",
        "created_at": "2026-10-26T06:00:00Z"
      }
    ]
  }
}
```

`series.daily[].total` is published messages that day. `negative` is how many of them are negative. `themes[].count` is the theme total. `regions` has one object per place that appears, with a count for each sentiment. Counts follow the seeded pulse and change after publish. `points` are the executive sentences. `feed` is the newest published items, up to 12. `source` is `ticket`, `review`, or `post`.

### POST /api/v1/pulse/publish

Publishes the next synthetic item, the same action as the web feed poll. Response `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "item": {
      "id": 59,
      "source": "ticket",
      "text": "Harare customers are quoting a reversal SMS and a PIN request at Copacabana.",
      "theme": "reversal_scam",
      "theme_label": "Reversal scam",
      "sentiment": "negative",
      "region": "Harare",
      "created_at": "2026-10-26T06:55:00Z"
    },
    "series": {"daily": [], "themes": [], "regions": []}
  }
}
```

`series` is the chart payload after the insert. The item text rotates through the built-in live script once unpublished rows are gone.

### POST /api/v1/pulse/highlight

No body. Rewrites `points` as a short care-lead note. Mock mode returns the points joined. A provider error falls back to the same points and sets `note`.

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "points": ["The loudest theme is Reversal scam."],
    "prose": "The loudest theme is Reversal scam.",
    "note": ""
  }
}
```

### GET /api/v1/onboarding/documents

Fictional SOP markdown. Quiz answer keys are not included. `"fiction": true` means this is not EcoCash policy.

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "fiction": true,
    "documents": [
      {
        "doc_id": "pin-handling",
        "title": "PIN handling",
        "body": "# PIN handling\n\nAn agent never asks a customer for a PIN..."
      }
    ]
  }
}
```

`body` is the full markdown of each file in `data/sops/`, with the quiz blocks removed.

### POST /api/v1/onboarding/ask

```json
{"question": "What do I do if a customer is asked for their PIN?"}
```

Response `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "question": "What do I do if a customer is asked for their PIN?",
    "answer": "Here is what the fictional SOPs say. This is hackathon material, not EcoCash policy.\n\nPIN handling — Never ask for a PIN: An agent never asks a customer for a PIN, OTP or password.",
    "hits": [
      {
        "doc_id": "pin-handling",
        "doc_title": "PIN handling",
        "heading": "Never ask for a PIN",
        "snippet": "An agent never asks a customer for a PIN, OTP or password."
      }
    ],
    "note": ""
  }
}
```

The answer cites the SOP headings retrieval found. In mock mode the answer is extractive. With a key, chat phrases the same hits and still falls back to the extract if the provider errors. `note` carries that fallback. `400` `validation` if the question is empty or over 500 characters. Digits that look like a PIN are scrubbed before the search.

### POST /api/v1/onboarding/quiz

No body. Returns three questions and stores the answer key on the server for this user. The key is not in the response.

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "note": "",
    "questions": [
      {
        "question": "A customer asks you to scan a payment QR and \"just send it\". What has to happen before money moves?",
        "doc_id": "accessibility-at-the-booth",
        "doc_title": "Accessibility At The Booth",
        "choices": [
          {"key": "A", "text": "Scanning the QR posts the payment immediately"},
          {"key": "B", "text": "You enter your staff PIN to approve the scan"},
          {"key": "C", "text": "The customer reviews the vendor and total, then confirms with a yes and their own PIN"},
          {"key": "D", "text": "You read the QR aloud and the payment posts when you finish speaking"}
        ]
      }
    ]
  }
}
```

Mock mode uses the questions written into the fictional SOPs. There is no `answer` field on a question.

### POST /api/v1/onboarding/quiz/score

Call quiz first. `answers` maps the zero-based question index to `A`, `B`, `C`, or `D`.

```json
{"answers": {"0": "C", "1": "A", "2": "B"}}
```

Response `200`:

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "score": {
      "correct": 1,
      "total": 3,
      "review": [
        {
          "question": "A customer asks you to scan a payment QR and \"just send it\". What has to happen before money moves?",
          "picked": "C",
          "answer": "C",
          "ok": true,
          "doc_title": "Accessibility At The Booth",
          "doc_id": "accessibility-at-the-booth"
        }
      ]
    }
  }
}
```

The correct letter is revealed only here. `400` `validation` if no quiz has been started on this account.

### GET /api/v1/ledger

The care book: customers with masked phones and wallet cents, merchants, agents, the latest 50 transactions, and saved tuckshop slips. No PIN hashes and no passwords.

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "customers": [
      {
        "id": 1,
        "full_name": "Rudo Moyo",
        "short_name": "Rudo Moyo",
        "city": "Harare",
        "language": "en",
        "role": "Tuckshop owner",
        "phone_masked": "0771••••01",
        "wallets": [
          {
            "currency": "USD",
            "balance_cents": 8600,
            "pending_cents": 0,
            "available_cents": 8600,
            "display_balance": "US$ 86.00",
            "display_available": "US$ 86.00"
          }
        ]
      }
    ],
    "merchants": [
      {"id": 1, "name": "Rudo's Tuckshop", "category": "Tuckshop", "city": "Harare"}
    ],
    "agents": [
      {"id": 1, "name": "Mercy Zhou", "city": "Harare", "booth": "Copacabana booth"}
    ],
    "transactions": [],
    "receipts": []
  }
}
```

Transaction objects match `GET /api/v1/transactions` except `outgoing` is `null` because the viewer is not a customer. Receipt objects match the tuckshop entry shape.

### GET /api/v1/ai-log

Metadata of recent model calls. The prompt text is never stored.

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "calls": [
      {
        "id": 4,
        "created_at": "2026-10-26T06:50:00Z",
        "module": "coach",
        "operation": "reply",
        "provider": "mock",
        "model": "mock",
        "status": "ok",
        "prompt_chars": 420,
        "latency_ms": 1,
        "error": ""
      }
    ]
  }
}
```

Up to 30 rows, newest first. `provider` is `mock` or `caimex`.

## What the app should not send to the model

Confirm is local. Interpret, coach, scam, receipts, pulse highlight, and onboarding do call the provider (or the mock stand-in). Scrubbing removes PIN, OTP, and password patterns plus Zimbabwe mobiles before those calls. Still keep the PIN field off those requests. The only bodies that should contain `pin` are the two confirm routes.

## Demo Day additions

Pending transfers now include `transaction.risk`:

```json
"risk": {
  "score": 10,
  "level": "low",
  "reasons": [],
  "requires_ack": false,
  "acknowledged": false,
  "channel": "api"
}
```

`level` is `low`, `medium`, `high`, or `none` when the row was never scored. `reasons` is a list of `{code, text}`. Codes: `new_recipient`, `unusual_amount`, `odd_hour`, `rapid`, `flagged`, `scammy`. High risk (`requires_ack` true) stays pending until confirm is called with `risk_ack` true. The PIN is still checked only after that, and it is still not sent to a model.

`POST /api/v1/voice/interpret` accepts `sample_id` (`tumira-5-tendai` or `thumela-5-tendai`) or multipart field `audio`. A matching demo clip is transcribed offline. Any other audio in mock mode returns `transcript_empty`.

`GET /healthz` is outside `/api/v1`. It is public and returns `{"ok": true, "synthetic": true}` for a container health check.

### GET /api/v1/impact

Care staff. Demo figures. `simulated` is always true. Each metric has `total`, `baseline`, `live`, and `basis` (`simulated` or `simulated+live`).

```json
{
  "ok": true,
  "synthetic": true,
  "data": {
    "simulated": true,
    "disclaimer": "Demo figures. The baseline is simulated from the synthetic pulse book.",
    "time_saved_minutes": {"total": 180, "baseline": 180, "live": 0, "basis": "simulated"},
    "tickets_deflected": {"total": 60, "baseline": 60, "live": 0, "basis": "simulated"},
    "scams_blocked": {"total": 4, "baseline": 4, "live": 0, "basis": "simulated"},
    "transfers_via_ai": {"total": 0, "baseline": 0, "live": 0, "basis": "simulated"}
  }
}
```

### POST /api/v1/demo/risk-transfer

Customer. Creates one pending transfer to Prize Desk that scores high. Balances are not moved. Confirm it with `risk_ack` true, a yes word, and the PIN, or cancel it.

Response `201` uses the same `transaction` shape as `POST /api/v1/transfers`, including `risk`.

### POST /api/v1/channels/ussd

Customer. Webhook-style body a USSD aggregator can send later. `msisdn`, when present, must be the signed-in customer's line.

```json
{"session_id": "", "text": "1", "service_code": "*151#", "msisdn": "0771000001"}
```

Response `data`: `session_id`, `message`, `continue_session`, `replies` (list of `{type, body}`), `service_code`, `channel`. Send the returned `session_id` on the next turn. Menu: 1 balance, 2 send money, 3 airtime, 4 ask Shamwari, 0 exit. Payments still need a yes word and the PIN. The PIN is not echoed.

### POST /api/v1/channels/chat

Customer. Same engine, chat wording. Not WhatsApp.

```json
{"session_id": "", "text": "tumira $5 kuna Tendai", "from": "0771000001"}
```

`data.replies` is what a WhatsApp Business handler could forward. The public name of this channel is "Chat channel (WhatsApp-style mock)".

### GET /api/v1/pulse/{item_id}/copilot

Care staff. Returns `case`, `suggestion` (`summary`, `context`, `drafts`, `next_action`, `provider`, `offline`), and `audit_id`. The first open logs action `suggested`. The draft is not sent to the customer.

### POST /api/v1/pulse/{item_id}/copilot

Care staff. Writes another `suggested` audit row and returns the same shape.

### POST /api/v1/pulse/{item_id}/decision

Care staff. Body: `action` is `approve`, `edit`, or `discard`. `edit` requires `text`. Approve and edit record the reply. Discard sends nothing. A person has to call this. The model does not.

```json
{"action": "approve", "text": "Please do not share your PIN."}
```

### GET /api/v1/audit

Care staff. Newest first, up to 80 rows: `id`, `created_at`, `actor_name`, `actor_role`, `module`, `action`, `subject_type`, `subject_id`, `decision`, `detail`. No PIN and no prompt text.

