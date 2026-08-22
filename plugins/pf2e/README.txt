PF2e Plugin for AresMUSH
=======================

Community / as-is package. Pathfinder 2e Remaster-oriented chargen, sheets,
advancement, magic, gear, and rolls for AresMUSH.

This plugin ships with a broad Player Core + Player Core 2 + Secrets of Magic
catalog. Your game decides what players may actually pick.


0. CLI-only as shipped (web is feasible later)
---------------------------------------------

This package is **CLI / in-game command only** as shipped:

  * sheets, rolls, chargen, gear, money, spells, staff tools

There is **no** ares-webportal UI in this release on purpose. Keeping the first
community cut CLI-only avoids coupling to portal Ember routes and version skew.

The Ruby side is still written so a web layer can be added without rewriting
rules:

  * Domain logic lives under plugins/pf2e/helpers/ (not inside command classes).
  * Commands are thin adapters: parse args → call helper → emit text.
  * Pf2eSheet / Character public models are ordinary data the portal could read.
  * Static catalogs load through Pf2e.read_data (same API a web handler would use).

If you add web later, prefer read-only sheet first, then optional chargen
wizards. Put portal code in ares-webportal; call the same helpers.

Helper map (start here):

  plugins/pf2e/helpers/
    chargen*.rb     identity, boosts, skills, languages, subclass picks, status
    advancement.rb  level-up / feat slot math (if present)
    combat.rb       attack / damage helpers
    magic.rb        spell lists, focus, cast hooks
    feats.rb        feat lookup / grants
    money.rb        purse + optional society_account ledger
    inventory.rb    gear, bulk hooks
    rolls.rb        d20 degrees of success
    sheet_display.rb  text sheet rendering


1. chargen_open — the main gate
------------------------------

Catalog YAML under plugins/pf2e/data/ uses:

    chargen_open: true

on each player-selectable entry (ancestries, heritages, backgrounds, classes,
subclass options such as bloodlines / doctrines / rackets / etc.).

Rules enforced by the plugin:

  * Missing key  → closed (not offered in lists, cannot be set in chargen)
  * false        → closed
  * true         → open for player chargen

Staff tools (pf2e/set and related) can still assign closed options when your
game needs an exception.

Default package state: every entry that ships in the data files is marked
chargen_open: true so a new install can play immediately. Close what you do
not want before opening applications.


2. How to disable content you do not want
-----------------------------------------

Edit the YAML, then restart/reload the plugin (or reboot the game) so
Pf2e.load_data picks up changes.

Examples:

  # Close an ancestry (plugins/pf2e/data/ancestry.yml)
  orc:
    name: Orc
    chargen_open: false

  # Close a class (plugins/pf2e/data/charclass.yml)
  barbarian:
    name: Barbarian
    chargen_open: false

  # Close one subclass option (plugins/pf2e/data/subclasses.yml)
  bloodline:
    demonic:
      name: Demonic
      chargen_open: false

Removing the chargen_open line entirely is the same as closed.

Do not delete whole entries unless you also remove references (heritage lists
on ancestries, feat grants, etc.). Prefer chargen_open: false.


3. Data layout and source-split catalogs
----------------------------------------

