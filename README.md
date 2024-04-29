# setup-check-codeowners

![Latest Release](https://img.shields.io/github/v/release/zendesk/setup-check-codeowners?label=Latest%20Release)
![Examples](https://github.com/zendesk/setup-check-codeowners/workflows/Test/badge.svg?branch=main)

A script to check `.github/CODEOWNERS`, and a GitHub Action to install it.

Features include:

- lookups
  - given a file, find the owner
  - given an owner, find their files
- coverage
  - find files which don't have a codeowner
  - find codeowner entries which don't match any files
- linting
  - find invalid codeowner definitions
  - check codeowners are alphabetical
  - check consistent indents

See [Usage](Usage.md) for details.

## Usage of the Github Action

This adds `check-codeowners` script to the `PATH`.

```yaml
steps:
  - id: setup-check-codeowners
    uses: zendesk/setup-check-codeowners@VERSION
```

where `VERSION` is one of the [repo tags](https://github.com/zendesk/setup-check-codeowners/tags)

## Script and Github Action Dependencies

- Ruby (in Github Actions [zendesk/setup-ruby action](https://github.com/zendesk/setup-ruby) can install it)
- Git

## Action Inputs

None.

## Action Output

None.
