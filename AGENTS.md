# Repository Guidelines

This repository contains a D language library. Follow the practices below when adding modules, tests, or documentation.

## Project Structure & Module Organization
- `source/` holds all D modules for the library.
- `source/nep/` is the root package; subpackages include `source/nep/container/` and `source/nep/datastructure/`.
- `source/**/package.d` files re-export public modules; add new public modules there.
- `tst.txt` is a small fixture used by `unittest` blocks.
- `dub.json` defines the package metadata and build settings.

## Build, Test, and Development Commands
Use `dub` for all local builds and tests:

```sh
dub build
```
Builds the library target defined in `dub.json`.

```sh
dub test
```
Runs `unittest` blocks embedded in modules.

## Coding Style & Naming Conventions
- Indentation: 2 spaces, no tabs, to match existing modules.
- Modules use lowercase paths (for example, `module nep.container.stack;`).
- Types use `PascalCase`; functions and variables use `lowerCamelCase`.
- Keep public APIs in `source/nep/` and export them through the nearest `package.d`.

## Testing Guidelines
- Prefer D `unittest` blocks next to the code they exercise.
- When a test needs a fixture, place it at repo root (for example, `tst.txt`).
- Run `dub test` before opening a PR.

## Commit & Pull Request Guidelines
- Recent history uses short, conventional prefixes such as `feat:`, `fix:`, and `update:`. Match that style.
- Keep commit subjects concise and imperative.
- PRs should describe the change, list test commands run, and link relevant issues or notes.
