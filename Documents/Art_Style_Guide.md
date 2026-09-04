# Art Style Guide

**Style name:** Lit Woodcut
**Tool:** Leonardo.ai (`app.leonardo.ai`) — no negative prompt field available
**Target:** 2D turn-based combat RPG, phone and desktop, characters ~250–350 px tall in play

---

## 0. The six non-negotiables

Every asset in the game obeys these. If an output breaks one, reject it regardless of how good it otherwise looks.

1. **Very thick uniform black contour outline on the outer silhouette**, and that silhouette edge stays clean and uninterrupted. Fussy, nibbled edges turn to mush at phone size.
2. **Flat color fields, hard-edged shadows, four value bands.** No gradients, no soft shading, no ambient occlusion. Four bands is a **value** rule, not a color-count rule — see section 1.
3. **One saturated accent per character**, flat and uniform, covering roughly
15–20% of the figure.
4. **Faces are lit and the eyes are visible.** Champions are people the player is meant to care about, and a concealed face reads as a prop. See section 3.
5. **Perspective spec** (section 8) is identical across every character, background, effect and icon. This is what makes assets composite without looking assembled from different games.

**Leonardo has no negative prompt field.** Every exclusion must be phrased as a positive opposite. Never paste a list of unwanted terms into the prompt — it reads as a request and you will get it.

---

## 1. Values

Value structure is what makes the style cohere. Hue variety is what makes it not depressing. These are separate axes and the old "four values, three colors" rule conflated them, which is what produced flat sepia figures that sank into their backgrounds.

**Four value bands, measured in L\*:**

| Band | L\* | Role |
|---|---|---|
| 1 | 6–12 | Ink black — outline, deep shadow, costume blacks |
| 2 | 28–36 | Dark materials, shadow side of mid materials |
| 3 | 52–62 | The main readable mid tone of most materials |
| 4 | 78–86 | Light materials, lit skin |
| Highlight | 90–94 | Bone white — small shapes only, plus the eyes |

**Rules that follow:**

- **Each material occupies at most two adjacent bands.** That is what keeps eight fills reading as a flat woodcut rather than a painting.
- **Band 1 covers roughly half the figure.** Large committed areas of solid black are what make the rest read as bright. This is the single biggest difference from the earlier sepia version.
- **Bone white is a highlight, not a fill.** Target 5% or less of the figure. If bone white is doing area work, the whole asset goes pale.
- **The outline black and the deepest shadow are the same value**, so shadow can eat part of a figure and merge it into the outline.
- **Ink black is tinted slightly toward blue-violet.** A true neutral black reads as photocopy; a tinted one reads as printed.

**The light-dominant exception.** One Role may invert this and be built on a light garment main, as the Jester is. For such a figure, the band 1 and bone white rules above do not apply. Judge it instead on whether black still holds the outline and roughly a third of the figure, carried by hose, boots and one split sleeve rather than by the torso. This is a deliberate identity for a single Role, not a second option — a second light-dominant character would cost the first one its distinctiveness.

---

## 2. The material slot system

Color is assigned by **what a thing is made of**, not by a global palette limit. Cohesion comes from the shared slots, which are identical on every character in the roster.

### 2.1 Shared slots — fixed across all twenty Roles

| Slot | Light value | Dark value | Notes |
|---|---|---|---|
| Ink black | — | `#14121A` | Outline, deep shadow. Blue-violet tinted. |
| Bone white | `#EFE6D2` | — | Highlights and eyes only. |
| Leather | `#4A3527` | `#2A1D15` | Belts, straps, boots, satchels. |
| Metal, pewter | `#6E727A` | `#3F444B` | Non-accent hardware. Buckles, fittings, plain blades. |

### 2.2 Per-character slots — where the variety lives

| Slot | Rule |
|---|---|
| Garment main | Two values. The largest colored area on the figure. |
| Material neutral | One or two values. **Deliberately the opposite temperature to the accent.** This is what makes the accent read as saturated rather than as one more brown. |
| Accent | One flat value, no texture, 15–20% coverage, head and chest region. |

