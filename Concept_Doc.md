# Game Concept Document: Character Collector (Temporary name)

---

## 1. Introduction
This game is a turn based combat RPG. The main idea is to collect characters that the player can use in combat, each of them with slightly different skill sets to defeat the encounters.

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
| Mid-Term (Weekly) | Strategy | Solving "Puzzle" encounters and bosses to acquire Role-specific gear or rare Trinkets; participating in rotating God events (e.g., God of Structure’s floor dungeon). |
| Long-Term (Monthly) | Collection | Using thematic resources to acquire new characters, completing faction-specific synergies, and uncovering the "Forgotten God" through world exploration. |


---

## 3. Core Mechanics
- Collecting characters
- Turn based strategic combat
- Bosses
- Gearing characters
- Upgrading character skills
- Energy system to restrict daily player activity
- Applying effects onto the turn bar. If a character stops within applied zones of the bar, certain effects trigger. The turn bar is split into a set of "zones" that can have effects applied to them through skills.

### 3.1. Champion Management
TODO

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
        * Influences the effectiveness of buffs and debuffs applied by the character. Also reduces critical damage taken.
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
* Aura?
* Synergy through combination of faction or characters
* Area?
* Home base upgrades?
* Clan
* Events

#### 3.1.3. Character Role
Each character role should define a baseline for a character but not necessarily the specifics of it. It will restrict which skills it could use as well as define its’ starting primary attributes.

Current roles, their identity and purpose exist as follows:
- Emissary
    - TODO
- Thief
    - A squishy damage dealer, focusing on set-up through skills and bypassing enemy defenses, can steal buffs. Primary attributes: Attack.
- Lancer
    - TODO
- Alchemist
    - A support character that focuses on buffing allies and debuffing enemies through various concoctions. Primary attributes: Knowledge, Mysticism.
- Sorcerer
    - A damage dealer that harnesses the power of magic to deal Area of Effect damage and control the battlefield. Primary attributes: Mysticism, Knowledge.
- Scholar
    - A support character that focuses on knowledge and strategy to enhance allies' abilities and exploit enemy weaknesses. Primary attributes: Knowledge.
- Diviner
    - Gains buffs (On self and allies if high rarity Diviner) if enemies are x-y% (depending on rarity of Diviner) behind the Diviner on the turn bar when their turn starts. Primary attributes: Mysticism.
- Appraiser
    - A master at exploiting enemy weaknesses, allowing oppertunity for the team to easily deal critical hits. Primary attributes: Critical Chance, Knowledge.
- Tactician
    - Gives buffs (On self and allies if high rarity Tactician) if allies are x-y% (depending on rarity of Tactician) behind the Tactician on the turn bar when their turn starts. Primary attributes: Knowledge, Speed.
- Symbiote
    - A character weak by default but given the option to alter itself to combine with one of select few monsters to gain their trait & bonus in attributes. Primary attributes: Health, Resistance.
- Jester
    - An unconventional tanking character that does not have significantly high Health or Defense but relies on skills that provoke hits to the Jester and dodge them. Primary attributes: Accuracy, Knowledge, Speed.
- Cultist
    - Consumes ally buffs or health to empower their own skills, dealing magical damage or applying debuffs. Primary attributes: Mysticism, Knowledge.
- Bar Brawler
    - A health focused character, dealing damage, tanking and applying few debuffs. Attacks scales of health primarily. Primary attributes: Health.
- Bloodmage
    - Spending their own or allies health for big pay-off skills in terms of damage or applying shields based on sacrificed health. Primary attributes: Health, Mysticism.
- Herald of the loom
    - A stance character, using 3 types of stances:
        - Golden thread; All buffs & debuffs only goes to the herald instead of allies.
        - Silver thread; All herald buffs & debuffs cast becomes more powerfull, adds one attribute value to the accuracy attribute value when attempting to apply debuffs.
        - Black thread; All damage dealt and received scale with mysticism instead of other attributes. One other player & enemy character will have their attributes averaged out while Black thread is in use.  Primary attributes: Mysticism, Accuracy.
- Chronophage
    - A speed focused character, applying various speed modifying skills onto the turn bar and primarily deals damage based on the Speed attribute. Primary attributes: Speed.
- Architect
    - A charge & support character, accumulates Calibration charges through basic skills, consumes a few charges applying defensive buffs to allies and massive charges for big final attacks. Primary attributes: Knowledge, Defense.
    - The Architect is a methodical "Charge" role aligned with the God of Rules. Instead of raw aggression, they build "Logic Chains" by observing the flow of battle, eventually "solving" the encounter with a massive structural shift.

### 3.2. Combat
Combat is turn based, using the Speed attribute of each character to move a representation accross a "turn bar". When a characters representation has crossed the entire bar, the game will pause for input to resolve their turn and then finish by putting the representation of the character back to the beginning. Then the system keeps going.

<br/>

There will be two types of combat, sharing all the core systems but one adds another layer of difficulty.

