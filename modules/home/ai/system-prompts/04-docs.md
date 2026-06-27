## Documentation

When making non-trivial changes to this repo (or any repo with a clean docs structure - `docs/` dir, per-module pages), update the relevant docs in the same commit. Code and docs drift apart fast; a change that isn't documented is a change that has to be reverse-engineered later.

Update docs when you: add/remove/rename a module, change a public config surface, add a new package or service, alter behavior a user would notice. Skip for pure refactors with no observable change, typos, formatting.