The temperature rule on the material neutral is the load-bearing part. Brass on warm leather disappears; brass on cold grey reads as metal. Terracotta on umber disappears; terracotta on slate reads as clay.

**When temperature separation can be dropped.** The rule exists so the accent has something to push against. If the garment main already sits at an extreme value — bone white, or near-black — the value contrast does that job on its own and the material neutral may be the same temperature as the accent. The Jester's scarlet neutral under a saffron accent works because both sit on white. Do not invoke this to rescue a mid-value garment; it only holds at the ends of the ramp.

### 2.4 Accent hexes that need attention

Several accents in section 9 are low-chroma by nature, and a dull accent on a dull garment gives a figure with no vibrancy anywhere:

- **Warlord `#6B7A88`** is a neutral, not an accent. It needs a real color or an explicit decision that this Role is the drab one.
- **Appraiser `#8F7326`**, **Plague Doctor `#2F5D3A`** and **Scholar `#DCCFA8`** are all close to being materials rather than accents. Raise chroma and let value and placement keep doing the separating.

Generate accents as flat uniform fills so they can be masked and boosted in post. Asking Leonardo for a brighter accent drags the whole figure with it; recoloring the mask does not.

### 2.5 Watch for cool-neutral drift

The temperature rule pushes toward a cold material neutral every time, because most accents in section 9 are warm. Left unchecked this produces a roster where every character wears blue-grey. Five of the first six Roles did exactly that before it was caught.

Cold neutrals available: slate blue-grey, ash grey, pewter blue, blue-violet charcoal, slate-olive.
Warm and neutral alternatives that still serve: bone buff, sand tan, oxblood, scarlet vermilion, warm charcoal brown, drab olive.

**Rule of thumb: no more than half the fielded roster on cool neutrals.** When a new Role's accent is warm and a cold neutral is the obvious pick, take a warm option if cool is already crowded. The Bar Brawler is the easiest existing Role to move if rebalancing is needed — dirty cream with warm leather works as well as the cold slate.

---

## 3. Faces and proportion

This section exists because both failure modes here were expensive to find.

### 3.1 The rules

- **The face is lit.** Shadow falls on the side of the head away from the light and beneath the jaw, never across the eyes.
- **Eyes are two bone white almond shapes, each with a solid ink black pupil.** Sized to read clearly at 300 px, but **no larger than an adult eye**.
- **Realistic adult head proportion.** State it explicitly in the prompt.
- **The head is the lightest region of the figure.** One bright area in a mostly dark figure pulls the eye straight to the face at any size.
- **Hair and beard are single flat masses.** No interior detail.

### 3.2 Concealed faces are an exception, not a tier

A hidden face is permitted only when concealment **is** the character's identity, and it costs that Role its most direct expression tool. The Architect earns it through the hat brim; most Roles do not. When in doubt, show the face.

Fodder enemies are the one place faces stay dark and anonymous, which is a free legibility win and matches the reduced detail tier in section 4.6.

### 3.3 Tone comes from word choice

Leonardo builds mood from adjectives more than from anything structural. The same design reads gritty or neutral depending on vocabulary:

| Avoid | Use |
|---|---|
| shirt straining | shirt pulled tight across the chest |
| fists loosely raised | fists raised ready |

a direction to watch out for, because it was reached by accident:

- **Frail.** `wiry`, `hunched`, `head pushed ahead`, `matted`. The failure is
  cumulative — two or more of these with nothing pushing back lands on NPC. One
  of them against established bulk, a weapon and a wide stance is a posture, not
  a status, and `hunched` in particular is useful for getting weight into an
  asymmetric silhouette.

### 3.4 Genre attractors

Leonardo has strong genre basins, and a prompt that puts several of their keywords together will land in one no matter what else it says. There is no negative field, so **the only fix is to change the vocabulary wholesale.** Adding qualifiers reinforces the basin.

Attractors hit so far, with the words that summoned them:

