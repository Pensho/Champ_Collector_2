# Game Concept Document: Character Collector (Temporary name)

---

## 1. Introduction
This game is a turn based combat RPG. The main idea is to collect characters that the player can use in combat, each of them with slightly different skill sets to manage to defeat enemy encounters.

---

## 2. Core Gameplay Loop
The core gameplay follows a cyclical "Prepare, Engage, Reward, Grow" loop designed to balance short-term satisfaction with long-term strategic planning.

### 2.1. The Loop Overview

**Preparation & Management:** The player manages their roster, equipping gear (Weapons, Off-hands, Boots) and selecting a team of characters whose Roles and Attributes (like Speed and Mysticism) complement each other.

**Resource Expenditure:** Players spend Energy (Food/Supplies) to enter different combat nodes, such as routine "Grind" maps, high-stakes Boss encounters, or God-themed Events.

**Turn-Based Engagement:** Players engage in combat where the Speed attribute determines turn order on the "turn bar."

- Routine Fights: Players use overwhelming power to clear enemies quickly for resources.

- Tactical Puzzles: Players must carefully time skills and manage Accuracy/Resistance to overcome specific boss mechanics.

**Reward Acquisition:** Victory grants Experience, Currencies (Area Unlocks/Thematic resources), and loot ranging from Common to Relic rarity.

**Character Progression:** Players use rewards to Ascend characters, upgrade skills, and refine item affixes, increasing their power to unlock the next Tier of challenges.

### 2.2. Short-Term vs. Long-Term Loops
| Loop Type | Focus | Primary Activity |
|-----------|-------|------------------|
| Short-Term (Daily) | Efficiency | Spending Energy on routine fights to gather crafting materials and XP; completing daily God-themed events. |
| Mid-Term (Weekly) | Strategy | Solving "Puzzle" encounters and bosses to acquire Role-specific gear or rare Trinkets; participating in rotating God events (e.g., God of Rules’ floor dungeon). |
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
For now there are no Common Characters that are usable by a player. Also, there will be no Relic tier Characters, that tier level is restricted for Items.
There is a maximum level of 50, with a future idea to use duplicate heroes as a mean to increase it a few steps at most (or to upgrade skills).

#### 3.1.1. Character Attributes
Each character is defined by a set of core attributes:
*   **Primary Stats:** 
    * Health
        * Determines how much damage a character can take before being defeated.
    * Speed
        * Influences turn order in combat.
    * Attack
        * Determines the damage output of physical attacks.
    * Defense
        * Reduces incoming physical damage.
    * Accuracy
        * Affects the likelihood of successfully landing debuffs or status effects on enemies.
    * Resistance
        * Reduces the chance of receiving debuffs or status effects.
    * Mysticism
        * Determines the damage output of magical attacks.
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

Current roles, their identity and purpose exist as follows:
- Emissary (Not yet implemented)
    - A field agent of the Iron Ledger who wins by building a case against the enemy rather than overpowering them. Keeps a per-enemy tally of Infractions (see the Standing Record passive) and issues Edicts — formal rulings whose severity is read off the target's Infraction tally. Punishment effects stay gradual rather than binary: no hard skill sealing or turn bar manipulation; instead buff duration reduction, resistance bypass, and attribute sanctions, all scaling with the target's Infraction count. Primary attributes: Accuracy, Knowledge.
    - Purpose: Debuffer, Control
    - Passive: Standing Record - Every enemy has a personal Infraction tally that only grows and is never consumed. An enemy gains one Infraction whenever they gain a buff, place a zone, or land a debuff on an ally. The tally is counted up to a cap of 9 for skill effects. The Emissary's skills that scale with Infractions apply a rarity-dependent rate per Infraction on the target; that rate is the only source of Infraction scaling (skills state what scales, never their own rate).
        - 2.5% per Infraction Uncommon, 3% Rare, 3.5% Epic, 4% Legendary
- Thief
    - A squishy damage dealer, focusing on set-up through skills and bypassing enemy defenses. Primary attributes: Attack.
    - Purpose: Damage.
    - Passive: Pilfer - Chance to steal a buff from the target when a skill is used.
        - 20% Uncommon, 30% Rare, 40% Epic, 50% Legendary
- Lancer
    - Always has at least one offensive skill and one defensive skill.
    - Purpose: Damage
    - Passive: Reckless Momentum - When an offensive skill is used the Lancer gains one Momentum stack (+x% damage, -x/2% defence while stacks are held, maximum 5 stacks). When a defensive skill is used, the Lancer gains Phalanx Guard (a role-unique 2-turn buff, +x% defence) and all Momentum stacks are consumed.
        - 4% Uncommon, 6% Rare, 8% Epic, 10% Legendary
- Alchemist (Not yet implemented)
    - A support character that focuses on buffing allies and debuffing enemies through various concoctions. Signature zone: Catalyst Cloud (see section 3.2.4.1). Primary attributes: Knowledge, Mysticism.
    - Purpose: Debuffer, Buffer
    - Passive: Fresh Batch - At the start of combat the Alchemist brews one concoction: a reagent drawn at random from an Alchemist-exclusive pool, occupying its own slot beyond the three brought reagents. It follows normal reagent rules (consumable once, by any champion, on their turn) except that it is never added to the inventory - if unconsumed when the battle ends, it is lost. Each fielded Alchemist brews their own concoction.
        - Brew potency: 90% Uncommon, 100% Rare, 110% Epic, 120% Legendary (relative to a standard reagent of equivalent effect); the brew pool holds 3 lesser reagents at Uncommon and Rare, 4 at Epic and Legendary (see section 3.3.3)
        - Depends on the reagent system (see section 3.3.3 and `Plans/Plan_Reagent_Combat_Application.md`); inactive until reagents exist.
