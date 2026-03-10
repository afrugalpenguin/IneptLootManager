# Inept Loot Manager

TBC Anniversary Classic fork of [Core Loot Manager](https://github.com/ClassicLootManager/ClassicLootManager) — a DKP based loot management system.

## About

Inept Loot Manager is a robust loot tracking and awarding tool for guilds running TBC Anniversary Classic. It uses **DKP** with automatic data synchronisation across your guild.

This fork has been stripped down to target TBC Anniversary Classic exclusively (Interface 20505).

## Features

- **DKP point system** with fine-grained configuration
- **Auto synchronisation** within your guild
- **Multiple roster (team) support** with independent configurations
- **Multiple item auction** — auction any number of items in a single auction
- **Simplified bidding UI** — clean bid/pass interface with minimum bid display
- **Alt-main linking** and **profile locking**
- **Multi-level access control** — Managers, Assistants, and Members

### Auction Modes

- Open, closed, and Vickrey bid systems
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

## License

This project is licensed under the Apache License 2.0. See the `LICENSE` and `NOTICE` files for more.