| Attractor | Trigger words |
|---|---|
| Dracula | high collar, pale, long open coat, crimson at throat, "bloodmage" |
| Barbarian / nomad | torn strips, bare chest, hard muscle, notched blade, hide |
| Shaman | bone cords, antlers, bound bones at the belt, ritual bowl |
| Modern working man | plain buttoned coat, flat cap, ordinary, unremarkable |
| Cartoon | soft floppy cap, wide grin, `wiry`, large head relative to body |

When an attractor lands, rewrite the costume from a different occupation rather than negating. The Bloodmage escaped Dracula by becoming a debt collector in a uniform; nothing about the words "not a vampire" would have done it.

---

## 4. Characters

### 4.1 Design the character before writing the prompt

Three characters cost several rounds each because the prompt was being rewritten when the concept was the thing that was undecided. So start by settling who/what the character is, what is their place in the world, what do they do?

**Every character needs an occupation.** Bar Brawler, Architect and Alchemist worked on the first or second attempt because each names a job, and a job comes with clothes, tools and a posture. "Bloodmage" names a magic system and left the person unspecified, which is why it took five attempts. Before writing a prompt, answer: *what does this person do for a living, and who employs or shuns them?*

**Check the concept for internal conflict.** "Shunned outcast" and "cool playable champion" pull against each other, because low status is what outcast looks like. No wording resolves that. Either the status changes (feared instead of shunned) or the visual reading of it does.

**Flavour text is not a costume brief.** "Hides from the Iron Ledger" taken literally produced a man in a plain working coat with no fantasy content and nothing for a player to want. Concealment survives as *style* — a brand showing at an open collar, dye that will not wash off — not as ordinary clothing.

### 4.2 The canonical general block

Substitute the bracketed slots from section 2. Everything else is identical in every character prompt, word for word. The repetition is doing most of the consistency work.

```
bold woodcut illustration with engraved structural linework, very thick
uniform black contour outline on the outer silhouette, clean uninterrupted
silhouette edge, flat color fields, hard-edged shadows, high contrast with
large areas of solid ink black, colors assigned by material: {SKIN} skin,
{GARMENT MAIN}, {MATERIAL NEUTRAL},
dull pewter grey metal fittings, all flat and unmodulated, warm bone white
reserved for small highlight shapes and the eyes, ink black tinted slightly
toward blue-violet, light from the upper left casting a narrow bone white
edge along the upper left contour, {FOCAL REGION} carrying the heaviest
engraved detail and reading as the focal point of the figure, the rest of the
body held as large flat angular panels with only sparse structural marks,
all marks large and structural, with
saturated {ACCENT} as the single accent covering roughly a fifth of the
figure, flat and uniform with little texture, used only on {PLACEMENT},
hand-carved edge quality.
```

**Detail vocabulary.** Ask for *structural* detail, and derive the nouns from
this Role's own trade and materials rather than reusing the list from the last
character. The test is size, not vocabulary: any mark that survives the round-trip in section 10 qualifies.

**Always use numeric counts, never adjectives.** "Three or four wrap bands" is a target the model can hit. "Moderate detail" is not, and it will revert to maximalism.

### 4.3 Decide the silhouette and the pose before anything else

Two phrases, written before a word of the prompt exists: what shape is this,
and what is the body doing. `strongly asymmetric silhouette, one human hand
and one bloomed limb` is a complete answer. So is `low squat, weight over the
heels, lance braced diagonally across the whole figure`.

State them near the front of the subject block and let the model solve them.
Do not decompose them into a parts list — enumerating chest, then shadow, then
limbs, then pose is what produced three interchangeable figures. The parts that
matter will follow from the shape; the parts that do not should stay flat.

The subject block has no fixed running order. The only fixed element is the
composition tail in 8.2.

### 4.4 Reference example — Bar Brawler (a sample, not a form)

