# QA-012 - Customer List Pagination Contract

**Story:** As a client consuming the customer endpoint, I should get a predictable page size.

## Expected
`GET /api/customers?page=1&limit=3` responds with exactly **3** customer records and `meta.limit` equal to 3.

`GET /api/customers?page=2&limit=3` responds with customer IDs 4, 5, 6.

`GET /api/customers?page=1&limit=10` responds with 10 records.

## Current known defect (intentional demo seed)
The current implementation uses a fixed effective page size of 10 regardless of the `limit` query argument. `meta.limit` still reports the requested limit. This makes the response inconsistent.

## QA acceptance criteria for the eventual fix
1. Limit is respected for first and subsequent pages.
2. Meta limit reflects the effective page size.
3. Validation and defaults are predictable for negative, zero, and excessively large values.
4. Regression tests cover 1, 3, 10, and 100.
5. Existing health and reference endpoints remain functional.

## Reproduction
```bash
curl -s 'http://127.0.0.1:3000/api/customers?page=1&limit=3'
```

Do not fix the bug before the sharing session; it is used in the demo.