- Sorcerer (Not yet implemented)
    - A damage dealer that harnesses the power of magic to deal Area of Effect damage and control the battlefield. Wields the unstable, shunned magic left behind by the God of Magic, and excels at drawing power from reagents scavenged from that era's ruins. Signature zone: Unstable Rift (see section 3.2.4.1). Primary attributes: Mysticism, Knowledge.
    - Purpose: Damage, Debuffer, Control
    - Passive: Arcane Instability - Using any skill grants one Instability stack (+x% Mysticism per stack, maximum 5). When the Sorcerer consumes a reagent, they gain two Instability stacks and the reagent's effect is amplified by y%. While at maximum stacks, the Sorcerer's next skill also releases a Surge: magical damage to all characters, allies included, scaling with the Sorcerer's Mysticism - then all stacks reset. Stacks do not persist between combats.
        - Per-stack Mysticism: 4% Uncommon, 6% Rare, 8% Epic, 10% Legendary
        - Reagent amplification: 20% Uncommon, 30% Rare, 40% Epic, 50% Legendary
        - Depends on the reagent system (see section 3.3.3 and `Plans/Plan_Sorcerer_Arcane_Instability.md`). Until reagents exist, the passive functions on skill-cast stacks alone.
- Scholar
    - A support character that focuses on knowledge and strategy to enhance allies' abilities and exploit enemy weaknesses. The zone-clearing specialist: the Scholar's kit is one of the two dedicated ways to remove zones from the turn bar (see section 3.2.4.1). Primary attributes: Knowledge.
    - Purpose: Debuffer, Buffer
    - Passive: Field of Study - The Scholar has studied every opponent and knows their weaknesses. At the start of combat, each enemy's weakness is identified: their highest primary attribute, Health excluded (ties broken at random). Whenever the Scholar applies a debuff to an enemy, that enemy's identified attribute is additionally reduced for the debuff's duration: Uncommon 4%, Rare 6%, Epic 8%, Legendary 10%.
- Diviner (Not yet implemented)
    - A squishy support.  Primary attributes: Mysticism.
    - Purpose: Sustain, Debuffer
    - Passive: Foresight - Place debuffs on enemies if they are close enough behind the Diviner on the turn bar when the Diviners turn starts.
        - 10% Uncommon, 15% Rare, 20% Epic, 25% Legendary
- Appraiser (May postpone implementation and keep as optional)
    - A master at exploiting enemy weaknesses, allowing opportunity for the team to easily deal critical hits. Primary attributes: Critical Chance, Knowledge.
    - Purpose: Debuffer
    - Passive: 
- Tactician
    - A squishy support. Primary attributes: Knowledge, Speed.
    - Purpose: Buffer
    - Passive: Plan - Gives buffs to allies who are within x% behind the Tactician on the turn bar when their turn starts. Applies at every rarity; only the Tactician's own self is excluded.
        - 10% Uncommon, 15% Rare, 20% Epic, 25% Legendary
- Symbiote (Not yet implemented)
    - A character weak by default but given the option to alter itself to combine with one of select few monsters to gain their trait & bonus in attributes. Primary attributes: Health, Resistance.
    - Purpose: Sustain, Buffer
    - Passive: 
- Jester
    - An unconventional tanking character that does not have significantly high Health or Defense but relies on skills that provoke hits to the Jester and dodge them. Primary attributes: Accuracy, Knowledge, Speed.
    - Purpose: Damage, Sustain
    - Passive: "Double the fun!" - A base 5% chance to completely avoid the damage of an incoming attack (debuffs from the attack still land). Each hit that lands instead of being avoided increases the chance by a rarity-dependent amount, up to 3 stacks: Uncommon +3%, Rare +4%, Epic +5%, Legendary +6% per stack. Avoiding damage resets the chance to the 5% base. Increases the chances of being targeted.
- Cultist (Not yet implemented)
    - Consumes ally buffs or health to empower their own skills, dealing magical damage or applying debuffs. Primary attributes: Mysticism, Knowledge.
    - Purpose: Debuffer, Damage
    - Passive: Chosen Vessel - At the start of combat the Cultist marks a random ally (the Cultist excluded) as their Vessel. Whenever the Cultist uses a non-basic skill, the Vessel loses 5% of their max Health and the skill gains a rarity-dependent power bonus: Uncommon +15%, Rare +20%, Epic +25%, Legendary +30%. The drain can kill the Vessel. When the Vessel dies (from any source), the Cultist gains the Attune buff for 3 turns (see section 3.2.3.2) and a new random ally is marked as the Vessel if any is alive. If all allies are dead then nothing happens.
- Bar Brawler
    - A health focused character, dealing damage, tanking and applying a few buffs. Attacks scales of health primarily. Primary attributes: Health.
    - Purpose: Sustain, Buffer
    - Passive: "On the House!" - Whenever the Bar Brawler gains a buff, from any source, he shares a round: all living allies (the Bar Brawler included) heal a rarity-dependent percentage of their own max Health. The round is poured at most once between each of the Bar Brawler's turns - further buffs gained before his next turn do not trigger it again.
        - Heal per round: Uncommon 3%, Rare 4%, Epic 5%, Legendary 6%
- Bloodmage
    - Spending their own or allies health for big pay-off skills in terms of damage or applying shields based on sacrificed health. Primary attributes: Health, Mysticism.
    - Purpose: Sustain, Damage
    - Passive: Hemoclarity - While below 50% health, gain increased Mysticism.
        - 25% Uncommon, 30% Rare, 35% Epic, 40% Legendary