```
[GENERAL BLOCK with warm tan skin, a dirty cream shirt, cold slate blue-grey
trousers, terracotta accent on the apron and knuckle wraps]
full body character, heavyset broad-shouldered brawler, barrel chest,
realistic adult head proportion, face lit with no shadow across the eyes,
shadow falling on the side of the head away from the light and beneath the
jaw, eyes as two bone white almond shapes each with a solid ink black pupil,
sized to read clearly but no larger than an adult eye, wide flattened nose,
heavy brow, solid beard shape as one flat mass, a worn tavern apron with
visible seams, ties and pocket divisions, shirt pulled tight across the
chest with a few bold fold lines, shirt and trousers falling into solid
black shadow on the lower right side, thick forearms wrapped in cloth
showing three or four wrap bands, trousers with two or three heavy fold
lines and a visible belt, boots with a simple sole division, weight forward
on the front foot, fists raised ready, standing on a flat ground line,
three-quarter view facing right, eye-level camera at chest height,
orthographic, isolated on a plain flat background of one uniform color,
full figure visible with headroom.
```

Architect and Alchemist subject blocks follow the same seven-step pattern with their own slot assignments; both are generated and approved.

### 4.5 Silhouette discipline

Each Role must be identifiable in pure black at 300 px. Assign a distinct silhouette family and hold to it:

| Family | Roles | Cue |
|---|---|---|
| Wide and low | Bar Brawler, Warlord | bulk at the waist, short stance |
| Tall and angular | Architect, Emissary | gaunt vertical, hard corners |
| Squared column | Bloodmage | heavy square shoulders, long straight coat to the knee |
| Narrow vertical, high shouldered | Cultist | layered robes, raised shoulder line, ankle hem |
| Asymmetric mass | Symbiote, Herald | growth or apparatus on one side |
| Off balance | Jester | leaning back off the vertical, one arm out as counterweight |
| Top-heavy | Alchemist | loaded chest, narrow legs |
| Narrow and vertical | Thief, Diviner | tight outline, no shoulder mass |

**Pose is the cheapest silhouette tool available.**
A squatting Lancer, a braced shield stance, a kneeling reload and a
standing column are four unmistakable black shapes at 300 px; four standing
figures are not, however different their costumes. Give every Role a pose that
is doing work.

The pose is a *held* combat stance, not a moment inside an action,
and it has to keep the face lit and the accent visible.

If two fielded Roles share a family, that is a design problem, not a prompt problem. Architect and Emissary are the pair to composite side by side early, and their material neutrals must not converge. Cultist and Diviner are the second pair to watch, since both are robed narrow verticals; the Cultist has room to go wider through the shoulders if they converge.

### 4.6 Detail tier by content tier

- **Player Roles** — the block as written.
- **Fodder enemies** — drop to `minimal interior detail, large simple shapes, three values`, faces dark and anonymous, no accent or a heavily reduced one.
- **Bosses** — same block as player Roles plus one additional counted focal element. Do not raise the detail ceiling. Distinguish bosses by scale and by the extra focal element.

## 5. Areas and backgrounds

### 5.1 Rules

- **Shallow stage.** A wall or skyline, a thin floor strip, almost nothing in between. This is what makes perspective mismatch impossible to see.
- **Empty center**, sized for the character line.
- **No figures, no creatures** — state both.
- **Flat horizon low in frame**, at the fixed screen fraction from section 8.
- **Backgrounds carry no character accent.** Accent belongs to characters and effects.

### 5.2 Scene light — the mood dial

Each area gets a **scene light color**. It is not a Role accent and never appears on a character's costume. It lives in the sky field, the haze band between parallax layers, and the tint of the floor strip.

| Area | Sky field | Ground / skyline |
|---|---|---|
| Iron Ledger / Holy City | cold slate blue #33414D | #10161B |
| Reclaimed City | sickly teal-green #2E5A50 | #0E1614 |
| Magic ruins | violet #3A2A52 | #120E1A |
| Pirate Coves / coast | cold teal #2C5F72 | #0E1418 |
| Caravan / Adventure | ember orange dusk #C4562A | #14100C |
| Clockwork Spire | TBD | TBD |

Ember dusk is the one warm area, and it is deliberately reserved for the Adventure content so that expeditions feel different from the city work.

