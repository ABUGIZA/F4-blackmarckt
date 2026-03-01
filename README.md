# F4 Black Market

Modern FiveM black market resource with NUI interface, delivery flow, reputation tiers, and dual framework support.

## Preview

![Preview 1](https://i.ibb.co/bgsVnnJF/image.png)
![Preview 2](https://i.ibb.co/3555PLVs/image.png)
![Preview 3](https://i.ibb.co/8Dj1Nmw2/image.png)
![Preview 4](https://i.ibb.co/Xr5vkRnF/image.png)
![Preview 5](https://i.ibb.co/rfkv8B0n/image.png)

## Supported Frameworks

- `qbx_core` + `ox_inventory`
- `qb-core` + `qb-inventory`

## Features

- Clean Black Market NUI (market, cart, and history views)
- NPC interaction point for opening the market
- Delivery NPC to claim purchased items
- Smart payment priority (`bank` then `cash`)
- Reputation + level progression with discount tiers
- Purchase history + pending deliveries persisted per player
- Auto migration for older DB formats
- Inventory image URL support from `ox_inventory` / `qb-inventory`

## Requirements

- `ox_lib`
- `oxmysql`
- One framework stack:
  - `qbx_core` + `ox_inventory`
  - or `qb-core` + `qb-inventory`

## Installation

1. Place folder in your resources directory.
2. Import SQL file:
   - `f4_blackmarket.sql`

3. Ensure load order in `server.cfg`:

```cfg
ensure ox_lib
ensure oxmysql

# Framework (choose one)
ensure qbx_core
ensure ox_inventory
# or
# ensure qb-core
# ensure qb-inventory

ensure F4-blackmarckt
```

## Configuration

Main config file:

- `shared/config.lua`

Important options:

- `Config.Framework` (`auto`, `qbx`, `qb`)
- NPC & delivery coordinates
- payment priority and reasons
- market schedule (`always_open` / `scheduled`)
- reputation levels and discount percentages
- product list and categories
- inventory image base URLs

## Resource Files

- `fxmanifest.lua`
- `client/main.lua`
- `server/main.lua`
- `shared/config.lua`
- `f4_blackmarket.sql`
- `ui/` (Svelte UI source + build output)