- Herald of the loom
    - A stance character, using 3 types of stances:
        - Golden thread; All buffs & debuffs only goes to the herald instead of allies.
        - Silver thread; All herald buffs & debuffs cast becomes more powerful, adds one attribute value to the accuracy attribute value when attempting to apply debuffs.
        - Black thread; All damage dealt and received scale with mysticism instead of other attributes. One other player & enemy character will have their attributes averaged out while Black thread is in use.  Primary attributes: Mysticism, Accuracy.
    - Purpose: Debuffer, Buffer
    - Passive: 
- Chronophage
    - A speed focused character, applying various speed modifying skills onto the turn bar and primarily deals damage based on the Speed attribute. Signature zones: Flicker Zone and Temporal Sinkhole (see section 3.2.4.1). Primary attributes: Speed.
    - Purpose: Control
    - Passive: Time Tithe - When the Chronophage's skills remove or reduce an enemy's turn bar, the Chronophage absorbs a portion of the stolen amount as its own turn-bar progress.
        - 25% Uncommon, 35% Rare, 45% Epic, 55% Legendary
- Architect
    - A methodical charge & support character aligned with the God of Rules. Instead of raw aggression, they construct "Logic Chains" over the course of battle, eventually "solving" the encounter with a massive structural shift. Primary attributes: Knowledge, Defense.
    - Purpose: Buffer, Damage
    - Passive: Calibration - The Architect accumulates Calibration charges (maximum 10; charges do not persist between combats). Basic skills grant one charge, and the Architect's constructed zone generates one charge per character that uses it. The Architect's non-basic skills consume charges and scale with the amount consumed: a few charges empower defensive ally buffs, while the finisher consumes all held charges and resolves in tiers - 1-3 charges deal damage only, 4-6 add a structural effect on top of the damage, 7-10 additionally re-erect the Architect's construction zone for free. Tier thresholds are fixed across rarities; rarity scales per-charge potency.
        - Per-charge potency: 4% Uncommon, 6% Rare, 8% Epic, 10% Legendary
        - Depends on the Architect's construction-zone skill (see `Plans/Plan_Architect_Calibration_Kit.md`); until it exists, charges are generated by basic skills alone.
- Tidal Corsair
    - Damage dealer. Primary attributes: Attack, Speed.
    - The Tidal Corsair is a Combo character where you plan your moves ahead, highly mobile but not inherently strong unless you set up your attacks correctly.
    - Purpose: Damage
    - Passive: Tidal Corsair Trait - Boarding Strike grants a Steel stack (+50% damage per stack
      on the finishing move), Saltwater Shot grants a Sea stack (-10% turn bar bump per stack
      on the finishing move). Corsair's Reckoning consumes all stacks. Up to 3 stacks can be
      held at a time.
        - Rarity scaling of these values is not yet implemented.
- Plague Doctor (Not yet implemented)
    - A debuff focused character, applying various damage over time and stat reducing debuffs to enemies. Signature zone: Miasma (see section 3.2.4.1). Primary attributes: Mysticism, Resistance.
    - Purpose: Debuffer
    - Passive: 
- Warlord (Not yet implemented)
    - A buffing tank character, applying various buffs to self and allies while being able to take a lot of damage. Primary attributes: Health, Defense.
    - Purpose: Sustain
    - Passive: Shield Wall - When an ally within 15% of the Warlord on the turn bar (in front or behind) takes attack damage, a portion of that damage is redirected to the Warlord instead. Proximity is checked at the moment the damage lands. Redirected damage is mitigated by the Warlord's Defense, not the ally's. AoE attacks are soaked separately for each affected ally within the window.
        - Redirected portion: 15% Uncommon, 20% Rare, 25% Epic, 30% Legendary

### 3.2. Combat
Combat is turn based, using the Speed attribute of each character to move a representation across a "turn bar". When a characters representation has crossed the entire bar, the game will pause for input to resolve their turn and then finish by putting the representation of the character back to the beginning. Then the system keeps going.

<br/>

There will be two types of combat, sharing all the core systems but one adds another layer of difficulty.

The first is simple fights to be routine and grind options to add to a players power fantasy, usually not requiring a specific combination of characters/skills but rather a numeric check of characters levels/gearing.

The second type is the main challenge in the form of puzzle of sorts. Each encounter should require one of two or three combinations of specific skills to defeat, or a significantly larger value of character levels/gearing than expected of the encounter.

<br/>

After a combat event, the players characters are healed to full and their skill cooldowns reset. They are given some kind of reward, usually in terms of experience and sometimes equipment.


#### 3.2.1. Combat Formulas
##### 1. Damage Calculation
Damage is ratio-based rather than subtractive: the attacker's scaled attributes are weighed
against the defender's Defence to produce a mitigation percentage, so no hit is ever fully
negated by a stat gap.

```
Caster_Scaled = Σ over the skill's weighted attributes (attribute_weight * Caster's attribute)
Effective_Defence = Defender's Defence * Skill's Defense_Ignore_Factor
Damage_Ratio = Caster_Scaled / (Effective_Defence + Caster_Scaled + 1)
Mitigation = Minimum_Damage_Percent + (1 - Minimum_Damage_Percent) * Damage_Ratio
Damage = Mitigation * Caster_Scaled * Critical_Multiplier * Random_Multiplier
```

- Every skill defines its own attribute weighting rather than a fixed Attack/Mysticism split,
  so a skill can scale off any mix of attributes (e.g. a Speed-scaling strike, or a hybrid of
  Attack and Knowledge). This is how Physical and Magical damage share one formula: the
  "school" of a skill is just which attributes its weighting favors.
