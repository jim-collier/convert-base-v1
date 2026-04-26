<!-- markdownlint-disable MD007 -- Unordered list indentation -->
<!-- markdownlint-disable MD010 -- No hard tabs -->
<!-- markdownlint-disable MD024 -- No duplicate headings [OK with no TOC] -->
<!-- markdownlint-disable MD033 -- No inline html -->
<!-- markdownlint-disable MD041 -- First line in a file should be a top-level heading -->
<!-- markdownlint-disable MD055 -- Table pipe style [Expected: leading_and_trailing; Actual: leading_only; Missing trailing pipe] -->
# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.1

Published 2026-04-26.

### Notes

`v1.0.1`, as the semantic version would suggest, is 100% backwards-compatible with `v1.0.0`. Nothing from the former interface or input/output has changed, only a bugfix and new option aliases added.

### Added

- Added option `--from` as an alias to `--ibase`.

- Added optional flag `--obase` (and alias `--to`), as an alternative to specifying the base as a positional argument.

- Updated inline help, and README.md, to reflect additional interfaces.

### Changed

- Bug fix: `--help` produced an error. It was trying to call non-existent function `fPrint_Help()`, rather than `fHelp()`

- Updated testing to also test flags like that.

## v1.0.0

Published 2026-04-25.

### Notes

This contains changes made through v1.0.0-beta1 and to release v1.0.0.

### Added

- More base aliases.

- Added scripting for exhaustive fuzz testing, including of base names and aliases (caught many edge-case bugs).

- Added scripting for exhaustive fuzz testing against v2. Even in beta, v2 can accurately handle _inputs_ of all the bases, whereas testing against self is limited to the input bases this version supports. In this way, v1b can be tested against all the bases it supports.

### Changed

- While older aliases still work, the advertised base names have been more streamlined and rationalized.

- Fixed numerous minor bugs found in fuzz testing.

- Improved help; now sorts by base #, rather than grouping them in category chunks. Added a column of whether its a standard base, pseudostandard, published, or custom (rather than aforementioned groups).

- Polished CI/CD/Dogfood scripts.

- Updated README.md with better and accurate examples.

## v1.0.0-beta1

### Notes

This is a breaking update over the previous version. As such, the exe suffix is renamed from `v1` to `v1b`. (`v2` is already being worked on.)

This rename is independent of the internal standard semantic versioning, and was intended for this reason from the start.

The rationale behind the minor but necessary breaking changes, and the version in the name, are explained in the `README.md`.

### Added

- CI/CD scripts.

- Base: 45email

- Base: 64hex. Unlike the RFC variants, sorts in code point order, hex-style. (Like 32hex.)

- Base: 48j1w. Replaces 48j1, with a different symbol set. Now accurately extends 32w.

- Base: 64j1w. Replaces 64j1uw, with a different symbol set. Extends 32w and 48j1w.

- Base: 128j1. Is now redefined as a left-most subset of 256j1 (and 288j1), for consistency. Extends base-62.

- Base: 128j1w. Replaces what used to be 128j1. Extends 48j1w and 64j1w (all now consistent with 32w), but is now different than the old removed 128j1.

- Alias: 64j1u -> 64j1.

### Changed

- Renamed base 64j1u -> 64j1 for consistency with other bases.

- 38username -> 39username. (Added an extra, valid username character.)

### Removed

- Base: 48j1. Was too inconsistent with 32w as a "word-safe" base.

- Base: 64j1uw. Was too inconsistent with 32w as a "word-safe" base.

- Base: 128j1. Was too inconsistent with 32w as a "word-safe" base, and different than 256j1 and 288j1.

- Removed all unadorned numbers (e.g. "128") as aliases for bases that don't have well-defined standards.

### Other work

- Added optional testing and CI/CD scripts.

<!--

## NEXT VERSION

### Notes

### Added

### Changed

### Removed

### Other work

-->