The first is simple fights to be routine and grind options to add to a players power fantasy, usually not requiring a specific combination of characters/skills but rather a numeric check of characters levels/gearing.

The second type is the main challenge in the form of puzzle of sorts. Each encounter should require one of two or three combinations of specific skills to defeat, or a significantly larger value of character levels/gearing than expected of the encounter.

<br/>


#### 3.2.1. Combat Formulas
##### 1. Damage Calculation
Use a multiplicative formula that involves both the attacker's Attack and the defender's Defence attributes, other attributes can substitute Attack depending on the attackers Role or Skill used.

**Physical Damage Formula:**
```
Damage = (Attacker's Attack - Defender's Defence) * Random_Multiplier
```
- The `Random_Multiplier` adds an element of chance, preventing every hit from being the exact same value. A range of 0.95 to 1.05 is a good starting point.
- You'll need a clause for when the result is negative. A good rule is to cap the damage at a minimum value, such as 1 or 5, to ensure all hits do some damage.

**Magical Damage Formula:**
This is where your Mysticism stat comes in. It should function similarly to Attack but for magical attacks.
```
Magical Damage = (Attacker's Mysticism - ((Defender's Resistance + Defender’s Defence) / 2))) * Random_Multiplier
```
- This formula gives a clear distinction between physical and magical combat roles. A Sorcerer's high Mysticism will be their main damage source, while a Knight's high Attack will be theirs.

##### 2. Turn Order and Speed
Your Speed stat is crucial for a turn-based system. A simple and effective way to handle it is to use it to determine the turn order at the start of each round.

**Turn Order Formula:**
The character or enemy with the highest Speed acts first, followed by the next highest, and so on.
- You can introduce ties by randomizing the order among characters with the same Speed.
- This makes Speed a valuable stat for all roles, as acting first can be a significant advantage.

##### 3. Debuff and Status Effect Application
Main attributes: Accuracy and Resistance.

**Debuff Success Rate Formula:**
```
Success Rate = Base Chance + (Caster's Accuracy - Target's Resistance) * Multiplier
```
- The `Base Chance` is the innate probability of the debuff landing (e.g., a "Poison" spell might have a 60% base chance).
- The `Multiplier` should be a small number (e.g., 0.5% to 1.0%) to ensure that small differences in stats don't make debuffs guaranteed to hit or miss.
- The result should be capped at a minimum and maximum, such as 10% to 90%, to ensure some level of uncertainty remains.

This formula makes Accuracy a key stat for your Strategist or Jester roles, who might rely more on disrupting enemies than on raw damage. Conversely, a high Resistance is crucial for a tank-like Knight to avoid crippling debuffs.

##### 4. Critical Hits
Critical hits add an element of excitement and potential for big plays.

**Critical Hit Chance Formula:**
The chance to land a critical hit can be a fixed value for each character/enemy, or it can be based on a stat (e.g., a "Critical" stat you might want to add).
- A simple approach is to have a fixed 5% to 10% chance.
- When a critical hit occurs, a `Critical Damage Multiplier` is applied to the final damage (e.g., 1.5x or 2.0x). This multiplier can be a static value or tied to another stat.

#### 3.2.2. Magic system (only as a potential idea, might be discarded)
Strengths and weaknesses.
Most often require;
* Powerful reagents (consumable loot? Some reference to the 3rd god?)
* Chants (discoverable in e.g. ruins or hidden religious pagan texts, also reference to the 3rd god?)
    * The player might choose x numbers of chants to bring onto an adventure?
* Environmental conditions

#### 3.2.3. Status Effects
A status effect is a temporary condition that can affect a character's attributes, abilities, or behavior in combat. Status effects can be beneficial (buffs) or detrimental (debuffs) and can significantly influence the outcome of battles.

##### 3.2.3.1 Turn Bar Effects
* Anchor (Debuff): The character cannot be pushed forward or backward on the turn bar by skills.
* Temporal Leak (Debuff): Every time this character moves 10% of the bar, they take damage scaling with their own Speed.

##### 3.2.3.2 Common Status Effects
* Expose Weakness (Debuff): Reduces Resistance and Defense by a percentage amount.
* Mana Burn	(Debuff): Deals damage whenever the target uses a skill, scaling based on the target's Mysticism.
* Frenzy (Buff): Increases Attack and Speed but reduces Defense and Accuracy.
* Rush (Buff): Bonus stats for a few turns then getting stunned for one turn.
* Exhert (Buff): Gain bonus stats at the cost of losing Health.
* Luck (Buff): Roll calculations twice and take the better result.
* Burn (Debuff): Deals 5% of max Health as damage.

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

##### 3.2.4.1 Turn Bar Skills
Turn bar skills apply effects to specific zones on the turn bar. When a character's turn starts, all characters within a zone that has an effect applied to it from a skill or environmental effect will be affected.

* Weight of Law (Zone Effect): Affected enemies are Stunned for their next turn.
* Flicker zone (Zone Effect): Affected allies move 15% further on the turn bar when they reach this zone.

