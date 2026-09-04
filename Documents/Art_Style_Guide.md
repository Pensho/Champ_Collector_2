# Art Style Guide

**Style name:** Lit Woodcut
**Tool:** Leonardo.ai (`app.leonardo.ai`) — no negative prompt field available
**Target:** 2D turn-based combat RPG, phone and desktop, characters ~250–350 px tall in play

This guide is the authority on visual style for every asset in the game. Where
`Concept_Document.md` and this guide disagree, this guide wins; the concept
document describes what the game *is*, this one describes what it *looks like*.

**How it is organised.** Part I holds the rules that bind every asset —
values, materials, perspective, prompting method, the post-processing pass and
the acceptance gate. Part II applies those rules per asset domain; a domain
section states only what differs from Part I. Part III records what has been
tried, how the pipeline is operated, and what is still undecided.

Sections marked *Not yet written* are known gaps with an owner-less
placeholder, deliberately listed so the span of the guide is visible even where
the content is missing.

---

## Contents

**Part I — Foundations**
1. The non-negotiables
2. Values
3. Materials and color
4. Perspective
5. Prompting method
6. Post-processing
7. Acceptance checklists

**Part II — Asset domains**
8. Champions
9. Enemies and bosses
10. Environments
11. Items, gear and reagents
12. Icons
13. UI art
14. Effects and VFX
15. Animation
16. Marketing and out-of-game art

**Part III — Record and process**
17. Rejected directions
18. Operational notes
19. Open decisions

---

# Part I — Foundations

*Everything in Part I applies to every asset in the game unless a Part II
section states an explicit, named exception.*

---

## 1. The non-negotiables

Every asset in the game obeys these. If an output breaks one, reject it regardless of how good it otherwise looks.

1. **Very thick uniform black contour outline on the outer silhouette**, and that silhouette edge stays clean and uninterrupted. Fussy, nibbled edges turn to mush at phone size.
2. **Flat color fields, hard-edged shadows, four value bands.** No gradients, no soft shading, no ambient occlusion. Four bands is a **value** rule, not a color-count rule — see section 2.
3. **One saturated accent per character**, flat and uniform, covering roughly
15–20% of the figure.
4. **Hue is a free axis inside every band, including band 1.** Value structure is what makes the style cohere; desaturation is not, and was never a rule. See section 3.5.
5. **Faces are lit and the eyes are visible.** Champions are people the player is meant to care about, and a concealed face reads as a prop. See section 8.4.
6. **Perspective spec** (section 4) is identical across every character, background, effect and icon. This is what makes assets composite without looking assembled from different games.

The seventh rule is a tool constraint rather than a style rule, and it is stated in full in section 5.1: **Leonardo has no negative prompt field**, so every exclusion must be phrased as a positive opposite.

---

## 2. Values

### 2.1 The four bands

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
- **The outline black and the deepest shadow are the same value**, so shadow can eat part of a figure and merge it into the outline. Same value — not necessarily the same hue. See 2.2.
- **The outline is always ink black `#14121A`**, tinted slightly toward blue-violet, on every character. A true neutral black reads as photocopy; a tinted one reads as printed. The outline is the one part of band 1 that never varies.

### 2.2 Tinted band 1 — the shadow black is a per-subject slot

Band 1 is half the figure. Holding it at one blue-violet black across twenty Roles was throwing away the largest colored area available, for no reason the value rules require.

**The shadow fill may be tinted per character**, at the same L\* as the outline. The outline stays `#14121A` so cohesion still runs through every contour in the game; the mass behind it carries hue.

Starting points, all to be measured to L\* 6–12 before use:

| Shadow black | Hex | Reads as |
|---|---|---|
| Blue-violet (default) | `#14121A` | The neutral option, and the outline value |
| Green-black | `#101A15` | Ruin damp, forest, verdigris |
| Aubergine-black | `#191220` | Arcane, corrupt |
| Umber-black | `#1A150F` | Warm, earthen, worked |
| Ash-blue-black | `#101519` | Cold, institutional |

**Two things to watch.**

**State the same-value rule in the prompt explicitly.** Given a tinted shadow, Leonardo renders it lighter than the outline by default, and the result reads as a mistake rather than a choice. The phrase has to say that the shadow mass and the contour sit at the same value.

**Tint against the garment main, not with it.** A green-black shadow under a green mantle reinforces a hue the figure already has, so half the figure changed and the figure still reads as two hues plus the accent. An umber or aubergine black under that same green mantle buys a genuine third hue. The cost is that the shadow stops reading as the mantle's own shadow and starts reading as its own material, which is the tension the lever creates — generate both on any character where it matters.

**The light-dominant exception.** One Role may invert the band 1 rules and be built on a light garment main, as the Jester is. For such a figure, the band 1 and bone white rules above do not apply. Judge it instead on whether black still holds the outline and roughly a third of the figure, carried by hose, boots and one split sleeve rather than by the torso. This is a deliberate identity for a single Role, not a second option — a second light-dominant character would cost the first one its distinctiveness.

---

## 3. Materials and color

Color is assigned by **what a thing is made of**, not by a global palette limit. Cohesion comes from the shared slots, which are identical on every character in the roster.

### 3.1 How the slots are used outside characters

> **Not yet written.** The slot system was written for champions and currently reads as if characters were the only consumer. Environments (10), items (11), icons (12) and UI (13) each need a stated position: which shared slots they inherit, which per-subject slots they are allowed, and whether they carry an accent at all. Section 12.1 already answers this for icons — the pattern of that answer is what the other domains need.

### 3.2 Shared slots

| Slot | Light value | Dark value | Notes |
|---|---|---|---|
| Outline black | — | `#14121A` | Contour only. Never varies. |
| Shadow black | — | per character | Band 1 fill. Same value as the outline, own hue. See 2.2. |
| Bone white | `#EFE6D2` | — | Highlights and eyes only. |
| Metal, pewter | `#6E727A` | `#3F444B` | Non-accent hardware. Buckles, fittings, plain blades. |
| Skin, warm | `#C08A63` | `#7E5238` | The default. |
| Skin, pale variant | `#D6BBA0` | `#937059` | Earned by concept, not chosen for looks. The Bloodmage uses it. |

Leather **left the shared slot list** — see 3.4.

The two skin rows were previously specified only in `Concept_Document.md` 7.1 even though the acceptance checklist and the general block both treat skin as a shared slot. They are recorded here now and the concept document no longer holds them.

### 3.3 Per-subject slots — where the variety lives

| Slot | Rule |
|---|---|
| Garment main | Two values. The largest colored area on the figure. **May be saturated.** |
| Material neutral | One or two values. Opposite temperature to the accent by default; may be saturated under 3.5. |
| Accent | One flat value, no texture, 15–20% coverage, head and chest region. |
| Shadow black | Band 1 fill hue, at the outline's value. |
| Leather | Two values, per character. |

