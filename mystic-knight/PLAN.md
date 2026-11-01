# Mystic Knight for Dragon's Dogma 2 (Dark Arisen) — Layout Plan

**Goal:** bring back the Dragon's Dogma 1 / Dark Arisen Mystic Knight as a full vocation in DD2, as close to the
original as the engine allows. It gets its own vocation entry, name, icon and stat growth, and its own skills at the
Vocation Guild, bought with Discipline and slotted like vanilla skills. No hold-LB+LT layer.

Status: **design only**. Nothing here is built or tested yet. Entries marked **[verify]** still need checking in the
game files or in-game.

---

## 1. Framework choice: Vocation & Skill Builder (VSB)

| | **VSB** (recommended) | Skill Creator | Skill Maker |
|---|---|---|---|
| Custom *vocation* (own name, icon, guild entry) | **Yes** | No (skills only) | No (skills only) |
| Skills bought at the Vocation Guild | Yes | Yes | No (own menu) |
| What players install | REFramework, _ScriptCore, VSB | REFramework, _ScriptCore, _NickCore (+ devtools for authors) | REFramework, _ScriptCore |
| Post-Dark-Arisen use | Yes: Pactblade (a VSB vocation) is tested on the post-DLC build | Unclear | Older (2024), unclear |
| Install method | Fluffy Mod Manager or drag-and-drop | Same | Same |

**Why VSB:** it's the only one that makes an actual vocation, and players install it the normal way. They download
three things from Nexus (REFramework, _ScriptCore, VSB), plus this mod, and drop them into Fluffy. There's no editor
to run and no JSON for them to touch.

**How a VSB vocation works** (based on the open-source Pactblade vocation, MIT licensed):
- The vocation is a *pack* in `reframework/data/VSB/packs/<id>/`: one `pack.json` for the vocation and one
  `skills/*.json` per skill.
- The vocation sits on top of a vanilla weapon job. **Ours uses `Job01` (Fighter)**, so sword and shield come for
  free. Fighter is already a sword-and-shield vocation, and Mystic Knight is a sword-and-shield vocation with a
  magick shield.
- Each skill has 2 levels in VSB (with only one level, the guild crashes). **We use level 2 as DD1's "Greater"
  version**, so Blink Strike → Burst Strike is one skill line with an upgrade, just like DD2's own skills.
- VSB handles names, icons, ranks and Discipline costs, and passes the button press to our Lua script. The script
  does the actual work: animations, projectiles, effects and damage.
- VSB also supports custom **core** skills (`kind: "core"`, which can replace a vanilla action such as `Job01_Guard`
  or listen for press/hold/tap combos). That's how the magick shield block gets built.

**One honest limitation:** VSB vocations appear under the Fighter entry. The player picks "Mystic Knight" from VSB's
menu once, and from then on, being a Fighter means being a Mystic Knight. The game doesn't get an 11th vocation slot.
Nobody has done that, and it would mean save-data surgery. Players will see the Mystic Knight name, icon, skills and
growth everywhere it matters.

**Player install (final):**
1. Install REFramework, _ScriptCore and VSB from Nexus (all normal downloads).
2. Add `MysticKnight.zip` to Fluffy Mod Manager and enable it.
3. In game: Insert → VocationAndSkillBuilder → Vocations → Fighter → **Mystic Knight**.
4. Go to a Vocation Guild and buy skills.

---

## 2. What DD1's Mystic Knight was (the reference)

