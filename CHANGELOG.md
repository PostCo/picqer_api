# Changelog

## [Unreleased]

## [0.1.0] - 2026-09-14

- Initial release.
- `PicqerAPI::Client` with subdomain + API key Basic auth, a required User-Agent, rate-limit
  header capture and opt-in retry on 429.
- Resources: returns (create, find, list, search, update, delete, logs, line delete, receive),
  return statuses, return reasons, warehouses, products, orders and hooks.
- `PicqerAPI::Text` for the utf8mb3 varchar(255) columns Picqer truncates silently.
- `PicqerAPI::Webhook` for signature verification and for normalising the two payload shapes.
- `PicqerAPI::NotAccessibleError` for `error_code 31`, the fulfilment-scope capability gap.
