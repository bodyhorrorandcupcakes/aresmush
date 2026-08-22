PF2e Plugin for AresMUSH
=======================

Community / as-is package. Pathfinder 2e Remaster-oriented chargen, sheets,
advancement, magic, gear, and rolls for AresMUSH.

This plugin ships with a broad Player Core + Player Core 2 catalog. Your game
decides what players may actually pick.


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
    ...

  # Close a class (plugins/pf2e/data/charclass.yml)
  barbarian:
    name: Barbarian
    chargen_open: false
    ...

  # Close one subclass option (plugins/pf2e/data/subclasses.yml)
  bloodline:
    demonic:
      name: Demonic
      chargen_open: false
      ...

  # Close a background (plugins/pf2e/data/backgrounds.yml)
  cultist:
    name: Cultist
    chargen_open: false
    ...

  # Close a heritage (plugins/pf2e/data/heritage.yml)
  whisper_elf:
    name: Whisper Elf
    chargen_open: false
    ...

Removing the chargen_open line entirely is the same as closed.

Do not delete whole entries unless you also remove references (heritage lists
on ancestries, feat grants, etc.). Prefer chargen_open: false.


3. Languages
------------

plugins/pf2e/data/languages.yml uses Remaster-oriented keys (common, elven,
dwarven, wildsong, …). Ancestries grant "common" plus their ancestry tongue.

Restricted languages (restricted: true), such as Wildsong, cannot be chosen
as free Int picks; they are class-granted only.

Optional "society: true" languages are auto-granted to every PC at commit.
None ship with that flag by default. Add it only if your game has a universal
cant or similar.


4. Config (game/config/pf2e.yml)
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


5. Dedication / archetype limits (code policy)
----------------------------------------------

helpers/archetypes.rb:

  DEDICATION_PLAYER_MAX = 1    # players may take one dedication freely
  DEDICATION_ABSOLUTE_MAX = 2  # second needs staff; third blocked

Adjust those constants if your table uses different multiclass limits.


6. Chargen flow (players)
-------------------------

  cg/start
  cg/ancestry | heritage | background | class   (Stage A)
  cg/identity
  cg/commit                                     # locks identity, grants languages/skills/wealth
  cg/boost … / cg/skill … / languages / feats   (Stage B)
  cg/status                                     # checklist of remaining picks

Staff:

  pf2e/review <name>                            # completeness review


7. What ships in data/
----------------------

  ancestry.yml, heritage.yml, backgrounds.yml, charclass.yml, subclasses.yml
  feats.yml (+ feats_subclass_stubs.yml)
  spells_*.yml (+ spells_subclass_stubs.yml)
  skills, saves, languages, weapons, armor, items, vendors, archetypes

Coverage aims at Player Core + Player Core 2 style catalogs. Some PC2 / SoM
edges still live as stubs (spells_subclass_stubs.yml, feats_subclass_stubs.yml)
so grants and lookups resolve; expand those files when you need full text.

Feats.yml is large; treat it as the live feat catalog. Subclass and class
features reference feat/spell slugs by key — keep keys stable when editing.


8. Install sketch
-----------------

  1. Copy plugins/pf2e/ into your AresMUSH plugins tree.
  2. Copy game/config/pf2e.yml (or merge keys) into game/config/.
  3. Enable the plugin in game/config/plugins.yml (or your game's equivalent).
  4. Edit data/*.yml chargen_open flags for your table.
  5. Load/reboot so data is read.
  6. Smoke-test: cg/start → pick open options → cg/status.


9. License / tone
-----------------

As-is community plugin. Adapt freely for your game. Pathfinder and related
names are used descriptively for compatibility with PF2e Remaster material;
respect Paizo's Community Use Policy where it applies to your publication.