- `Defense_Ignore_Factor` is a per-skill dial (0.0-1.0) for bypassing Defence — an armor-piercing
  skill sets it below 1.0, and 0.0 ignores Defence entirely.
- `Minimum_Damage_Percent` is a mitigation floor: no matter how far Defence outstrips the
  attacker's scaled attributes, every hit still chips away at the target.
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
- Both sides roll an independent random multiplier (0.95 to 1.0) against their stat; the debuff
  lands if the caster's rolled Accuracy exceeds the target's rolled Resistance.
- There is no base chance and no floor or ceiling: a sufficiently large Accuracy-Resistance gap
  makes a debuff land (or resist) with effective certainty. Encounters that rely on a debuff as
  the intended solution must be tuned so that counter-play's Accuracy beats the target's
  Resistance.

This formula makes Accuracy a key stat for your Strategist or Jester roles, who might rely more on disrupting enemies than on raw damage. Conversely, a high Resistance is crucial for a tank-like Knight to avoid crippling debuffs.

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
- A defender's Knowledge blunts incoming critical hits, giving Knowledge-scaling roles (e.g. the
  Strategist) a secondary defensive niche.
- `Minimum_Crit_Damage` ensures a critical hit always deals meaningfully more damage than a
  normal hit even against a very high-Knowledge defender.

#### 3.2.2. Magic system (only as a potential idea, might be discarded)
Strengths and weaknesses.
Most often require;
* Powerful reagents (consumable loot? Some reference to the 3rd god?)
* Chants (discoverable in e.g. ruins or hidden religious pagan texts, also reference to the 3rd god?)
    * The player might choose x numbers of chants to bring onto an adventure?
* Environmental conditions

#### 3.2.3. Status Effects
A status effect is a temporary condition that can affect a character's attributes, abilities, or behavior in combat. Status effects can be beneficial (buffs) or detrimental (debuffs) and can significantly influence the outcome of battles.

Unless stated otherwise, a buff or debuff lasts 2 turns.

##### 3.2.3.1 Turn Bar Effects
* Anchor (Debuff): The character cannot be pushed forward or backward on the turn bar by skills. (Not yet implemented)
* Temporal Leak (Debuff): Every time this character moves 10% of the bar, they take damage scaling with their own Speed. (Not yet implemented)
* Dead Weight (Debuff): When the character takes damage, they lose 3% turn bar. (Not yet implemented)
* Slipstream (Buff): The character passes through enemy-placed zones without triggering them. (Not yet implemented)
* Steadfast (Buff): The character cannot be moved backward on the turn bar. (Not yet implemented)
* Resonance (Buff): Ally-placed zones affect the character at double effect. (Not yet implemented)
* Battle Orders (Buff): When the character takes damage, all allies gain 5% turn bar. (Not yet implemented)

##### 3.2.3.2 Common Status Effects

Debuffs:
* Expose Weakness: Reduces Defense by 30%.
* Enfeeble: Reduces the Attack by 30%.
* Mana Burn: Deals damage whenever the target uses a non-basic skill, scaling based on the target's Mysticism. (Not yet implemented)
* Burning: Deals 4% of max Health as damage per stack; Burning stacks, so repeated applications (e.g. standing in a Lava zone) add independent instances up to the status-effect cap.
* Sequence Lock: Speed cannot be increased or decreased. (Not yet implemented)
* Suppress: Reduces Mysticism by 30%. (Not yet implemented)
* Slow: Reduces Speed by 15%. (Not yet implemented)
* Blind: Reduces Accuracy by 30%. (Not yet implemented)
* Unravel: Reduces Resistance by 30%. (Not yet implemented)
* Confound: Reduces Knowledge by 30%. (Not yet implemented)
* Exposed Facet: Attacks against the character gain +15 percentage points Critical Chance. (Not yet implemented)
* Bleed: At the start of the character's turn, they take damage scaling with the caster's Attack. (Not yet implemented)
* Plague: Deals magical damage each turn scaling with the caster's Mysticism; when it expires, it spreads to a random other enemy with fresh duration. (Not yet implemented)
* Blight: Healing received is reduced by 50%. (Not yet implemented)
* Severance: The character cannot gain new buffs. (Not yet implemented)
* Hexed: Roll calculations twice and take the worse result. (Not yet implemented)
* Stun: The character skips their next turn. (Not yet implemented)
* Fatigue: The character's skill cooldowns do not tick down. (Not yet implemented)
* Refracted: The character's single-target skills hit a random character instead, allies included. (Not yet implemented)
* Warped: The character's damage dealt scales with Mysticism instead of the skill's normal attribute. Whether other calculations are also forced through Mysticism is not yet decided. (Not yet implemented)
* Signed Writ: The character cannot resist debuffs. (Not yet implemented)
* Sanction: Reduces all primary attributes except Health by the applier's Standing Record rate per Infraction on the target, set at the moment of application (see the Emissary's passive in section 3.1.3). (Not yet implemented)

