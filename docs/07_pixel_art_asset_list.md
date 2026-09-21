# 7. Pixel-Art Asset List

**Style target:** NES/GBC/Pokémon R&B-era — limited palette (~32 colors), clean black or dark-navy outlines, chunky readable silhouettes, 2–4 frame animations (no need for fluid 12-frame animation — that era relied on strong poses).

**Canvas convention:** Author sprites on a small native grid (e.g., 32×32 or 64×64 for the cat, 16×16 for icons), import with filtering off, then scale up (2×/3×/4×, integer only) to look correct at 1280×720.

## Palette
- Define one shared `.gpl`/reference palette (~32 colors: a few skin/fur tones, 4–6 UI blues/grays, red/green feedback colors, yellow accents) before drawing anything — reuse it everywhere for cohesion.

## Character: Cat
| Asset | Frames | Native Size | Notes |
|---|---|---|---|
| Cat Idle | 2 (blink cycle) | 64×64 | Default gameplay pose |
| Cat Happy (correct) | 2–3 | 64×64 | Ears up, eyes closed/starry, maybe a little hop |
| Cat Sad (incorrect) | 2 | 64×64 | Ears down, eyes squint |
| Cat Happy Big (Level-Up popup) | 2–3 | 96×96 or 128×128 | Larger hero pose |
| Cat Sad Big (Demotion popup) | 2 | 96×96 or 128×128 | Larger hero pose |
| Cat Title Idle | 2 | 64×64 | Cameo on title screen (can reuse gameplay idle) |

## Backgrounds
| Asset | Size | Notes |
|---|---|---|
| Title Background | 1280×720 | Simple parallax-friendly scene (chalkboard/classroom or starry night — pick one motif) |
| Gameplay Background | 1280×720 | Neutral classroom/notebook-paper motif so foreground UI reads clearly |
| Game Over Background | 1280×720 | Muted/darker variant of gameplay bg |
| (Stretch) Per-grade backdrop tint/variant | 1280×720 x4 | Grades 1–4 recolors/motif swaps |

## UI Chrome
| Asset | Size | Notes |
|---|---|---|
| Panel 9-slice frame | 16×16 tile (9-slice) | Used for question panel, popups, pause menu, game over panel |
| Answer Button — normal | 300×80 (9-slice) | |
| Answer Button — hover/focus | 300×80 (9-slice) | Slightly brighter border |
| Answer Button — correct feedback | 300×80 (9-slice) or overlay | Selected button switches to green; text stays white |
| Answer Button — incorrect feedback | 300×80 (9-slice) or overlay | Selected button switches to red |
| Answer Button — promotion feedback | 300×80 (9-slice) or overlay | Promotion-triggering correct selection switches to blue; text stays white |
| Level-Up feedback | 300×80 (9-slice) or overlay | Blue banner/text treatment |
| Xbox face-button cluster | 96×96 | Four 44×44 circular A/B/X/Y glyphs in a centered diamond between the answer buttons; noninteractive visual input reference |
| Grade badge icons (1–4) | 32×32 each | Small numeral badge shown in HUD |
| Score/coin icon | 24×24 | |
| Timer/clock icon | 24×24 | |
| Streak pip — correct (filled/empty) | 16×16 x2 | |
| Streak pip — incorrect (filled/empty) | 16×16 x2 | |
| Heart/life icon (filled/empty) | 16×16 x2 | 9 shown in a row in the HUD; one flips to empty per incorrect answer |
| Level-Up banner graphic | ~600×200 | Stars/confetti motif |
| Demotion banner graphic | ~600×200 | Rain-cloud/broken-heart motif |
| Logo — "Math Cat" title art | ~700×300 | |
| Cursor/selector arrow (menus) | 24×24 | |
| Confetti/particle sprites | 8×8 x3–4 variants | For level-up celebration |

## Bitmap Font
| Asset | Notes |
|---|---|
| Pixel bitmap font (or a free NES/GB-styled font imported as a Godot `Font` resource) | Use for all in-game text for consistent retro feel; a single free/CC0 pixel font (e.g., "Press Start 2P"-style) is a perfectly valid jam shortcut if time is short. |

## Priority for MVP (Must-have art, everything else is polish)
1. Cat idle/happy/sad (gameplay-size) — even a simple 1-color-block placeholder is fine day 1.
2. Answer button states (normal + correct/incorrect flash).
3. Basic panel frame.
4. Title/Game Over background (can be solid color + logo text initially).
Everything else (big popup cat poses, per-grade backdrops, confetti) is Should/Could-have — see doc 10.