The temperature rule on the material neutral remains the default: brass on warm leather disappears; brass on cold grey reads as metal. Terracotta on umber disappears; terracotta on slate reads as clay.

**When temperature separation can be dropped.** The rule exists so the accent has something to push against. If the garment main already sits at an extreme value — bone white, or near-black — the value contrast does that job on its own and the material neutral may be the same temperature as the accent. The Jester's scarlet neutral under a saffron accent works because both sit on white. Do not invoke this to rescue a mid-value garment; it only holds at the ends of the ramp.

### 3.4 Leather is per subject

One warm brown `#4A3527` on every belt, strap, boot and satchel in the roster was a large share of the shared mud, and it bought nothing that the outline and the value ramp were not already buying.

Leather now varies: blackened, tar-dark, oxblood-stained, bark-brown, bleached grey-tan. Pick per character and keep it inside two adjacent bands like any other material. The old warm brown remains available; it is now a choice rather than a default.

### 3.5 Saturation — why every character was beige, and the two levers

This section exists because six characters in, every figure was arriving as a different grade of beige with one muted accent, and the cause was arithmetic rather than prompting.

**The arithmetic.** The old shared slots were four neutrals — brown leather, grey pewter, tan skin, black — and they appeared on every figure. Band 1 was specified at roughly half the figure and held at one hue. Accent was capped at 15–20%. That left about a quarter of the figure for the two variable slots, and the material neutral rule then asked one of those two to be a *neutral*. Essentially nothing on the figure was permitted to carry saturated color except the accent, which is exactly what the outputs showed.

**Nothing in the rules ever required the garment main to be desaturated.** The temperature rule in 3.3 applies to the material neutral only. But all six worked examples — dirty cream, ash grey, oatmeal, near-black charcoal, slate-violet, bone white — chose a neutral anyway, and the precedent hardened into a rule nobody wrote.

**Lever one: saturate the garment main.** Give it real chroma and place it at a value the accent is not at. Value does the separating instead of chroma, which is what 3.3 already concedes at the ends of the ramp. Check garment and accent hue adjacency per character; when they merge, move the garment a full value band, never shift either hue.

**Lever two: tint band 1** — section 2.2. Half the figure becomes colored and no value band moves.

**Saturating the material neutral as well is a third step, and it is not free.** It was taken on the Sorcerer and it worked, because garment, neutral and accent sat at three clearly separated values. But it removes the thing the accent pushes against, and it is the first change to roll back if a figure comes back noisy or if the accent stops reading at 300 px. Treat it as per-character permission, not as a new default.

**What is *not* the fix:** the scene-light LUT (section 6). It tints everything uniformly, so it moves area mood without touching the sameness *within* a figure. Keep it as the mood dial it is.

**Open decision.** The five characters approved before these levers were built under the old arithmetic. Either they get regenerated or the roster carries a visible split. Composite any new lever-built character next to the approved Bar Brawler before going further: if the new one sings and the Brawler now reads as a placeholder, that is the answer, and it is much cheaper to act on at six characters than at fifteen.

### 3.6 Watch for cool-neutral drift

The temperature rule pushes toward a cold material neutral every time, because most accents in section 8.9 are warm. Left unchecked this produces a roster where every character wears blue-grey. Five of the first six Roles did exactly that before it was caught.

Cold neutrals available: slate blue-grey, ash grey, pewter blue, blue-violet charcoal, slate-olive.
Warm and neutral alternatives that still serve: bone buff, sand tan, oxblood, scarlet vermilion, warm charcoal brown, drab olive.

**Rule of thumb: no more than half the fielded roster on cool neutrals.** When a new Role's accent is warm and a cold neutral is the obvious pick, take a warm option if cool is already crowded. The Bar Brawler is the easiest existing Role to move if rebalancing is needed — dirty cream with warm leather works as well as the cold slate.

Note that 3.5 relieves some of this pressure: with a saturated garment main and a tinted shadow black carrying hue, the material neutral is no longer the only place variety can live, so a cool neutral costs less than it used to.

---

## 4. Perspective — identical everywhere

### 4.1 The spec

- Camera at **character chest height, straight on**. No tilt, ever.
- **Horizon line at a fixed screen fraction.** Pick one (45% from the top is a reasonable default), write it down, never move it.
- **Orthographic, no vanishing point.** State it explicitly. Models still cheat, but less.
- **One ground line.** Depth in the battle layout comes from scale and overlap, not from moving figures up the screen.
- **Light from upper left**, in every single asset. Mismatched light reads to players as a perspective error even when the geometry is fine.

### 4.2 Composition tail

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

### 4.3 Grey-box first

Build the battle scene in Godot with plain rectangles at final resolution. Decide how tall a character is in pixels, where the ground line sits, how much background shows above and to the sides. **Then** generate art to fill known boxes.

---

## 5. Prompting method

The craft rules below are tool behaviour, not style, and they apply to every prompt written for any asset — character, background, icon or effect.

### 5.1 There is no negative field

**Leonardo has no negative prompt field.** Every exclusion must be phrased as a positive opposite. Never paste a list of unwanted terms into the prompt — it reads as a request and you will get it.

When an unwanted element keeps returning, the fix is to change the vocabulary that is summoning it (5.3), not to add words against it.

### 5.2 Tone comes from word choice

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

### 5.3 Genre attractors

Leonardo has strong genre basins, and a prompt that puts several of their keywords together will land in one no matter what else it says. There is no negative field, so **the only fix is to change the vocabulary wholesale.** Adding qualifiers reinforces the basin.

Attractors hit so far, with the words that summoned them:

| Attractor | Trigger words |
|---|---|
| Dracula | high collar, pale, long open coat, crimson at throat, "bloodmage" |
| Barbarian / nomad | torn strips, bare chest, hard muscle, notched blade, hide |
| Shaman | bone cords, antlers, bound bones at the belt, ritual bowl |
| Modern working man | plain buttoned coat, flat cap, ordinary, unremarkable |
| Modern outdoorsman | travel coat, gaiters, pack roll, tarp, harness, staff as walking pole |
| Generic wizard | robe, hood, staff, tome, wand, "sorcerer" |
| Cartoon | soft floppy cap, wide grin, `wiry`, large head relative to body |

When an attractor lands, rewrite the costume from a different occupation rather than negating. The Bloodmage escaped Dracula by becoming a debt collector in a uniform; nothing about the words "not a vampire" would have done it.

**The two basins on either side of a magic Role are close together.** Fleeing the generic-wizard basin with surveyor and travel vocabulary lands in the modern-outdoorsman basin, which is the same failure as the Bloodmage's plain working coat: the fantasy content is gone and there is nothing a player wants to field. The Sorcerer escaped by taking his nouns from the ruins themselves — ruin masonry, ruin ironwork, a shoulder yoke, a chained slab — rather than from either travel gear or wizardry.

