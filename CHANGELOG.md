# Changelog

All notable changes to `buildkiterb` are documented in this file.

## [2.0.0]

### Upgrading from 1.x

- Ruby 3.3 or newer is required, and Faraday must be 2.14.3 or newer (a security fix).
- Response objects no longer use `OpenStruct`. `Buildkite::Object` stores attributes in a hash and reads them through
  dot notation or hash access (`object[:id]`). Nested objects are now `Buildkite::Object`s rather than `OpenStruct`s,
  so code that checks for `OpenStruct` or calls `OpenStruct`-only methods needs updating. Missing attributes still
  return `nil`.
- Errors are now subclasses of `Buildkite::Error` (for example `Buildkite::NotFoundError`), so existing
  `rescue Buildkite::Error` code keeps working. Error messages are unchanged apart from 503, which was reported as
  a rate limit but is now a `ServerError`.
- Other 5xx responses (502, 504, ...) and unknown 4xx responses used to be returned as if they had succeeded. They now
  raise.
- `Buildkite::Build.list` and `Buildkite::Artifact.list` take extra keyword arguments as query params, so a typo in a
  keyword is now sent to the API instead of raising `ArgumentError`.

### Added

- Pagination. Collections are `Enumerable` and have `next_page?`, `next_page`, `each_page` and `auto_paginate`.
  Previously only the first page of results could be read.
- Every `list` method accepts filter params, such as `page`, `per_page`, `branch` and `state`.
- Rate limited requests (429) are retried after the time Buildkite asks for. Configure with `max_retries` and
  `max_retry_wait`.
- Error classes carry the `status`, `body` and `response`. Timeouts and connection failures raise
  `Buildkite::ConnectionError`.
- `timeout`, `open_timeout` and `adapter` settings. Requests previously had no timeout.
- `key?`, `to_h`, `to_json` and equality on response objects.

### Fixed

- A token set or changed after the first request is now used. It was captured when the first request was made.
- `delete` requests passed their headers as query params.
- The error message for a non-JSON error body (such as an HTML 502 page) no longer risks raising `NoMethodError`.
- The README example for retrieving an organization used `get` instead of `retrieve`.

### Changed

- The packaged gem now only contains `lib/`, the README, LICENSE and CHANGELOG.
- CI runs Ruby 3.3, 3.4 and 4.0.
