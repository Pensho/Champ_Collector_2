# Game Concept Document: Character Collector (Temporary name)

---

## 1. Introduction
This game is a turn based combat RPG. The main idea is to collect characters that the player can use in combat, each of them with slightly different skill sets to manage to defeat enemy encounters.

### 1.1. Design Pillar: The Blowout

This section outranks every other part of this document. Where another section conflicts with it, this section wins and the other section is wrong.

**The target emotion:** when a player assembles the right team and plays it correctly, they should suspect they broke the game. The reward for solving an encounter is not a comfortable win — it is an outcome so far past the requirement that it reads as a mistake in the player's favour.

There are two accepted forms of this, and they are sequential rather than alternative. The **realisation** ("that combination works together?") is the discovery; the **blowout** (the numbers it produces) is the payoff for executing it. An encounter delivers the realisation as its lock and the blowout as its reward. Neither is a substitute for the other, and an encounter that offers a realisation with no payoff has not met the pillar.

#### 1.1.1. Fight shape

Expected fight lengths in section 5.3 are unchanged: the pillar changes how damage is *distributed* across a fight, not how long the fight runs. Constant round budgets plus enormous numbers requires damage to be back-loaded.

A solved encounter therefore runs as **pressure and burst**: most of its rounds are spent building — placing effects, accumulating conditions, holding position — at unremarkable numbers, followed by one resolution that ends the fight. On a solved boss the burst accounts for the majority of total damage dealt, targeting 60–80%.

Two properties follow and must hold:

* **The threat curve peaks before the burst, not after.** The tension is "can I survive to the trigger", not "can I out-damage it". A burst that is guaranteed once set up is a cutscene.
* **Unsolved is a wall, not a slow fight, at Boss tier.** Without the combination there is no burst, and the remaining chip damage cannot finish the encounter inside its round budget. Fodder and mini-boss keep their own texture, per 5.3 — which is the tie-breaker on this bullet specifically, despite this section otherwise outranking the document.

#### 1.1.2. Where the blowout is legible

Enemy Health scales alongside player power, so the burst is never large relative to the enemy's Health bar. The contrast is read **inside the fight**, against the numbers the player saw during the build-up.

The calibration target is that a burst resolution deals **30 to 50 times** what the same champion's basic skill deals in the same fight, aiming at the upper end of that band. Per tier:

* **Fodder:** no dedicated burst. Blowout here is overkill on trash — encounters die to routine kit output.
* **Mini-boss:** one realisation, a partial burst, target around 10x.
* **Boss:** layered realisations, full burst, target 30–50x, preferring 50x.

These ratios are confirmed reachable through kit design. Against a boss-tier Defence of 120, a 50x burst needs a 50x multiplier on the scaled attribute aggregate — about six independent factors of 2x, ten of 1.5x, or four of 3x. Spread across a three-champion team under the composition law below, that is roughly two factors per champion, which normal kits can carry.

Enemy Health is the value that has to move. Against the balanced bosses (Health attribute 270–330, so roughly 1080–1320 hit points) a 50x burst lands at 150–284% of a boss — overkill, but not by an order of magnitude. For a burst to land as 60–80% of a boss, boss Health attributes need to roughly **triple** (2.1–4.1x, depending on the boss). A 30x burst needs roughly double (1.3–2.4x).

The ratios remain open to revision once the burst is playable and can be felt rather than computed. `Scripts/Debug/blowout_calibration.gd` recomputes all of the above when the formula or the presets change.

#### 1.1.3. The three damage channels

Blowout requires terms that grow independently and combine multiplicatively. Damage is produced by three channels:

1. **Scaled attributes (additive).** Attributes and gear accumulate into the skill's scaled attribute sum, as described in section 3.2.1. This channel grows steadily and stays readable, and it is the only channel a champion has access to without setup.
2. **Combined modifier (multiplicative).** Not a meter that is filled — a product assembled at the moment a skill resolves, from every damage-relevant condition true at that instant: buffs on the caster, debuffs and statuses on the target, zone effects, and skill-specific conditions. Each contributing source supplies **its own factor**, so satisfying a further condition multiplies the result rather than adding to it. A buff that raises an attribute instead feeds channel 1; a buff that modifies damage contributes a factor here.
3. **Cascade (count).** Effects that trigger off other effects, each producing its own resolution. A single action can therefore release many separate damage instances in sequence. Every instance carries its own combined modifier, so instance count and modifier size compound against each other.

**Enablers.** A fourth class of effect produces no damage at all: it creates or protects the window in which the three channels fire. Denying the enemy an answer (Blight against a healing boss), blocking an incoming effect that would break the setup (Aegis, Premonition), and buying a turn (Stun, Anchor) are enablers. They are not a damage channel and are not to be converted into one — section 1.1.1 requires the threat curve to peak before the burst, and enablers are what the player answers that threat with. A roster where every status touches damage carries fewer decisions, not more.

**Channel tag vocabulary.** Role passives (3.1.3), status effects (3.2.3), skills (3.2.4.2) and
reagents (3.3.3) are each tagged with the channel they belong to: **[Channel 1]** moves an
attribute, continuously and additively; **[Channel 2]** supplies its own factor to the combined
modifier; **[Channel 3 — Cascade]** triggers a separate resolution; **[Enabler]** does neither and
is judged by 1.1.6's collapse test instead. A double tag is dual classification on purpose — a
mechanism and a role can differ. A skill that only applies an already-tagged status inherits that
status's tags. `Scripts/Debug/kit_contribution_manifest.gd` holds the full ledger and the evidence
behind each tag.

**The composition law:** *contributions grouped by mechanic identity — buff type, debuff type, trait resource, skill effect — add into one factor; distinct mechanics form separate factors that multiply.* Character identity never enters the grouping: the same combination of mechanics scores the same whether one champion contributes all of them or three do, and adding a champion who contributes nothing relevant never changes the result. A single champion stays tame and readable on their own because their kit is usually a small number of distinct mechanics. Two or three kits whose effects contribute independent mechanics are where the fight detonates. Collection is therefore the source of the power fantasy — more kits means more distinct mechanics in play, not additional bodies multiplying the same one.

#### 1.1.4. Rules the channels must obey

