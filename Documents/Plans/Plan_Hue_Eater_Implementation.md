# Plan: Hue-Eater Implementation

The Hue-Eater (`Encounter_Design_Document.md` 2.2) through the boss design process
(`Encounter_Design_Document.md`, Boss design process); each step below is the process step of the
same number. Open balance questions live in `Playtest_Checklist.md`, not here.

## Steps

### 1. Mechanics (done)
Beams that has a chance to hit either an opponent or herself, Hex rolls this in favor for the player.
Translucency that reduce incoming damage, Hex makes her take full damage.
Hexagon builds up from 0 to 6 parts over time and hits all player characters when complete. Enfeeble breaks 2 parts.

### 2. Prototype (done)
Playable from the debug catalog.

### 3. Teaching design (done)
Recorded in `Encounter_Design_Document.md` 2.2: her Teaching entry, the crystal die, Slab Tossers,
and Chanter and Gatherers.

### 4. Teaching prototype (done)
Build, with tests:
- **Crystal die** replacing the prism's coloured faces: colourless, tinted red while she holds Hexed.
- **Luck line** combat text: its trigger and its once-per-battle limit.
- **Slab Tossers:** the slab toss as a chance roll Hexed biases, +1 Echo on the good side, weak hit
  and 1-turn self-Hexed on the bad side, and the flip visual with its yellow flash and motes.
- **Chanter and Gatherers:** the chant's Enfeeble on every character, and a three-part triangle
  starting at one part. Generalise the Hue-Eater's hexagon scene and trait logic to a part count
  rather than copying them.
- **Pre-battle tooltip:** her text in `_thematic_hint`, shown on the pre-battle menu.
- **Hint node** carrying her text.

### 5. Teaching playtest
Playtest with players who do not know the solution (`Playtest_Checklist.md`). On failure, return to
step 3, or to step 1.

### 6. Finish

#### 6.1. Art
- **Hue-Eater sprite.** Replaces the placeholder violet silhouette. A clean alpha edge and a strong
  silhouette, so the translucency shader (6.2) reads. (done)
- **Crystal die.** Greyscale, so code owns the red tint.
- **Slab Tossers:** decide what they are (not necessarily human) and name them; their slab.
- **Hexagon.** No texture: each slice stays a polygon drawing the background behind it in greyscale,
  with a glowing outline per slice. Polish the glow. (done)
- **Grey patches.** A shader at her feet greying the ground through a shifting noise mask; one or
  two noise textures at most.

#### 6.2. Effects
- **Beams** fall from above onto the die, then refract to their target; a beam passing through
  her carries on off the right of the screen.
- **Full hexagon** pulses through the turn it hovers.
- **Hexagon impact** on the party: flash or shatter, and screen shake.
- **Enfeeble consumed:** the Enfeeble icon is pulled into the hexagon; the two slices crack off and
  fall as Prism-Salt crystals at her feet.
- **Translucency shader** replacing plain transparency: dithered, obscuring her form; a shimmer when
  she turns solid under Hexed.
- **Phase 2 feed:** a mote of light travels from each champion a beam lands on into the hexagon.
- **Death:** die and hexagon shatter; the grey patches regain colour.

#### 6.3. Sound
Beam fall and refraction, pass-through, bent-back hit, slice gained, full-hexagon hum loop, launch
and impact, Enfeeble crack, Hexed applied, translucent-to-solid shift, phase 2, her cues and death;
the slab toss and the chant; a boss music track if bosses get their own.

#### 6.4. Placement
Place her as the Magic Ruins adventure boss, with its fodder and Hint node, and set her tier weight.

#### 6.5. Text
- Replace the phase 2 line ("The light bends to me!").
- Remove the "Passes through" combat text once the effects show a beam passing through her on their
  own (`Playtest_Checklist.md`).

#### 6.6. Close the encounter entry
Move her settled mechanics into `Encounter_Design_Document.md` section 1 as opponent skills, and
set her status to implemented.

## Watch for

- The die's tint and the slice colours stay in code, never baked into art.
- Boss-specific visuals stay in her own scenes (`hue_eater_visuals.tscn`, her effect scenes); generic
  battle classes only gain generic hooks.
- Opponent traits carry no player text; hints go through the channels in step 3.
