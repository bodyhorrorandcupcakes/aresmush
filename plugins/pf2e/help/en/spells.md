---
toc: PF2e
order: 40
summary: Spellcasting sources, catalog search, daily prep, prepare/learn, cast.
aliases:
- spells
- spell
- cast
- innate
- spells/cast
- spells/search
- spells/daily
- spells/prepare
- spells/learn
---
# Spells and Innate Magic

Spellcasting is tracked per **source** on the sheet (`wizard`, `cleric`, a dedication slug, or `innate`). Multiclass characters can have more than one source; rolls and prepare/learn/cast need a source when more than one exists.

## Commands

| Command | Effect |
|---------|--------|
| `spells` | Show your spellcasting sources, slots, lists, and innate grants |
| `spells/search [query]` | Browse the Player Core catalog (5 per page; `spells/search/2` next page) |
| `spells/daily` | Daily preparations: clear spent slots, restore innate uses, restore Focus Points |
| `spells/prepare [<source>=]<rank>/<spell> [spell...]` | Set prepared spells for a rank (prepared casters) |
| `spells/learn [<source>=]<spell> [rank]` | Add a spell to spellbook / repertoire / cantrips |
| `spells/cast` / `cast` | Cast a spell (slots, focus, cantrips, innate) |

## Catalog search

```
spells/search
spells/search fire
spells/search 3
spells/search arcane
spells/search cantrip
spells/search/2 fire
```

- No args: all catalog entries, A–Z by name
- Digits only: exact **rank** (0 = cantrips)
- Otherwise: substring match on slug, name, category, traits, traditions, range, etc.
- Page size **5** (same as `feats`); use `/N` for page N

## Casting

```
cast <spell>
cast <spell> <rank>
cast <source>=<spell>
cast <source>=<spell> <rank>
```

| Kind | Resource | Notes |
|------|----------|--------|
| **Innate** | Daily uses (or at-will) | Prefer innate when only innate knows the slug |
| **Focus** | 1 Focus Point | Slug on a source's `focus_spells` list |
| **Cantrip** | None | On the source cantrip list |
| **Prepared** | Slot at cast rank | Must be prepared at that rank |
| **Spontaneous** | Slot at cast rank | In repertoire; may heighten |

Cast emits OOC to the room and logs to an open scene. Follow with `roll spell_attack` / `roll spell_dc` (or `spell_dc:<source>`) when needed.

## Rolling spell DC / attack

- `spell_dc` / `spell_attack` — only source, or error if multiple
- `spell_dc:wizard` / `spell_attack:innate` — explicit source

## Staff seed

    pf2e/set Bob=magic/sync
    pf2e/set Bob=magic/learn/wizard/force_barrage
    pf2e/set Bob=magic/innate/add/detect_magic/arcane/0/at_will

See `help manage pf2e` for the full staff path list.
