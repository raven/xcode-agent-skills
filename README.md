# Xcode Agent Skills

The agent skills (`SKILL.md` bundles) that Apple ships inside Xcode, tracked over time so changes between Xcode releases show up as diffs.

Current snapshot: **Xcode 27.0 beta 4 (27A5228h)** — 10 skills.

## Where these come from

Xcode plugins contribute skills through the `Xcode.IDEIntelligenceProtocol.SkillDefinitionProvider` extension point, namespaced as `xcode-integration:*`. They were collected three ways:

| Skills | Source |
| --- | --- |
| `adopt-c-bounds-safety`, `audit-xcode-security-settings`, `device-interaction`, `modernize-tests`, `swiftui-specialist`, `swiftui-whats-new-27`, `uikit-app-modernization` | `xcrun agent skills export` against a running Xcode (the supported route — these are the "globally available" skills) |
| `translation`, `translation-coordinator` | Copied from `IDEXCStringsSupport.framework/Versions/A/Resources/Skills/` in the app bundle (not globally available; Xcode injects them into its localization agent flow). As of beta 3 the bundled files carry a `.packaged` suffix, preserved here |
| `ios-dynamic-text` | Extracted from the `IDEAXSpecialist` framework binary, where it's embedded as a string (also not exported; `SKILL.md` only, no references) |

`skills/c-bounds-safety` is a stale leftover, not part of the current snapshot: the skill was renamed to `adopt-c-bounds-safety` in beta 3 (verified by re-running the export against a beta 3 install), but `xcrun agent skills export --replace-existing` only overwrites — it never deletes skills a new build drops.

## Updating for a new Xcode build

With the new Xcode **running** and its license accepted:

```sh
./update-skills.sh /Applications/Xcode-beta.app   # defaults to xcode-select -p
```

The script performs all three collection steps (export, bundle copy, binary extraction), then prints the `git commit` + `git tag` commands for the new build number. It warns instead of failing silently if a skill has moved or vanished in a new build — that's a diff worth noticing.

(If you're doing it by hand: `xcrun agent skills export` needs an absolute `--output-dir`, because relative paths resolve against Xcode's own working directory.)

## Provenance / license

All skill content is authored and © Apple Inc., reproduced here unmodified for study and change-tracking. The repo structure and README are the only original content.
