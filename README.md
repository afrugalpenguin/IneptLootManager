# Inept Loot Manager

TBC Anniversary Classic fork of [Core Loot Manager](https://github.com/ClassicLootManager/ClassicLootManager) — a DKP based loot management system.

## About

Inept Loot Manager is a robust loot tracking and awarding tool for guilds running TBC Anniversary Classic. It uses **DKP** with automatic data synchronisation across your guild.

This fork has been stripped down to target TBC Anniversary Classic exclusively (Interface 20505), and DKP only.

## Features

- **DKP point system** with fine-grained configuration
- **Auto synchronisation** within your guild
- **Multiple roster (team) support** with independent configurations
- **Multiple item auction** — auction any number of items in a single auction
- **Simplified bidding UI** — clean bid/pass interface with minimum bid display
- **Alt-main linking** and **profile locking**
- **Multi-level access control** — Managers, Assistants, and Members

### Auction Modes

- Open or closed bidding systems.
- Anonymous bidding support
- Static, ascending, and tiered item value systems
- Anti-snipe protection
- Auction from corpse or bag (default: alt-click)

### Point Awards

- On-time, raid completion, and interval bonuses
- Boss kill bonuses (configurable per TBC boss)
- Configurable weekly and hard point caps

### Administration

- Full history tracking (point changes and item awards)
- Auditing UI for event management
- Time travel / sandbox mode for correcting historical errors
- Multi-level logging

## Slash Commands

- `/ilm` — Open main window
- `/ilm help` — List all available commands
- `/ilm bid` — Toggle bidding window
- `/ilm award [item]` — Award item GUI
- `/ilm guireset` — Reset GUI position

## Installation

Copy the `IneptLootManager/` folder into your `Interface/AddOns/` directory.

## Bundled Libraries

ILM bundles the following libraries. Thanks to their authors for making them available:

| Library | Author(s) | License |
|---------|-----------|---------|
| [Ace3](http://www.wowace.com) | Ace3 Development Team | Limited BSD |
| AceGUI-3.0-SharedMediaWidgets | Yssaril | — |
| CallbackHandler-1.0 | Ace3 Development Team | Limited BSD |
| LibCandyBar-3.0 | Ammo, Funkydude, Rabbit | — |
| LibDataBroker-1.1 | Tekkub | Public Domain |
| [LibDBIcon-1.0](https://www.curseforge.com/wow/addons/libdbicon-1-0) | Funkydude | GPLv2+ |
| [LibDeflate](https://github.com/SafeteeWoW/LibDeflate) | Haoqian He (SafeteeWoW) | zlib |
| [LibDeformat-3.0](http://www.wowace.com/projects/libdeformat-3-0/) | ckknight | MIT |
| LibEventDispatcher | [Sam Mousa](https://github.com/SamMousa) | — |
| LibEventSourcing | [Sam Mousa](https://github.com/SamMousa) | — |
| [LibLogger](https://github.com/ClassicLootManager/LibLogger) | Lantis | MIT |
| [LibSerialize](https://github.com/rossnichols/LibSerialize) | Ross Nichols | MIT |
| [LibSharedMedia-3.0](http://www.wowace.com/projects/libsharedmedia-3-0/) | Elkano | LGPL v2.1 |
| [lib-st](https://www.wowace.com/projects/lib-st) | Dan Dumont | GPLv3+ |
| [LibStub](http://www.wowace.com/wiki/LibStub) | Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke | Public Domain |
| LibUIDropDownMenu | Numy (fork) | GPLv2 |

## License

This project is licensed under the Apache License 2.0. See the `LICENSE` and `NOTICE` files for more.
