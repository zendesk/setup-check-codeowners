# setup-check-codeowners

![Latest Release](https://img.shields.io/github/v/release/zendesk/setup-check-codeowners?label=Latest%20Release)
![Examples](https://github.com/zendesk/setup-check-codeowners/workflows/Test/badge.svg?branch=main)

A GitHub action to install `check-codeowners`. This action will add
`check-codeowners` to the `PATH` making them available for subsequent
actions.

Note that `check-codeowners` is written in Ruby, so you'll also
probably want to use the `zendesk/setup-ruby` action. `check-codeowners` also
uses `git`.

## Inputs

This Action has no inputs.

## Output

This Action has no outputs.

## Usage

### Install check-codeowners

```yaml
steps:
  - id: setup-check-codeowners
    uses: zendesk/setup-check-codeowners@v1
```