## 6. Effects and VFX

### 6.1 Rules

Effects are the one place the accent may exceed its budget, because they are transient. Everything else holds.

- **Same thick black outline**, even on magic. An unlined glow does not belong to this game.
- **Shape over glow.** Radiating lines, chunky sparks, solid smoke masses, cracked rings. Not soft bloom.
- **Effects inherit the caster's accent color.** This is the single strongest reinforcement of the identity color system.
- Generate on **plain black or plain white**, keyed out afterward, never on a scene.

### 6.3 Where the juice actually comes from

Most perceived impact is code, not art, and costs far less than more VFX assets:

- Whole-sprite squash and stretch via Tween on `scale`, plus `skew`
- Hit-flash shader, white or the accent color, two frames
- Hitstop of 60–100 ms, screen shake
- Idle bob of 2–3 px plus 1–2% scale on a long sine

Build this layer before commissioning more effect art.

---

## 7. Icons

Icons are where the style either works or fails, because they are the smallest thing on screen.

A lot of context and content is not yet written down here yet, like one subchapter per type of icon. Right now only 7.3. for Node icon exists and it is bare-bones at most. Some that are missing (not a complete list): active skills, status effects, passive skills & identity related buttons like for grafting or switching thread stance.

### 7.1 Rules

- **Target size first.** Decide the pixel size (map nodes ~48–64 px, skill icons ~64–96 px) and judge every candidate at exactly that size, never at full resolution.
- **Drop to three values.**
- **Drop the material slot system.** At icon scale there is no room for eight fills. Icons use ink black, bone white, one mid neutral and the accent.
- **One idea per icon.** A single object, centered, filling the frame.
- **Silhouette must survive being filled black.**
- **Outline gets proportionally thicker**, not thinner, as size drops.
- **Node type icons carry no accent** — they are map furniture. **Skill icons carry the caster's accent**, and here the accent may run to 30% because there is nothing else competing.

### 7.2 Prompt pattern

```
bold woodcut icon, very thick uniform black contour outline, flat color
fields, three values, hard-edged shadows, a single {SUBJECT} centered and
filling the frame, large simple shapes, minimal interior detail, no fine
linework, no small marks, readable at very small size, rendered in ink
black, bone white and one mid grey[, with {ACCENT} as the single flat accent
on {PLACEMENT}], plain flat background, no scenery.
```

### 7.3 Node icon subjects (Expeditions map)

Keep these to one unmistakable object each: Fight — crossed blades; Boss — a horned skull; Rest Stop — a campfire with three logs; Hint — an open eye; Gamble — a pair of dice; Escalate — an upward arrow through a broken ring.

---

## 8. Perspective — identical everywhere

### 8.1 The spec

- Camera at **character chest height, straight on**. No tilt, ever.
- **Horizon line at a fixed screen fraction.** Pick one (45% from the top is a reasonable default), write it down, never move it.
- **Orthographic, no vanishing point.** State it explicitly. Models still cheat, but less.
- **One ground line.** Depth in the battle layout comes from scale and overlap, not from moving figures up the screen.
- **Light from upper left**, in every single asset. Mismatched light reads to players as a perspective error even when the geometry is fine.

### 8.2 Composition tail

Appended verbatim to every character prompt:

```
in contact with a single flat ground line, three-quarter view facing right,
eye-level camera at chest height, orthographic, isolated on a plain flat
background of one uniform color, full figure visible with headroom.
```
The tail constrains the camera and the ground plane only. Squatting, kneeling,
braced, seated and leaning are all compatible with it. "Eye-level camera at
chest height" means the standing chest height the figure would have — it does
not move down when the character does, or the perspective breaks against
everything else in the scene.

### 8.3 Grey-box first

Build the battle scene in Godot with plain rectangles at final resolution. Decide how tall a character is in pixels, where the ground line sits, how much background shows above and to the sides. **Then** generate art to fill known boxes.

---

## 9. Accent color reference

One color per Role, no sharing. Hue alone cannot separate twenty entries at phone size, so **value** and **placement** carry the same signal in parallel.

