---
summary: PF2e character generation commands.
---

# Chargen

Build your Pathfinder 2e Remaster sheet in stages. Stage A (identity) can be changed freely until you lock it. After lock, change requires `cg/reset` (not available to approved characters).

## Stage A — Identity

| Command | Purpose |
|---------|--------|
| `cg/ancestry [slug]` | Set or list ancestries |
| `cg/heritage [slug]` | Set or list heritages for current ancestry |
| `cg/background [slug]` | Set or list backgrounds |
| `cg/class [slug] [key ability]` | Set or list classes |
| `cg/identity` | Show current combination and grants |
| `cg/commit` | Lock identity and apply fixed grants |
| `cg/reset` | Wipe sheet to defaults (unapproved only) |

## Class options (required before commit)

After `cg/class`, set the option your class requires:

| Class | Command |
|-------|--------|
| Witch | `cg/contact <slug>` |
| Sorcerer | `cg/bloodline <slug>` |
| Champion | `cg/cause <slug>` |
| Bard | `cg/muse <slug>` |
| Rogue | `cg/racket <slug>` |
| Investigator | `cg/methodology <slug>` |
| Druid | `cg/order <slug>` |
| Ranger | `cg/edge <slug>` |
| Wizard | `cg/school <slug>` |
| Cleric | `cg/doctrine <slug>` |

Omit the slug to list open options. Only open options can be selected; closed classes and options are not listed.

## Stage B — After commit

| Command | Purpose |
|---------|--------|
| `cg/boost <source> = <abilities>` | Assign free ability boosts |
| `cg/bgskill <choice>` | Resolve background skill choices |
| `cg/skill <skills>` | Spend class skill picks |
| `cg/language <lang>` | Free language picks |
| `cg/feat <slug>` | Take a feat into an open slot |
| `cg/unfeat <slug>` | Remove a chosen feat |

See also: sheet, roll, feats, spells, gear, money, shop.