### 5.4 Counts, not adjectives

**Always use numeric counts, never adjectives.** "Three or four wrap bands" is a target the model can hit. "Moderate detail" is not, and it will revert to maximalism. This holds for background elements and icon interiors exactly as it holds for costume detail.

### 5.5 Detail has to survive the pipeline

Ask for *structural* detail — shapes large enough to survive quantization to four bands and downscaling to target size. Texture words (grime, stains, grease, fine hatching) cost prompt budget and return nothing after post-processing. The test is the round-trip in section 6, and it is the same test for a costume, a wall, a sword and an icon.

---

## 6. Post-processing — applied to every asset

Uniformity of this pass matters more than any individual generation. Run it even on assets that already look right.

1. Quantize to the fixed value ramp from section 2
2. Mask the accent region and correct its saturation to the section 8.9 hex
3. One shared overlay (grain or paper), identical settings every time
4. One LUT per area, identical within that area
5. Downscale to target in-game size, then judge

**The quantize step must snap L\* while preserving hue.** A greyscale-ramp implementation strips the tinted band 1 (2.2) and the saturated garment (3.5) straight back out, and the levers appear to have done nothing. If a lever-built character comes back muted, check the quantize step before blaming the generation.

**The LUT is the mood dial, and it lives in the engine.** Because every asset quantizes to a known ramp and the accent is a maskable flat fill, area mood can be tuned live in Godot rather than baked into generations. Build the scene light as a layer: a `CanvasModulate` for the global cast, a colored haze quad at low alpha between parallax bands, and the area LUT. Then a biome's color is a value you can iterate on in seconds instead of forty regenerations.

**The round-trip detail test.** Downscale to target size, posterize to the ramp, upscale back with nearest-neighbour. Detail that survives is detail worth keeping.

---

## 7. Acceptance checklists

Run before any asset enters the project. Section 7.1 applies to everything; the domain lists are additions to it, not replacements.

### 7.1 Universal

- [ ] Outer silhouette is unbroken and reads at target size when filled pure black
- [ ] Outline thickness matches the rest of the set, and the outline is ink black `#14121A`
- [ ] Four value bands; no gradients anywhere
- [ ] Every material sits in at most two adjacent bands
- [ ] Bone white is under 5% and is not doing area work
- [ ] Ground line, horizon, camera height and light direction match the spec
- [ ] Wear and detail are structural, not textural
- [ ] Detail concentrated in one focal region, not spread evenly
- [ ] Post-processing pass applied with the same settings as everything else
- [ ] Viewed at final in-game size, not full resolution
- [ ] Composited into the actual scene alongside an existing asset before acceptance

### 7.2 Champions

- [ ] Band 1 covers roughly half the figure, and its tint sits at the outline's value
- [ ] Shared slots (skin, pewter, outline black, bone) match the rest of the roster
- [ ] Garment main, accent and shadow black are separated by value, not by desaturation
- [ ] Material neutral is the opposite temperature to the accent, unless 3.5 permission was taken deliberately
- [ ] Exactly one accent, flat and uniform, roughly 15–20% coverage
- [ ] Accent has not bled onto skin, hair or background
- [ ] Face is lit, eyes are visible, head proportion is adult
- [ ] An age is stated and the face nouns are not the last character's cluster
- [ ] Expression reads through brow, tilt or mouth line
- [ ] Eyes hand-placed and consistent with the last approved character
- [ ] Limbs carry light detail, not blank
- [ ] The Role's occupation is legible from the costume alone, with no name attached
- [ ] Silhouette family is not shared with another fielded Role

### 7.3 Enemies

> **Not yet written.** Which of 7.2 survives at fodder tier, and what a boss adds on top.

### 7.4 Environments

> **Not yet written.** Empty-center sizing, scene-light conformance, no accent bleed, parallax band separation, composite against a fielded team of three.

### 7.5 Items, gear and reagents

> **Not yet written.** Reads at inventory-cell size, silhouette distinct from other items in its slot, rarity signal present and legible.

### 7.6 Icons

> **Not yet written.** Judged at exact target px, three values, one idea, survives being filled black, accent policy correct for the icon class.

### 7.7 UI

> **Not yet written.** Frame weight consistent, no gradient creep from templates, legible over both light and dark area LUTs.

---

# Part II — Asset domains

*Each section below states only what differs from Part I.*

---

## 8. Champions

### 8.1 Design the character before writing the prompt

Three characters cost several rounds each because the prompt was being rewritten when the concept was the thing that was undecided. So start by settling who/what the character is, what is their place in the world, what do they do?

**Every character needs an occupation.** Bar Brawler, Architect and Alchemist worked on the first or second attempt because each names a job, and a job comes with clothes, tools and a posture. "Bloodmage" names a magic system and left the person unspecified, which is why it took five attempts. Before writing a prompt, answer: *what does this person do for a living, and who employs or shuns them?*

**Check the concept for internal conflict.** "Shunned outcast" and "cool playable champion" pull against each other, because low status is what outcast looks like. No wording resolves that. Either the status changes (feared instead of shunned) or the visual reading of it does.

**Flavour text is not a costume brief.** "Hides from the Iron Ledger" taken literally produced a man in a plain working coat with no fantasy content and nothing for a player to want. Concealment survives as *style* — a brand showing at an open collar, dye that will not wash off — not as ordinary clothing.

### 8.2 Decide the silhouette and the pose before anything else

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

### 8.3 Silhouette discipline

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
| Planted diagonal | Sorcerer | mid-calf hem over boots, yoke across the back, rod planted forward across the figure |

**Robed Roles are crowded.** Cultist, Diviner and Sorcerer are all robed, and the Sorcerer stays out of that family on two cues: the hem is cut at mid-calf over visible boots rather than falling to the ankle, and the planted rod puts a hard diagonal through a silhouette the other two hold as a clean vertical. Giving up the ankle hem is the single cheapest separation available to any robed character.

**Pose is the cheapest silhouette tool available.**
A squatting Lancer, a braced shield stance, a kneeling reload and a
standing column are four unmistakable black shapes at 300 px; four standing
figures are not, however different their costumes. Give every Role a pose that
is doing work.

The pose is a *held* combat stance, not a moment inside an action,
and it has to keep the face lit and the accent visible.

If two fielded Roles share a family, that is a design problem, not a prompt problem. Architect and Emissary are the pair to composite side by side early, and their material neutrals must not converge.

### 8.4 Faces and proportion

This section exists because every failure mode here was expensive to find.

#### 8.4.1 The rules

- **The face is lit.** Shadow falls on the side of the head away from the light and beneath the jaw, never across the eyes.
- **Eyes are two bone white almond shapes, each with a solid ink black pupil.** Sized to read clearly at 300 px, but **no larger than an adult eye**.
- **Realistic adult head proportion.** State it explicitly in the prompt.
- **The head is the lightest region of the figure.** One bright area in a mostly dark figure pulls the eye straight to the face at any size.
- **Hair and beard are single flat masses.** No interior detail.