Buffs:
* Empower: Increases Attack by 30%.
* Fortify: Increases Defense by 30%.
* Daunting Strength: Doubles the damage of the next attack.
* Frenzy: Increases Attack and Speed but reduces Defense and Accuracy. (Not yet implemented)
* Rush: Increases all primary attributes except Health by 30%; when the buff expires, it applies the Stun debuff to the character for 1 turn. This Stun cannot be resisted and is applied after other expiring buffs (such as Aegis) are removed. (Not yet implemented)
* Exhert: Increases all primary attributes except Health by 20%, but the character loses 5% of their max Health every time they take a turn. (Not yet implemented)
* Luck: Roll calculations twice and take the better result. (Not yet implemented)
* Phalanx Guard: Gain bonus defense per stack of momentum consumed. (Lancer Specific)
* Attune: Increases Mysticism by 30%. (Not yet implemented)
* Haste: Increases Speed by 20%. (Not yet implemented)
* True Aim: Increases Accuracy by 30%. (Not yet implemented)
* Clarity: Increases Resistance by 30%. (Not yet implemented)
* Keen Edge: Increases Critical Chance by 15 percentage points. (Not yet implemented)
* Insight: Increases Knowledge by 30%. (Not yet implemented)
* Regeneration: Heals 4% of max Health at the start of each turn. (Not yet implemented)
* Barrier: A shield that absorbs damage up to a set amount before Health is touched. Barriers do not stack; a new Barrier replaces an existing one only if it is larger. (Not yet implemented)
* Deathward: The next hit that would be fatal instead leaves the character at 1 Health, then the buff is consumed. (Not yet implemented)
* Aegis: Blocks the next debuff that would land on the character, then the buff is consumed. (Not yet implemented)
* Mirror Coat: When a debuff lands on the character, a copy is applied to the attacker, checked against the attacker's Resistance as normal. (Not yet implemented)
* Opportunist: The character's attacks deal +10% damage per debuff on the target. (Not yet implemented)
* Catalyst: The next reagent the character consumes has +50% effect. Stacks additively with other reagent potency modifiers; has no effect on binary reagents (see section 3.3.3). (Not yet implemented)
* Wanderlust: At the start of each of the character's turns, gain +20% to one random primary stat until their next turn. (Not yet implemented)
* Overflow: When this buff expires, it deals magical damage to all enemies, scaling with the holder's Mysticism. (Not yet implemented)
* Vigor: Increases max Health by 30%. (Not yet implemented)
* Lethal Precision: Increases Critical Damage by 50%. (Not yet implemented)
* Spotlight: The character is much more likely to be targeted by enemies and takes 10% less damage. (Not yet implemented)
* Premonition: The next attack against the character automatically misses, then the buff is consumed. (Not yet implemented)
* Rehearsed: The character's next non-basic skill does not go on cooldown, then the buff is consumed. (Not yet implemented)

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

Of the skills a character has, they always have 1 basic skill that has no cooldown but in general is weaker or more basic than other skills.

##### 3.2.4.1 Zone System Rules
Turn bar skills apply effects to specific zones on the turn bar.

Zone system rules:
* The turn bar is divided into 5 sections. Each section can hold at most one zone at a time.
* When placing a zone, the player chooses which section it goes into. A section that already holds a zone cannot be targeted; the placement is blocked until that zone is gone.
* Trigger: when any character's turn starts, every character standing inside a zone is affected by it — but only once per visit. A character that has been affected by a zone is not affected by it again until they leave the section and re-enter it.
* Zones do not expire with time. A zone holds a set number of charges; each time it affects a character, one charge is consumed, and when the last charge is consumed the zone dissipates.
* Zones are removed only by dedicated clearing effects — the Scholar's kit and a zone-clearing reagent. There is deliberately no universal zone-clearing skill.
* Both sides place zones; the 5 sections are shared between allies and enemies.
* The effect of ally-placed zones scales with the placing character's Knowledge (see section 3.1.1).
* Each zone belongs to one of three lore families that define its visual language: order zones (God of Rules), unstable zones (God of Magic), and momentum zones (God of Adventure).

##### 3.2.4.2 Skills by Role
Skills allocated to a specific Role, listed in the same order as their entries in section 3.1.3. A Role with no skills assigned yet keeps a placeholder heading so its absence is visible at a glance.

###### Emissary
* Citation
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Magical Damage to a single target enemy, scaling with Knowledge, increased by the Standing Record rate per Infraction on the target.
* Signed Writ
    * Type: Debuff
    * Cooldown: 3 turns
    * Effect: Reduces the durations of all the target's buffs by 1 turn and applies the Signed Writ debuff for 1 turn (see section 3.2.3.2). If the target has 6 or more Infractions, buff durations are reduced by 2 turns and Signed Writ lasts 2 turns instead.
* Levied Sanction
    * Type: Debuff
    * Cooldown: 4 turns
    * Effect: Applies the Sanction debuff to a single enemy for 2 turns (see section 3.2.3.2); its potency is set by the target's Infraction tally at the moment of application.

###### Thief
* Stab
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Physical Damage to a single target enemy, scaling with Attack.
* Pierce Weakness
    * Type: Damage
    * Cooldown: 2 turns
    * Effect: Deals Physical Damage to a single enemy, ignoring 60% of the target's Defense, scaling with Attack.
* Case the Target
    * Type: Buff
    * Cooldown: 3 turns
    * Effect: The Thief gains the Opportunist buff for 2 turns (see section 3.2.3.2).

###### Lancer
* Lance Thrust
    * Type: Damage (basic skill, no cooldown; counts as an offensive skill)
    * Effect: Deals Physical Damage to a single target enemy, scaling with Attack.
* Rending Charge
    * Type: Damage, Debuff (counts as an offensive skill)
    * Cooldown: 3 turns
    * Effect: Deals heavy Physical Damage to a single enemy, scaling with Attack, and applies the Bleed debuff for 2 turns (see section 3.2.3.2).
* Disarm
    * Type: Damage, Debuff (counts as a defensive skill)
    * Cooldown: 3 turns
    * Effect: Deals Physical Damage to a single enemy and applies the Enfeeble debuff for 2 turns (see section 3.2.3.2).

