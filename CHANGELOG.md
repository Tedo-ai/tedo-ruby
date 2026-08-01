# Changelog

## 0.2.0

- Align the shared API base URL and every Billing route with the registered `/billing/v1/*` surface.
- Add the contract-tested billable-usage ledger, cursor read-back, customer-period composer, and manual-period closure used by Bidvise shadow reconciliation.
- Require caller-owned idempotency keys for financial writes and preserve them across bounded transient retries.
- Add typed conflict, transport, rate-limit, and server errors so callers can separate permanent failures from retryable ones.
- Pin the ledger methods, paths, required fields, headers, and response fields to Tedo Billing's generated OpenAPI contract.

## 0.1.1

- Add Tables API coverage for bases, tables, columns, rows, bulk upsert, snapshots, share tokens, and CSV import.
- Add a runnable Tables example.