#### 8.4.2 State an age, and vary the noun cluster

Left unstated, Leonardo returns its average man: roughly forty, conventionally handsome, and identical from character to character. Two rules follow.

**Name the age in the prompt.** "A man in his late twenties with a smooth unlined face" is a target. Nothing is not.

**Watch the noun cluster, not the individual nouns.** Hollow cheeks, shelf brow, hooked nose and a hard-set jaw are four nouns from one gaunt-severe cluster, and any two of them land on forty-year-old man regardless of the stated age. Build each Role's face from a different cluster — round and heavy, narrow and fine, broad and flat, young and unmarked — and check the last approved character before writing the next.

**Age is characterisation, not decoration.** A young face makes scarring read as a story; the same scars on a middle-aged face read as ordinary wear. Pick the age the Role's motive implies.

#### 8.4.3 Hair length is a silhouette tool

Hair is a single flat mass with no interior detail, so hair length costs nothing in detail budget and changes the outline of the head. Long hair past the shoulders gives a wider, softer head shape than anything else available, and on a roster of cropped and bearded men it is one of the cheapest ways to make a figure recognisable in pure black.

#### 8.4.4 Expression in flat woodcut

Three things carry expression at four values with no interior modelling. Everything else is lost.

- **Brow asymmetry** — one eyebrow raised higher than the other
- **Head tilt** — toward or away from what the figure is holding or facing
- **Mouth line** — flat, parted, or set

Chin up reads as interest; chin tucked reads as caution. Curiosity is brow plus tilt plus a slightly parted mouth. Note that a young face with a raised brow and parted lips sits close to the cartoon attractor (5.3) — if it goes goofy, cut the parted lips first and keep the brow and the tilt.

#### 8.4.5 Concealed faces are an exception, not a tier

A hidden face is permitted only when concealment **is** the character's identity, and it costs that Role its most direct expression tool. The Architect earns it through the hat brim; most Roles do not. When in doubt, show the face.

A hood is not automatically a concealed face. Worn up but pushed back off the brow, it keeps the silhouette and the accent placement while leaving the whole face open and lit — this is how the Sorcerer keeps his hood.

Fodder enemies are the one place faces stay dark and anonymous, which is a free legibility win and matches the reduced detail tier in section 9.1.

### 8.5 Wear is shape, not texture

Dirt, grime, stains and grease do not survive the post-processing pass — four flat value bands quantize a smudge into nothing, and asking for them costs prompt words for no visible result.

Wear that reads at 300 px is structural: a sleeve burned off at the elbow, a hem torn and re-panelled, a mended patch with hard angular edges, a strap replaced with the wrong material, a scar as a solid band 1 shape.

**Tie the wear to the Role's mechanics wherever possible.** The Sorcerer's Arcane Instability surges damage him along with everyone else, so his burned-away right sleeve and blackened forearm are the visible cost of how he fights — a mark no other Role can carry. Wear derived from the kit is characterisation; wear applied for grit is texture.

**Scarring is band 1, never the accent.** Accent on skin breaks the acceptance checklist. Burn marks, brands and glyph scars are solid ink black shapes.

### 8.6 The canonical general block

Substitute the bracketed slots from section 3. Everything else is identical in every character prompt, word for word. The repetition is doing most of the consistency work.

```
bold woodcut illustration with engraved structural linework, very thick
uniform black contour outline on the outer silhouette, clean uninterrupted
silhouette edge, flat color fields, hard-edged shadows, high contrast with
large areas of solid shadow in a deep {SHADOW BLACK}, that shadow mass and
the outline sitting at the same value, colors assigned by material: {SKIN}
skin, {GARMENT MAIN}, {MATERIAL NEUTRAL}, {LEATHER} leather straps and
boots, dull pewter grey metal fittings, all flat and unmodulated, warm bone
white reserved for small highlight shapes and the eyes, outline black
tinted slightly toward blue-violet, light from the upper left casting a
narrow bone white edge along the upper left contour, {FOCAL REGION}
carrying the heaviest engraved detail and reading as the focal point of the
figure, the rest of the body held as large flat angular panels with only
sparse structural marks, all marks large and structural, with saturated
{ACCENT} as the single accent covering roughly a fifth of the figure, flat
and uniform with little texture, used only on {PLACEMENT}, hand-carved edge
quality.
```

**Detail vocabulary.** Ask for *structural* detail, and derive the nouns from
this Role's own trade and materials rather than reusing the list from the last
character. The test is size, not vocabulary: any mark that survives the round-trip in section 6 qualifies.

**Always use numeric counts, never adjectives.** "Three or four wrap bands" is a target the model can hit. "Moderate detail" is not, and it will revert to maximalism.

### 8.7 Reference example — Bar Brawler (pre-levers)

Kept as the reference for the subject block's shape. Its slot assignments predate section 3.5 and should not be copied.

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

### 8.8 Reference example — Sorcerer (post-levers, approved)

The working example of sections 2.2, 3.5, 8.4.2–8.4.4 and 8.5 together. Three real hues on the figure — saturated bottle green garment, saturated warm ochre neutral, cobalt accent — separated by value rather than by desaturating two of them, over a green-black band 1.

Slots: garment main saturated deep bottle green, material neutral saturated warm ochre, leather blackened, shadow black green-black, accent unstable cobalt `#2F52C4` on the slab inscriptions, hood lining and rod crown, focal region the chained slab and the hands. Occupation: a ruin-breaker who pries relics out of dead temples.

```
[GENERAL BLOCK with the slots above]
full body character, a young ruin-breaker who pries relics out of dead temples, heavy hooded mantle over a shorter under-robe cut at mid-calf above laced boots, a dark iron shoulder yoke across the back carrying a broken slab of carved ruin masonry chained flat against his chest, weight settled back on the rear foot, a thick cord-wrapped length of ruin ironwork planted forward as one hard diagonal across the whole figure ending in swirling in weird shapes, realistic adult head proportion, a man in his late twenties with a smooth unlined face and a lean jaw, long hair falling past the shoulders as one flat mass inside the hood, deep hood worn up but pushed back off the brow so the entire face is open and lit, face lit with no shadow across the eyes, shadow falling on the side of the head away from the light and beneath the jaw, eyes as two bone white almond shapes each with a solid ink black pupil, sized to read clearly but no larger than an adult eye, one eyebrow raised higher than the other, lips slightly parted, chin up, head tilted toward the slab at his chest, three ink black glyph scars burned across the temple, four rough ruin-stone reagent chunks held in a hinged case at the chest, the mantle burned away at the right sleeve leaving the bare forearm blackened to the elbow, the mantle falling into solid green-black shadow on the lower right side and inside the hood, the free hand closed hard around the cord grip, the rod crown broken and asymmetric with three iron teeth swirling around a carved stone, boots with a simple sole division, in contact with a single flat ground line, three-quarter view facing right, eye-level camera at chest height, orthographic, isolated on a plain flat background of one uniform color, full figure visible with headroom.
```