###### Alchemist
* Acrid Splash
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Magical Damage to a single target enemy, scaling with Knowledge.
* Catalyst Cloud
    * Type: Turn Bar (Zone)
    * Cooldown: 3 turns
    * Effect: Affected allies gain the Catalyst buff for 2 turns (see section 3.2.3.2). Holds 4 charges.
* Dissolving Agent
    * Type: Debuff
    * Cooldown: 3 turns
    * Effect: Applies the Unravel debuff to a single enemy for 2 turns (see section 3.2.3.2).

###### Sorcerer
* Arc Lash
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Magical Damage to a single target enemy, scaling with Mysticism.
* Unstable Rift
    * Type: Turn Bar (Zone)
    * Cooldown: 3 turns
    * Effect: All affected characters, allies and enemies alike, gain the Warped debuff for 2 turns (see section 3.2.3.2) and take Magical Damage scaling with the Sorcerer's Mysticism — enemies take 30% of a standard hit, allies 15%. Holds 5 charges.
* Cataclysmic Surge
    * Type: Damage (AoE)
    * Cooldown: 4 turns
    * Effect: Deals Magical Damage to all enemies, scaling with Mysticism. Targets currently affected by the Warped debuff take 30% increased damage.

###### Scholar
* Sharp Rebuttal
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Magical Damage to a single target enemy, scaling with Knowledge.
* Refutation
    * Type: Turn Bar
    * Cooldown: 3 turns
    * Effect: Removes one zone of the Scholar's choice from the turn bar. If the zone was enemy-placed, the enemy who placed it takes Magical Damage scaling with Knowledge — 10% of a standard hit per charge remaining on the zone. If it was ally-placed, the placing ally's zone skill has its cooldown reduced by 2.
* Expose Fallacy
    * Type: Debuff, Buff
    * Cooldown: 3 turns
    * Effect: Applies the Confound debuff to a single enemy for 2 turns and grants all allies the Opportunist buff for 2 turns (see section 3.2.3.2).

###### Diviner
* Fateful Glimpse
    * Type: Damage, Heal (basic skill, no cooldown)
    * Effect: Deals minor Magical Damage to a single target enemy and restores a small amount of Health to the most injured ally (the Diviner included), both scaling with Mysticism.
* Premonition
    * Type: Buff
    * Cooldown: 3 turns
    * Effect: Grants an ally the Premonition buff for 1 turn (see section 3.2.3.2).
* Ill Omen
    * Type: Damage, Debuff
    * Cooldown: 3 turns
    * Effect: Deals Magical Damage to a single enemy, scaling with Mysticism, and applies the Hexed debuff for 2 turns (see section 3.2.3.2).

###### Appraiser
* Sizing Cut
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Physical Damage to a single target enemy, scaling with Knowledge.
* Flaw Analysis
    * Type: Debuff
    * Cooldown: 2 turns
    * Effect: Applies the Exposed Facet debuff to a single enemy for 2 turns (see section 3.2.3.2).
* (Third skill not yet decided.)

###### Tactician
* Signal Strike
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Physical Damage to a single target enemy, scaling with Knowledge.
* Fatal Flaw
    * Type: Buff
    * Cooldown: 2 turns
    * Effect: One ally gains the Daunting Strength buff for 1 turn (see section 3.2.3.2).
* Battle Orders
    * Type: Buff (Turn Bar)
    * Cooldown: 4 turns
    * Effect: One ally gains the Battle Orders turn bar buff for 2 turns (see section 3.2.3.1).

###### Symbiote
* Spore Lash
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Magical Damage to a single target enemy, scaling with Resistance.
* Symbiotic Overdrive
    * Type: Buff
    * Cooldown: 5 turns
    * Effect: The Symbiote gains the Exhert buff for 4 turns (see section 3.2.3.2).
* Grafted Flesh
    * Type: Buff, Heal
    * Cooldown: 3 turns
    * Effect: The Symbiote loses 10% of its max Health; one ally gains the Regeneration buff for 3 turns (see section 3.2.3.2).

###### Jester
* Pratfall Sting
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Physical Damage to a single target enemy, scaling with Accuracy. Deals +30% damage if the Jester avoided an attack since their last turn.
* Burning Bolas
    * Type: Damage, Debuff
    * Cooldown: 2 turns
    * Effect: Throws flaming bolas at a single enemy, dealing Physical Damage scaling with Attack, and applies the Burning debuff for 2 turns (see section 3.2.3.2).
* Center Stage
    * Type: Buff
    * Cooldown: 3 turns
    * Effect: The Jester gains the Spotlight buff for 2 turns and the Luck buff for 1 turn (see section 3.2.3.2).

###### Cultist
* Profane Bolt
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Magical Damage to a single target enemy, scaling with Mysticism.
* Devour Blessing
    * Type: Damage
    * Cooldown: 3 turns
    * Effect: Consumes all buffs on one ally; deals heavy Magical Damage to a single enemy, scaling with Mysticism, +25% damage per buff consumed.
* Rite of Severance
    * Type: Damage, Debuff
    * Cooldown: 4 turns
    * Effect: Deals Magical Damage to a single enemy and applies the Severance debuff for 2 turns (see section 3.2.3.2).

###### Bar Brawler
* Heap on
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Physical Damage to one enemy, scaling with Health, and grows stronger with every use.
* Liquid Courage
    * Type: Buff, Heal
    * Cooldown: 3 turns
    * Effect: The Bar Brawler gains the Vigor buff for 2 turns (see section 3.2.3.2) and heals 15% of max Health.