* **Stack ceilings:** cap what accrues automatically; leave uncapped what costs the player an action or a resource. The existing capped passives (Momentum, Arcane Instability, Steel and Sea stacks) are correct as written — they accrue on their own. A resource the player deliberately builds may run without a ceiling.
* **Cascade termination:** every cascade must terminate, under two independent bounds. **Depth** bounds chain length — an effect triggered from inside a cascade instance sits one level deeper, and a chain able to re-enter itself is a defect, not a large number. **Fan-out** bounds how many instances one originating action may release in total, which depth does not constrain: many instances at the same level are breadth, not depth. The two do not substitute for each other.
* **A trigger fires once; the instances it yields are not separately re-triggered.** Each trigger source fires at most once per originating action, and that single firing yields an instance count. Repetition is therefore expressible without re-entry — an effect may deliberately resolve once per point of a status's remaining duration or once per remaining zone charge, and repeat instances are what make instance count multiply against the other two channels rather than add to them. A count read from a live quantity is fixed when the trigger fires, not re-read as the instances drain it.
* **The combined modifier multiplies the scaled attribute aggregate, not the final damage.** The placement is damage-equivalent either way, since Defence's mitigation ratio no longer depends on the aggregate (see the next bullet); it stays on the aggregate to keep one multiplicative pipeline, where the trait and ramp multipliers already apply.
* **Defence keeps its full percentage weight at burst scale.** Defence's mitigation ratio is taken against a fixed scale constant, not against the caster's own scaled aggregate, so a given Defence value cuts the same percentage of damage whether the hit is a basic swing or a burst: varying `Defense_Ignore_Factor` from 1.0 to 0.0 nearly doubles a burst's damage. Defence-ignore is a legitimate lever at every scale, not only on basic and mid-sized hits.
* **Base attribute values stay tame.** Growth belongs in the combined modifier and cascade channels. Inflating base attributes to chase the pillar breaks fodder tuning and Health-bar readability.
* **The combined modifier's boundary is the caster's scaled aggregate, not every damage-relevant term.** Three paths sit outside it by design, not as omissions to close later: target-side reductions (Spotlight's incoming-damage cut) apply to final damage, since pre-mitigation placement would make them stronger than intended; the crit path (Exposed_Facet, Cracked_Facet) stays its own, since crit chance saturates at 100 and crit damage is countered by target Knowledge; and Barrier absorbs after damage resolves.
* **The status-effect cap is eight, shared across buffs and debuffs.** Eight slots hold a mix of self-inflicted stacks, opponent debuffs, and ally buffs, several arriving with no cast at all (trait/graft/zone triggers). Assembling many distinct mechanics onto one target competes with your own stacks and with what the opponent has landed on you — a deliberate resource constraint, not to be raised or split by category. An application past the cap is denied outright (no application, no effect) rather than silently dropped, so the player can see why a status didn't land.

#### 1.1.5. Resolution and presentation

The burst is a mechanic, not an effect layer applied afterwards — how it resolves on screen carries as much of the emotion as the numbers do. A burst resolves as a **visible sequence**: each instance lands one at a time, attributed to its source, with the tempo and magnitude escalating through the cascade rather than flushing at once.

#### 1.1.6. Rejection test

Applied to every new mechanic, skill, item, and encounter:

> If a mechanic's best case is a linear improvement over not having it, it does not serve the pillar.

A mechanic passes one of two ways: by feeding one of the three channels in a way that multiplies with something else in the game, or by gating a burst that fails without it. A mechanic that only makes an existing number somewhat larger is rejected regardless of how well it fits the theme.

The second route is the enabler class in section 1.1.3, and it is held to the **collapse test**: removing the mechanic has to make the fight go materially differently — the burst does not happen, or does not survive to happen. An enabler that is merely useful to have fails, the same as a linear damage bump does.

---

## 2. Core Gameplay Loop
The core gameplay follows a cyclical "Prepare, Engage, Reward, Grow" loop designed to balance short-term satisfaction with long-term strategic planning.

### 2.1. The Loop Overview

**Preparation & Management:** The player manages their roster, equipping gear (Weapons, Off-hands, Boots) and selecting a team of characters whose Roles and Attributes (like Speed and Mysticism) complement each other.

**Resource Expenditure:** Players spend Energy (Food/Supplies) to enter different combat nodes, such as routine "Grind" maps, high-stakes Boss encounters, or God-themed Events.

**Turn-Based Engagement:** Players engage in combat where the Speed attribute determines turn order on the "turn bar."

- Routine Fights: Players use overwhelming power to clear enemies quickly for resources.

- Tactical Puzzles: Players must carefully time skills and manage Accuracy/Resistance to overcome specific boss mechanics.

**Reward Acquisition:** Victory grants Experience, Currencies (Area Unlocks/Thematic resources), and loot ranging from Common to Legendary rarity.

**Character Progression:** Players use rewards to Ascend characters, upgrade skills, and refine item affixes, increasing their power to unlock the next Tier of challenges.

### 2.2. Short-Term vs. Long-Term Loops
| Loop Type | Focus | Primary Activity |
|-----------|-------|------------------|
| Short-Term (Daily) | Efficiency | Spending Energy on routine fights to gather crafting materials and XP; completing daily God-themed events. |
| Mid-Term (Weekly) | Strategy | Solving "Puzzle" encounters and bosses to acquire Role-specific gear or rare Relics; participating in rotating God events (e.g., God of Rules’ floor dungeon). |
| Long-Term (Monthly) | Collection | Using Commissions of guilds to acquire new characters, completing faction-specific synergies, and uncovering the "Forgotten God" through world exploration. |


---

## 3. Core Mechanics
- Collecting characters
- Turn based strategic combat
- Bosses
- Gearing characters
- Upgrading character skills
- Energy system to restrict daily player activity
- Applying effects onto the turn bar. If a character stops within applied zones of the bar, certain effects trigger. The turn bar is split into a set of "zones" that can have effects applied to them through skills.
- Central hub area to manage characters, gear and access different game modes.

### 3.1. Champions
The terms Champion, Character, Hero are synonymous for the playable characters a player can acquire and use.
For now there are no Common Characters that are usable by a player.
There is a maximum level of 50, with a future idea to use duplicate heroes as a mean to increase it a few steps at most (or to upgrade skills).

#### 3.1.1. Character Attributes
Each character is defined by a set of core attributes:
*   **Primary Stats:** 
    * Health
        * Determines how much damage a character can take before being defeated.
    * Speed
        * Influences turn order in combat.
    * Attack
        * A common scaling attribute for damaging skills (see 3.2.1 "1. Damage Calculation" — every skill defines its own attribute weighting).
    * Defense
        * Reduces incoming damage from every skill, regardless of which attributes it scales with.
    * Accuracy
        * Affects the likelihood of successfully landing debuffs or status effects on enemies.
    * Resistance
        * Reduces the chance of receiving debuffs or status effects.
    * Mysticism
        * A common scaling attribute for damaging skills, alongside Attack (see 3.2.1 "1. Damage Calculation").
    * Knowledge
        * Increases the effect of ally turn bar zones placed by this character. Also reduces critical damage taken.
    * Critical chance
        * The likelihood of landing a critical hit, which deals increased damage.
    * Critical damage
        * The multiplier applied to damage when a critical hit occurs.
* **Secondary attributes:**
    * Level
    * Experience
    * Skill levels
    * Role
    * Faction
    * Rarity
    * Name
    * Rank

#### 3.1.2. Progression Systems
* Ascension
    * Lets a character be upgraded beyond max level using duplicate characters, unlocking a new passive or stat ceiling.
* ~~Aura~~
* Synergy through combination of faction or characters
* Area?
* Home base upgrades?
* ~~Clan~~
* Events

#### 3.1.3. Character Role
Each character role should define a baseline for a character but not necessarily the specifics of it. It will restrict which skills it could use as well as define its starting primary attributes.

A role is not a 1 to 1 map of a character, it is a field to help describe the character. Much like any other field populated.

Each Role can have one or two main purposes in combat but it doesn't have to restrict their kit of skills. The types:
- Damage
    - Revolves around either or both relying on other characters or by themselves to deal significant amounts of damage onto the opponents.
- Sustain
    - The intent of the sustain purpose is to keep ally characters alive, either or both through being able to tank incoming damage or healing through buffs or abilities.
- Debuffer
    - Applies various debuffs to enemies to either make them weaker, take more damage, become slower etc. So to make the encounter easier by affecting opponents.
- Control
    - Manipulates turn order, skill availability or targeting of skills.
- Buffer
    - Applies various buffs to allies to make them stronger.

**Sustain, Control, and denial purposes are discharged through the enabler class of section
1.1.3.** They reach the burst rather than build it, so a Role carrying one of them needs no damage
channel allocated on that purpose's account. Those skills must be **authored with intent and
counted as kit content**, each held to 1.1.6's collapse test: a Role that fills all three slots
with damage while its declared Sustain or Control purpose goes unserved has failed its Role,
whatever its damage channels score.

A Role's contribution also has a **direction** — self-facing when its kit's value shows up in its
own output, exported when the value shows up on teammates, whether as a damage factor they carry or
as the window they survive in. Both are load-bearing; the intended per-Role allocation across the
roster lives in `Role_Kit_Design.md` section 5.

Every Role passive below carries a channel tag (see 1.1.3's tag vocabulary).

Current roles, their identity and purpose exist as follows:
- Emissary
    - A field agent of the Iron Ledger who wins by building a case against the enemy rather than overpowering them. Keeps a per-enemy tally of Infractions (see the Standing Record passive) and issues Edicts — formal rulings whose severity is read off the target's Infraction tally. Punishment effects stay gradual rather than binary: no hard skill sealing or turn bar manipulation; instead buff duration reduction, resistance bypass, and attribute sanctions, all scaling with the target's Infraction count. Primary attributes: Accuracy, Knowledge.
    - Purpose: Debuffer, Control
    - Passive: Standing Record [Enabler] - Every enemy has a personal Infraction tally that only grows and is never consumed. An enemy gains one Infraction whenever they gain a buff, place a zone, land a debuff on an ally, or has one of their own buffs stripped to zero duration by Signed Writ. The tally is counted up to a cap of 9 for skill effects. The passive owns a rarity-dependent rate per Infraction on the target; a skill may state its own multiple of that rate, never a rate of its own.
        - 2.5% per Infraction Uncommon, 3% Rare, 3.5% Epic, 4% Legendary
    - Fielded by: `Emissary.tres`
- Thief
    - A squishy damage dealer, focusing on set-up through skills and bypassing enemy defenses. Primary attributes: Attack.
    - Purpose: Damage.
    - Passive: Between the Plates [Channel 1] - Every attack ignores a percentage of the target's
      Defense, subtracted in points after every other Defense modifier has applied.
        - 12% Uncommon, 16% Rare, 20% Epic, 25% Legendary
    - Fielded by: `Thief.tres`
- Lancer
    - A shock cavalry fighter who reads distance on the turn bar and turns it into a heavier hit, at the cost of its own tempo. Primary attributes: Attack, Speed.
    - Purpose: Damage
    - Passive: Couched Lance [Channel 2] - Rending Charge deals x% more damage per turn-bar section between the Lancer and its target (counting both their own sections, so the same section is 1 and opposite ends of the bar is 5), then throws the Lancer back 10% of the turn bar per section charged.
        - +9% per turn-bar section Uncommon, +12% Rare, +15% Epic, +18% Legendary
    - Fielded by: `Centaur_Lancer.tres`, `Knight.tres`
- Alchemist
    - A support character that focuses on buffing allies and debuffing enemies through various concoctions. Signature zone: Catalyst Cloud (see section 3.2.4.1). Primary attributes: Knowledge, Mysticism.
    - Purpose: Debuffer, Buffer
    - Passive: Fresh Batch [Enabler + Channel 2] - At the start of combat the Alchemist brews one concoction: a reagent drawn at random from an Alchemist-exclusive pool, occupying its own slot beyond the three brought reagents. It follows normal reagent rules (consumable once, by any champion, on their turn) except that it is never added to the inventory - if unconsumed when the battle ends, it is lost. Each fielded Alchemist brews their own concoction. Whenever any ally, the Alchemist included, consumes a reagent (brewed or brought), the whole team gains a damage buff for 2 turns, under the Alchemist's own bucket key (distinct from Fractured Idol's reagent damage bonus, so the two multiply rather than add).
        - Brew potency: 90% Uncommon, 100% Rare, 110% Epic, 120% Legendary (relative to a standard reagent of equivalent effect); the brew pool holds 3 lesser reagents at Uncommon and Rare, 4 at Epic and Legendary (see section 3.3.3)
        - Brews are self-targeted (the consumer is always the recipient). Magnitudes: Lesser Restorative Brew heals 10% of max Health; Lesser Tincture grants +5% to one random primary attribute, battle-long; Lesser Barrier Brew grants a Barrier absorbing 40% of max Health; Lesser Purging Brew (Epic/Legendary pool only) removes 1 debuff.
        - Team damage buff: 20% Uncommon, 23% Rare, 26% Epic, 29% Legendary.
    - Fielded by: `Alchemist.tres`
- Sorcerer
    - A damage dealer that harnesses the power of magic to deal Area of Effect damage and control the battlefield. Wields the unstable, shunned magic left behind by the God of Magic, and excels at drawing power from reagents scavenged from that era's ruins. Signature zone: Unstable Rift (see section 3.2.4.1). Primary attributes: Mysticism, Knowledge.
    - Purpose: Damage, Debuffer, Control
    - Passive: Arcane Instability (implemented) [Channel 3] - Using any skill grants one Instability stack (maximum 5); stacks do not persist between combats. Consuming a reagent grants two stacks, amplifies the reagent's effect, and grants one Echo charge. At maximum stacks the next skill also releases a Surge — damage to every character, the Sorcerer included, scaling 1.4x with the Sorcerer's Mysticism, never a critical hit — then stacks reset and one Echo charge is granted, banked for the following cast. Each Echo charge makes the next skill repeat once more, all charges consumed when it does, each Echo compounding on the previous; a repeated debuff or zone charge is not reapplied, only the damage. A cast that placed a zone instead has each Echo amplify that zone (see Unstable Rift, section 3.2.4.2).
        - Echo compounding: 1.40 Uncommon, 1.50 Rare, 1.60 Epic, 1.70 Legendary
        - Reagent amplification: 20% Uncommon, 30% Rare, 40% Epic, 50% Legendary
        - First Echo fraction: 50% at every rarity
        - Echo zone amplification: 15% per Echo, compounding, at every rarity
    - Fielded by: `Sorcerer.tres`
- Scholar
    - A support character that focuses on knowledge and strategy to enhance allies' abilities and exploit enemy weaknesses. The zone-clearing specialist: the Scholar's kit is one of the two dedicated ways to remove zones from the turn bar (see section 3.2.4.1). Primary attributes: Knowledge.
    - Purpose: Debuffer, Buffer
    - Passive: Field of Study [Channel 2, exported] - Every attribute buff or debuff the Scholar's team applies is amplified additional percentage points: Uncommon 7%, Rare 8%, Epic 9%, Legendary 11%. Critical Chance and Critical Damage are excluded.
    - Fielded by: `Centaur_Archivist.tres`
- Diviner
    - A squishy support.  Primary attributes: Mysticism.
    - Purpose: Sustain, Debuffer
    - Passive: Foresight [Enabler] - Place debuffs on enemies if they are close enough behind the Diviner on the turn bar when the Diviners turn starts. Applies Enfeeble for 1 turn, with no resist roll (symmetric to the Tactician's Plan applying Empower).
        - 10% Uncommon, 15% Rare, 20% Epic, 25% Legendary
    - Fielded by: `Diviner.tres`
- Appraiser
    - A master at exploiting enemy weaknesses, allowing opportunity for the team to easily deal critical hits. Primary attributes: Critical Chance, Knowledge.
    - Purpose: Debuffer, Buffer
    - Passive: No Wasted Margin [Enabler] - Team-wide. For every percentage point of an ally's Critical Chance above 100, that ally gains Critical Damage instead of the excess being discarded: 2 percentage points Uncommon, 3 Rare, 4 Epic, 5 Legendary.
    - Fielded by: `Appraiser.tres`
- Tactician
    - A squishy support. Primary attributes: Knowledge, Speed.
    - Purpose: Buffer
    - Passive: Plan [Channel 1] - Gives buffs to allies who are within x% behind the Tactician on the turn bar when their turn starts. Applies at every rarity; only the Tactician's own self is excluded.
        - 10% Uncommon, 15% Rare, 20% Epic, 25% Legendary
    - Fielded by: `Tactician.tres`
- Symbiote
    - A character weak by default, able to permanently graft itself onto an enemy in battle to gain that enemy's graft effect and an attribute bonus at the cost of a drawback. Primary attributes: Health, Resistance.
    - Purpose: Sustain, Buffer
    - Passive: Graft [Channel 1, mechanism only — the bound graft effect's own channel is
      pool-dependent, see `Symbiote_Graft_Pool.md`] - The Symbiote begins ungrafted and comparatively weak. Once per lifetime, during any battle and as a free action, the Symbiote may target a living enemy and graft onto it, confirmed through a warning that the choice is permanent. Grafting is irreversible: it binds that enemy's graft effect to the Symbiote for the rest of its existence, and can never be undone or replaced. A graft grants the Symbiote its bound effect, a bonus to attributes, and a drawback; the effect and attribute bonus scale with the Symbiote's own rarity, while the drawback does not. A graft takes hold immediately. Once grafted, the graft option is no longer offered for that Symbiote.
    - Fielded by: `Symbiote.tres`
- Jester
    - An unconventional tanking character that does not have significantly high Health or Defense but relies on skills that provoke hits to the Jester and dodge them. Primary attributes: Accuracy, Knowledge, Speed.
    - Purpose: Damage, Sustain
    - Passive: "Double the fun!" [Enabler] - A base 5% chance to completely avoid the damage of an incoming attack (debuffs from the attack still land). Each hit that lands instead of being avoided increases the chance by a rarity-dependent amount, up to 3 stacks: Uncommon +3%, Rare +4%, Epic +5%, Legendary +6% per stack. Avoiding damage resets the chance to the 5% base. Increases the chances of being targeted.
    - Fielded by: `Jester.tres`
- Cultist
    - Consumes ally buffs or health to empower their own skills, dealing damage or applying debuffs. Primary attributes: Mysticism, Attack.
    - Purpose: Debuffer, Damage
    - Passive: Chosen Vessel [Channel 1 + Channel 2] - At the start of combat the Cultist marks a random ally (the Cultist excluded) as their Vessel. Whenever the Cultist uses a non-basic skill, the Vessel loses 5% of their max Health and the skill gains a rarity-dependent power bonus. The drain can kill the Vessel. When the Vessel dies (from any source), the Cultist gains the Attune buff for 3 turns (see section 3.2.3.2), a new random ally is marked as the Vessel if any is alive, and the Cultist permanently gains Devotion: a rarity-dependent damage bonus for the rest of the fight, in its own bucket, uncapped and never spent. If all allies are dead then nothing happens.
        - Power bonus: 15% Uncommon, 20% Rare, 25% Epic, 30% Legendary
        - Devotion bonus: 10% Uncommon, 13% Rare, 16% Epic, 20% Legendary
    - Fielded by: `Cultist.tres`
- Bar Brawler
    - A health focused character, dealing damage, tanking and applying a few buffs. Attacks scales of health primarily. Primary attributes: Health.
    - Purpose: Sustain, Buffer
    - Passive: "On the House!" [Enabler] - Whenever the Bar Brawler gains a buff, from any source, he shares a round: all living allies (the Bar Brawler included) heal a rarity-dependent percentage of their own max Health. The round is poured at most once between each of the Bar Brawler's turns - further buffs gained before his next turn do not trigger it again.
        - Heal per round: Uncommon 6%, Rare 7%, Epic 8%, Legendary 9%
    - Fielded by: `Bar_Brawler.tres`
- Bloodmage
    - Spending their own or allies health for big pay-off skills in terms of damage or applying shields based on sacrificed health. Primary attributes: Health, Mysticism.
    - Purpose: Sustain, Damage
    - Passive: Hemoclarity [Channel 1] - For every 1% of max Health missing (capped at 80%), gain increased Mysticism, and the same percentage increases all healing and Barrier absorption the Bloodmage creates.
        - Per 1% missing: 0.7% Uncommon, 0.8% Rare, 0.9% Epic, 1.0% Legendary
    - Fielded by: `Bloodmage.tres`
- Herald of the loom
    - A stance character whose three threads shape how its cascade instances and debuffs behave. Primary attributes: Mysticism, Accuracy.
    - Purpose: Debuffer, Buffer
    - Passive: Weft and Warp [Channel 3 — Cascade] - The Herald always holds exactly one thread, starting on Silver at battle start; switching is a free action available any number of times during the Herald's own turn, and the active thread persists as ordinary trait state (not a status effect) until changed again. Golden Thread: gain 1 Tension (capped at 7) whenever a cascade instance resolves on an enemy, Cut the Cloth's own instances excluded. Silver Thread: the Herald's own applied debuffs cannot be resisted and last 1 turn longer. Black Thread: the cascade instance produced by the Herald's own action resolves one additional time. Cascade instances the Herald produces deal bonus damage.
        - Self-bonus: +5% Uncommon, +10% Rare, +15% Epic, +20% Legendary
        - Starting Tension: 0 Uncommon/Rare, 1 Epic/Legendary. Tension does not persist between combats.
    - Fielded by: `Herald_of_the_loom.tres`
- Chronophage
    - A speed focused character, applying various speed modifying skills onto the turn bar and primarily deals damage based on the Speed attribute. Signature zones: Flicker Zone and Temporal Sinkhole (see section 3.2.4.1). Primary attributes: Speed.
    - Purpose: Control
    - Passive: Time Tithe [Channel 3 — Cascade] - When the Chronophage's skills remove or reduce an enemy's turn bar, the Chronophage absorbs a portion of the stolen amount as its own turn-bar progress. When the Chronophage's effects move an ally forward on the turn bar and no other ally (the Chronophage included) is in that ally's turn-bar section, the ally gains Borrowed Time for 1 turn (see section 3.2.3).
        - Tithe: 25% Uncommon, 35% Rare, 45% Epic, 55% Legendary
        - Borrowed Time strength: 30% Uncommon, 40% Rare, 50% Epic, 60% Legendary
    - Fielded by: `Chronophage.tres`
- Architect
    - A methodical charge & support character aligned with the God of Rules. Instead of raw aggression, they construct "Logic Chains" over the course of battle, eventually "solving" the encounter with a massive structural shift. Primary attributes: Knowledge, Defense.
    - Purpose: Buffer, Damage
    - Passive: Calibration [Channel 1 + Channel 2 + Enabler] - The Architect accumulates Calibration charges (maximum 12; charges do not persist between combats). Basic skills grant one charge, and the Architect's constructed zone (Raise the Frame) generates one charge per character that uses it. The Architect's non-basic skills consume charges and scale with the amount consumed: a few charges empower defensive ally buffs, while the finisher consumes all held charges and resolves in tiers - 1-4 charges deal damage only, 5-8 add a structural effect on top of the damage, 9-12 additionally re-erect the Architect's construction zone for free. Tier thresholds are fixed across rarities; rarity scales per-charge potency.
        - Per-charge potency: 4% Uncommon, 6% Rare, 8% Epic, 10% Legendary
    - Fielded by: `Architect.tres`
- Tidal Corsair
    - Damage dealer. Primary attributes: Attack, Speed.
    - The Tidal Corsair is a Combo character where you plan your moves ahead, highly mobile but not inherently strong unless you set up your attacks correctly.
    - Purpose: Damage
    - Passive: Wrangle the Sea [Channel 2 + Enabler] - Boarding Strike grants a Steel stack, Saltwater Shot grants a Sea stack (up to 3 held). Corsair's Reckoning consumes all stacks and resolves by composition: Steel only (Broadside) adds bonus damage per Steel stack; Sea only (Bring Her Alongside) raises or resupplies The Gilded Deck at 2 charges per Sea; mixed (Boarding Party) deals base damage, adds 1 Deck charge per Sea (capped at 2), and grants every other living ally Slipstream and Empower for 2 turns. An ally whose turn starts on the Deck gains a permanent Sea Legs stack, boosting their own highest primary attribute (not Health), scaled by the Corsair's Knowledge, capped at 4.
        - Damage per Steel stack: 45% Uncommon, 50% Rare, 55% Epic, 60% Legendary
        - Sea Legs bonus per stack: 5% Uncommon, 6% Rare, 7% Epic, 8% Legendary
        - Known bug: the in-combat Sea Legs tooltip has been observed showing a lower percent on a
          later stack than an earlier one on the same standing deck. The resolver's own stacking
          math and emitted `CombatResult` are confirmed correct (`Role_Kit_Design.md` section 9.13);
          the defect is somewhere in the live UI rendering, unreproduced outside actual play.
    - Fielded by: `Tidal_Corsair.tres`
- Plague Doctor
    - A debuff focused character, applying various damage over time and stat reducing debuffs to enemies. Signature zone: Miasma (see section 3.2.4.1). Primary attributes: Mysticism, Resistance.
    - Purpose: Debuffer
    - Passive: Comorbidity [Channel 3] - Debuffs placed by the Plague Doctor's skills trigger a cascading extra tick once for every other distinct debuff type present on the target (any source, uncapped, subject to the shared cascade fan-out cap in section 1.1.4). Total damage per turn is unchanged from a flat multiplier — the difference is that each repeat resolves as its own cascade instance, visible to other Channel 3 effects that react to cascade instances.
        - Known gap: the zone-trigger debuff path (used by Miasma's Blight) does not thread the
          Comorbidity flag, so Blight itself never repeats — only debuffs placed by non-zone
          skills (e.g. Outbreak's Plague) do. See `Scripts/Debug/kit_contribution_manifest.gd`
          (Comorbidity entry) and `apply_debuff_effect.gd`'s zone-trigger branch.
    - Fielded by: `Plague_Doctor.tres`
- Warlord
    - A buffing tank character, applying various buffs to self and allies while being able to take a lot of damage. Primary attributes: Health, Defense.
    - Purpose: Sustain
    - Passive: Shield Wall [Enabler] - When an ally within 15% of the Warlord on the turn bar (in front or behind) takes attack damage, a portion of that damage is redirected to the Warlord instead. Proximity is checked at the moment the damage lands. Redirected damage is mitigated by the Warlord's Defense, not the ally's. AoE attacks are soaked separately for each affected ally within the window.
        - Redirected portion: 15% Uncommon, 20% Rare, 25% Epic, 30% Legendary
    - Fielded by: `Warlord.tres`

### 3.2. Combat
The player fields a team of up to 3 characters in a battle. The party is ordered left to right, in the order the characters are picked in the pre-battle menu; some skills target by battlefield position (see the targeting types in section 3.2.4). Combat is turn based, using the Speed attribute of each character to move a representation across a "turn bar". When a characters representation has crossed the entire bar, the game will pause for input to resolve their turn and then finish by putting the representation of the character back to the beginning. Then the system keeps going.

<br/>

There will be two types of combat, sharing all the core systems but one adds another layer of difficulty.

The first is simple fights to be routine and grind options to add to a players power fantasy, usually not requiring a specific combination of characters/skills but rather a numeric check of characters levels/gearing.

The second type is the main challenge in the form of puzzle of sorts. Each encounter should require one of two or three combinations of specific skills to defeat, or a significantly larger value of character levels/gearing than expected of the encounter.

Before a battle the player sees the enemy composition, not the enemies' skills. In battle, enemy passives are not inspectable (unlike the player's own): the player learns enemy mechanics by observing them in play, and that knowledge carries into later encounters that re-use the same enemy variants.

<br/>

After a combat event, the players characters are healed to full and their skill cooldowns reset. They are given some kind of reward, usually in terms of experience and sometimes equipment.


#### 3.2.1. Combat Formulas
##### 1. Damage Calculation
Damage is ratio-based rather than subtractive: the attacker's scaled attributes are weighed
against the defender's Defence to produce a mitigation percentage, so no hit is ever fully
negated by a stat gap.

```
Combined_Modifier = Π over every damage-relevant condition true at resolution (its factor)
Caster_Scaled = Σ over the skill's weighted attributes (attribute_weight * Caster's attribute) * Combined_Modifier
Effective_Defence = Defender's Defence * Skill's Defense_Ignore_Factor
Damage_Ratio = Caster_Scaled / (Effective_Defence + Caster_Scaled + 1)
Mitigation = Minimum_Damage_Percent + (1 - Minimum_Damage_Percent) * Damage_Ratio
Damage = Mitigation * Caster_Scaled * Critical_Multiplier * Random_Multiplier
```

- Every skill defines its own attribute weighting rather than a fixed Attack/Mysticism split,
  so a skill can scale off any mix of attributes (e.g. a Speed-scaling strike, or a hybrid of
  Attack and Knowledge) — there is no fixed damage-type split, only per-skill weighting.
- `Defense_Ignore_Factor` is a per-skill dial (0.0-1.0) for bypassing Defence — an armor-piercing
  skill sets it below 1.0, and 0.0 ignores Defence entirely.
- `Minimum_Damage_Percent` is a mitigation floor: no matter how far Defence outstrips the
  attacker's scaled attributes, every hit still chips away at the target.
- `Combined_Modifier` is the multiplicative channel described in section 1.1.3: one factor per
  contributing mechanic (caster buffs, target debuffs and statuses, zones, skill conditions),
  multiplied together at resolution time rather than accumulated into a stored value. It multiplies
  `Caster_Scaled` before `Damage_Ratio` is computed, per section 1.1.4 — not the final damage
  product — so it is the term the blowout is built out of.
- `Random_Multiplier` keeps a range of 0.95 to 1.05, preventing every hit from being the exact
  same value.

##### 2. Turn Order and Speed
Turn order is not resolved once per round; each character moves continuously along a turn bar
(see the combat overview above) at a rate proportional to their Speed relative to the fastest
combatant in the fight, and acts the instant they reach the end. A character with double
another's Speed reaches the end roughly twice as often, rather than simply going first — Speed
is a rate, not a priority ranking.

##### 3. Debuff and Status Effect Application
Main attributes: Accuracy and Resistance.

**Debuff Success Rate Formula:**
```
Contest = Caster's Accuracy * Random_Multiplier_A vs Target's Resistance * Random_Multiplier_B
```
- Both sides roll an independent random multiplier (0.85 to 1.0) against their stat; the debuff
  lands if the caster's rolled Accuracy exceeds the target's rolled Resistance.
- There is no base chance and no floor or ceiling: a sufficiently large Accuracy-Resistance gap
  makes a debuff land (or resist) with effective certainty. Encounters that rely on a debuff as
  the intended solution must be tuned so that counter-play's Accuracy beats the target's
  Resistance.

Accuracy is therefore a key stat for the Emissary and Jester, who rely on disrupting enemies rather than on raw damage, and high Resistance is what keeps a tank like the Warlord from being crippled by debuffs.

##### 4. Critical Hits
Critical Chance and Critical Damage are primary attributes, rolled per hit rather than fixed
per character.

**Critical Hit Chance Formula:**
```
Crits if: random_integer(1, 100) <= Attacker's Critical Chance
```

**Critical Damage Formula:**
```
Critical_Multiplier = max(Minimum_Crit_Damage, Attacker's Critical Damage - Defender's Knowledge * 0.5)
```
- A defender's Knowledge blunts incoming critical hits, giving Knowledge-scaling roles (Scholar,
  Appraiser, Architect) a secondary defensive niche.
- `Minimum_Crit_Damage` ensures a critical hit always deals meaningfully more damage than a
  normal hit even against a very high-Knowledge defender.

##### 5. Enemy Target Selection

**Targeting Priority Formula:**
```
Priority = (Health + Defence) * Trait_Weight_Multiplier * Buff_Weight_Multiplier
```
- Enemies attack the highest-priority character their skill can legally target, recomputed at the
  start of every turn. Selection is an ordering, not a chance roll — the same character stays the
  target until the ordering changes.
- The baseline is durability, so building a tank is what draws fire. Trait and buff multipliers
  (Spotlight's 1.5x) shift a character up or down that order; multiple multipliers combine.

#### 3.2.2. Magic system (only as a potential idea, might be discarded)
Strengths and weaknesses.
Most often require;
* Powerful reagents (consumable loot? Some reference to the 3rd god?)
* Chants (discoverable in e.g. ruins or hidden religious pagan texts, also reference to the 3rd god?)
    * The player might choose x numbers of chants to bring onto an adventure?
* Environmental conditions

#### 3.2.3. Status Effects
A status effect is a temporary condition that can affect a character's attributes, abilities, or behavior in combat. Status effects can be beneficial (buffs) or detrimental (debuffs) and can significantly influence the outcome of battles.

An attribute-modifying status holds its effect continuously for its whole duration: it affects
every relevant calculation, not only the holder's own turn or moments when the holder is
directly targeted. A Defense buff lowers incoming damage between the holder's own turns just as
much as a Speed buff changes how fast the holder advances on the turn bar.

Unless stated otherwise, a buff or debuff lasts 2 turns.

Status effect descriptions are surfaced to the player in two places: a press-and-hold
tooltip on each status icon during combat, and a browsable glossary tab in the Hollow
Ledger. Both read the same static, authored description per effect.

Every status effect below carries a channel tag (see 1.1.3's tag vocabulary); Blind and Warped are
the dual-classified cases.

##### 3.2.3.1 Turn Bar Effects
* Anchor (Debuff) [Enabler]: The character cannot be pushed forward or backward on the turn bar by skills.
* Temporal Leak (Debuff) [Channel 2]: Every time this character moves 10% of the bar, they take damage equal to 5% of their own Speed, multiplied by the applier's damage-scaling factors (the same channel-2 factors that scale their attacks) as they stood at the moment the debuff was applied.
* Dead Weight (Debuff) [Enabler]: When the character takes damage from an attacker, they lose 3% turn bar.
* Slipstream (Buff) [Enabler]: The character passes through enemy-placed zones without triggering them.
* Steadfast (Buff) [Enabler]: The character cannot be moved backward on the turn bar.
* Resonance (Buff) [Enabler]: Ally-placed zones affect the character at double effect.
* Battle Orders (Buff) [Enabler]: When the character takes damage from an attacker, all allies gain 5% turn bar.

##### 3.2.3.2 Common Status Effects

Debuffs:
* Expose Weakness [Channel 1]: Reduces Defense, by a fixed amount or an amount its applier sets. Defence keeps its full percentage weight at burst scale (section 1.1.4), so every attacker against the holder benefits, at burst magnitudes as much as during build-up.
* Enfeeble [Channel 1]: Reduces the Attack by 30%.
* Mana Burn [Enabler]: Deals damage whenever the target uses a non-basic skill, scaling based on the target's Mysticism. The damage is incidental to the punish; it is not a combined-modifier factor.
* Burning [Enabler]: Deals a rolled 2-10% of max Health as damage per stack (mean 6%), biased by the holder's Luck or Hexed; Burning stacks, so repeated applications (e.g. standing in a Lava zone) add independent instances up to the status-effect cap. Its composable value is as a debuff *type* other mechanics key off (Opportunist, and any effect counting distinct debuff types on the target), not a factor of its own.
* Sequence Lock [Enabler]: Speed cannot be increased or decreased.
* Suppress [Channel 1]: Reduces Mysticism by 30%.
* Slow [Channel 1]: Reduces Speed by 15%, including how fast the character advances on the turn bar.
* Blind [Channel 1 / Enabler]: Reduces Accuracy by 30%.
* Unravel [Channel 1]: Reduces Resistance by 30%.
* Confound [Channel 1]: Reduces Knowledge by 50%.
* Exposed Facet [Channel 2]: Attacks against the character gain +15 percentage points Critical Chance. Contributes through the crit path (section 1.1.4) rather than the combined modifier itself.
* Cracked Facet [Channel 2]: Critical hits against the character deal bonus Critical Damage equal to 60% of the applier's own Knowledge, snapshotted at application. Same crit-path note as Exposed Facet.
* Consigned [Channel 1]: Critical Chance and Critical Damage are reduced to zero.
* Bleed [Channel 1 + Channel 2]: At the start of the character's turn, they take damage equal to 40% of the caster's Attack, multiplied by the caster's damage-scaling factors, both snapshotted together at the moment of application.
* Plague [Channel 1 + Channel 2]: Deals damage each turn equal to 30% of the caster's Mysticism, multiplied by the caster's damage-scaling factors, both snapshotted together at the moment of application. Stacks, and each stack ticks independently.
* Blight [Enabler]: Healing received is reduced by 50%.
* Severance [Enabler]: The character cannot gain new buffs.
* Hexed [Enabler]: Roll every chance roll in combat twice and take the worse result (the damage-variance roll is not favored either way — its spread is too small to matter).
* Stun [Enabler]: The character skips their next turn.
* Fatigue [Enabler]: The character's skill cooldowns do not tick down.
* Refracted [Enabler]: The character's single-target skills hit a random character instead, allies included.
* Warped [Channel 1 / Enabler]: The character's damage dealt scales with Mysticism instead of the skill's normal attribute — damage-scaling only; non-damage calculations (healing, absorb values, turn-bar effects) stay on their native attribute. Dual-classified: channel 1 by mechanism, since it re-points which attribute channel 1 reads rather than adding a term of its own; enabler by role, since forcing a target's real damage through an attribute it's weak in is denial that protects the team, not a passive attribute swap.
* Signed Writ [Enabler]: The character cannot resist debuffs.
* Sanction [Channel 2]: Attacks against the character deal +2x the applier's Standing Record rate per Infraction on the target, and all primary attributes except Health are reduced by 0.5x that rate, both set at the moment of application (see the Emissary's passive in section 3.1.3). Readable by any attacker, not only the applier's.
* Hemorrhage [Channel 2]: Attacks against the character deal +6% damage per 10% of the character's own missing Health. Readable by any attacker, not only the applier's.

Buffs:
* Empower [Channel 1]: Increases Attack by 30%.
* Fortify [Channel 1]: Increases Defense by 30%.
* Daunting Strength [Channel 2]: Doubles the damage of the next attack. Consumed the moment that attack resolves, so it cannot bank a second bonus across a turn where the holder is stunned or casts a non-damaging skill.
* Frenzy [Channel 1]: Increases Attack and Speed by 30% but reduces Defense and Accuracy by 30%.
* Rush [Channel 1]: Increases all primary attributes except Health by 30%; when the buff expires, it applies the Stun debuff to the character for 1 turn. This Stun cannot be resisted and is applied after other expiring buffs (such as Aegis) are removed.
* Exhert [Channel 1]: Increases all primary attributes except Health by 20%, but the character loses 5% of their max Health every time they take a turn.
* Luck [Enabler]: Roll every chance roll in combat twice and take the better result (the damage-variance roll is not favored either way — its spread is too small to matter).
* Phalanx Guard [Channel 1]: Gain bonus defense.
* Attune [Channel 1]: Increases Mysticism by 30%.
* Haste [Channel 1]: Increases Speed by 20%, including how fast the character advances on the turn bar; Haste stacks, so repeated applications add independent instances up to the status-effect cap.
* True Aim [Channel 1]: Increases Accuracy by 30%.
* Clarity [Channel 1]: Increases Resistance by 30%.
* Keen Edge [Channel 1]: Increases Critical Chance by the applier's own Critical Chance, snapshotted at application.
* Insight [Channel 1]: Increases Knowledge by 30%.
* Regeneration [Enabler]: Heals 4% of max Health at the start of each turn. Sustained self-healing is buying time to survive to the trigger, the same shape as Stun/Anchor buying a turn, only continuous and self-directed.
* Barrier [Enabler]: A shield that absorbs damage up to a set amount before Health is touched. Barriers do not stack; a new Barrier replaces an existing one only if it is larger.
* Deathward [Enabler]: The next hit that would be fatal instead leaves the character at 1 Health, then the buff is consumed.
* Aegis [Enabler]: Blocks the next debuff that would land on the character, then the buff is consumed.
* Mirror Coat [Enabler]: When a debuff lands on the character, a copy is applied to the attacker, checked against the attacker's Resistance as normal.
* Opportunist [Channel 2]: The character's attacks deal +10% damage per debuff *type* present on the target (stacked instances of one debuff type count once).
* Catalyst [Enabler, provisional]: The next reagent the character consumes has +50% effect. Stacks additively with other reagent potency modifiers; has no effect on binary reagents (see section 3.3.3). Passes the collapse test only if reagents gate a burst — ratified by the itemization channels work.
* Wanderlust [Channel 1]: At the start of each of the character's turns, gain +20% to one random primary stat until their next turn.
* Overflow [Channel 1]: When this buff expires, it deals damage to all enemies, scaling with the holder's Mysticism. Resolves through the cascade machinery but always yields exactly one instance, so it multiplies nothing (section 1.1.3) — a delayed area hit, not a cascade contribution.
* Vigor [Channel 1]: Increases max Health by 30%.
* Lethal Precision [Channel 1]: Increases Critical Damage by the applier's own Critical Damage, snapshotted at application.
* Spotlight [Enabler]: The character is much more likely to be targeted by enemies (1.5x targeting weight) and takes 20% less damage. Both halves are one survival tool — drawing focused fire away from the pieces a burst depends on, and taking less of what lands.
* Premonition [Enabler]: The next attack against the character automatically misses, the buff is consumed, and the character immediately answers with their own basic skill against the attacker, at full strength and at no cost.
* Rehearsed [Enabler]: The character's next non-basic skill does not go on cooldown, then the buff is consumed.
* Sanguine Pact [Channel 2, granted]: Increases the holder's damage by 12% per 10% of the holder's own missing Health, and redirects 30% of damage the holder takes to whoever applied the Pact instead.
* Borrowed Time [Channel 3 — Cascade, granted]: The holder's next damaging skill resolves one additional time, at 30-60% strength by the applier's rarity. Does not stack. Consumed only by a damaging cast; a non-damaging skill leaves it untouched for a later one.
* Sea Legs [Channel 1, granted]: Boosts the holder's own highest primary attribute other than Health, by an amount its applier sets. Permanent; never expires. Stacks in place up to 4 times rather than as separate instances, each stack recomputing the boost against the current stack count.

#### 3.2.4. Skills
Skills can be categorized into three main types: Turn Bar Skills, Role Specific Skills, and Universal Skills.
Every character can have up to 3 skills. Some may also have a passive skill that is always active depending on role.

Skill targeting types:
* Single Enemy
* All Enemies
* Random Enemy
* Single Ally
* All Allies
* Random Ally
* Zone All
* Zone Ally
* Zone Enemy
* Ally Not Self
* Random One
* All Characters
* Left-most Enemy
* Right-most Enemy
* Most Injured Ally
* Most Injured Enemy

Positional targeting (Left-most Enemy, Right-most Enemy) is absolute: it follows the left-to-right party order (see section 3.2) and is not redirected by targeting-weight effects such as Spotlight.

Of the skills a character has, they always have 1 basic skill that has no cooldown but in general is weaker or more basic than other skills.

**Description length is soft-capped**: 60 words for a skill's effect line (3.2.4.2), 120 for a passive (3.1.3). Over it, cut a clause before accepting the length — a mechanic that genuinely needs more words earns them by saying what no shorter wording can.

##### 3.2.4.1 Zone System Rules
Turn bar skills apply effects to specific zones on the turn bar.

Zone system rules:
* The turn bar is divided into 5 sections. Each section can hold at most one zone at a time.
* When placing a zone, the player chooses which section it goes into. A section that already holds a zone cannot be targeted; the placement is blocked until that zone is gone. The Tidal Corsair's Gilded Deck is the sole exception: it auto-places to the free section holding the most allies (ties toward the end of the bar, then a random free section), since Corsair's Reckoning spends its targeting on an enemy.
* Trigger: when any character's turn starts, every character standing inside a zone is affected by it — but only once per visit. A character that has been affected by a zone is not affected by it again until they leave the section and re-enter it.
* Zones do not expire with time. A zone holds a set number of charges; each time it affects a character, one charge is consumed, and when the last charge is consumed the zone dissipates.
* Zones are removed only by dedicated clearing effects — the Scholar's kit and a zone-clearing reagent. There is deliberately no universal zone-clearing skill.
* Both sides place zones; the 5 sections are shared between allies and enemies.
* The effect of ally-placed zones scales with the placing character's Knowledge (see section 3.1.1).
* Each zone belongs to one of three lore families that define its visual language: order zones (God of Rules), unstable zones (God of Magic), and momentum zones (God of Adventure).

##### 3.2.4.2 Skills by Role
Skills allocated to a specific Role, listed in the same order as their entries in section 3.1.3. A Role with no skills assigned yet keeps a placeholder heading so its absence is visible at a glance.

Every skill's `Effect:` line below carries a channel tag (see 1.1.3's tag vocabulary); a skill
combining its own effect with an applied status is tagged with both. Named status effects are
cataloged in 3.2.3.

Where a skill entry disagrees with the shipped `.tres`, the disagreement is **flagged, not silently
rewritten** — section 1.1's precedence rule makes that a fix to make, and each flag names whether
the fix belongs in the data or the document.

###### Emissary
* Citation
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1 + Channel 2] Deals damage to a single target enemy, scaling with Knowledge, increased by the Standing Record rate per Infraction on the target.
* Signed Writ
    * Type: Debuff
    * Cooldown: 3 turns
    * Effect: [Enabler] Reduces the durations of all the target's buffs by 1 turn and applies the Signed Writ debuff for 1 turn. If the target has 6 or more Infractions, buff durations are reduced by 2 turns and Signed Writ lasts 2 turns instead. Every buff this strips to zero duration adds an Infraction to the target's tally.
* Levied Sanction
    * Type: Debuff
    * Cooldown: 4 turns
    * Effect: [Channel 2] Applies the Sanction debuff to a single enemy for 2 turns; its potency is set by the target's Infraction tally at the moment of application.

###### Thief
* Stab
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Attack.
* Pierce Weakness
    * Type: Damage
    * Cooldown: 2 turns
    * Effect: [Channel 1] Deals damage to a single enemy, scaling with Attack. Ignores 2.5x the
      passive's Defense-ignore rate.
* Cut Purse
    * Type: Damage, Buff
    * Cooldown: 3 turns
    * Effect: [Channel 1 + Enabler] Deals damage to a single enemy, scaling with Attack. Steals one
      of its buffs, which lasts one extra turn on the Thief, and grants the Thief the Opportunist
      buff for 2 turns.

###### Lancer
* Lance Thrust
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Attack.
* Rending Charge
    * Type: Damage, Debuff
    * Cooldown: 3 turns
    * Effect: [Channel 1 + Channel 2] Deals heavy damage to a single enemy, scaling with Attack and the Couched Lance passive, and applies the Bleed debuff for 2 turns.
* Disarm
    * Type: Damage, Debuff
    * Cooldown: 2 turns
    * Effect: [Channel 1] Deals damage to a single enemy and applies the Enfeeble debuff for 2 turns.

###### Alchemist
* Acrid Splash
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Knowledge.
* Catalyst Cloud
    * Type: Turn Bar (Zone)
    * Cooldown: 3 turns
    * Effect: [Enabler] Affected allies gain the Catalyst buff for 2 turns. Holds 4 charges. While Catalyst is held, consuming a non-brew reagent refunds one Alchemist brew-pool reagent into the spent slot.
* Dissolving Agent
    * Type: Damage, Debuff
    * Cooldown: 3 turns
    * Effect: [Channel 1] Deals damage to a single enemy, scaling with Knowledge, and applies the Unravel and Expose Weakness debuffs for 2 turns.

###### Sorcerer
* Arc Lash
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Mysticism. 25% chance to apply Warped for 1 turn.
* Unstable Rift
    * Type: Turn Bar (Zone)
    * Cooldown: 3 turns
    * Effect: [Channel 1 / Enabler] All affected characters, allies and enemies alike, gain the Warped debuff for 2 turns and take damage scaling with the Sorcerer's Mysticism — enemies take 30% of a standard hit, allies 15%. Holds 5 charges. Echoes amplify this zone rather than repeating its damage (see Arcane Instability, section 3.1.3).
* Cataclysm
    * Type: Damage (AoE)
    * Cooldown: 4 turns
    * Effect: [Channel 1 + Channel 2] Deals damage to all enemies, scaling with Mysticism. Targets currently affected by the Warped debuff take 30% increased damage.

###### Scholar
* Sharp Rebuttal
    * Type: Damage, Debuff (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Knowledge. If any zone stands on the turn bar, also applies Suppress to the target for 1 turn.
* Refutation
    * Type: Turn Bar
    * Cooldown: 3 turns
    * Effect: [Channel 1 + Enabler] Removes one zone of the Scholar's choice from the turn bar. If the zone was enemy-placed, the enemy who placed it takes damage scaling with Knowledge — 10% of a standard hit per charge remaining on the zone. If it was ally-placed, the placing ally's zone skill has its cooldown reduced by 2.
* Expose Fallacy
    * Type: Debuff, Buff
    * Cooldown: 3 turns
    * Effect: [Channel 1 + Channel 2] Applies the Confound debuff to a single enemy for 2 turns and grants all allies the Opportunist buff for 2 turns.

###### Diviner
* Fateful Glimpse
    * Type: Damage, Heal (basic skill, no cooldown)
    * Effect: [Channel 1] Deals minor damage to a single target enemy and restores a small amount of Health to the most injured ally (the Diviner included), both scaling with Mysticism.
* Premonition
    * Type: Buff
    * Cooldown: 3 turns
    * Effect: [Enabler] Grants an ally the Premonition buff for 1 turn: the next attack against them automatically misses and is answered with their own basic skill.
* Ill Omen
    * Type: Damage, Debuff
    * Cooldown: 3 turns
    * Effect: [Channel 1 + Enabler] Deals damage to a single enemy, scaling with Mysticism, and applies the Hexed debuff for 2 turns.

###### Appraiser
* Sizing Cut
    * Type: Damage, Debuff (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Knowledge, and applies the Exposed Facet debuff for 1 turn.
* Flaw Analysis
    * Type: Debuff
    * Cooldown: 2 turns
    * Effect: [Enabler] Applies the Confound and Cracked Facet debuffs to a single enemy for 3 turns.
* Full Appraisal
    * Type: Buff, Debuff
    * Cooldown: 4 turns
    * Effect: [Enabler] Consigns the caster's own Critical Chance and Critical Damage to one ally (not self) for 3 turns as the Keen Edge and Lethal Precision buffs, and applies the Consigned debuff to the caster for the same duration.

###### Tactician
* Signal Strike
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Attack.
* Fatal Flaw
    * Type: Buff
    * Cooldown: 2 turns
    * Effect: [Channel 2] All other allies gain the Daunting Strength buff for 1 turn.
* Battle Orders
    * Type: Buff (Turn Bar)
    * Cooldown: 4 turns
    * Effect: [Enabler] One ally gains the Battle Orders turn bar buff for 2 turns.

###### Symbiote
* Spore Lash
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Resistance.
* Symbiotic Overdrive
    * Type: Buff
    * Cooldown: 5 turns
    * Effect: [Channel 1] The Symbiote gains the Exhert buff for 4 turns.
* Grafted Flesh
    * Type: Buff, Heal
    * Cooldown: 4 turns
    * Effect: [Enabler] The Symbiote loses 10% of its max Health; one ally gains the Regeneration buff for 4 turns.

###### Jester
* Pratfall Sting
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1 + Channel 2] Deals damage to a single target enemy, scaling with Accuracy. Deals +30% damage if the Jester avoided an attack since their last turn.
* Burning Bolas
    * Type: Damage, Debuff
    * Cooldown: 2 turns
    * Effect: [Channel 1 + Enabler] Throws flaming bolas at a single enemy, dealing damage scaling with Attack, and applies the Burning and Hexed debuffs for 2 turns.
* Center Stage
    * Type: Buff
    * Cooldown: 3 turns
    * Effect: [Enabler] The Jester gains the Spotlight buff for 2 turns and the Luck buff for 1 turn.

###### Cultist
* Desecrated Blade
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1 + Channel 2] Deals damage to a single target enemy, scaling with Attack. +25% damage while the Vessel is alive and below half its own max Health.
* Devour Blessing
    * Type: Damage
    * Cooldown: 3 turns
    * Effect: [Channel 1 + Channel 2] Consumes all buffs from the ally holding the most; deals heavy damage to a single enemy, scaling with Attack, +25% damage per buff consumed.
* Rite of Severance
    * Type: Damage, Debuff
    * Cooldown: 4 turns
    * Effect: [Channel 1 + Enabler] Deals damage to a single enemy, scaled by Mysticism and applies the Severance debuff for 2 turns.

###### Bar Brawler
* Heap on
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1 + Channel 2] Deals damage to one enemy, scaling with Health, and grows stronger with every use.
* Liquid Courage
    * Type: Buff, Heal
    * Cooldown: 3 turns
    * Effect: [Channel 1] The Bar Brawler gains the Vigor buff for 2 turns and heals 15% of max Health.