| Role | Accent | Hex | Value | Placement |
|---|---|---|---|---|
| Thief | rust orange | #C25A1E | mid | hood lining, blade edges at belt |
| Bloodmage | crimson | #A32036 | dark | chest channels, forearm staining, belt-chain cord |
| Bar Brawler | terracotta | #B8563A | mid | apron, knuckle wraps |
| Lancer | flame copper | #E07B2C | light | lance pennant, helmet crest |
| Jester | saffron | #EDB431 | light | cap bells, collar motley, wrapped knife grips |
| Architect | muted brass | #C69A4B | mid-light | drafting instruments on chest, hat band |
| Appraiser | antique gold | #8F7326 | dark | loupe, scale beam, tally gorget |
| Scholar | ledger parchment | #DCCFA8 | lightest | open ledger at chest, spectacle rims |
| Alchemist | acid chartreuse | #A8BF3A | light | flask contents, apron spill stain |
| Symbiote | verdant green | #4E8C3F | mid | fungal mass on shoulder and skull |
| Plague Doctor | deep moss | #2F5D3A | dark | beak lenses, vial rack |
| Tidal Corsair | sea teal | #2E8C8C | mid | coat sash, pistol furniture |
| Chronophage | ice cyan | #8FD4DC | light | clock-face at chest |
| Sorcerer | unstable cobalt | #2F52C4 | mid | rift glow at hands and inside hood |
| Emissary | ink indigo | #26326B | dark | seal wax on chest documents, badge |
| Diviner | pale lilac | #B9A5D9 | light | veil trim, throat sigil |
| Cultist | deep amethyst | #5B2A78 | dark | throat brand, robe lining, stained fingers |
| Herald of the Loom | violet magenta | #8E3A91 | mid | active thread through chest loom-frame |
| Tactician | rose magenta | #C2447A | mid | map case, marker rods |
| Warlord | steel blue-grey | #6B7A88 | mid | shield device, helmet plume |

**Watch these three pairs:** Architect brass / Appraiser gold, Sorcerer cobalt / Emissary indigo, Cultist amethyst / Herald magenta. The value gap does the separating in each case, so if a hex is adjusted, never adjust it toward its neighbour's brightness. Placement differs in all three pairs as a backup.

**Eyes are never the accent.** Cultist and Chronophage previously listed eye placements; both have been moved to chest elements. Accent-colored eyes read as menacing and break section 3.

**Only three champions are fielded at a time**, so full-roster clashes are largely theoretical. What matters is that any three the player picks stay separable.

**Extend each accent beyond the sprite** — card border, map icon, damage numbers, skill VFX. Twenty hues is a lot to learn from sprites alone, but the association forms within an hour or two of play when the same color appears in four places.

---

## 10. Post-processing — applied to every asset

Uniformity of this pass matters more than any individual generation. Run it even on assets that already look right.

1. Quantize to the fixed value ramp from section 1
2. Mask the accent region and correct its saturation to the section 9 hex
3. One shared overlay (grain or paper), identical settings every time
4. One LUT per area, identical within that area
5. Downscale to target in-game size, then judge

**The LUT is the mood dial, and it lives in the engine.** Because every asset quantizes to a known ramp and the accent is a maskable flat fill, area mood can be tuned live in Godot rather than baked into generations. Build the scene light as a layer: a `CanvasModulate` for the global cast, a colored haze quad at low alpha between parallax bands, and the area LUT. Then a biome's color is a value you can iterate on in seconds instead of forty regenerations.

**The round-trip detail test.** Downscale to target size, posterize to the ramp, upscale back with nearest-neighbour. Detail that survives is detail worth keeping.

---

## 11. Animation

Cutout skeletal animation suits this style — flat fields and hard outlines survive being chopped apart.

