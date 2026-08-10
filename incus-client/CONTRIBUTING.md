# Contributing to incus-client

Thank you for your interest in contributing! The most common contribution is adding
support for a new Incus API endpoint. This document explains how to do that and how
the project is structured.

---

## Repository structure

```
.
├── Cargo.toml                  # Workspace root
├── extract_openapi.py          # Helper script (see below)
├── incus-client/               # The published crate
│   ├── Cargo.toml
│   ├── README.md
│   ├── README_API.md           # Auto-generated API reference
│   ├── src/
│   │   ├── lib.rs              # Modified to include unix_socket.rs
│   │   ├── unix_socket.rs      # Handwritten
│   │   └── ...                 # Generated
│   └── .openapi-ignore
└── incus-client-tests/         # Integration tests (not published on crates.io)
```

Files listed in `incus-client/.openapi-generator-ignore` are handwritten and must not be
modified by the generator. Everything else inside `incus-client/` is generated.

---

## Finding the right endpoint

Not sure which API endpoint corresponds to the CLI command you want to replicate?
Run any `incus` command with the `--debug` flag — it prints every API call it makes,
including the full URL and request body:

```bash
incus list --debug
incus launch images:ubuntu/22.04 my-instance --debug
```

This makes it straightforward to map a CLI command to the endpoint you need to add.

---

## Adding a new endpoint

### 1. Prerequisites

You only need Docker installed in order to update the definitions file and generate
new library code using the `build.sh` script.

The script itself will pull images for running Python and the OpenAPI generator as
necessary.

#### 2. List available endpoints

`./build.sh list <TAG>` will list all available endpoints for the `<TAG>` version of Incus.

**Example**  List all available endpoints in `v7.3.0`:

`./build.sh list v7.3.0`

#### 3. Include additional endpoints

`my-subset.yaml` only includes a subset of the complete Incus API for which code should be generated.

`./build.sh include <TAG> [ENDPOINTS...]` will expand `my-subset.yaml` to include any endpoints matching the provided `ENDPOINTS`.

**Example** Include the `networks` and `network-zones` endpoints:

`./build.sh include v7.3.0 '/1.0/networks*' '/1.0/network-zones*'`

### 4. Generate the library files using `my-subset.yaml`.

Update generated code based on `my-subset.yaml`
`./build.sh build`

### 5. Verify

```bash
cargo test

cd incus-client
cargo build
cargo clippy
```

Fix any compilation errors. The generator occasionally emits code that needs minor
manual adjustments.

### 6. Add a test

Add an integration test in `incus-client-tests/` that covers the new endpoint.
Tests require a running Incus daemon and are not run in CI by default:

```bash
cd incus-client-tests
cargo test -- --nocapture
```

### 7. Update the README

Add your endpoint to the covered endpoints table in `incus-client/README.md`:

```markdown
| `/1.0/networks` | `GET`, `POST` | Incus 6.7 |
```

### 8. Open a PR

Submit your pull request with:
- The regenerated files in `incus-client/`
- Your test in `incus-client-tests/`
- The updated endpoints table in `README.md`

---

## Changing handwritten code

The following files are maintained by hand and are not touched by the generator:

| File | Purpose |
|------|---------|
| `incus-client/src/unix_socket.rs` | Unix socket transport and path resolution |
| `incus-client/src/lib.rs` | Crate root and module re-exports |
| `incus-client/Cargo.toml` | Dependencies and feature flags |
| `incus-client/README.md` | This crate's documentation |

For changes to these files, please open an issue first to discuss the approach before
submitting a PR.

---

## Requesting an endpoint

If you need an endpoint but do not want to implement it yourself, open an issue with:

- The endpoint path (e.g. `/1.0/networks`)
- A brief description of your use case

---

## Questions

Feel free to open an issue for any questions about the project or the contribution process.