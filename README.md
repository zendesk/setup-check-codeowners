# setup-check-codeowners

![Latest Release](https://img.shields.io/github/v/release/zendesk/setup-check-codeowners?label=Latest%20Release)
![Examples](https://github.com/zendesk/setup-check-codeowners/workflows/Test/badge.svg?branch=main)

A script to check `.github/CODEOWNERS`; also a Github Action to add that
script to the `PATH` making it available for subsequent
actions.

`check-codeowners` is written in Ruby, and has no non-core dependencies, which makes
it pretty easy to run. `check-codeowners` also uses `git`.

If you're using it via the Github Action, you'll need `ruby` on your `PATH`.
The [zendesk/setup-ruby action](https://github.com/zendesk/setup-ruby) can help here.

## Inputs

This Action has no inputs.

## Output

This Action has no outputs.

## Usage of the Github action

### Install check-codeowners

```yaml
steps:
  - id: setup-check-codeowners
    uses: zendesk/setup-check-codeowners@VERSION
```

where VERSION is the version you wish you use, e.g. `v7`. Check the top of this readme
to find the latest release.

This adds `check-codeowners` to your `PATH`.

## Usage of `check-codeowners`

See [the Usage guide](Usage.md).