Counted groups: glyph scars at the temple, reagent chunks at the chest, iron teeth on the rod crown — three, in three regions. The mended hem panels are a borderline fourth and are the first cut if a variant comes back busy.

Architect and Alchemist subject blocks follow the same pattern with their own slot assignments; both are generated and approved under the pre-lever rules.

### 8.9 Accent registry

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
| Sorcerer | unstable cobalt | #2F52C4 | mid | slab inscriptions at the chest, hood lining, stone in the rod crown |
| Emissary | ink indigo | #26326B | dark | seal wax on chest documents, badge |
| Diviner | pale lilac | #B9A5D9 | light | veil trim, throat sigil |
| Cultist | deep amethyst | #5B2A78 | dark | throat brand, robe lining, stained fingers |
| Herald of the Loom | violet magenta | #8E3A91 | mid | active thread through chest loom-frame |
| Tactician | rose magenta | #C2447A | mid | map case, marker rods |
| Warlord | steel blue-grey | #6B7A88 | mid | shield device, helmet plume |

**Watch these three pairs:** Architect brass / Appraiser gold, Sorcerer cobalt / Emissary indigo, Cultist amethyst / Herald magenta. The value gap does the separating in each case, so if a hex is adjusted, never adjust it toward its neighbour's brightness. Placement differs in all three pairs as a backup.

**With saturated garments in play, check the accent against the garment too.** Hue adjacency between a Role's own garment main and its accent is a new failure mode — the Sorcerer's bottle green sits next to cobalt and holds only because the garment is a full value band darker. When they merge, move the garment's value; never shift either hue.

**Eyes are never the accent.** Cultist and Chronophage previously listed eye placements; both have been moved to chest elements. Accent-colored eyes read as menacing and break section 8.4.

**Accent never lands on skin.** Scars, brands and burns are band 1 shapes (8.5).

**Only three champions are fielded at a time**, so full-roster clashes are largely theoretical. What matters is that any three the player picks stay separable.

**Extend each accent beyond the sprite** — card border, map icon, damage numbers, skill VFX. Twenty hues is a lot to learn from sprites alone, but the association forms within an hour or two of play when the same color appears in four places.

#### 8.9.1 Accent hexes that need attention

Several accents in section 8.9 are low-chroma by nature, and a dull accent on a dull garment gives a figure with no vibrancy anywhere:

- **Warlord `#6B7A88`** is a neutral, not an accent. It needs a real color or an explicit decision that this Role is the drab one.
- **Appraiser `#8F7326`**, **Plague Doctor `#2F5D3A`** and **Scholar `#DCCFA8`** are all close to being materials rather than accents. Raise chroma and let value and placement keep doing the separating.

Generate accents as flat uniform fills so they can be masked and boosted in post. Asking Leonardo for a brighter accent drags the whole figure with it; recoloring the mask does not.

### 8.10 Portrait and card crops

> **Not yet written.** Roster, party-select and card UI show champions at a different crop and size from the battle sprite. Needs: crop rectangle relative to the full figure, minimum face size in px, whether the accent budget is recomputed for the crop, and whether portraits are generated separately or cut from the approved full figure.

---

## 9. Enemies and bosses

Enemies inherit everything in Part I and most of section 8. What follows is the difference.

### 9.1 Detail tier by content tier

- **Player Roles** — the block as written.
- **Fodder enemies** — drop to `minimal interior detail, large simple shapes, three values`, faces dark and anonymous, no accent or a heavily reduced one.
- **Bosses** — same block as player Roles plus one additional counted focal element. Do not raise the detail ceiling. Distinguish bosses by scale and by the extra focal element.

### 9.2 Fodder

> **Not yet written.** Beyond the reduced detail tier: how many distinct fodder bodies exist per area, whether recolours are permitted and on which slot, and how a fodder silhouette stays separable from a champion's at 300 px.

### 9.3 Mini-bosses and bosses

> **Not yet written.** Scale relative to champions, how the additional counted focal element is chosen, and whether bosses carry an accent registered like a Role's or borrow the area scene light.

### 9.4 Non-humanoid and creature forms

> **Not yet written.** The whole guide currently assumes a humanoid figure. Beasts, constructs and statues need their own answers on band 1 coverage, the face rule (section 8.4 assumes eyes), and where the accent sits when there is no head-and-chest region.

### 9.5 Enemy color policy

> **Not yet written.** Whether enemies draw from the champion accent registry, from the area scene light, or from a separate reserved set — and how enemy color avoids being read as a champion's identity color during a fight.

---

## 10. Environments

There are **two kinds of environment art**, and they do not share a camera.

**Battle stages** (10.3) obey the perspective spec in section 4 exactly, because
characters stand in them. They are built from four draw-order bands.

**Overworld views** (10.4) are the navigation screens — vistas, or high-above
views the player clicks points of interest on. They are the one asset class in
the game that is **exempt from section 4**, since a chest-height orthographic
camera cannot show a region. The exemption is granted here and nowhere else, and
it is bounded: everything else in Part I still binds, and the value ramp,
outline weight and post-processing pass are what keep an overworld reading as
the same game as the battle it leads into.

Both kinds sit inside an **area** (10.6). An area owns a scene light, a hub, at
least one overview screen, and a catalog of elements its battle bands are
assembled from.

### 10.1 Rules

Applies to battle stages. Overworld views take the last two bullets only.

- **Shallow stage.** A wall or skyline, a thin floor strip, almost nothing in between. This is what makes perspective mismatch impossible to see.
- **Empty center**, sized for the character line.
- **No figures, no creatures** — state both.
- **Flat horizon low in frame**, at the fixed screen fraction from section 4.
- **Backgrounds carry no character accent.** Accent belongs to characters and effects.

### 10.2 Scene light — the mood dial

Each area gets a **scene light color**. It is not a Role accent and never appears on a character's costume. It lives in the sky field, the haze band between parallax layers, and the tint of the floor strip.

| Area | Sky field | Ground / skyline |
|---|---|---|
| Iron Ledger / Holy City | cold slate blue #33414D | #10161B |
| Reclaimed City | sickly teal-green #2E5A50 | #0E1614 |
| Magic ruins | violet #3A2A52 | #120E1A |
| Pirate Coves / coast | cold teal #2C5F72 | #0E1418 |
| Caravan / Adventure | ember orange dusk #C4562A | #14100C |
| Clockwork Spire | TBD | TBD |

Ember dusk is the one warm entry, and it was reserved for the Adventure content so that expeditions feel different from the city work. That reservation is now in tension with 10.7, where Adventure takes its look from whichever area variant a run starts in.