- **Give every cut piece its own closed black outline.** Half-committing, where some edges are lined and some are raw, is the failure mode.
- **Cut with generous overlap**, not at the joint. Round the end of each limb piece so rotation sweeps inside the shape.
- **Three-quarter view costs extra work**: the far arm and leg are occluded and must be redrawn, plus whatever sits behind each piece.
- **Sprite2D on Bone2D** for rigid limbs. Polygon2D skinned to Skeleton2D only for genuinely soft things (tendrils, coat hems).
- **Keep the eyes on their own layer.** They are hand-placed and they are the first thing that breaks when a head piece rotates.

**Do the cheap layer first** (section 6.3). At 300 px on a phone, whole-sprite squash/stretch plus hit-flash plus hitstop delivers most of the perceived quality.

**Middle option:** generate 3–4 pose variants per character and hard-cut between them, no tweening. Limited animation is period-correct, hides a multitude of sins, and plays better with generated art than rigging does.

---

## 12. Acceptance checklist

Run before any asset enters the project.

- [ ] Outer silhouette is unbroken and reads at target size when filled pure black
- [ ] Outline thickness matches the rest of the set
- [ ] Four value bands; no gradients anywhere
- [ ] Band 1 covers roughly half the figure
- [ ] Bone white is under 5% and is not doing area work
- [ ] Every material sits in at most two adjacent bands
- [ ] Shared slots (skin, leather, pewter, black, bone) match the rest of the roster
- [ ] Material neutral is the opposite temperature to the accent
- [ ] Exactly one accent, flat and uniform, roughly 15–20% coverage
- [ ] Accent has not bled onto skin, hair or background
- [ ] Face is lit, eyes are visible, head proportion is adult
- [ ] Eyes hand-placed and consistent with the last approved character
- [ ] Limbs carry light detail, not blank
- [ ] Ground line, horizon, camera height and light direction match the spec
- [ ] Post-processing pass applied with the same settings as everything else
- [ ] Viewed at final in-game size, not full resolution
- [ ] The Role's occupation is legible from the costume alone, with no name attached
- [ ] Composited into the actual battle scene alongside an existing asset before acceptance
- [ ] Detail concentrated in one focal region, not spread evenly over the figure

---

## 13. Rejected directions

Recorded so they are not retried. Each of these was generated and judged, not reasoned about.

- **Enlarged head plus enlarged eyes.** Moving both dials at once is the cartoon recipe. The lit face was the fix for distance; the proportions were not, and changing them read as goofy.
- **Bone white eyes glowing out of a shadowed upper face.** A horror device. Pushed the tone further toward menacing, which was the opposite of the goal.
- **Bloodmage as a pale nobleman in a high-collared coat.** Landed on Dracula immediately, cape and fangs included. See 3.4.
- **Bloodmage as a frail wilderness outcast.** Read as an NPC. Low status is what "shunned" looks like, and no amount of gear fixes it.
- **Bloodmage as a composed sorcerer in bone regalia.** The overcorrection from frail. Regal, clean, and no longer transgressive.
- **Cultist in torn strips with a bare chest and a notched blade.** Reads as a barbarian, and it was also four counted groups deep.
- **Cultist in a plain working coat and flat cap.** Taking "hides from the Ledger" literally removed all fantasy content and left nothing a player would want to field.
- **Jester with a soft floppy cap, wide grin and a wiry build.** Cartoon. `wiry` shrinks the body and makes the head read as oversized.

---

## 14. Operational notes

**Lock the model and settings.** Same Leonardo model, same Style Reference / Elements, same generation settings across the whole set. Record them here once chosen. Changing model mid-roster is the single fastest way to break cohesion.

**Composite early.** Perspective and value problems are obvious in a composite and nearly invisible when looking at assets one at a time in a browser tab. Never accept a character without dropping it into the battle scene next to one already approved.

**Steam disclosure.** Valve requires disclosure of AI-generated content that ships with the game and is consumed by players, including in-game art and store-page marketing. AI dev tools used behind the scenes are exempt under the January 2026 rewrite. Write the disclosure as the public-facing document it is — it appears on the store page.

**Commercial terms.** Confirm the Leonardo plan tier grants commercial rights and the export resolution needed before building further on this pipeline.