# Using check-codeowners

## Overview

`check-codeowners` can be used to check and interrogate `.github/CODEOWNERS`. Depending on
the options given, it does one of three things:

 * [runs the checks](#running-the-checks). This is the default.
 * finds out [who owns one or more files](#who-owns-this-file)
 * finds out [which files are owned by one or more owners](#which-files-does-this-owner-own)

## Running the checks

Runs various checks against `CODEOWNERS`. If everything's fine, then it exits successfully and silently.

If `--strict` was used, then any warnings get upgraded to errors.
Any errors or warnings are shown on standard output.
If there were any warnings or errors, then a link to this document is shown.
The exit status is 2 if there were any errors, or 0 otherwise.

You can also get the output as json with `--json`.

The remaining options control which checks run: for the full set, use `--brute-force --check-unowned --strict`.

See [Errors and warnings](#errors-and-warnings) for a description of the checks that are run.

## Errors and warnings

### Line is duplicated or out of sequence

By default, lines in both `CODEOWNERS` and `CODEOWNERS.ignore` must be in alphabetical order. This error
indicates that the lines are not in order. Comments and blank lines are excluded from this check.

To fix this, put the lines in order, and remove duplicates. Alternatively, use `--no-check-sorted`.

Note that, depending on your setup, lines may be compared using the C locale,
which is case-sensitive. For example,

```text
# Error!
another_file  @some/owner
OneFile       @some/owner
```

would give this error, because "O" (being upper case) sorts before "a" (lower case).

### Mismatched indent

By default, the "owner" part of `CODEOWNERS` must be aligned all the way down the file:

```text
# Good
a_file       @some/owner
file         @some/owner
foo          @someone/else
```

```text
# Bad
a_file @some/owner
file @some/owner
foo @someone/else
```

To fix this, ensure that all of the indents line up. Alternatively, use `--no-check-indent`.

Note that tabs are not supported.

### Invalid owner

By default, there must be a `VALIDOWNERS` file, which lists all the valid code owners.
This error occurs when a `CODEOWNERS` entry is seen where the owner is not in `VALIDOWNERS`:

```text
# VALIDOWNERS
@org/design_team
@org/project_team
```

```text
# CODEOWNERS
a_file      @org/design_team
something   @org/projetc_team
```

Here `projetc_team` would be rejected as an invalid owner.

To fix, add the owner to `VALIDOWNERS`. Alternatively, use `--no-check-valid-owners`.

### Please add this file to CODEOWNERS

This error occurs when `--check-unowned` is used (which is not the default),
and a file exists which is covered neither by `CODEOWNERS` nor `CODEOWNERS.ignore`.

To fix, ensure that the file is owned according to `CODEOWNERS` (e.g. by adding a line for it),
or ignore it via `CODEOWNERS.ignore`. Alternatively, stop using `--check-unowned`.

### The following entry in CODEOWNERS.ignore doesn't match any unowned files and should be removed

Hopefully self-explanatory. This message indicates that an entry in `CODEOWNERS.ignore`
is superfluous, and therefore in the interests of keeping things minimal and tidy, should be removed.

### Pattern ... at ... doesn't match any files

This message indicates that an entry in `CODEOWNERS` is superfluous, because it doesn't match anything.
In the interests of keeping things minimal and tidy, it should therefore be removed.

### Unrecognised line at ...

This indicates that the line shown does not seem to be a valid `CODEOWNERS` line. For example, it lists
a file, but no owner:

```text
# Bad
file1  @team_one
file2
file3  @team_two
```

Comments and blank lines are allowed.

To fix, ensure that all `CODEOWNERS` lines are of the form `filename owner [owner ...]`.

## Who owns this file?

```shell
check-codeowners --who-owns [FILE ...]
```

For each FILE listed (or if none, then all files), print a single line showing code ownership.
Each line is of the form "filename, tab, owners":

```text
$ check-codeowners --who-owns Usage.md
Usage.md	@zendesk/enigma
$
```

If a file is unowned, the owner is shown as `-`.

You can also get the output as JSON:

```shell
check-codeowners --json --who-owns [FILE ...]
```

## Which files does this owner own?

```shell
check-codeowners --files-owned OWNER [...]
```

For each OWNER listed, and for each file they own, print a single line showing code ownership.
Each line is of the form "filename, tab, owners":

```shell
$ check-codeowners --files-owned @zendesk/enigma
.github/CODEOWNERS	@zendesk/enigma
.github/workflows/release.yml	@zendesk/enigma
.github/workflows/test.yml	@zendesk/enigma
...
```

You can also get the output as JSON:

```shell
check-codeowners --json --files-owned OWNER [...]
```