* Headbutt
    * Type: Damage, Debuff (Turn Bar)
    * Cooldown: 3 turns
    * Effect: Deals Physical Damage to a single enemy, scaling with Health, and applies the Dead Weight debuff for 2 turns (see section 3.2.3.1).

###### Bloodmage
* Blood Bolt
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Magical Damage to a single target enemy, scaling with Mysticism. Costs 3% of the Bloodmage's max Health to cast.
* Transfusion
    * Type: Buff
    * Cooldown: 3 turns
    * Effect: The Bloodmage sacrifices 15% of max Health; one ally gains a Barrier absorbing 200% of the Health sacrificed, lasting 2 turns (see section 3.2.3.2).
* Tithe of Vitality
    * Type: Damage, Debuff
    * Cooldown: 4 turns
    * Effect: Drains 10% of max Health from each living ally (the Bloodmage excluded). Deals moderate Magical Damage to a single enemy, scaling with Mysticism, and applies the Mana Burn debuff for 2 turns (see section 3.2.3.2).

###### Herald of the loom
* Thread Snap
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Magical Damage to a single target enemy, scaling with Mysticism.
* Thread Lash
    * Type: Damage, Debuff
    * Cooldown: 3 turns
    * Effect: Deals Magical Damage to a single enemy and applies the Suppress debuff for 2 turns (see section 3.2.3.2).
* Woven Blessing
    * Type: Buff
    * Cooldown: 3 turns
    * Effect: One ally gains the Attune buff for 2 turns (see section 3.2.3.2).

###### Chronophage
* Zap
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Magical Damage to a single target enemy, scaling with Speed. (Also available as a Universal skill, see section 3.2.4.3.)
* Flicker Zone
    * Type: Turn Bar (Zone)
    * Cooldown: 3 turns
    * Effect: Affected allies move 15% further on the turn bar. Holds 5 charges.
* Temporal Sinkhole
    * Type: Turn Bar (Zone)
    * Cooldown: 4 turns
    * Effect: Affected enemies lose a portion of their turn bar progress. Holds 4 charges.

###### Architect
* Cornerstone
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Physical Damage to a single target enemy, scaling with Knowledge, and generates one Calibration charge.
* Raise the Frame
    * Type: Turn Bar (Zone)
    * Cooldown: 2 turns
    * Effect: Constructs a zone: affected allies gain the Barrier buff for 2 turns (see section 3.2.3.2), sized by the Calibration charges invested in the construction. Holds 5 charges.
* Final Calculation
    * Type: Damage
    * Cooldown: 3 turns
    * Effect: Consumes all held Calibration charges: 1-3 charges deal damage only; 4-6 also apply the Expose Weakness debuff for 2 turns (see section 3.2.3.2); 7-10 additionally re-erect the Architect's construction zone for free.

###### Tidal Corsair
* Boarding Strike
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Physical Damage to a single target enemy, scaling with Attack, and grants the Tidal Corsair one Steel stack.
* Saltwater Shot
    * Type: Damage (no cooldown)
    * Effect: Deals Physical Damage to a single target enemy, scaling with Attack, and grants the Tidal Corsair one Sea stack.
* Corsair's Reckoning
    * Type: Damage
    * Cooldown: 3 turns
    * Effect: A devastating blow consuming all held stacks: +50% damage per Steel stack; the target loses 10% turn bar progress per Sea stack.

###### Plague Doctor
* Septic Lance
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Magical Damage to a single target enemy, scaling with Mysticism.
* Miasma
    * Type: Turn Bar (Zone)
    * Cooldown: 3 turns
    * Effect: Affected enemies gain the Plague debuff for 3 turns (see section 3.2.3.2). Holds 4 charges.
* Quarantine Breach
    * Type: Damage, Debuff
    * Cooldown: 4 turns
    * Effect: Deals Magical Damage to a single enemy and applies the Blight debuff for 2 turns (see section 3.2.3.2).

###### Warlord
* Shield Slam
    * Type: Damage (basic skill, no cooldown)
    * Effect: Deals Physical Damage to a single target enemy, scaling with Defense.
* Hold the Line
    * Type: Buff
    * Cooldown: 3 turns
    * Effect: All allies gain the Fortify buff for 2 turns (see section 3.2.3.2).
* Brace for Impact
    * Type: Buff
    * Cooldown: 4 turns
    * Effect: The Warlord gains the Rush buff and the Aegis buff for 1 turn each (see section 3.2.3.2). When Rush expires, the Warlord receives the Stun debuff per the Rush effect.

##### 3.2.4.3 Unassigned / Generic Skills
Not yet tied to a specific Role, grouped by mechanical type for lookup.

**Turn Bar (Zone Effects)**
* Weight of Law
    * Effect: Affected enemies are Stunned for their next turn.

**Universal**
* Pagan Curse
    * Type: Debuff
    * Effect: A ticking debuff. After 3 turns, the character is hit with a massive burst of Magical Damage unless they use a specific Chant to cleanse it.
* Zap
    * Type: Damage
    * Effect: Deals Magical Damage to a single target enemy, scaling with Speed.
* Stab
    * Type: Damage
    * Effect: Deals Physical Damage to a single target enemy, scaling with Attack.

##### 3.2.4.4 Opponent Skills
* Break Guard
    * Type: Damage, Debuff
    * Cooldown: 2 turns
    * Effect: A blunt tackle dealing Physical Damage to a single target, scaling with Attack, and applies the Expose Weakness debuff for 2 turns (see section 3.2.3.2).

### 3.3. Items and Resources