**Characters now carry saturated hue of their own** (3.5), so check each new area against a fielded team of three: a saturated garment main can collide with a scene light in a way a beige one never did. The fix is the area, not the character.

**This table predates the four-area plan in 10.6 and no longer matches it.** Magic
ruins is not among the four areas and is either a variant inside one of them or
dropped. Caravan / Adventure is not an area at all — Adventure derives from the
four (10.7), so this row is a mood reservation rather than a place, and 10.7.4
has to resolve it. Decide before any plate is generated, because the scene light
is what a variant is built around. Every area also needs **one scene light per variant**,
not one per area — a jungle and a ruin under the same sickly teal-green will
read as the same place.

### 10.3 Battle stages — the four bands

Every battle stage is assembled from four bands in draw order. A band is a
budget as much as a layer: content that belongs to one band does not appear in
another, which is what lets elements be reused across stages within an area.

#### 10.3.1 Background

Sky, clouds, moon, sun, mountains, silhouettes of far-away things. Carries the
scene light's sky field (10.2) as one flat saturated field. Lowest detail of the
four bands, and the only band permitted to reduce below the full value ramp.

> **Not yet written.** Value range allowed, whether distant masses are silhouette-only, and whether the sky is a separate scrolling asset from the far masses.

#### 10.3.2 Midband

The visible surroundings of the combat: buildings, trees, foliage, rocks, walls,
waterfalls. This is the band that says which area the player is in, and the band
where the empty-center rule in 10.1 is actually enforced.

> **Not yet written.** Detail budget relative to a champion, how the empty center is composed rather than merely left blank, and whether the midband is one plate per stage or assembled from keyed elements.

#### 10.3.3 Floor

Characters are drawn on top of this band. It is deliberately not a clean plane:
small ground clutter — rocks, grass tufts, dirt piles, trash — breaks the strip
up. Everything here must sit below the ground line established in section 4, and
clutter must not compete with a character's silhouette for the same value.

> **Not yet written.** Clutter density per stage, minimum clear area around each character slot, and whether clutter is baked into the floor plate or scattered by the engine from a small element set.

#### 10.3.4 Foreground

The last band before UI: vines, weather (rain, snow, fog, sun rays), and
occasional silhouettes intruding from the bottom edge — crates, bushes, trash,
similar. Foreground reads as pure band 1 by default, since anything with
interior detail here fights the characters.

> **Not yet written.** Maximum screen coverage so the fight stays readable, whether weather is art or shader, and whether a foreground occluder may ever cross a character slot.

#### 10.3.5 Layer and parallax spec

> **Not yet written.** Scroll ratio per band, pixel dimensions, and how much of each band is off-screen at rest. Section 6 already assumes a haze quad between bands, so state where the haze sits relative to the four. Grey-box this (4.3) before generating anything.

#### 10.3.6 Element catalog and reuse

> **Not yet written.** Each area variant owns a catalog of elements per band, and a stage is a composition of them. Needs: how many elements a variant needs before it stops looking repetitive, the rule for what may be reused across variants inside an area, and whether elements are generated individually and keyed or cut from generated plates.

### 10.4 Overworld and navigation views

One or more per area (10.6), used to navigate by clicking points of interest.

#### 10.4.1 Camera and framing

> **Not yet written.** Vista versus high-above is a choice per area or a single convention for all of them — decide which. Needs the camera treatment, whether the view scrolls or fits one screen, and how it holds the light-from-upper-left rule when the ground plane is no longer vertical.

#### 10.4.2 Points of interest

> **Not yet written.** What a clickable POI looks like on the plate, its states (locked, available, cleared, current), how it stays legible against dense terrain, and its relationship to the Expeditions node icons in 12.3 — the same visual language or a separate one.

#### 10.4.3 Legibility at overworld scale

> **Not yet written.** Detail at this camera is far smaller than a character's, so state what survives: the outline weight at region scale, whether the four-band ramp holds or drops to three like icons do, and how an area reads as itself when its midband vocabulary is not visible.

### 10.5 Hub screens

One per area (10.6). The hub is where the war room, Armory, Adventurer's Guild
and shop live (`Concept_Document.md` 3.6).

> **Not yet written.** Decide first whether a hub is an illustrated plate with clickable regions, UI panels over a plate, or an icon-driven menu — that decision sets how much art exists at all. Then: whether a hub reuses its area's battle-band elements or is generated as its own composition, and how the four hubs stay distinguishable at a glance.

### 10.6 Area catalog

Four areas are planned. Each has **two variants**, one hub (10.5), at least one
overview screen (10.4), and its own element catalog per battle band (10.3.6).
Variants are as distinct from each other as two areas would be, so treat a
variant, not an area, as the unit of work. Each also owes Adventure an element
set (10.7), since a run starts from a chosen variant.

| Area | Variant A | Variant B |
|---|---|---|
| Reclaimed City | Jungle | Ruins |
| Clockwork Spire | Mechanical construction areas | Oily ad-hoc slums in mines |
| Pirate Coves | Rocky islands, harsh ocean presence | Candle-lit moist and mouldy shanty town, wood and sailcloth |
| The Iron Ledger | Run-down slums of a massive city | White glistering inner city |

**The Iron Ledger's inner city is the hardest asset in the plan.** White
glistering is a light-dominant environment, and section 2 gives band 1 roughly
half of every figure. A champion in front of a white plate is a black cutout.
Either the inner city takes a treatment that keeps large committed darks in the
midband, or the character rules bend for that one variant — the same trade the
Jester takes in 2.2, and it should be decided deliberately rather than
discovered in a composite.

**Pirate Coves variant B is the only candle-lit interior in the set**, which
means a warm scene light and a light source that is not upper-left at region
scale. Section 4's light rule holds for the assets themselves; how a warm
interior coexists with the one-warm-area reservation in 10.2 is open.

#### 10.6.1 Reclaimed City

> **Not yet written.** Per variant: scene light, band vocabulary (10.3.1–10.3.4), approved plates.

#### 10.6.2 Clockwork Spire

> **Not yet written.** Per variant: scene light, band vocabulary, approved plates. No scene light assigned yet at all (10.2).

#### 10.6.3 Pirate Coves

> **Not yet written.** Per variant: scene light, band vocabulary, approved plates.

#### 10.6.4 The Iron Ledger

> **Not yet written.** Per variant: scene light, band vocabulary, approved plates. Resolve the white-plate problem above before generating.

### 10.7 Adventure — the derived overview

Adventure is not a fifth area. It is a feature reached from each of the four
hubs, and a run starts in one of that area's two variants (10.6), taking its
look from there. Every variant therefore owes Adventure an element set, and
**eight sets are in scope, not one.**

It is a third camera case rather than a third kind of environment. Like an
overview (10.4) it shows a region the player clicks through, but it is not a
finished plate: the map is **composed at runtime from many small elements**,
which makes it the only environment in the game where art is authored as parts
and assembled by code. That inverts the usual acceptance route — a single
element can pass every check in section 7 and the assembled map still fail.

