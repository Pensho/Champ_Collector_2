# Game design manifest

---

## Table of contents
- Champ Collector
- Factions
- Possible enhancements of characters
- Resources
- Items
- Util
- Character roles
- Effects
- Minimum viable product
- Content fill
- WorldBuilding
- Religion
- God 1, the god of adventure
- God 2, the god of Rules (Structure/Process/Strategy/Law/Instruction/Regulation/Sense/Logic)
- God 3, the god of magic
- Rival
- Magic system
- Combat
- Combat formulas
- Events
- Level up system
- Passive tree designers
- Godot stuff

---

## Champ Collector
- Champion collector gacha
- Low fantasy
- Hallway auto battles - choose different forks in the road
- Multiple factions and kingdoms
- What type of bosses?
- What type of gear?
- Auras?
- AI generated concept art

## Factions
- Humans
- Bandits
- Pirates
- Trolls
- Elves?
- Dwarfs?
- Fae?

## Possible enhancements of characters
* Level
* Tier
* Gear
* Ascension
* Skill levels
* Talent points
* Aura
* Role?
* Combination of faction or characters
* Area
* Home base upgrades
* Clan
* Event

## Resources
- Currency to speed up
- Area unlock currency
- Energy of some kind
- Silver
- Gems
- Shards

In-game currency could include some PoE currency to alter items, e.g. Exalts to increase the rarity of an item and add an affix. Chaos to randomize new affixes. Annulment to remove a random affix and reduce the rarity.

## Items
Rarity for items:
* Common
* Uncommon
* Rare
* Epic
* Legendary
* Relic
    * Has both upsides and downsides. Shall have a unique effect.

Items can exist for general use that most characters can use and Role specific type of items.

Items can have specific bosses that they only drop from at a low rate.

## Util
- Two types of battles - Armies & Duels
- Online user account
- Leaderboard for progression and clearing time
- Fat character Explode and modify area

## Character roles
Each character role should define a baseline for a character but not necessarily the specifics of it. It will restrict which skills it could use as well as define its’ starting attributes.
Existing roles are defined here: Characters

## Effects
* Particles
* Sounds
* Light

## Minimum viable product
* Champion pull
* Champion collection
* Battles (Duel?)
    * 3 battles (one main and follow-up options)

## Content fill
* Battles (Army)
* Negotiation conflict

### Character attributes
* Level
* Experience
* Health
* Speed
* Attack
* Defence
* Skill levels
* Role
* Affinity
* Faction
* Rarity
* Accuracy
* Resistance
* Name
* Rank
* Reputation

## WorldBuilding

### Religion
One or multiple gods exist but they have spent their power already to affect the world in their vision.
Maybe 3 gods, one “forgotten” due to the other 2. They all helped create the world but the 2 betrayed the 3rd to garner believers for themselves. Believers grant the gods power, but very slowly. Fragments of the 3rd god exist in ruins written in obscure languages only used in history.
The 3rds only mark left on the world other than ruins is the magic system, which the other 2 now forcefully shuns through their doctrines.
Since the 3rds imprisonment the magic system became very restricted in terms of conjuration and effect, often requiring powerful reagents, chants only known in parts or environmental conditions.

#### God 1, the god of adventure
#### God 2, the god of Rules (Structure/Process/Strategy/Law/Instruction/Regulation/Sense/Logic)
Created order and systems in the world, letters and numbers.
#### God 3, the god of magic

### Rival
Maybe have a character that follows along helping out at times and competing at times, potentially betraying the player in the 3rd quarter of the game to become the boss?

### Magic system
Strengths and weaknesses.
Most often require;
* Powerful reagents (consumable loot? Some reference to the 3rd god?)
* Chants (discoverable in e.g. ruins or hidden religious pagan texts, also reference to the 3rd god?)
* Environmental conditions ()

## Combat
Turn based combat, speed determines who goes first and then in descending order.

### Combat formulas