#### 3.3.1. Itemization
Each character can have 3 or 4 types of equipment, a weapon, off-hand (shield, book or something), boots and if certain a talent tree node has been acquired then a "trinket" can also be equipped. These four pieces (Weapon, Off-hand, Boots, Trinket) are the core intended loadout.

The codebase additionally defines six more equipment slots (Helmet, Chest, Pants, Gloves, Ring, Amulet) for future flexibility. These are optional and not currently in scope for itemization design or content — no items or drop tables target them yet.

Rarity for items:
* Common
* Uncommon
* Rare
* Epic
* Legendary
* Relic
    * Has both upsides and downsides. Shall have a unique effect.

Each step in rarity adds one attribute bonus for the equipping character, except for Relic rarity that instead adds a strong unique bonus and a downside.

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

Rules (designed; implementation planned in `Plans/Plan_Reagent_Data_And_Catalog.md`,
`Plans/Plan_Reagent_Inventory_And_Storage_UI.md`, and
`Plans/Plan_Reagent_Combat_Application.md`):
- Before a battle the player selects up to 3 reagents from their inventory to bring along.
- Each brought reagent can be consumed exactly once per battle, by any champion on
  their turn, as a free action (it does not consume the turn). Reagents are usable
  strictly on the consumer's own turn, never reactively.
- A consumed reagent is permanently deleted; reagents brought but not used return to
  the inventory.
- Reagents can be sold for Silver from the reagent storage screen (in the collection
  menu). Sell values scale with rarity (values not yet decided).
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

Families — one entry per rarity tier:
* Tinctures: one family per primary attribute. A small battle-long increase to that
  attribute. Not a buff: undispellable, unstealable, and invisible to buff-counting
  effects. Deliberately weaker than the equivalent 30% buff.
* Restorative Draught: heals one ally for a percentage of max Health.
* Purging Tonic: removes up to N debuffs from one ally, N set by rarity.
* Thief's Regret: destroys (not steals) up to N buffs on one enemy, N set by rarity.
* Barrier Stone: grants one ally a Barrier with a flat absorb amount set by rarity.
* Rewinding Grit: ticks one chosen skill's cooldown down by (1/1/1/2) turns, set by rarity.
* Second Wind Phial: after the consumer's current turn ends, their turn bar resets to
  15/20/25/30% (by rarity) instead of 0. Self-only.

Singletons:
* Zone-Dissolving Salts (Binary): clears one targeted zone section (one of the two
  dedicated zone-clearing effects, see section 3.2.4.1).
* Deathward Charm (Binary): applies the Deathward buff to one ally.
* Chant Fragment (Binary): cleanses Pagan Curse from one ally. God of Magic lore family.
* Notarized Seal (Binary): applies the Signed Writ debuff to one enemy for 1 turn. God of Rules
  lore family.
* Wayfarer's Draught: applies Wanderlust to the consumer, with the random-stat bonus
  percentage set by rarity instead of the buff's standard value. God of Adventure
  lore family.
* Unrefined Residue: applies the effect of one random tincture family. God of Magic
  lore family.
* Fractured Idol: a crumbling artifact of the Forgotten God. Deals 10/14/18/22% (by
  rarity) of the consumer's max Health as damage (cannot reduce the consumer below
  1 Health) and grants a battle-long +10/13/16/20% (by rarity) to damage dealt.
  Potency modifiers raise both the cost and the bonus. God of Magic lore family.

Alchemist brew pool — an Alchemist-exclusive pool of lesser scalar reagents; pool
size is 3 at Uncommon and Rare, 4 at Epic and Legendary:
* Lesser Restorative Brew: a small heal for a percentage of one ally's max Health.
* Lesser Tincture: a small battle-long increase to one random primary attribute of
  one ally.
* Lesser Barrier Brew: a small Barrier on one ally.
* Lesser Purging Brew (Epic and Legendary Alchemists only): removes one debuff from
  one ally.

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
Where players can purchase consumables, gear, and other items using various currencies.

### 3.7 Energy Systems
To limit daily player activity, an energy system will be implemented. Players will have a set amount of Energy (Supplies) that depletes when entering combat nodes. Supplies regenerate over time at a rate of +10 per 10 real-world minutes, up to a cap of 100, and can also be replenished through in-game actions or purchases. Regeneration is offline-aware: elapsed real time is applied on load, with partial progress toward the next +10 preserved.

### 3.8 Reward structure
The idea is to have every encounter hold a "loot table" of possible drops. Some drops may always drop for certain encounters.
Then each drop is given a "reward value", where e.g.
- X silver is Y reward value points
- X experience is Y reward value points
- Gear of rarity Z is Y reward value points equivalent

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
- **Escalate**: offers Silver and/or Supplies (15% of the encounter's reward budget) in
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

So there now is 3 encounters to choose from for gear farming, one per equippable item.

##### 5.2.2.1 Reanimating Statues 1 (Boots)
This encounter is a against a statue that relies on very high speed and through that attack many times, using skills to get slightly faster each turn. The player can utilize e.g. Sequence Lock and/or Anchor to mitigate the speed.

##### 5.2.2.2 Reanimating Statues 2 (Weapons)
This encounter is against a statue that use a very high damage single target attack every few turns, so the player can utilize the Enfeeble debuff to reduce the hit or using some defensive skill from a Sustain focused character.

##### 5.2.2.3 Reanimating Statues 3 (Off-hands)
This encounter is against a statue that has high defense, so the player can utilize the debuffs Expose Weakness to deal more damage to it or for example Burning to deal a percentage of its health.

#### 5.2.3. Caravan (Currency encounter)


## 6. Development tools
- Godot Engine version 4.5