#### 10.7.1 Element set requirements

> **Not yet written.** What runtime composition demands that a plate does not: which elements tile or repeat without a visible seam, how many variations of each are needed before repetition is legible, how density and placement are driven, and how the outline weight survives elements being placed at differing scales next to each other. The catalog is per variant and derives from that variant's band vocabulary (10.3.6) rather than being drawn fresh.

#### 10.7.2 Map furniture

> **Not yet written.** Node icons (12.3), path connectors, and node states are the layer that sits on top of the composed field. Needs the same states as 10.4.2 and should share their answer — a player should not learn two POI languages. State whether furniture is generated art or drawn in engine.

#### 10.7.3 Composition acceptance

> **Not yet written.** The check that a plate does not need: several generated maps viewed at target size, judged for repetition, for whether the variant is still recognisable once elements are scattered rather than composed by hand, and for whether nodes stay findable against a dense field.

#### 10.7.4 Scene light for Adventure

> **Not yet written.** Ember dusk (10.2) was reserved to make expeditions feel unlike the city work, but that predates Adventure deriving its look from a chosen variant. The two cannot both hold as written: either a run keeps its source variant's light and loses the reserved mood, or ember dusk overrides it and the eight element sets read as one place. Resolve before generating any of them.

---

## 11. Items, gear and reagents

> **Not yet written.** This whole section is missing and is the largest gap in the guide. Gear is a core loop (`Concept_Document.md` 3.3), and none of it has a visual spec.

### 11.1 Shared conventions

