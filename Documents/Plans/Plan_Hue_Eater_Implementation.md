# Plan: Hue-Eater Implementation

The Hue-Eater (`Encounter_Design_Document.md` 2.2) is prototyped and playable from the debug
catalog. This plan turns her into a finished, placed boss: art, effects, sound, placement and text.
Open balance questions live in `Playtest_Checklist.md`, not here.

## Steps

### 1. Art
- **Hue-Eater sprite.** Replaces the placeholder violet silhouette. A clean alpha edge and a strong
  silhouette, so the translucency shader (step 2) reads. (done)
- **Prism.** Layered, so code keeps owning the colours: one greyscale face wedge placed five times
  and tinted per face, a frame spinning with the wedges, a static top-lit highlight, and a Hexed
  glyph overlay covering the whole prism.
- **Hexagon.** No texture: each slice stays a polygon drawing the background behind it in greyscale,
  with a glowing outline per slice. Polish the glow. (done)
- **Grey patches.** A shader at her feet greying the ground through a shifting noise mask; one or
  two noise textures at most.

### 2. Effects
- **Beams** fall from above onto the prism, then refract to their target; a beam passing through
  her carries on off the right of the screen.
- **Forward face.** The prism snaps to a face of the outcome's colour as each beam lands.
- **Full hexagon** pulses through the turn it hovers.
- **Hexagon impact** on the party: flash or shatter, and screen shake.
- **Enfeeble consumed:** the Enfeeble icon is pulled into the hexagon; the two slices crack off and
  fall as Prism-Salt crystals at her feet.
- **Translucency shader** replacing plain transparency: dithered, obscuring her form; a shimmer when
  she turns solid under Hexed.
- **Phase 2 feed:** a mote of light travels from each champion a beam lands on into the hexagon.
- **Death:** prism and hexagon shatter; the grey patches regain colour.

### 3. Sound
Beam fall and refraction, pass-through, bent-back hit, slice gained, full-hexagon hum loop, launch
and impact, Enfeeble crack, Hexed applied, translucent-to-solid shift, phase 2, her vocal cues and
death; a boss music track if bosses get their own.

### 4. Placement
Place her as the Magic Ruins adventure boss and set her tier weight.

### 5. Text
- Replace the phase 2 line ("The light bends to me!").
- Remove the "Passes through" combat text once the effects show a beam passing through her on their
  own (`Playtest_Checklist.md`).

### 6. Close the encounter entry
Move her settled mechanics into `Encounter_Design_Document.md` section 1 as opponent skills, and
set her status to implemented.

## Watch for

- Face and slice colours stay in code (`HueEaterPrism`), never baked into art.
- Boss-specific visuals stay in her own scenes (`hue_eater_visuals.tscn`, her effect scenes); generic
  battle classes only gain generic hooks.