Pf2e.load_data deep-merges every plugins/pf2e/data/*.yml on boot. Top-level
keys (feats, spells, ancestries, …) merge; later files overlay matching keys.

Spells (mechanical fields only — name, rank, traits, traditions, cast, …):

  spells_cantrips.yml
  spells_rank_1_3.yml
  spells_rank_4_6.yml
  spells_rank_7_10.yml
  spells_focus.yml
  spells_rituals.yml
  spells_pc2.yml          # Player Core 2 lists + bloodline/mystery/devotion focus
  spells_som.yml          # Secrets of Magic (~200 spells)
  spells.yml              # tradition index / meta if present

Feats are split so file size stays sane and books stay navigable:

  feats.yml               # large Player Core (+ most PC2 class feats) dump
  feats_pc2.yml           # Player Core 2 addenda / grant anchors
  feats_som.yml           # Secrets of Magic (magus, summoner, order feats, …)

When you add another book, prefer a new file:

  feats_roe.yml           # example: Rage of Elements
  spells_roe.yml
  items_treasure_vault.yml

Use the same top-level key (feats / spells / items) and a source: field on
each entry. Document the file in this README. Keep full rulebook prose out of
YAML — mechanical fields only.


4. How to add another book
--------------------------

  1. Create plugins/pf2e/data/<catalog>_<abbrev>.yml
  2. Top-level key must match an existing section (feats, spells, items, …).
  3. Entries use stable slug keys (live_wire, expansive_spellstrike).
  4. Set source: "Pathfinder <Book Name>" on each row.
  5. For player-selectable identity options, set chargen_open: true|false.
  6. Reload the plugin / reboot.
  7. Smoke-test: feat/spell lookup commands and cg/status.

Suggested optional packs (not in the default ship set):

  Rage of Elements, Treasure Vault, Guns & Gears, Dark Archive,
  Howl of the Wild, Book of the Dead

Default ship target remains: Player Core + Player Core 2 + Secrets of Magic.


5. Languages
------------

plugins/pf2e/data/languages.yml uses Remaster-oriented keys (common, elven,
dwarven, wildsong, …). Ancestries grant "common" plus their ancestry tongue.

Restricted languages (restricted: true), such as Wildsong, cannot be chosen
as free Int picks; they are class-granted only.

Optional "society: true" languages are auto-granted to every PC at commit.
None ship with that flag by default.


6. Config (game/config/pf2e.yml)
--------------------------------

Useful keys:

  use_encumbrance: true/false
  starting_wealth: "15gp"
  starting_wealth_to: purse          # or "society" for the optional ledger
  xp_to_level: 1000
  scene_xp_enabled / scene_xp
  vendor_level_lock / vendor_level_offset

"society_account" on the sheet is an optional off-person ledger (not Bulk).
Default starting wealth goes to the on-person purse.


7. Dedication / archetype limits (code policy)
----------------------------------------------

helpers/archetypes.rb:

  DEDICATION_PLAYER_MAX = 1    # players may take one dedication freely
  DEDICATION_ABSOLUTE_MAX = 2  # second needs staff; third blocked

Adjust those constants if your table uses different multiclass limits.


8. Chargen flow (players)
-------------------------

  cg/start
  cg/ancestry | heritage | background | class   (Stage A)
  cg/identity
  cg/commit                                     # locks identity, grants languages/skills/wealth
  cg/boost … / cg/skill … / languages / feats   (Stage B)
  cg/status                                     # checklist of remaining picks

Staff:

  pf2e/review <name>                            # completeness review


9. What ships in data/
----------------------

  ancestry.yml, heritage.yml, backgrounds.yml, charclass.yml, subclasses.yml
  feats.yml, feats_pc2.yml, feats_som.yml
  spells_*.yml (including spells_pc2.yml, spells_som.yml)
  skills, saves, languages, weapons, armor, items, vendors, archetypes

Coverage aims at Player Core + Player Core 2 + Secrets of Magic mechanical
catalogs. Expand with per-book files when you need more.


10. Install sketch
------------------

  1. Copy plugins/pf2e/ into your AresMUSH plugins tree.
  2. Copy game/config/pf2e.yml (or merge keys) into game/config/.
  3. Enable the plugin in game/config/plugins.yml (or your game's equivalent).
  4. Edit data/*.yml chargen_open flags for your table.
  5. Load/reboot so data is read.
  6. Smoke-test: cg/start → pick open options → cg/status.


11. License / tone
------------------

As-is community plugin. Adapt freely for your game. Pathfinder and related
names are used descriptively for compatibility with PF2e Remaster material;
respect Paizo's Community Use Policy where it applies to your publication.
Mechanical YAML fields support play; they are not a substitute for the books.