##### 3.2.4.2 Role Specific Skills
* Symbiotic Overdrive (Symbiote): Increases all primary attributes by 20% but causes the character to lose 5% of their max Health every time they take a turn.
* Burning Bolas (Jester): Throws flaming bolas at an enemy, dealing damage and applying the Burn debuff, scaling of Attack.

##### 4.2.4.3 Universal Skills
* Pagan Curse: A ticking debuff. After 3 turns, the character is hit with a massive burst of Magical Damage unless they use a specific Chant to cleanse it.
* Zap (Damage Skill): Deals Magical Damage to a single target enemy, scaling with Speed.
* Heap on (Damage Skill): Deals damage to one enemy, scaling with Health and grows stronger with every use.
* Stab (Damage Skill): Deals Physical Damage to a single target enemy, scaling with Attack.

### 3.3. Items and Resources

#### 3.3.1. Itemization
Each character can have 3 or 4 types of equipment, a weapon, off-hand (shield, book or something), boots and if certain a talent tree node has been acquired then a "trinket" can also be equipped.

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
- Energy of some kind (probably food or supplies or something)
- Some kind of thematic resource to acquire new characters

### 3.4. Game Modes
TODO

#### 3.6.1. Main Campaign
TODO

#### 3.6.2. Daily/Weekly Challenges
TODO

#### 3.6.3. Draft Mode
The player faces a series of battles, each time asked to in a specific order ban and pick characters from their collection and a set of random characters for the opponent.

Order:
| Player | Computer |
|--------|----------|
| Ban    |          |
|        | Ban      |
| Pick   |          |
|        | Pick     |
| Ban    |          |
|        | Ban      |
| Pick   |          |
|        | Pick     |
| Ban    |          |
|        | Ban      |
| Pick   |          |
|        | Pick     |

#### 3.6.4. Roguelite Mode
TODO

### 3.5. Events
Maybe a rotating schedule composed of one type of event per god? E.g.
*   **God of Structure**
    *   A numeric “floor” dungeon like raids doom tower
*   **God of Adventure**
    *   A small storyline, quest
    *   Some boss and or mystery
*   **God of Magic**
    *   Chaotic event, involving many elements that change often?


---

## 4. World and Narrative
TODO

### 4.1. Religion

In this world there are 3 gods that created it, but through their effort they have litte power left to affect it directly. There was the god of adventure, the god of rules and the god of magic. The god of magic was betrayed by the other two and imprisoned somewhere unknown. The only remaining mark of the god of magic is the magic system, which is now heavily restricted and shunned by the other two gods through their doctrines, leaving magic to be a rare and obscure art.

The reason for betrayal is since while initially magic provided many oppertunities and options for adventure and structure, it eventually became clear that magic could easily break both adventure and structure if left unchecked. The god of adventure saw magic as a way to create endless possibilities, but the god of rules viewed it as a chaotic force that undermined order and predictability. Fearing the destabilizing potential of magic, the god of rules conspired with the god of adventure to imprison the god of magic, believing that by doing so, they could preserve their own domains.

Believers grant the gods power, but very slowly. Fragments of the god of magic exists in ruins written in obscure languages only used in history.
The god of magics only mark left on the world other than ruins is the magic system.
Since the imprisonment the magic system became very restricted in terms of conjuration and effect, often requiring powerful reagents, chants only known in parts or environmental conditions.

#### God 1, the god of adventure

The God of Adventure is the divine personification of curiosity, risk, and the thrill of the unknown. Unlike the God of Rules, who seeks to categorize the world into letters and numbers, the God of Adventure views the world as a vast, unpredictable playground. This deity is a playful thrill-seeker who lacks the power to manifest physically and instead watches the creatures of the world with a voyeuristic intensity, seeking to live vicariously through their triumphs and tragedies.

The god is indifferent to the survival of their followers; a spectacular, high-stakes failure is considered just as entertaining as a victory. This is reflected in mechanics like the "Frenzy" buff, which grants great power at the cost of "Defense" and "Accuracy," embodying the god's preference for glass-cannon heroics.

#### God 2, the god of Rules (Structure, Regulation & Logic)

Created order and systems in the world, letters and numbers.
The God of Rules is the divine architect of reality, responsible for the creation of order, systems, letters, and numbers. This deity views the world as a complex machine that functions best when every gear turns with mathematical precision. While the God of Adventure thrives on the chaos of the unknown, the God of Rules demands predictability and strategic foresight.

#### God 3, the god of magic

The God of Magic holds immense knowledge of the arcane arts and the mysteries of the universe. This deity is a master of transformation, capable of bending reality to their will through spells and enchantments. However, their power is a double-edged sword; while they can create wonders, they can also unleash chaos if not properly controlled. Holding that much knowledge but in trade naive to the ways of interaction, with only interest in exploring their possibilities of creation.

### 4.2. Factions
- Humans
  - multiple kingdoms?
- Bandits?
- Pirates?
- Trolls
- Elves?
- Dwarfs?
- Fae?
