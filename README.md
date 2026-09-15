# PicqerAPI

Rails-independent Ruby client for the [Picqer](https://picqer.com) warehouse-management API.

Picqer accepts far more than it stores: unknown fields are dropped, unsupported filters are
ignored, long strings are truncated and emoji are removed — all silently, all behind a `200` or
`201`. This gem does not hide that. It makes the sharp edges explicit and leaves the correctness
decisions with the caller.

## Installation

```ruby
gem "picqer_api", "~> 0.1.0"
```

## Usage

### Client

```ruby
require "picqer_api"

client = PicqerAPI::Client.new(
  subdomain: "acme",          # the account's subdomain; for a fulfilment provider this is
  api_key: ENV["PICQER_KEY"],   # the provider's, shared across its customers
  user_agent: "PostCo (engineering@postco.co)"
)
```

The API key is sent as the HTTP Basic username with an empty password. A `User-Agent` is
required by Picqer; the default identifies this gem.

**The subdomain is not a unique key.** Under Picqer Fulfilment, one provider's subdomain serves
many retailers, each with its own customer-scoped key. Identify an integration by its
credentials, not by its subdomain.

### Returns

```ruby
created = client.returns.create({
  idreturn_status: 17267,       # the only field Picqer actually requires
  reference: "RMA-12345",
  tracking_code: "3SABCD1234567",
  returned_products: [
    {idproduct: 51654384, idreturn_reason: 13593, price: 24.95, amount: 1}
  ]
})

stored = client.returns.find(created.idreturn)
```

**Read back before trusting anything.** The create response echoes your input rather than what
was stored, and a `201` only means a row was written. Compare `stored` against what you sent.

**A `400` can still leave a return behind.** Picqer writes the header, then validates the lines,
and does not roll back — so validate `idreturn_reason` and `idproduct` locally before calling,
and never blind-retry a failed create.

#### Filters

```ruby
client.returns.list(status: "completed")          # one page of 100
client.returns.all(updated_after: "2026-09-14")   # every page, walked by offset
client.returns.search("RMA-12345")                # fuzzy substring match
```

`all` raises `PaginationError` rather than returning a truncated list if the result runs past
10,000 rows. A list that looks complete and is not is the failure this gem exists to prevent,
so the ceiling is loud: narrow the query with a supported filter, or page by hand with
`offset`.

Only `search`, `status`, `emailaddress`, `idcustomer`, `created_after`, `updated_after` and
`offset` are honoured. Every other filter is accepted, ignored, and answered with the **entire
list** and a `200`, so anything outside that set raises `ArgumentError` here rather than
returning a list that looks filtered.

`search` is the only free-text lookup and it is fuzzy with no uniqueness guarantee. It cannot
answer "the return whose reference is X":

```ruby
matches = client.returns.search("RMA-12345").select { |row| row.reference == "RMA-12345" }

case matches.length
when 0 then create_it
when 1 then matches.first
else flag_for_manual_review(matches)
end
```

That verify step is deliberately yours. There is no convenience wrapper for it, because every
caller has to decide what several matches mean.

#### Status changes and lines

```ruby
client.returns.add_log(idreturn, idreturn_status: 17272, message: "Refunded in PostCo")
client.returns.logs(idreturn)
client.returns.delete_returned_product(idreturn, idreturn_product)
```

### Vocabularies

```ruby
client.return_statuses.all        # return-level: dynamic, account-owned, editable
client.return_statuses.completed  # the only dependable semantic marker
client.return_reasons.all         # required on every line; free text is rejected
client.warehouses.all             # payload field, not credential scope
```

Return-level statuses and reasons are defined by whoever owns the Picqer account — under a
fulfilment arrangement, the provider rather than the retailer — and can be renamed or removed at
any time. Pull them at connect time and re-pull on refresh. Do not key behaviour on `default:
true`: accounts have been observed with it set on nothing at all.

Line-level status is a fixed enum and cannot drift: `expected`, `received`, `added_to_stock`,
`unsalable`. It is the disposition signal, and it moves independently of return-level status — a
return can sit at "Completed" with every line still `expected`.

### Lookups

```ruby
client.products.by_productcode("LC808899")   # exact SKU match
client.orders.by_reference("skikoffer #360476")
```

Both return every match. A SKU maps 1:1 to a variant only when Picqer's own webshop connector
imported the catalogue, and which order field carries the webshop order name is a connector
convention rather than a guarantee. Handle zero and several matches explicitly; a bad `idorder`
is fatal to a return create, while a null one is normal.

### Field limits

```ruby
PicqerAPI::Text.sanitize("Anna 😀 Smith")   # => "Anna Smith"
PicqerAPI::Text.truncated?("a" * 300)       # => true
```

Every string field on a return is a utf8mb3 `varchar(255)`. Picqer truncates at 255 characters
and strips four-byte characters silently — an emoji in a customer name disappears and leaves
mangled spacing. `returns.create` and `returns.update` sanitize the known header fields by
default so the loss happens where you can see it; pass `sanitize: false` to send the raw values.
`logs.message` is a `text` column (65,535).

### Webhooks

```ruby
unless PicqerAPI::Webhook.valid_signature?(payload: raw_body, signature: request.headers["X-Picqer-Signature"], secret: stored_secret)
  return head :unauthorized
end

event = PicqerAPI::Webhook.parse(raw_body)
event.idreturn
event.updated_at           # identical across both events of one change
event.log_type             # "status_changed" or "received_products"
event.received_products?
event.iduser               # the actor, on returns.status_changed only
```

Verify before parsing. Three things to build around:

- **One status change emits two events** (`returns.status_changed` and `returns.changed`), and
  Picqer also fires them for writes you made yourself — so an unguarded handler both
  double-processes and loops. `(idreturn, updated_at)` works as an idempotency key.
- **The payload shape differs by event.** `returns.created` and `returns.changed` carry the
  return flat in `data`; `returns.status_changed` nests it as `data.return` plus
  `data.return_log`. `parse` normalises both.
- **`returns.status_changed` means two different things.** It fires for a real status change and
  for a receive, told apart by `log_type`, not by the event name. A receive does not move the
  return-level status at all.

`hooks.deactivate` maps to `DELETE /hooks/{id}`, which deactivates rather than deletes — the row
persists and is revivable with `reactivate`. Reuse an inactive hook instead of accumulating
duplicates on reconnect.

### Errors

All errors inherit from `PicqerAPI::Error` and carry `status_code`, `error_code`, `response`,
`retry_after` and `rate_limit`.

| Class                 | Raised on                                                   |
| --------------------- | ----------------------------------------------------------- |
| `ValidationError`     | 400 / 422                                                   |
| `AuthenticationError` | 401, 403                                                    |
| `NotFoundError`       | 404                                                         |
| `NotAccessibleError`  | any status with `error_code 31`                             |
| `RateLimitError`      | 429                                                         |
| `PaginationError`     | a list ran past the page ceiling, so it would be truncated  |
| `ServerError`         | 5xx                                                         |
| `APIError`            | anything else, including timeouts and dropped connections   |

**Branch on `error_code`, never on the message** — Picqer's messages are in Dutch and are
display text.

`NotAccessibleError` is the capability gap: the endpoint exists but a customer-scoped key may
not call it. `POST /returns/{id}/receive` is the one this integration meets — receiving belongs
to the warehouse, so `client.returns.receive` raises it on a scoped key and works on a key that
owns the warehouse.

### Rate limiting

500 requests per minute per API key. The headers from the most recent response are on the
client:

```ruby
client.rate_limit.remaining   # => 498
client.rate_limit.exhausted?  # => false
```

A 429 is retried once by default, honouring `Retry-After`. Pass `max_retries: 0` to handle it
yourself, or inject `sleeper:` to control how the wait happens.

## Development

```bash
bundle install
bundle exec rake        # minitest + standard
bundle exec rake test   # tests only
```

One file, or one test: `bundle exec ruby -Itest -Ilib test/picqer_api/text_test.rb -n /truncat/`.

### Probing a live account

The suite never touches the network. To exercise the gem against a real account:

```bash
export PICQER_SUBDOMAIN=your-subdomain
export PICQER_API_KEY=$(cat ~/.config/picqer/key)

bin/smoke            # read-only: reachability, vocabularies, scope, rate limit
bin/smoke --write    # also creates a probe return, reads it back and deletes it
bin/console          # IRB with a live `client` already built
```

`bin/smoke` is the quickest way to tell a scoped key from an unscoped one: a scoped key
reports an `idfulfilment_customer` on its returns and raises `NotAccessibleError` on
`receive`.

The write probe deletes what it creates. A return stops being deletable only once a line has
been added to stock, which requires `receive` and which the probe never calls.

There is no Picqer sandbox. Picqer issue free, non-expiring developer accounts on their own
subdomain; ask explicitly for the fulfilment version if you need to exercise customer-scoped
keys. See [RELEASING.md](RELEASING.md) to cut a release.
