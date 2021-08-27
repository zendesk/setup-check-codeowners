# Using check-codeowners

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
or ignore it via `CODEOWNERS.ignore` (or stop using `--check-unowned`).

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

Comments and blank lines are allowed too.

To fix, ensure that all `CODEOWNERS` lines are of the form `filename owner [owner ...]`.
