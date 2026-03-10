**v1.0.0**

- First public release of Inept Loot Manager
- TBC Anniversary Classic fork of Core Loot Manager — DKP only
- Full rebrand from CLM to ILM (code, UI, slash commands, SavedVariables)
- Simplified bidding UI, auction settings, and roster configuration
- CLM JSON import (/ilm import) with standings, point history, and loot history
- Manager Control Panel
- All libraries bundled directly — no external dependencies
- CI/CD via BigWigs packager and GitHub Actions

**v0.9.0**

- Flatten addon files to repo root for BigWigs packager compatibility
- Add CI workflows (release via BigWigs packager, luacheck on push/PR)
- Add bundled libraries credit table to README
- Add CREDITS.md for original CLM contributors

**v0.8.0**

- Remove minimap icon (replaced by Manager Control Panel)
- Remove dead files: Bindings.xml, .gitman.yml, custom audio
- Strip non-TBC item IDs from Tooltips.lua
- Strip metadata cruft from bundled Libs (tests, docs, .github, etc.)

**v0.7.0**

- Add CLM JSON import (/ilm import) with standings, point history, and loot history
- Add Manager Control Panel
- Simplify auction to DKP ascending only
- Remove zero-sum bank from auction settings

**v0.6.0**

- Strip roster settings to TBC-only essentials
- Fix AceConfigDialog rootframe nil crashes
- Improve configuration UX

**v0.5.0**

- Replace complex bidding UI with simplified native bid/pass frame
- Remove Changelog and CrossGuildSync modules

**v0.4.0**

- Update icons to TGA format, rebrand author to Castborn
- Bundle all library dependencies directly (no BigWigs packager or SVN needed)

**v0.3.0**

- Fold Alerts and Tracker sub-addons into core addon
- Remove Integrations sub-addon entirely

**v0.2.0**

- Strip EPGP and SK point systems — DKP only
- Remove non-existent /ilm queue command from docs

**v0.1.0**

- Fork Core Loot Manager as Inept Loot Manager
- Rebrand all code references, UI strings, slash commands, SavedVariables from CLM to ILM
- Set all TOC files to TBC Anniversary only (Interface 20505)
- Strip encounter data to TBC-only raids
- Strip non-TBC classes, transmog, and disenchant roll types
- Remove legacy GitHub artifacts (FUNDING.yml, scripts, workflows)