* Headbutt
    * Type: Damage, Debuff (Turn Bar)
    * Cooldown: 3 turns
    * Effect: [Channel 1 + Enabler] Deals damage to a single enemy, scaling with Health, and applies the Dead Weight debuff for 2 turns.

###### Bloodmage
* Blood Bolt
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Mysticism. Costs 3% of the Bloodmage's max Health to cast.
* Transfusion
    * Type: Buff
    * Cooldown: 4 turns
    * Effect: [Enabler + Channel 2 (granted)] The Bloodmage sacrifices 15% of max Health; all other allies gain a Barrier absorbing 200% of the Health sacrificed (2 turns) and the Sanguine Pact buff for 2 turns.
* Tithe of Vitality
    * Type: Damage, Debuff
    * Cooldown: 4 turns
    * Effect: [Channel 2] Drains 10% of max Health from each living ally (the Bloodmage excluded). Deals damage to a single enemy, scaling with Mysticism, increased 35% per living ally currently below half Health, and applies the Hemorrhage debuff for 3 turns.

###### Herald of the loom
* Thread Snap
    * Type: Damage, Debuff (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Mysticism, and applies the Suppress debuff for 1 turn.
* Pull the Thread
    * Type: Damage, Debuff, Turn Bar
    * Cooldown: 4 turns
    * Effect: [Enabler] Deals damage to a single enemy, scaling with Mysticism, pushes them backward 15% on the turn bar, and applies the Temporal Leak debuff for 3 turns. Grants the Herald 2 Tension, regardless of the currently held thread (see the Weft and Warp passive).
* Cut the Cloth
    * Type: Damage
    * Cooldown: 4 turns
    * Effect: [Channel 3 — Cascade] Deals damage to a single enemy at 90% of a normal Mysticism-scaled hit, resolved once for the base cast plus once more per Tension held (minimum once, at zero Tension), then consumes all Tension.

###### Chronophage
* Zap
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Speed. (Also available as a Universal skill, see section 3.2.4.3.)
* Flicker Zone
    * Type: Turn Bar (Zone)
    * Cooldown: 2 turns
    * Effect: [Enabler] Affected allies move 15% further on the turn bar. Holds 5 charges.
* Temporal Sinkhole
    * Type: Turn Bar (Zone)
    * Cooldown: 4 turns
    * Effect: [Enabler] Affected enemies lose a portion of their turn bar progress. Holds 4 charges.

###### Architect
* Cornerstone
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Knowledge, and generates one Calibration charge.
* Raise the Frame
    * Type: Turn Bar (Zone)
    * Cooldown: 2 turns
    * Effect: [Enabler] Constructs a zone: affected allies gain the Barrier buff for 2 turns, sized by the Architect's Knowledge and boosted by the Calibration charges invested in the construction. Holds 5 charges.
* Final Calculation
    * Type: Damage
    * Cooldown: 3 turns
    * Effect: [Channel 1 + Channel 2 + Enabler] Consumes all held Calibration charges: 1-4 charges deal damage only; 5-8 also apply the Expose Weakness debuff for 2 turns, its Defense reduction deepening with charges spent beyond 5; 9-12 additionally re-erect the Architect's construction zone for free.

###### Tidal Corsair
* Boarding Strike
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Attack, and grants the Tidal Corsair one Steel stack.
* Saltwater Shot
    * Type: Damage (no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Attack, and grants the Tidal Corsair one Sea stack, spent by Corsair's Reckoning to raise or resupply The Gilded Deck.
* Corsair's Reckoning
    * Type: Damage
    * Cooldown: 3 turns
    * Effect: [Channel 1 + Channel 2 + Enabler] Consumes all held Stacks. Steel only: bonus damage per Steel. Sea only: raises or resupplies The Gilded Deck. Mixed: base damage, fewer Deck charges, and Slipstream plus Empower for every other ally. Rates per the Wrangle the Sea passive (section 3.1.3).

###### Plague Doctor
* Septic Lance
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Mysticism.
* Miasma
    * Type: Turn Bar (Zone)
    * Cooldown: 3 turns
    * Effect: [Channel 3] Enemies caught by the trigger have all their active debuffs tick again immediately, without losing a turn of duration, and gain the Blight debuff for 2 turns. Holds 4 charges.
* Outbreak
    * Type: Damage, Debuff
    * Cooldown: 4 turns
    * Effect: [Channel 2] Deals damage to a single enemy, scaling with Mysticism, +8% per distinct debuff type on the target (any source, uncapped), and applies a stack of the Plague debuff for 3 turns.

###### Warlord
* Shield Slam
    * Type: Damage (basic skill, no cooldown)
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Defense.
* Hold the Line
    * Type: Buff
    * Cooldown: 3 turns
    * Effect: [Enabler] All allies gain the Fortify buff for 2 turns.
* Brace for Impact
    * Type: Buff
    * Cooldown: 4 turns
    * Effect: [Enabler] The Warlord gains the Rush buff and the Aegis buff for 1 turn each. When Rush expires, the Warlord receives the Stun debuff per the Rush effect. While either buff holds, any enemy whose attack lands on the Warlord — including damage redirected to him by Shield Wall — gains the Enfeeble debuff for 2 turns, rolled against the Warlord's Accuracy like any other applied debuff.

##### 3.2.4.3 Unassigned / Generic Skills
Not yet tied to a specific Role, grouped by mechanical type for lookup.

The two entries below are shipped and functional but referenced by no Character Preset, as is
`Power_Tide.tres` (an orphaned all-ally Empower buff) — a roster-assignment gap to close.

**Turn Bar (Zone Effects)**
* Weight of Law
    * Effect: [Enabler] Affected enemies are Stunned for their next turn.

**Universal**
* Pagan Curse
    * Type: Debuff
    * Effect: [cannot be classified — no resource and no code reference exist anywhere in the
      project; recorded as a coverage gap, not a channel verdict] A ticking debuff. After 3 turns,
      the character is hit with a massive burst of damage unless they use a specific Chant to
      cleanse it.
* Zap
    * Type: Damage
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Speed.
* Stab
    * Type: Damage
    * Effect: [Channel 1] Deals damage to a single target enemy, scaling with Attack.

##### 3.2.4.4 Opponent Skills
Skills authored for enemies are cataloged in `Encounter_Design_Document.md` section 1 (Break Guard moved there). Any status effect they reference must exist in the 3.2.3 catalog.

### 3.3. Items and Resources

#### 3.3.1. Itemization
Each character equips three types of equipment: a weapon, an off-hand (shield, book or something), and boots. These three pieces are the core intended loadout.

The codebase additionally defines seven more equipment slots (Helmet, Chest, Pants, Gloves, Ring, Amulet, Trinket) for future flexibility. These are optional and not currently in scope for itemization design or content — no items or drop tables target them yet. A talent-tree-gated fourth slot is a candidate feature rather than committed scope; see `FeatureIdeas.md`.

Rarity for items:
* Common
* Uncommon
* Rare
* Epic
* Legendary

Every item also carries an **item type**, orthogonal to rarity: **Standard** or **Relic**. The
type decides what a rarity step buys. A Relic occupies one of the same slots and competes with a
standard item for it.

| | Standard | Relic |
|---|---|---|
| Attribute steps | rarity (1–5) | ceil(rarity / 2) — 1, 1, 2, 2, 3 |
| Unique effect | none | one, magnitude scaling with rarity |
| Downside | none | one, magnitude may scale with rarity |

**Gear verdict:** standard gear feeds the scaled attribute sum only. [Channel 1] Each step in
rarity adds one attribute bonus for the equipping character; no affix contributes a factor to
the combined modifier (section 1.1.3's second channel). A Relic trades attribute steps for a
unique effect and a drawback, and its effect may feed any channel: a conditional
combined-modifier factor [Channel 2], a cascade trigger [Channel 3 — Cascade], or a pure
[Enabler]. Every Relic is channel-tagged in section 1.1.3's vocabulary and audited individually
against the 1.1.6 rejection test.

**The upside is conditional, the downside is not.** A Relic's unique effect fires on a trigger, a
state, or a threshold; its drawback is always on. The player pays every turn and collects only
when the condition holds, which is what keeps a Relic off the median. Rarity may scale the
drawback alongside the effect, so a higher-rarity copy is a larger swing in both directions and
a sharper decision rather than an automatic upgrade.

Relic effects are written against the same hook vocabulary as character traits, firing across the
range of battle situations rather than through a narrow interface of their own.

**Multi-Relic bound:** the number of equipped Relics is not capped. Each Relic's contribution
must be conditional on a distinct mechanic identity, so section 1.1.3's composition law governs a
multi-Relic loadout the same way it governs multiple champions. The per-Relic audit and the
worst-case three-slot product live in `Relic_Design.md`.

**Relic acquisition:** item type is rolled independently of the loot budget. Every gear drop
rolls its rarity from the encounter's reward budget as normal, then a flat 5% roll decides Relic
instead of Standard at that rarity, and the Relic costs the same budget as the standard item
would. Availability therefore does not scale with difficulty — a Common Relic is reachable from
the first encounter. The shop's gear slots roll the same
chance (section 3.6.4). Every Relic in the current catalog is a general drop; boss-specific
Relics are a later addition, once bosses exist to carry them.

At the ceiling — a fully-geared Legendary loadout (Weapon, Off-Hand, Boots), every item rolled
and then fully upgraded (ten times each) — gear raises a
champion's relevant attribute by 3.1x, which comes out to a 4.2x-5.3x contrast ratio against
boss-tier Defence once the attribute's own effect on mitigation is included (see
`Scripts/Debug/blowout_calibration.gd`'s `_ReportGearCeiling()` for the calibration and how
that ratio was judged).
Only two of the three slots (Weapon, Off-Hand) can roll the attribute a given caster's skill
scales on — Boots' attribute pool never includes Mysticism, so a maxed Legendary Boots
contributes 0 to a Mysticism-scaled skill's damage regardless of how it rolls, even though
it is still equipped and raises other attributes. That stays below the 10x mini-boss burst
target, but it is a permanent, no-setup multiplier, which is worth knowing when reading
section 1.1.4's "stays tame."
That figure is an upper bound a Relic loadout can only sit below: a Relic displaces a standard
item rather than adding to the loadout, and rolls fewer attribute steps. What a Relic raises is
channels 2 and 3, which the per-Relic audit governs.

Items can exist for general use that most characters can use and Role specific type of items.

Some items may only be acquired from defeating specific bosses at a low rate.

One type of consumable could include some types to alter items, e.g. increase the rarity to add an additional attribute to an item. A type to randomize new attribute affix combinations. A type to remove a random attribute affix and reduce the rarity.

#### 3.3.2. Currencies
- Area unlock currency
- Supplies
    - Used to run playable content. Every encounter costs a base of 6 supplies, plus an
      optional additional surcharge (e.g. adventure tier cost stacks on top of the base).
      Half of the total cost (rounded down) is refunded if the player loses. Starting an
      encounter is blocked if the player cannot afford the total cost.
- Fortune’s Favor
    - Used in Adventurer's guild locations in hubs.
    - Comes in three tiers — Bone, Brass, and Parchment — each tracked as a separate
      balance. Higher tiers roll more reward slots (Bone 3, Brass 5, Parchment 9), which
      raises the odds of winning a champion since each slot independently has a chance
      to award one.

#### 3.3.3. Reagents
Reagents are universal consumable items left over from the era of the God of Magic,
looted primarily from that god's ruins and other encounters (rarer reagents drop only
from bosses). They are stored in a persistent player inventory.

Rules (designed and implemented — data model, catalog, persistent inventory, loot
acquisition, storage/sell UI, pre-battle loadout selection, and in-battle free-action
consumption; see `Technical_Design_Document.md` sections 6.1, 7.4, 9, and 10.1):
- Before a battle the player selects up to 3 reagents from their inventory to bring along.
- Each brought reagent can be consumed exactly once per battle, by any champion on
  their turn, as a free action (it does not consume the turn). Reagents are usable
  strictly on the consumer's own turn, never reactively.
- A consumed reagent is permanently deleted; reagents brought but not used return to
  the inventory.
- Reagents can be sold for Silver from the reagent storage screen (in the collection
  menu). Sell value scales with rarity: `60 ^ (1 + rarity * 0.15)`, the same formula
  shape used for equipment sell values (`LootManager.GetReagentSellValue`).
- Reagents are currently loot-only (dropped by bosses and the Escalate adventure node,
  see below); shop purchase is a tracked follow-up (see `FeatureIdeas.md`).
- Reagents come in rarities (Uncommon, Rare, Epic, Legendary). Reagent effects scale
  with rarity only — never with the consumer's attributes.
- Every reagent effect is either scalar or binary:
  - Scalar effects have a magnitude that potency modifiers can raise.
  - Binary effects (marked "(Binary)" in the catalog below) either happen or don't;
    potency modifiers ignore them, and they cannot appear in the Alchemist's brew pool.
- All reagent potency modifiers — the Sorcerer's Arcane Instability amplification, the
  Catalyst buff, and the Alchemist's brew potency — stack additively on one consumption.
  None of them affect binary reagents.
- Any role can use reagents, but the Sorcerer excels at them through the Arcane
  Instability passive (section 3.1.3), which grants extra Instability stacks and
  amplifies the consumed reagent's effect.
- The Alchemist is the reagent producer counterpart: its Fresh Batch passive
  (section 3.1.3) brews a battle-scoped concoction at the start of combat, in a
  slot beyond the three brought reagents. Brews follow normal reagent rules but
  never enter the inventory.
- Enemies never use reagents.

Reagent catalog (designed; magnitudes without listed values are not yet decided):

Families — one entry per rarity tier — tagged using the same bracket vocabulary as section
3.2.3 (see section 3.1.3's lead-in for the definitions):
* Tinctures [Channel 1]: one family per primary attribute. A small battle-long +6/9/12/15%
  (by rarity) increase to that attribute. Not a buff: undispellable, unstealable,
  and invisible to buff-counting effects. Deliberately weaker than the equivalent
  30% buff.
* Restorative Draught [Channel 1]: heals the user for 15/20/25/30% (by rarity) of max Health.
* Purging Tonic [Enabler]: removes up to 1/1/2/2 (by rarity) debuffs from the user.
* Thief's Regret [Enabler]: destroys (not steals) up to 1/1/2/2 (by rarity) buffs on one enemy.
* Barrier Stone [Enabler] (not yet implemented, see Technical Design Document 6.1): grants a
  Barrier with a flat absorb amount set by rarity to the user.
* Rewinding Grit [Enabler]: targets one ally and reduces the cooldown of every skill they have
  currently on cooldown by (1/1/1/2) turns, set by rarity.
* Second Wind Phial [Enabler]: after the consumer's current turn ends, their turn bar resets to
  15/20/25/30% (by rarity) instead of 0. Self-only.

Singletons:
* Zone-Dissolving Salts (Binary) [Enabler]: clears one targeted zone section (one of the two
  dedicated zone-clearing effects, see section 3.2.4.1).
* Deathward Charm (Binary) [Enabler] (not yet implemented, see Technical Design Document 6.1):
  applies the Deathward buff to the user.
* Chant Fragment (Binary) [Enabler] (not yet implemented, see Technical Design Document 6.1):
  cleanses Pagan Curse from one ally. God of Magic lore family.
* Notarized Seal (Binary) [Enabler] (not yet implemented, see Technical Design Document 6.1):
  applies the Signed Writ debuff to one enemy for 1 turn. God of Rules
  lore family.
* Wayfarer's Draught [Channel 1] (not yet implemented, see Technical Design Document 6.1):
  applies Wanderlust to the consumer, with the random-stat bonus
  percentage set by rarity instead of the buff's standard value. God of Adventure
  lore family.
* Chaotic Blessing [Channel 1]: applies one random buff from a fixed pool (Empower, Fortify,
  Haste, True Aim, Clarity, Attune, Insight, Vigor), with its magnitude overridden to
  15/20/25/30% (by rarity) and its duration set to 3 turns instead of the buff's
  standard values. God of Magic lore family.
* Fractured Idol [Channel 2, sanctioned exception]: a crumbling artifact of the Forgotten God.
  Deals 10/14/18/22% (by rarity) of the consumer's max Health as damage (cannot reduce the
  consumer below 1 Health) and grants a battle-long +10/13/16/20% (by rarity) to damage dealt.
  Potency modifiers raise both the cost and the bonus. God of Magic lore family.

Alchemist brew pool — an Alchemist-exclusive pool of lesser scalar reagents,
self-targeted (the consumer is always the recipient); pool size is 3 at Uncommon and
Rare, 4 at Epic and Legendary:
* Lesser Restorative Brew [Channel 1]: heals the consumer for 10% of their max Health.
* Lesser Tincture [Channel 1]: a small battle-long +5% increase to one random primary attribute
  of the consumer.
* Lesser Barrier Brew [Enabler]: grants the consumer a Barrier absorbing 40% of their max Health.
* Lesser Purging Brew [Enabler] (Epic and Legendary Alchemists only): removes up to 1 debuff
  from the consumer.

### 3.4. Game Modes
TODO

#### 3.4.1. Main Campaign
TODO

#### 3.4.2. Daily/Weekly Challenges
TODO

### 3.5. Events
Maybe a rotating schedule composed of one type of event per god? E.g.
*   **God of Rules**
    *   A numeric “floor” dungeon like raids doom tower
*   **God of Adventure**
    *   A small storyline, quest
    *   Some boss and or mystery
*   **God of Magic**
    *   Chaotic event, involving many elements that change often?

### 3.6. Hub Area
The hub areas will be almost identical but for visual themes, minor differences in NPCs and decorations.
The biggest differences will come along the theme of the hub as it can be either neutral or run by one or more factions. This will affect the recruitment weighting of characters.

#### 3.6.1. The war room (Gate out of town etc)
Transports the player to a new screen, the world atlas. Where the player can access different playable encounters.

#### 3.6.2. The Armory
Where players can manage their character roster, equip gear, and upgrade skills.

#### 3.6.3. The Adventurer's Guild
Where players recruit new characters using Fortune’s Favors.
There is a chance when using a Fortune’s Favor to get a champion, or they could get supplies or currency as a filler.

#### 3.6.4. The shop
Six stock slots: 3 gear, 1 reagent, 1 Supplies bundle, 1 featured Fortune's Favor offer.
Gear and reagent rarity scale with player progress. Each gear slot rolls its item type on the
same flat 5% chance a drop uses (section 3.3.1), so a Relic can appear in the shop at any
progress level; a Relic is priced at a substantially higher markup than a standard item of its
rarity. The Favor slot always offers a Bone
tier Favor for a fixed Silver price. Stock restocks on a one-hour real-world timer; the
Favor slot instead waits out its own three-day cooldown after purchase. A purchased slot
stays sold out until its next restock (or, for Favor, until its cooldown ends).

### 3.7 Energy Systems
To limit daily player activity, an energy system will be implemented. Players will have a set amount of Energy (Supplies) that depletes when entering combat nodes. Supplies regenerate over time at a rate of +10 per 10 real-world minutes, up to a cap of 100, and can also be replenished through in-game actions or purchases. Regeneration is offline-aware: elapsed real time is applied on load, with partial progress toward the next +10 preserved.

### 3.8 Reward structure
The idea is to have every encounter hold a "loot table" of possible drops. Some drops may always drop for certain encounters.
Then each drop is given a "reward value", where e.g.
- X silver is Y reward value points
- X experience is Y reward value points
- Gear of rarity Z is Y reward value points equivalent, keyed by rarity alone — a Relic costs
  the same as the standard item of its rarity, since item type is rolled outside the budget
  (section 3.3.1)

Then every encounter will be given a reward value points buffer depending on difficulty and cost of supplies to engage.

When a victory is achieved, rewards will be randomly selected from the loot table and subtract that value from the reward value points buffer. Note that some drops may be guaranteed and will be picked out first before random selection. This goes on until the buffer is spent or if the remaining value is too small to equate another reward.

### 3.9 Adventure node types
An adventure is a generated graph of nodes the player steps through. Besides the
**Fight** and **Boss** combat nodes, the following interactive node types resolve
directly in the adventure scene without entering battle:

- **Rest Stop**: each Rest Stop is generated with one fixed buff. The player chooses
  how long to receive it: 0 Supplies for the next combat, 6 Supplies for the next 3
  combats, or 18 Supplies for the rest of the adventure.
- **Hint**: a placeholder node that shows a configured hint (text and/or image) meant
  to assist with an out-of-game puzzle, and grants a small Silver/Supplies reward
  (5% of the encounter's reward budget) on acknowledgement. No puzzle backend exists yet.
- **Gamble**: a 50/50 choice. On a win, the player receives a buff lasting 4 combats;
  on a loss, a debuff lasting 2 combats.
- **Escalate**: offers Silver and/or Supplies (15% of the encounter's reward budget) plus a
  guaranteed reagent (Uncommon-Epic; Legendary is boss-exclusive, see section 3.3.3) in
  exchange for a permanent +1 to the adventure's difficulty for its remainder.

Buffs and debuffs granted by these nodes are **adventure-spanning effects**: they are
tracked on `AdventureState` as combats-remaining (rather than turns) and are applied to
every player champion for the full duration of each subsequent combat until they expire.
They reuse the existing combat `Buff_Type`/`Debuff_Type` set (Empower, Fortify,
Daunting_Strength / Burning, Enfeeble, Expose_Weakness) — no new effect types were added.

The adventure graph is drawn over a generated background rather than a flat color. Each
biome defines zones (e.g. a Reclaimed City forest, clearing, or rubble field); a
low-frequency noise sample assigns a zone to each region of the map so scenery forms
contiguous forests and open gaps instead of an even speckle, and a second, finer noise
pass scatters that zone's decor (trees, grass, rubble, etc.) within it. Generation is
seeded from the adventure's own generation seed, so revisiting the same adventure always
shows the same scenery. Each node also scatters a deterministic ring of node-type-themed
props around it — reusing the same density, scale, rotation, and texture-variant mechanics
as zone decor — so every node's surroundings vary while still reading clearly as their type.


---

## 4. World and Narrative
Also look at World_Building.md for more brainstorm writing.

### 4.1. Religion

In this world there are 3 gods that created it, but through their effort they have little power left to affect it directly. There was the god of adventure, the god of rules and the god of magic. The god of magic was betrayed by the other two and imprisoned somewhere unknown. The only remaining mark of the god of magic is the magic system, which is now heavily restricted and shunned by the other two gods through their doctrines, leaving magic to be a rare and obscure art.

The reason for betrayal is since while initially magic provided many opportunities and options for adventure and structure, it eventually became clear that magic could easily break both adventure and structure if left unchecked. The god of adventure saw magic as a way to create endless possibilities, but the god of rules viewed it as a chaotic force that undermined order and predictability. Fearing the destabilizing potential of magic, the god of rules conspired with the god of adventure to imprison the god of magic, believing that by doing so, they could preserve their own domains.

Believers grant the gods power, but very slowly. Fragments of the god of magic exists in ruins written in obscure languages only used in history.
The god of magics only mark left on the world other than ruins is the magic system, written in old scrolls lost to civilization.
Since the imprisonment the magic system became very restricted in terms of conjuration and effect, often requiring powerful reagents, chants only known in parts or environmental conditions.

These events transpired long before the player enters the game, with gods leaving little direct impact on the world and most people in the world wont even experience anything related to them except for stored or warped doctrines, statues and hard to come by books.

In the present day the gods' doctrines survive mostly as warped institutions: the God of Rules is worshipped as the Divine Auditor of the Iron Ledger's bureaucracy, the God of Adventure's legacy lives on in the Great Caravans and the Khasar Fleet, and the God of Magic — also called the "Forgotten God" — is remembered only through the hazardous ruins that are strip-mined for reagents (World_Building.md sections 1, 2 and 4). Magic itself is treated as a contaminated resource; practicing mages are useful for war but shunned in daily life, and Chants circulate as lost "encryption keys" rather than prayers (World_Building.md 2).

#### God 1, the god of adventure

The God of Adventure is the divine personification of curiosity, risk, and the thrill of the unknown. Unlike the God of Rules, who seeks to categorize the world into letters and numbers, the God of Adventure views the world as a vast, unpredictable playground. This deity is a playful thrill-seeker who lacks the power to manifest physically and instead watches the creatures of the world with a voyeuristic intensity, seeking to live vicariously through their triumphs and tragedies.

The god is indifferent to the survival of their followers; a spectacular, high-stakes failure is considered just as entertaining as a victory. This is reflected in mechanics like the "Frenzy" buff, which grants great power at the cost of "Defense" and "Accuracy," embodying the god's preference for glass-cannon heroics.

#### God 2, the god of Rules (Structure, Regulation & Logic)

Created order and systems in the world, letters and numbers.
The God of Rules is the divine architect of reality, responsible for the creation of order, systems, letters, and numbers. This deity views the world as a complex machine that functions best when every gear turns with mathematical precision. While the God of Adventure thrives on the chaos of the unknown, the God of Rules demands predictability and strategic foresight.

#### God 3, the god of magic

The God of Magic holds immense knowledge of the arcane arts and the mysteries of the universe. This deity is a master of transformation, capable of bending reality to their will through spells and enchantments. However, their power is a double-edged sword; while they can create wonders, they can also unleash chaos if not properly controlled. Holding that much knowledge but in trade naive to the ways of interaction, with only interest in exploring their possibilities of creation.

### 4.2. Factions
The factions below are developed in detail in World_Building.md; the section references point there.

- Humans — split between two dominant power blocs locked in an economic cold war (World_Building.md sections 1 and 4):
  - **The Iron Ledger**: the Holy City's world-spanning auditing bureaucracy, ruled by the Grand Auditors and enforced by the Emissaries (World_Building.md 1.1.1, 4.1).
  - **The Merchant-States of the Spire**: trade guilds and the Scholar Caste who control the Clockwork Spire's Logic-Chains (World_Building.md 1.1.2).
  - **The Pirate Coalition ("The Gilded Wake")**: the free-trade society of the Pirate Coves, governed by the loose Council of Coves (World_Building.md 1.2.2, 4.2).
  - **The Scavenger Economy** of the Reclaimed City, including the shunned Symbiote Slums (World_Building.md 1.2.1).
- Trolls — classified as "Biological Assets" by the Iron Ledger; heavy laborers in the Clockwork Spire and prized shields for the pirates (World_Building.md 4.5.1).
- Harpies — high-altitude couriers caught between the Ledger's compliance fees and the pirates' schemes (World_Building.md 4.5.2).
- Fae — geometric architects of the "harsh growth" reclaiming the Reclaimed City's forest (World_Building.md 4.6.1).
- Centaurs — nomad archivists and information brokers, organized as the Khasar Fleet and its Regimes (World_Building.md 4.6.2, 6.2 and 7).

Notable groups within these factions:
- **House Aethelgard** — the Holy City's publicly devout, privately smuggling "shadow bank" noble house (World_Building.md 6.1).
- **The Khasar Fleet** — the Centaur courier and toll-keeper regime of the open plains (World_Building.md 6.2).
- **The Filter-Folk** — brass-skinned mutated humans of the Under-Spire who worship "Maintenance" (World_Building.md 5.1).

### 4.3. Notable cities and locations

#### 4.3.1. Reclaimed City
A city built on the edge of a vast forest, where originally nobels invested heavily to forage and claim valuable magical resources from the forest. However the strong and harsh growth of the forest eventually proved too much for the city to handle, reaping too few rewards for further investment. The city was eventually abandoned and left to the forest, turning into ruin. Until recently when adventurers and scavengers have started to reclaim parts of the city to gather its resources once more. Today it runs on a scavenger "Gold Rush" economy: the shunned Symbiote Slums, whose workers bond with forest organisms to survive the toxic spores, and the "Green-Market" black market for magical reagents (World_Building.md 1.2.1). The Fae quietly work to regrow the forest into the human outposts (World_Building.md 4.6.1), and the ruin known as the Ossuary of Stolen Hues lies deep within the city (World_Building.md 5.4.1).

Associated characters:
- Symbiote
- Plague Doctor
- Alchemist
- Diviner
- Appraiser

#### 4.3.2. The Pirate Coves
A series of hidden coves along a treacherous coastline, serving as a haven for pirates and smugglers. These coves are notorious for their labyrinthine tunnels and secret passages, making them difficult to navigate for outsiders. The Pirate Coves are a hub of illicit trade, where anything from rare magical artifacts to forbidden knowledge can be bought and sold. The area is also known for its lawlessness, with various pirate factions vying for control over the lucrative smuggling routes. Politically the coves operate as the Free-Trade Coalition, "The Gilded Wake" — a functional, if violent, society built on bypassing the Iron Ledger's taxes, governed by the loose Council of Coves (World_Building.md 1.2.2, 4.2).

Associated characters:
- Tidal Corsair
- Thief
- Bar Brawler
- Jester

#### 4.3.3. The Clockwork Spire
A towering structure located in the heart of a sprawling desert, the Clockwork Spire is a marvel of engineering and arcane technology. Built by a long-lost civilization, the spire is filled with intricate gears, pulleys, and mechanisms that power its various functions. Once a research facility for scholars and inventors, the spire now functions as a factory: trade guilds of the Merchant-States fight for control over its "Logic-Chains" (ancient automated assembly lines) to produce high-end gear, while the Scholar Caste hoards knowledge of its mechanics to keep a monopoly on technology (World_Building.md 1.1.2). However, the spire is also home to dangerous traps and guardians, making it a perilous destination for those who dare to explore its depths. Beneath it sprawl the Grease-Pits of the Under-Spire, a slum in the shadow of the Great Gears and home to the Filter-Folk (World_Building.md 5.1).

Associated characters:
- Architect
- Chronophage
- Scholar

#### 4.3.4. The god of rules holy city (The Iron Ledger)
A city dedicated to the worship of the God of Rules, where order and structure are paramount.
The city is a bastion of law and discipline, with strict regulations governing every aspect of daily life. Citizens are expected to adhere to a rigid code of conduct, and any deviation from the norm is met with swift and severe punishment. The city's architecture reflects its devotion to order, with perfectly symmetrical buildings and meticulously maintained streets.

Known as **The Iron Ledger**, the city is not just a place of worship but the world's central bank and legal capital: the God of Rules has been reinterpreted as the Divine Auditor, citizens are taxed on their "predictability", and the ruling council of Grand Auditors interprets the Ancient Statutes (World_Building.md 1.1.1, 4.1). Its Emissaries are not priests but high-ranking lawyers and adjudicators who enforce the god's will as field agents, treating an enemy's existence as a clerical error to be corrected. The city also secretly hosts House Aethelgard, its "shadow bank" (World_Building.md 6.1).

The city's hub area is located in **the Margins**, the slums pressed between the last audited district and the city wall, where the Adventurer's Guild hall stands as neutral ground; the district and its native gang, the Arrears, are detailed in World_Building.md 5.5 and 6.3.

Associated characters:
- Emissary

#### 4.3.5. The god of adventures caravan
A nomadic settlement that travels across the land, following the whims of the God of Adventure.
The caravan is a vibrant and eclectic community, filled with adventurers, performers, and thrill-seekers. The Centaurs of the Khasar Fleet are closely tied to the caravan culture, escorting and tolling the Great Caravans along their migration cycles (World_Building.md 6.2 and 7).

Associated characters:
- Warlord
- Lancer
- Tactician

#### 4.3.6. The various ruins of the god of magic
Scattered across the world are ancient ruins that were once dedicated to the worship of the God of Magic. These ruins are remnants of a bygone era, when magic was a dominant force in the world. The ruins are often hidden in remote and dangerous locations, protected by powerful enchantments and guardians. Inside the ruins, adventurers can find forgotten knowledge, powerful artifacts, and clues to the god's imprisonment. However, the ruins are also fraught with peril, as many have been corrupted by dark magic or overrun by hostile creatures.

In the present day these ruins are less places of pilgrimage than strip-mines: a "Gold Rush" mentality has formed around their reagents, with the Iron Ledger classifying them as "Hazardous Waste Sites" to seize artifacts as contraband while the pirates hire unlicensed mages to haul out materials (World_Building.md 2, 5.4). Within them, Chants act as physical keys — reciting the correct ancient phrase reshapes the ruins' geometry. Notable named ruins are the Ossuary of Stolen Hues and the Vault of Recursive Seconds (World_Building.md 5.4.1, 5.4.2).

Associated characters:
- Bloodmage
- Cultist
- Sorcerer
- Herald of the loom

#### 4.3.7. Other notable locations
Developed in World_Building.md section 5; listed here for reference:
- **The Churning Marches and the Glass Weald** — the geographical "scar" of the God of Magic's betrayal, a forest of razor-sharp glass trees where those who linger become "Refracted" (World_Building.md 5.3).
- **The Frozen Ledger (The Glacial Archives)** — northern mountain vaults of "Inert Information" guarded by the Silent Monks of the Abacus (World_Building.md 5.2).
- **The Under-Spire (The Grease-Pits and the Sinking Sluices)** — the slums beneath the Clockwork Spire, home to the Filter-Folk (World_Building.md 5.1).


## 5. Playable content
Most forms of encounters shall have difficulty options, this is for several reasons. One is to have more challenging content for players whose account have outgrown certain encounters. Another is to scale the reward given to be able to farm specific gear/experience/currency to manage other difficult content.

### 5.1. Longform
Intended to be adventures aimed to span days to weeks to complete.

### 5.2. Shortform
Intended to be singlular encounters with specific, targetable and grindable rewards.

#### 5.2.1. Quest Board (Experience encounter)
A quest board is accessible where one randomized encounter (out of two or three) will be available, with the purpose of having different characters/strategies be more efficient at different encounters.

The intended way to engage is to bring one suitable character to deal with the encounter and two weak characters to grow from the encounter reward, the experience points.

#### 5.2.2. Reanimating Statues 1, 2 and 3 (Gear encounter)
In the future the intent is to have one type of encounter per type of gear set, where all types of equippable items or a subset can be a drop for that set.
For now though in the meantime as gear sets doesn't exist yet, the intention is for each encounter to drop one type of equippable item as e.g. one encounter for boots, one for weapons and one for off-hands.

So there now is 3 encounters to choose from for gear farming, one per equippable item: Reanimating Statues 1 (Boots), 2 (Weapons), and 3 (Off-hands). All three are Mini-boss tier (see section 5.3); their mechanics, compositions, and intended solutions are cataloged in `Encounter_Design_Document.md` section 2.2.

#### 5.2.3. Caravan (Currency encounter)


### 5.3. Encounter tiers

Every battle encounter belongs to one of three tiers. Expected fight length is a tier parameter, measured in rounds — one round is each fielded champion acting once. The round targets are starting points, to be tuned as content is placed.

* **Fodder** — no dedicated burst; blowout here is overkill on trash. 3–4 rounds.
* **Mini-boss** — one realisation, a partial burst, around 10x the champion's own basic skill. The threat curve peaks before it. 6–10 rounds solved, roughly double unsolved.
* **Boss** — layered realisations, a full burst at 30–50x carrying 60–80% of total damage dealt. The threat curve peaks before the burst, not after. 10–12 rounds solved; unsolved is a wall, not merely slow.

Every mechanic states its onset — by which enemy turn it becomes relevant — and that onset must fall inside its tier's expected kill window.

Encounter entries, opponent skills, and the production rules (overlap tolerance, answer anchoring, volume targets) live in `Encounter_Design_Document.md` and `Plans/Plan_Encounter_Solution_Design.md`.

## 6. Development tools
- Godot Engine version 4.7