Source: Fextralife DD1 wiki (Mystic Knight, Magick Shield Skills and Great Cannon pages), cross-checked against
community posts. Fextralife has some errors (it describes Ruinous Sigil with Vortex Sigil's text, for example), so
we fix those as we go.

- **Hybrid vocation**, unlocked at level 10 at the Union Inn in Gran Soren. **Pawns couldn't be Mystic Knights.**
- **Weapons:** sword or mace + magick shield, *or* staff.
- **Skill slots:** 3 sword/mace skills + 3 magick shield skills (or 3 staff skills).
- **Signature mechanics:** perfect blocks with the magick shield trigger elemental counters; the shield's Magick adds
  to your attacks; self-enchanting your weapon; sigils and the Great Cannon spellshot turret.

### Stat growth (per level)
| Stat | Lv 10–99 | Lv 100+ |
|---|---|---|
| Health | 30 | 15 |
| Stamina | 20 | 5 |
| Strength | 2 | 1 |
| Defense | 3 | 1 |
| Magick | 3 | 1 |
| Magick Defense | 3 | 1 |

---

## 3. Mapping DD1 to DD2

### Slot parity
DD1 Mystic Knight had **3 sword + 3 shield = 6 skills**. Dark Arisen gives DD2 **6 weapon skill slots**. The
original loadout fits one-to-one, so the slot count needs no compromise.

### Pawns
DD1 pawns couldn't be Mystic Knights, so the mod is **player-only on purpose**. Pawn support was the hardest part of
any custom vocation, and the original design lets us skip it.

### Save safety
Same rules Pactblade follows: anything we change on items or stats is restored while the game saves or uploads
pawn/Arisen data. Uninstalling the mod leaves a normal Fighter save.

---

## 4. The vocation (pack.json)

| Field | Value |
|---|---|
| id | `mystic_knight` |
| name | Mystic Knight |
| description | "A knight who wields sword and magick shield in concert, turning the foe's own blows against them." (DD1-style wording, final text TBD) |
| weapon | `Job01` (sword + shield) |
| icon | A shield-type icon from the game's sheets **[verify]** in VSB's icon picker |
| unlock | Level 10, like DD1's hybrid. VSB `progression.unlock_rank` covers skill ranks; the level-10 gate is a script check **[verify]** if VSB has a native one |
| stat growth | DD1 table above, applied through `JobStatusParamHolder.getJobStatusParam(Job01)` while Mystic Knight is active. DD2 stat scales differ from DD1, so we copy the *ratios* (MK ≈ Fighter's HP/defense with Mage-level Magick), normalized to DD2's Fighter/Mage numbers **[verify]** |

---

## 5. Core skills (always on, no slot)

| DD1 core | Weapon | DD1 rank / DP | DD2 implementation | Difficulty |
|---|---|---|---|---|
| **Repel** (magick shield block) | Shield | Default | Fighter's Guard, re-themed: VSB core replacing `Job01_Guard` with a magick shield glow and magick-flavored block sound | Medium |
| **Reflect** (perfect block that sends magick back) | Shield | 3 / 1600 | Upgrades Repel: blocking magick projectiles sends them back. Uses Fighter's true deflect (`JustGuard`) window plus a reflection projectile | Hard |
| **Perfect block** (base mechanic) | Shield | — | Fighter's deflect/true-deflect windows (`HalfJustGuard 4` / `JustGuard 5`) become *the* trigger for all Counter/Riposte skills (§6.2) | Medium |
| **Onslaught** / **Dire Onslaught** | Sword | Default / 1:800 | DD2 Fighter already has Onslaught. Dire Onslaught = faster, harder version (speed + damage multiplier) bought at rank 1 | Easy |
| **Empale** / **Takedown** | Sword | Default / 1:600 | DD2 Fighter has an Empale-style thrust. Takedown adds a tackle follow-up (borrowed shoulder-check animation) | Medium |
| **Vault** | Sword | Default | DD2 jump plus the existing climb/mantle. Probably fine as is **[verify]** | Easy |
| **Controlled Fall** | Sword | 3:1200 | Enable Thief's `Job04_BreakFall` (id 17) core for Mystic Knight. Pactblade already does this | Easy |
| **Magick shield passive** | Shield | — | While Mystic Knight is active, the equipped shield gets a Magick value (from its Defense) and that Magick adds to sword hits, like DD1 magick shields. Same item-data technique as Pactblade's sword | Medium |

### Fighter shield cores we turn off
Fighter's own shield cores (Steeled Foundation, Enchanted Counter, etc.) are switched off while Mystic Knight is
active, so they don't overlap with ours. Exception: if DD2's Enchanted Counter (`EnchantGuard 8`) plays well with the
Counter skills, we may build on it instead **[verify]**.

---

## 6. Weapon skills

Each line is one VSB skill: **level 1 = DD1 base skill, level 2 = DD1 Greater version.** Ranks and costs follow DD1
and get scaled to DD2's Discipline curve later if needed.

### 6.1 Sword / mace skills (10 lines)

| # | Line (base → Greater) | DD1 rank/DP | What it does (DD1) | DD2 approach | Difficulty |
|---|---|---|---|---|---|
| S1 | **Blink Strike → Burst Strike** | Default → 3:600 | Rush the target for a powerful blow; Greater reaches farther | **DD2 Fighter has Blink Strike** (`Job01_BlinkStrike`). Reuse it; level 2 adds range and damage | Easy |
| S2 | **Broad Cut → Broad Slash** | 1:200 → 4:1000 | Wide cut that hops back out of danger; Greater can be steered | Wide-arc slash animation + backstep, steering on level 2 | Medium |
| S3 | **Sky Dance → Sky Rapture** | 1:400 → 4:1600 | Air kick into a forward charge-and-slash; Greater travels farther | Jump + air dash + slash chain (warp/move technique from Pactblade) | Medium |
| S4 | **Tusk Toss → Antler Toss** | 2:400 → 6:1600 | Upward arc that launches light foes; Greater lifts heavier foes and juggles | **DD2 has Tusk Toss** (`HumanNormalSkillID TuskToss 6`). Reuse it; level 2 raises weight limit and adds air hits | Easy–Medium |
| S5 | **Perilous Sigil → Ruinous Sigil** | 4:900 → 6:2000 | Draw a magick sigil on the ground that **explodes when enemies touch it**; Greater is bigger and lasts longer | Ground sigil effect (Sorcerer/Mage circle) + trigger area + explosion. Element follows your weapon enchant | Medium |
| S6 | **Funnel Sigil → Vortex Sigil** | 4:1400 → 6:2800 | Sigil that **pulls light foes together**; Greater is bigger and lasts longer | Same sigil base + a pull force on light enemies | Medium–Hard |
| S7 | **Magick Cannon → Great Cannon** | 4:1400 → 6:2800 | Summon a sigil that fires **seeking magick spellshot when hit** by your, your pawns' or enemies' attacks. About 18 s; damage scales with Strength *and* Magick and takes the weapon's enchant; Greater fires more shots | Floating sigil object + hit detection; each hit fires homing bolts (Sorcerer/Spearhand bolt projectiles). Disappears if you switch away from a sword (Warfarer) | Hard (*the* signature skill, top priority) |
| S8 | **Compass Slash → Full Moon Slash** | 5:1400 → 7:2000 | Spinning blade circle you can do while being hit; Greater hits wider and more often | **DD2 Fighter has Full Moon Slash** (`Job01_FullMoonSlash`). Level 1 = shorter spin, level 2 = full. Great at setting off Great Cannon, as in DD1 | Easy |
| S9 | **Downthrust → Downcrack** | 5:1400 → 7:2000 | Plant the blade for a short, strong thrust; Greater hits twice with more reach | Ground stab with a short shockwave; level 2 doubles it | Medium |
| S10 | **Stone Grove → Stone Forest** | 8:900 → 9:2000 | Channel magick into the ground to raise stone pillars; Greater raises more | Needs a stone pillar / ground eruption effect in DD2 (some monster or Sorcerer earth effects might work) **[verify]**. Hardest to source | Hard |

### 6.2 Magick shield skills (8 lines, 20 elemental variants)

DD1's counter, enchanter and trance skills came in five elements: **Fire, Ice, Thunder, Holy, Dark**. Each element
is its own skill, as in DD1, so players choose an element by choosing a skill. That's faithful but takes a lot of
skill entries; §8 covers the alternative.

| # | Line (base → Greater) | DD1 rank/DP | What it does (DD1) | DD2 approach | Difficulty |
|---|---|---|---|---|---|
| M1 | **Firecounter → Flame Riposte** | Default → 4:1200 | Hold the shield up: normal blocks stagger the enemy; a **perfect block shoots a fireball** that sets foes alight. Greater lasts longer and summons more fire | Counter stance = Guard with a timer. A deflect inside the window fires the element's projectile (Mage/Sorcerer fire shell) | Medium |
| M2 | **Icecounter → Frost Riposte** | 1:300 → 4:1200 | Perfect block **freezes** foes | Same frame, ice shell + freeze status | Medium |
| M3 | **Thundercounter → Thunder Riposte** | 1:300 → 4:1200 | Perfect block **calls down lightning** | Same frame, Levin-style strike on the attacker | Medium |
| M4 | **Holycounter → Blessed Riposte** | 1:300 → 4:1200 | Perfect block fires **homing holy light** | Same frame, homing holy bolts | Medium |
| M5 | **Darkcounter → Abyssal Riposte** | 1:300 → 4:1200 | Perfect block casts a dark pall that inflicts **Torpor** | Same frame, dark cloud + slow (Torpor). DD2 status for Torpor **[verify]** | Medium–Hard |
| M6 | **Demonspite → Demonswrath** | 2:900 → 3:900 | Damage you block is **turned into a magick bolt**; a perfect block makes a stronger one | Stored-damage counter: blocked damage builds up, released as a bolt on the next attack | Medium |
| M7 | **Holy Wall → Holy Fortress** | 2:900 → 5:2000 | Put up a broad magick barrier in front of you; Greater is broader and lasts longer | Fighter's Shield Summons / Divine Defense barrier is a likely base (`Job01_ShieldSummons`, `Job01_DivineDefense`) **[verify]** | Medium |
| M8 | **Holy Aid → Holy Grace** | 7:3800 → 9:6000 | Blocked damage **turns into Health**; more on a perfect block; Greater lasts longer | Timed buff + heal in the block hook | Medium |
| M9 | **(Element) Enchanter → (Element) Trance** ×5 | 5:1600 → 8:4000 | Enchant **your weapon and nearby pawns' weapons** with the element; Trance makes the enchant longer and stronger and boosts the recipients' Magick | DD2's Mage elemental boons for Fire/Ice/Thunder, cast on self + pawns in range. Holy and Dark need custom handling if DD2 has no boon for them **[verify]** | Medium (F/I/T), Hard (H/D) |
| M10 | **Dark Anguish → Abyssal Anguish** | 7:3800 → 9:6000 | Charge your weapon with dark magick: **extra hits and longer reach**, shield power added to the weapon; Greater adds a dark shockwave and lasts longer | Timed buff: sword swings spawn an extra dark slash wave (Spearhand's Magike Cut wave works as a base, recolored). Combos with Great Cannon (more hits = more spellshot), as in DD1 | Hard |
| M11 | **Holy Glare → Holy Furor** | 9:5000 → 9:7500 | Summon light beams that **seek out and hit** enemies around you; the whole party uses more stamina while it lasts; Greater is stronger and lasts longer | Timed aura spawning homing holy projectiles at nearby enemies + party stamina drain | Hard |

Count: M1–M8, M10 and M11 are 10 lines, plus 5 Enchanter/Trance lines = **15 shield skill lines**. Add the 10 sword
lines from §6.1 for **25 VSB skill entries** in total.

### 6.3 Staff skills

DD1 Mystic Knights could pick up a staff and use a small set of Mage-style spells (Ingle, Frazil, Levin, and their
High versions, plus a few more; the source lists conflict, **[verify]**). DD2's Fighter job can't hold a staff. The
options:

- **A. Skip the staff (recommended for v1).** Most Mystic Knight players in DD1 used sword + shield. The staff was
  a side mode, and its spells are what DD2's Mage already does.
- **B. Warfarer path.** VSB vocations can be used from Warfarer. A Warfarer with a staff could get the Mystic Knight
  staff spells. That's a later add-on.

---

## 7. Augments (7)

DD1 augments worked with any vocation. DD2's augments work the same way, but VSB support for *custom* augments is
**[verify]**. If VSB can't add them, the Lua script grants them while you have them "learned", saved in a mod
settings file.

| Augment | DD1 rank / DP | Effect | DD2 approach |
|---|---|---|---|
| **Fortitude** | 1 / 1200 | Less physical damage taken | Damage multiplier on incoming physical hits |
| **Adamance** | 2 / 1800 | Blocking with a shield costs half the stamina | Halve guard stamina cost |
| **Periphery** | 3 / 1800 | Keep your footing when blocking (less knockback) | Lower guard knockback |
| **Reinforcement** | 6 / 4000 | Pawns you help up take less physical/magick damage for a while | Hook on reviving/helping a pawn → timed defense buff on that pawn |
| **Retribution** | 6 / 4000 | Pawns you help up gain Strength/Magick for a while | Same hook → timed attack buff |
| **Sanctuary** | 8 / 6500 | Higher Defense/Magick Defense at low health | Low-HP check → defense multiplier |
| **Restoration** | 9 (Dark Arisen) / 7000 | Pawns you revive get more Health back | Revive hook → bigger heal |

---

## 8. Open design decisions (yours to make)

1. **Elemental skills: 5 separate skills each, or 1 skill + element choice?** Faithful = 5 separate Counter skills
   and 5 Enchanter skills, as in DD1. Simpler = one "Counter" and one "Enchanter" skill whose element follows your
   weapon's enchant or a mod setting. I lean faithful.
2. **Mace look.** DD2 swords include mace-like weapons. Do we want an actual mace model swapped in, or are swords
   fine? (Gameplay is identical; DD1 treated them the same.)
3. **Staff:** skip (A) or Warfarer add-on (B), §6.3.
4. **Discipline costs:** keep DD1 numbers as-is, or scale them to DD2's curve?
5. **Level-10 unlock gate:** faithful, but stops brand-new characters from trying it. Do we want an "unlock anyway"
   setting?

---

## 9. Build order (milestones)

| Phase | Content | Why first |
|---|---|---|
| **0. Groundwork** | VSB pack + empty Lua script; vocation appears in VSB menu and guild; skill entries with names/icons/costs; save-safety hooks | Proves the pipeline on Dark Arisen before any real work |
| **1. Shield identity** | Repel/perfect block re-theme, magick shield passive, **Firecounter** end to end | The core of the class. If perfect block → counter feels right, the rest follows |
| **2. Signature skills** | **Great Cannon**, **Ruinous Sigil**, Blink/Burst Strike, Full Moon Slash | The four everyone remembers; also the playable v0.1 |
| **3. Shield kit** | Remaining 4 counters, Demonspite, Holy Aid/Grace, Holy Wall, Enchanter/Trance ×5 | Fills out the shield side |
| **4. Sword kit** | Broad Cut, Sky Dance, Tusk/Antler Toss, Downthrust, Vortex Sigil | Fills out the sword side |
| **5. Late game** | Abyssal Anguish, Holy Glare/Furor, Stone Grove/Forest | Hardest effects |
| **6. Augments + growth** | 7 augments, DD1 stat growth | Balancing pass |
| **7. Polish** | Recolored effects/sounds (pak), icons, Nexus page, Fluffy zip | Release |

### Testing split
I can write the pack, the Lua and the docs, but I can't run DD2 from here. You test in-game and send me:
`re2_framework_log.txt` (in the game folder), screenshots or clips, and a description of what happened. Phase 0
needs one test session; each phase after that, a few.

---

## 10. File layout (planned)

```
mystic-knight/
├── PLAN.md                                   (this file)
└── MysticKnight/                             (Fluffy-ready mod folder)
    ├── modinfo.ini
    └── reframework/
        ├── autorun/
        │   ├── MysticKnight.lua              (main script: hooks, adapter, save safety)
        │   └── MysticKnight/                 (modules: shield.lua, cannon.lua, sigils.lua, counters.lua, ...)
        └── data/
            ├── MysticKnight.json             (default settings)
            └── VSB/packs/mystic_knight/
                ├── pack.json
                └── skills/mk_*.json          (25 skill entries)
```

---

## Sources
- VSB: https://www.nexusmods.com/dragonsdogma2/mods/1917
- Pactblade (VSB reference vocation, MIT): https://github.com/ntgoten/pactblade
- Skill Creator: https://www.nexusmods.com/dragonsdogma2/mods/1337
- Skill Maker: https://www.nexusmods.com/dragonsdogma2/mods/691 / https://github.com/alphazolam/Skill-Maker
- DD1 Mystic Knight: https://dragonsdogma.wiki.fextralife.com/Mystic+Knight
- DD1 Magick Shield Skills: https://dragonsdogma.wiki.fextralife.com/Magick+Shield+Skills
- DD1 Great Cannon: https://dragonsdogma.wiki.fextralife.com/Great+Cannon
