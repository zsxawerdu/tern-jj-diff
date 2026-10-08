# tern-jj-diff

A [Tern](https://docs.stencil.so/tern/) plugin that renders [Jujutsu](https://jj-vcs.github.io/jj/) `jj diff` and `jj show` output as a native view: summary badges (files, additions, deletions) and one collapsible diff per file, with `A`/`M`/`D`/`R` markers, rename sources, and a note for binary files.

Tern already has built-in views for `jj st` and `jj log`. This fills the gap for diffs. It does not touch those two.

## Install

```sh
tern plugin install github.com/zsxawerdu/tern-jj-diff
```

Tern clones the default branch and the plugin runs as soon as it is installed. Plugins are trusted code with full access to your user account, so read `host.luau` first, or pin a commit you have reviewed.

To hack on it, clone the repo and use `tern plugin link DIR` instead; Tern reloads on every change.

## Use

```sh
jj diff --git
jj show --git
jj diff --git -r @-
```

## Requirement: git-style diff output

The lens parses unified diff. jj only prints that when asked:

- type `--git`, or add a fish abbreviation: `abbr -a jjd jj diff --git`
- or make it the default: `jj config set --user ui.diff-formatter ':git'`

With another formatter (for example `difft`), plain `jj diff` is not unified diff. The lens finds no file headers and shows the raw output unchanged.

## How it works

- Claims `jj diff` and `jj show` (and their `jj --no-pager` forms) with any arguments. It deliberately does not claim `jj log` or `jj st`, because a plugin claim replaces the built-in view.
- A Tern lens only sees the output of the command you typed; it cannot run its own. Pipelines and stdout redirects are never lensed.
- Limits: 200 files shown, 2000 lines kept per file, the rest folds into a "more" line. Files after the 8th, and files over 300 lines, start collapsed.

## License

MIT, see [LICENSE](LICENSE).
