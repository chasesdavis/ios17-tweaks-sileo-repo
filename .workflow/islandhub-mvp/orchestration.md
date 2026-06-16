# IslandHub MVP Orchestration

1. Complete Scout T001 by mapping repo patterns and confirming safety limits.
2. Activate Worker T002 and create `tweaks/IslandHub`.
3. Build in a temporary directory so generated Theos artifacts do not pollute source.
4. Activate Worker T003 and copy the built deb into `repo/debs`, preserving pending IslandInbox.
5. Regenerate Packages metadata and run package audits.
6. Activate Worker T004 and publish both `main` and `gh-pages`.
7. Poll GitHub Pages until `IslandHub 1.0.0-1` is live and byte-identical.
8. Complete Judge T999 with final evidence.

Branching rules:
- If the build fails, fix IslandHub files only.
- If package metadata references a missing deb, stop and repair repo metadata before publishing.
- If a requested module would require external credentials or hidden data capture, ship a local UI placeholder and defer real integration.
- If unrelated pending files are present, preserve them and do not revert.