#### 1. Damage Calculation
A common and effective approach is to use a multiplicative formula that involves both the attacker's Attack and the defender's Defence.

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

#### 2. Turn Order and Speed
Your Speed stat is crucial for a turn-based system. A simple and effective way to handle it is to use it to determine the turn order at the start of each round.

**Turn Order Formula:**
The character or enemy with the highest Speed acts first, followed by the next highest, and so on.
- You can introduce ties by randomizing the order among characters with the same Speed.
- This makes Speed a valuable stat for all roles, as acting first can be a significant advantage.

#### 3. Debuff and Status Effect Application
Main attributes: Accuracy and Resistance.

**Debuff Success Rate Formula:**
```
Success Rate = Base Chance + (Caster's Accuracy - Target's Resistance) * Multiplier
```
- The `Base Chance` is the innate probability of the debuff landing (e.g., a "Poison" spell might have a 60% base chance).
- The `Multiplier` should be a small number (e.g., 0.5% to 1.0%) to ensure that small differences in stats don't make debuffs guaranteed to hit or miss.
- The result should be capped at a minimum and maximum, such as 10% to 90%, to ensure some level of uncertainty remains.

This formula makes Accuracy a key stat for your Strategist or Jester roles, who might rely more on disrupting enemies than on raw damage. Conversely, a high Resistance is crucial for a tank-like Knight to avoid crippling debuffs.

#### 4. Critical Hits
Critical hits add an element of excitement and potential for big plays.

**Critical Hit Chance Formula:**
The chance to land a critical hit can be a fixed value for each character/enemy, or it can be based on a stat (e.g., a "Critical" stat you might want to add).
- A simple approach is to have a fixed 5% to 10% chance.
- When a critical hit occurs, a `Critical Damage Multiplier` is applied to the final damage (e.g., 1.5x or 2.0x). This multiplier can be a static value or tied to another stat.

## Skills
Skills are actions that a character can perform either inside or outside of combat.
Existing skills are defined here: Characters

## Events
Maybe a rotating schedule composed of one type of event per god? E.g.
*   **God of Structure**
    *   A numeric “floor” dungeon like raids doom tower
*   **God of Adventure**
    *   A small storyline, quest
    *   Some boss and or mystery
*   **God of Magic**
    *   Chaotic event, involving many elements that change often?

## Level up system
Maybe try out unlockable things by level or star-up? Could involve an additional skill/passive, a stat boost, a new gear slot or a synergy option.

One option could be to have a FFX/PoE passive tree per character. But since there would be so many characters there could be an argument to have one for the player instead. If it is for the player maybe one could have multiple versions at the same and choose which one is active.
If there is a passive tree for a character the idea of a cluster jewel (in this game a Relic item probably) would be interesting to allow the tree to expand. Also if it is for a character the tree needs to be fairly small with big increments to feel impactful and not dizzying to use/learn.
The character passive tree could be the tool for level up mechanics, the issue is to gradually introduce new elements for the player to use and to not lock them behind a tree in a way that they could miss it.

For a character passive tree, expect around at most 20 points to be allocated. With an assumed max level of 60, that is 1 point per 3 levels. One way to change the passive point curve could be to give a point after certain events/achievements instead, so maybe 1 point per 5 levels; 12 points and 3-8 points from other sources.

## Passive tree designers
- Gamedevgrunt, a versatile tool that exports .json files.
- Maybe try to implement one

## Godot stuff
1.  make a custom icon [project-settings -> app -> config]
2.  make a custom splash screen [project-settings -> app -> bootsplash]
3.  set main scene (start point for game) [project-settings -> app -> run]
4.  name your game [project-settings -> app -> config]
5.  make game full-screen default [project-settings -> display -> window]
6.  custom mouse cursor [project-settings -> display -> mouse]
7.  import blend files [project-settings -> filesystem -> import & editor settings -> filesystem -> import {blender install location}]
8.  use anti-aliasing when doing modern games [project -> rendering -> anti-aliasing]