> **Not yet written.** Which value bands and slots items use, whether items carry an accent, the camera treatment (items are objects, not figures, so 4.2's composition tail does not apply), and the presentation angle.

### 11.2 Weapons, off-hands and boots

> **Not yet written.** One silhouette convention per equipment slot so an item is identifiable as a weapon or a boot at inventory-cell size before it is identified as which one.

### 11.3 Reagents

> **Not yet written.** Reagents are consumed and appear in kit text, so they need to be identifiable at very small size and in quantity. Decide whether they are icons (12) or objects (11) — they are currently neither.

### 11.4 Currencies and consumables

> **Not yet written.** Each currency in `Concept_Document.md` 3.3.2 needs one unmistakable shape, held to the icon rules rather than the item rules.

### 11.5 Rarity and gear-set signalling

> **Not yet written.** How rarity reads visually without a colored frame doing all the work, and how a gear set stays recognisable across three equipment slots. Note this competes with the champion accent system for the player's color vocabulary — decide the priority.

---

## 12. Icons

Icons are where the style either works or fails, because they are the smallest thing on screen.

### 12.1 Rules

- **Target size first.** Decide the pixel size (map nodes ~48–64 px, skill icons ~64–96 px) and judge every candidate at exactly that size, never at full resolution.
- **Drop to three values.**
- **Drop the material slot system.** At icon scale there is no room for eight fills. Icons use ink black, bone white, one mid neutral and the accent. The tinted band 1 of 2.2 does not apply at icon scale.
- **One idea per icon.** A single object, centered, filling the frame.
- **Silhouette must survive being filled black.**
- **Outline gets proportionally thicker**, not thinner, as size drops.
- **Node type icons carry no accent** — they are map furniture. **Skill icons carry the caster's accent**, and here the accent may run to 30% because there is nothing else competing.

### 12.2 Prompt pattern

```
bold woodcut icon, very thick uniform black contour outline, flat color
fields, three values, hard-edged shadows, a single {SUBJECT} centered and
filling the frame, large simple shapes, minimal interior detail, no fine
linework, no small marks, readable at very small size, rendered in ink
black, bone white and one mid grey[, with {ACCENT} as the single flat accent
on {PLACEMENT}], plain flat background, no scenery.
```

### 12.3 Node icon subjects (Expeditions map)

Keep these to one unmistakable object each: Fight — crossed blades; Boss — a horned skull; Rest Stop — a campfire with three logs; Hint — an open eye; Gamble — a pair of dice; Escalate — an upward arrow through a broken ring.

### 12.4 Active skill icons

> **Not yet written.** The largest icon set in the game, one or more per skill across twenty Roles. Needs a subject convention (what an icon depicts — the effect, the gesture, or the tool), how the caster's accent is applied at 30%, and how skills that share a mechanic stay visually related without becoming interchangeable.

### 12.5 Status effect icons

> **Not yet written.** Eight simultaneous slots (`Concept_Document.md` 1.1.4), so these are read in a row at the smallest size in the game. Needs a buff/debuff distinction that is not color alone, a stack-count treatment, and a shared shape language across the status list in 3.2.3.

### 12.6 Passive and identity buttons

> **Not yet written.** Passive skills, grafting, thread stance switching. These are persistent UI affordances rather than one-shot icons and may belong with 13.1 instead — decide which.

### 12.7 Item and reagent icons

> **Not yet written.** The inventory-cell rendering of section 11. State whether these are separate assets from the item art or downscales of it.

### 12.8 Currency and resource icons

> **Not yet written.** Energy, currencies, experience. Read constantly in HUD chrome, so they must survive at the smallest size of all and must not compete with status icons for attention.

---

## 13. UI art

> **Not yet written.** Also entirely missing. The style has strong opinions (thick outline, four values, no gradients) that a default engine UI will contradict on the first screen.

### 13.1 Frames, panels and buttons

> **Not yet written.** Outline weight at UI scale, corner treatment, panel fill values, button states (idle, pressed, disabled), and whether UI chrome sits inside the four-band ramp or is exempt.

### 13.2 Typography

> **Not yet written.** Typeface choice for headers and body, and whether numbers in combat get their own treatment. A woodcut style is unusually sensitive to this — a neutral UI sans will read as a different game.

### 13.3 Combat HUD

> **Not yet written.** Health and resource bars, turn order, damage numbers, and the Echo sequence presentation required by `Concept_Document.md` 1.1.5. Damage numbers carry the caster's accent (8.9), so they are style assets, not engine defaults.

### 13.4 Layout and screen inventory

> **Not yet written.** One entry per screen, each with its grey-box (4.3) before any art is generated.

---

## 14. Effects and VFX

### 14.1 Rules

Effects are the one place the accent may exceed its budget, because they are transient. Everything else holds.

- **Same thick black outline**, even on magic. An unlined glow does not belong to this game.
- **Shape over glow.** Radiating lines, chunky sparks, solid smoke masses, cracked rings. Not soft bloom.
- **Effects inherit the caster's accent color.** This is the single strongest reinforcement of the identity color system.
- Generate on **plain black or plain white**, keyed out afterward, never on a scene.

### 14.2 Where the juice actually comes from

Most perceived impact is code, not art, and costs far less than more VFX assets:

- Whole-sprite squash and stretch via Tween on `scale`, plus `skew`
- Hit-flash shader, white or the accent color, two frames
- Hitstop of 60–100 ms, screen shake
- Idle bob of 2–3 px plus 1–2% scale on a long sine

Build this layer before commissioning more effect art.

### 14.3 Status effect visual language

> **Not yet written.** A status is on a target for several rounds and must be visible on the sprite, not only in the status bar. Needs a persistent-effect vocabulary distinct from the transient hit effects above.

### 14.4 Impact and cascade library

> **Not yet written.** The burst resolves as a visible sequence of Echoes (`Concept_Document.md` 1.1.5), which is a specific VFX requirement: escalating tempo and magnitude across many resolutions. Needs a shared impact set and a rule for how an Echo differs visually from the action that spawned it.

---

## 15. Animation

Cutout skeletal animation suits this style — flat fields and hard outlines survive being chopped apart.

- **Give every cut piece its own closed black outline.** Half-committing, where some edges are lined and some are raw, is the failure mode.
- **Cut with generous overlap**, not at the joint. Round the end of each limb piece so rotation sweeps inside the shape.
- **Three-quarter view costs extra work**: the far arm and leg are occluded and must be redrawn, plus whatever sits behind each piece.
- **Sprite2D on Bone2D** for rigid limbs. Polygon2D skinned to Skeleton2D only for genuinely soft things (tendrils, coat hems).
- **Keep the eyes on their own layer.** They are hand-placed and they are the first thing that breaks when a head piece rotates.

**Do the cheap layer first** (section 14.2). At 300 px on a phone, whole-sprite squash/stretch plus hit-flash plus hitstop delivers most of the perceived quality.

**Middle option:** generate 3–4 pose variants per character and hard-cut between them, no tweening. Limited animation is period-correct, hides a multitude of sins, and plays better with generated art than rigging does.

---

## 16. Marketing and out-of-game art

> **Not yet written.** Store capsules, screenshots, wordmark and key art are consumed by players and fall under the same disclosure obligation as in-game art (18). They also break the composition tail in 4.2 — a capsule is a composition, not an isolated figure — so they need their own rules rather than an exception granted case by case.

### 16.1 Logo and wordmark

> **Not yet written.** Studio name is settled; the wordmark treatment is not.

### 16.2 Store capsules and screenshots

> **Not yet written.** Sizes, which champions appear, and whether capsule art is generated or composited from approved assets.

---

# Part III — Record and process

---

## 17. Rejected directions

Recorded so they are not retried. Each of these was generated and judged, not reasoned about.

- **Enlarged head plus enlarged eyes.** Moving both dials at once is the cartoon recipe. The lit face was the fix for distance; the proportions were not, and changing them read as goofy.
- **Bone white eyes glowing out of a shadowed upper face.** A horror device. Pushed the tone further toward menacing, which was the opposite of the goal.
- **Bloodmage as a pale nobleman in a high-collared coat.** Landed on Dracula immediately, cape and fangs included. See 5.3.
- **Bloodmage as a frail wilderness outcast.** Read as an NPC. Low status is what "shunned" looks like, and no amount of gear fixes it.
- **Bloodmage as a composed sorcerer in bone regalia.** The overcorrection from frail. Regal, clean, and no longer transgressive.
- **Cultist in torn strips with a bare chest and a notched blade.** Reads as a barbarian, and it was also four counted groups deep.
- **Cultist in a plain working coat and flat cap.** Taking "hides from the Ledger" literally removed all fantasy content and left nothing a player would want to field.
- **Jester with a soft floppy cap, wide grin and a wiry build.** Cartoon. `wiry` shrinks the body and makes the head read as oversized.
- **Sorcerer as a field surveyor in a travel coat, gaiters and pack roll.** Competent and legible, and completely bland — modern hiking gear with no fantasy content, and the staff came back as a plain walking pole. Fleeing the wizard basin with travel vocabulary lands in the outdoorsman basin.
- **Sorcerer with hollow cheeks, shelf brow, hooked nose and a hard-set jaw.** Four nouns from one cluster, no stated age: returned the model's default forty-year-old handsome man, indistinguishable from the other male heads in the set.
- **Desaturated garment main as an unwritten default.** Not a generation failure but a documentation one — six characters were built on a rule nobody had written, and the roster came out as grades of beige with one muted accent each. See 3.5.

---

## 18. Operational notes

**Lock the model and settings.** Same Leonardo model, same Style Reference / Elements, same generation settings across the whole set. Record them here once chosen. Changing model mid-roster is the single fastest way to break cohesion.

**Composite early.** Perspective and value problems are obvious in a composite and nearly invisible when looking at assets one at a time in a browser tab. Never accept a character without dropping it into the battle scene next to one already approved.

**Document ownership.** This guide owns style. `Concept_Document.md` section 7 has been reduced to a pointer at it plus the game-facing facts style depends on; when the two disagree, this guide is correct and the concept document is stale. Do not restate slot tables, accent hexes or prompt blocks in the concept document again — the last duplication drifted in three places before it was caught.

**Steam disclosure.** Valve requires disclosure of AI-generated content that ships with the game and is consumed by players, including in-game art and store-page marketing. AI dev tools used behind the scenes are exempt under the January 2026 rewrite. Write the disclosure as the public-facing document it is — it appears on the store page.

**Commercial terms.** Confirm the Leonardo plan tier grants commercial rights and the export resolution needed before building further on this pipeline.

---

## 19. Open decisions

Collected so they are visible in one place rather than buried in the sections that raise them.

- **The pre-lever five.** Five characters were approved under the old arithmetic and either get regenerated or the roster carries a visible split. See 3.5; act on it at six characters rather than at fifteen.
- **Warlord accent.** `#6B7A88` is a neutral, not an accent. Either it becomes a real color or this Role is declared the drab one on purpose (8.9.1).
- **Scene light table versus the four-area plan.** The 10.2 table lists six areas; 10.6 plans four with two variants each. Magic ruins and Caravan / Adventure need a home or a deletion, and scene light needs to be assigned per variant rather than per area.
- **Clockwork Spire scene light.** Unassigned for both variants (10.2, 10.6.2).
- **The white inner city.** A light-dominant environment against figures that are half band 1. Either the midband keeps committed darks or the character rules bend for one variant (10.6).
- **Overworld camera.** The one exemption from section 4 in the whole guide. Vista or high-above, one convention or per area (10.4.1).
- **Adventure's scene light.** Ember dusk was reserved for expeditions, but Adventure now derives its look from the variant a run starts in. Both cannot hold (10.7.4).
- **One POI language or two.** The overview screens (10.4.2) and the Adventure map (10.7.2) both need clickable points with states. Answering them separately teaches the player two vocabularies.
- **Model and settings lock.** Not yet recorded (18).
- **Rarity colors versus accent colors.** Two color-identity systems competing for the same player attention (11.5).
