# Adventure Mode

## 1. Architecture Audit

Adventure extends the existing game rather than maintaining a second question-playing scene. The implementation audit identified these existing owners:

| Existing owner | Responsibility retained |
| --- | --- |
| [autoload/game_manager.gd](../autoload/game_manager.gd) | Session mode/state, lives, scoring, authoritative answer resolution, restart |
| [autoload/progression_manager.gd](../autoload/progression_manager.gd) | Five-correct promotion and three-incorrect demotion |
| [autoload/profile_manager.gd](../autoload/profile_manager.gd) | Shared profile, settings, career totals, persistence |
| [scenes/game/game.gd](../scenes/game/game.gd) | Question bank, answer diamond, hearts, text fitting, input, pause/options |
| [autoload/achievement_manager.gd](../autoload/achievement_manager.gd) | Question, streak, lifetime, and Retro-only eligibility |
| [autoload/audio_manager.gd](../autoload/audio_manager.gd) | Existing music, SFX, volume and pause behavior |
| [scripts/character/character_evolution_manager.gd](../scripts/character/character_evolution_manager.gd) | Existing character assets and reactions |
| [scripts/background/background_evolution_manager.gd](../scripts/background/background_evolution_manager.gd) | Retro background progression |

The main risks were accidental Retro victory/record updates, evolving a campaign character at boss boundaries, loading a question twice, and stale input or deadlines surviving pause/restart. Adventure uses separate result signals and question tokens to isolate those paths.

## 2. Minimal Extension

There are no new autoloads, question generators, sprite sheets, music assets, or third-party dependencies. One hub scene presents campaigns and maps. A small Adventure controller attached to the shared game owns presentation; GameManager remains authoritative for rules. A catalog supplies all 27 level configurations. Stages 1-8 use a dedicated procedural pixel-art background keyed by map stage, while bosses retain Retro's Grade 12 synthwave shader. The earlier procedural city prototype is no longer instantiated.

## 3. Entry and State Flow

The title order is Retro Mode, Blitz, Adventure, Options, Stats, Achievements, Exit Game.

```text
Title -> Campaign Select -> World Map -> Shared Gameplay
                                      -> Pause -> Resume / Restart / Options / World Map
Gameplay -> Level Complete -> Payment -> World Map (automatic)
Boss -> Campaign Complete -> VICTORY! / Payment -> World Map (selected)
Gameplay -> Level Failed -> Retry Level / World Map
World Map -> Campaign Select -> Title
```

`ADVENTURE` is appended to `SessionMode`, preserving existing enum values. New states are `CAMPAIGN_SELECT`, `WORLD_MAP`, `LEVEL_COMPLETE`, `LEVEL_FAILED`, and `CAMPAIGN_COMPLETE`. Adventure results emit `adventure_finished`, not Retro's `session_ended`.

## 4. Campaign Configuration

Source: [scripts/adventure/adventure_catalog.gd](../scripts/adventure/adventure_catalog.gd).

| Campaign ID | Grades | Fixed character | Timed question | Boss victory on entering | Music |
| --- | --- | --- | --- | --- | --- |
| `elementary` | 1-4 | Kitten (0) | 12 seconds | Grade 5 | `mathkitten_theme` |
| `middle` | 5-8 | Big Cat (1) | 24 seconds | Grade 9 | `mathcat_theme` |
| `high` | 9-12 | Tiger (2) | 36 seconds | Grade 13 | `mathtiger_theme` |

The music column applies to levels 1-8. Every campaign's boss overrides gameplay music to `nerdcat_theme` and background presentation to Grade 12, independently of its question grade and character. Bosses use the shared `SESSION_TIME_SEC` (120 seconds), not the per-question `timed` / `timer_seconds` fields.

`level(campaign, number)` returns campaign, number, grade, character, timed, timer_seconds, correct_target, background, city_name, level_type, boss_start_grade, boss_victory_grade, reward, and music. `CORRECT_TARGET` defaults to 10 and can be changed centrally. Session configuration is a fresh dictionary, so tests or future authored overrides do not mutate the catalog.

## 5. Level Configuration

| Level | Elementary | Middle | High | Rule | Coins per clear |
| --- | --- | --- | --- | --- | --- |
| 1 | The Oregon Math Trail (Grade 1) | Mega Math Cat (Grade 5) | Super Variable Bros. (Grade 9) | Untimed, 10 correct | 25 |
| 2 | Duck Count (Grade 1) | Street Fraction II (Grade 5) | Final Factoring (Grade 9) | Timed, 10 correct | 30 |
| 3 | River City Subtraction (Grade 2) | Double Decimal (Grade 6) | F(x)-Zero (Grade 10) | Untimed, 10 correct | 35 |
| 4 | ExciteMath (Grade 2) | Super Mathorid (Grade 6) | Conker's Bad Equation Day (Grade 10) | Timed, 10 correct | 40 |
| 5 | Mathlevania (Grade 3) | Streets of Algebra (Grade 7) | Resident Equal (Grade 11) | Untimed, 10 correct | 45 |
| 6 | StarCat 64 (Grade 3) | The Elder Sums (Grade 7) | Derivative Kong Country (Grade 11) | Timed, 10 correct | 50 |
| 7 | Divide Horizon (Grade 4) | Microsoft Flight Calculator (Grade 8) | Halo: Calculus Evolved (Grade 12) | Untimed, 10 correct | 55 |
| 8 | Metal Gear Kitten (Grade 4) | Gears of Bar Charts (Grade 8) | Killer Integral (Grade 12) | Timed, 10 correct | 60 |
| Boss | The Legend of Math Cat | Teenage Mutant Ninja Mathematicians | Chrono Trigonometry | 2:00 session + promotion time bonuses | 100 |

## 6. Scene Hierarchies

[scenes/adventure/adventure_hub.tscn](../scenes/adventure/adventure_hub.tscn) has a full-rect Control with this runtime hierarchy:

```text
AdventureHub (Control, procedural map drawing)
  Canvas (1280x720 design surface, scaled and centered)
    Heading / Progress labels
    Campaign buttons + existing MathCat sprites, OR nine level buttons
    Selected-level detail
    MapCat (active level marker)
    Back button
```

The existing [scenes/game/game.tscn](../scenes/game/game.tscn) remains the gameplay scene. Its runtime additions are:

```text
Game (existing Control)
  Background (existing synthwave shader, visible for bosses and other modes)
  AdventureStageBackground (procedural Control, visible only for Adventure stages 1-8)
  Grade13Equations (existing, hidden in Adventure)
  Content / Answers / MathCat (existing)
  PauseOverlay (existing, World Map replaces Quit to Title)
    Save failure notice
  AdventureGameplay (Node, presentation controller)
  Save-error warning (only on failure)
  Result overlay (created only on completion/failure)
    Dim / Heading / campaign victory subtitle / existing MathCat / coin textures / Status
    Retry Save or Retry Level / World Map
```

## 7. Map and Unlocks

Every campaign starts with level 1 unlocked. Completion unlocks only the next node; level 9 caps the unlock index. Locked nodes are disabled, `FOCUS_NONE`, and excluded from actionable navigation. The manager rejects locked entry even if a caller bypasses the map UI.

After a successful clear unlocks a new level, the map cat starts above the completed node and hops along the connector to the newly unlocked node. Returning from a boss victory instead plays three jumps in place above the boss, including boss replays. These one-shot animations survive the results-to-map scene change and save retries, but do not repeat on reopening the map or visiting the shop. Replaying an ordinary completed level, failing, or leaving an incomplete attempt does not trigger an unlock animation. Choosing another map control interrupts the animation cleanly; changing screens or starting another attempt clears it. Cat movement remains enabled when Animated Background is off.

The city-trail map uses Rooftop Rescue's synthwave visual language: midnight ink sky, twinkling pixel stars, a striped peach/pink sunset, a deterministic building skyline, and a perspective grid. Player-facing level names vary by campaign, while the shared visual stage art remains keyed to stage number. Rooftop buildings remain beneath stages 6-9; buildings beneath stages 1-5 are omitted to leave the lower grid visible. The campaign picker shares the same sky and skyline. The original nine node positions and hit targets are unchanged. Neon connectors show the route (cyan for unlocked connections, muted for locked ones); locked nodes, completed `DONE` markers, the distinct boss label, thick focus border, and campaign cat remain visible. Quiet header/detail bands keep text readable. Background drawing shares the controls' centered 1280x720 transform at smaller window sizes.

The shared **Animated Background** setting freezes the star/grid clock without removing the skyline, sunset, or route. Re-enabling it resumes from that frame; no random geometry changes during redraws. Mouse focus synchronizes keyboard/controller selection. Stick navigation has a 100ms cooldown and consumes rejected motion events. Back/Escape/B traverses map -> campaigns -> title.

The nine stage-button borders use an authored neon palette: cyan, sky blue, periwinkle, mint (`#7FFFD4`), lemon (`#EFFF7F`), gold (`#FFD76A`), candy pink (`#FF9CDA`), light coral (`#FFB3A3`), and the sun's warm peach (`#FFBC87`). The middle stages avoid lavender/purple hues that blend into the scenery; stages 7 and 8 keep their brighter shades. Full-brightness borders retain at least 4.5:1 contrast against the purple sky, building fills, grid, and roof trim. A six-pixel midnight backing behind each button separates its border/glow from nearby scenery without changing its hit target.

All stage fills remain dark teal (`#203B3A`); both white text and full-brightness borders retain at least 4.5:1 contrast against the fill. Focused, hovered, and pressed borders thicken from 4 to 7 pixels, with a stronger subtle glow, without changing the stage's color or fill. Locked borders are darkened by 25% without a glow; `LOCK`/`NEXT`/`DONE` captions identify progress. Campaign-picker and Back buttons retain their existing gold focus borders.

## 8. Nine-Life Attempts

**Chosen rule:** every entry and restart begins a fresh nine-life attempt. Lives are not carried between levels or saved as an unfinished attempt. The map labels this explicitly as `NEXT ATTEMPT: 9 LIVES`.

Every accepted wrong answer or per-question timeout removes exactly one life. Correct answers do not restore lives. Zero lives produces `LEVEL_FAILED`; completed nodes, currency, records, and previously earned correct-answer totals remain saved. A boss session timeout ends the attempt immediately without subtracting a life or counting another wrong answer.

## 9. Fixed-Grade Progress

Levels 1-8 keep their configured grade, hide promotion/demotion meters, and show `correct / target`. Only accepted correct answers advance this counter. Wrong answers and timeouts do not reduce it. Reaching the target immediately closes gameplay and enters completion. Existing scoring is reused for per-level records: 10 times the answered grade for each correct answer.

## 10. Question Timer and Race Rules (Levels 1-8)

`prepare_adventure_question` closes input and creates a new question ID. The existing bank loads and formats the question; the presentation controller waits two frames and finishes text fitting before calling `ready_adventure_question`.

Timed questions use a monotonic millisecond deadline. The display rounds upward to tenths and never shows negative time or minutes. It resets to the full configured allowance for every question. Answer feedback freezes it. Pause stores remaining time and excludes paused time from response-duration achievements.

Submission checks the session serial and question ID, synchronizes the deadline, then rechecks the gate. **Timeout wins at the exact deadline.** Resolution closes the gate before emitting signals, so repeated input cannot cost a second life. Timeout immediately loads a new question; ordinary answer feedback lasts 0.7 seconds. Replacement questions cannot accept queued input before readiness. Restart/exit invalidates asynchronous callbacks using the session serial. Pausing during feedback cannot unlock the old answer.

## 11. Bosses

Bosses reuse ProgressionManager, including its existing counter resets and five-correct / three-incorrect thresholds. Its new `grade_floor` is the campaign start grade; reset restores Retro's floor of 1. Bosses begin at 1, 5, or 9 and win immediately on entering 5, 9, or 13. No question is loaded at the victory boundary.

The boss uses Retro's shared overall session countdown, starting at `TIME 02:00`. It does not reset per question. Nonfinal promotions add `completed_grade * TIME_BONUS_PER_COMPLETED_GRADE` seconds (10 per completed grade) and the existing 50 score points. The final promotion awards score and wins immediately, without a further time bonus. The clock runs only in `PLAYING`: pause, `LEVEL_UP`, and `DEMOTION` freeze it, while ordinary answer feedback consumes time as in Retro. Zero time produces `LEVEL_FAILED` with reason `time_up` and heading `TIME'S UP!`; new attempts restore 120 seconds and nine lives. An answer at zero is rejected even before the next process tick.

Five correct answers show green `Level Up! Grade N` text, Retro's blue selected-answer highlight, the five filled flashing pips, and the existing two-cycle `play_level_up()` animation. Retro's promotion/evolution text also uses green, with a capital U in `Level Up!`. Generic happy feedback cannot replace the promotion celebration. Grade changes hold feedback for 2.0 seconds, matching Retro; ordinary boss answers use Retro's 0.75 seconds. Incorrect feedback remains red, including demotion. The campaign cat never evolves into another form. Every boss HUD reads `FINAL BOSS` at the same 36-point font size as Grade and LIVES. Location names are not displayed during gameplay. Timer and save-warning labels remain hidden while paused, including in Options.

Boss victory still uses Adventure's `CAMPAIGN_COMPLETE` state and result/save path. It never triggers Retro's result screen, records, or victory achievement.

## 12. Payment and Replay

**Chosen rule:** every successful clear pays the level's configured coin reward, including normal-level and boss replays. Each new completed attempt adds one reward and updates best score, best remaining lives, and clear count. Replays do not duplicate completed map nodes or change the unlock sequence. Clearing all nine levels once earns 440 coins per campaign; replay earnings are additional.

The controller uses existing character celebration and positive SFX with an original generated pixel-coin animation. The result is saved before return is enabled. After about 1.8 seconds, successful saved normal levels return to the map automatically. Bosses keep the final correct answer highlighted with green `VICTORY!` feedback and play the campaign cat's `evolution_pose` animation without changing its form. After Retro's shared one-second `RESULT_REVEAL_DELAY_SECONDS`, a dedicated green `VICTORY!` heading appears with campaign identity and the campaign cat's existing looping celebration. Input stays locked during the delay; restarting or exiting invalidates the pending reveal. Old gameplay content is hidden only when the result appears, while the grid remains behind it. The screen stays open until World Map is selected, allowing the one-shot victory music to finish. A new attempt restores the shared gameplay layer. Retro retains its matching one-second final-answer/evolution delay and uses the green `VICTORY!` heading too.

A failed save displays Retry Save; retry calls only `save()`, never completion again. Repeated completion notifications cannot pay the same attempt twice, duplicate the victory overlay, or restart its music. Successful replays show the same coin payment and animation as a first clear.

### Pet Shop

The world map's **PET SHOP** opens a campaign-specific cosmetic store with seven items:

| Cosmetic | Coins | Slot |
|---|---:|---|
| Bow Tie | 50 | Neck |
| Bandana | 100 | Neck |
| Golden Crown | 200 | Head |
| Top Hat | 150 | Head |
| Flower | 75 | Head |
| Sunglasses | 125 | Face |
| Bell Collar | 75 | Neck |

Focus an item to preview it on the campaign cat without changing saved equipment; activate the item to focus the explicit **Buy & Equip** action. Buying equips automatically in that item's slot. Wear one head, face, and neck item together, such as Top Hat + Sunglasses + Bell Collar. Equipping replaces only the same slot, and previews retain compatible equipped items. Owned items can be equipped or individually removed for free. **Remove All** lives in the footer, separate from merchandise; select it and confirm using the primary action to clear the outfit. All seven merchandise rows remain visible without scrolling.

The shop uses the existing menus' navy, blue-grey, white, and gold palette over a subdued Adventure tile background. Generated nine-slice pixel frames separate the inventory from a dressing room. Inventory rows show the same pixel accessory artwork as the cat, left-aligned names, and right-aligned prices or ownership states. A top-right coin wallet reuses the completion-reward coin texture. The animated campaign cat stands over a small rug, with live **HEAD / FACE / NECK** slot icons and labels below it; the previewed slot is highlighted in gold. After purchase or removal, the cat and slot indicators show the saved outfit. The footer keeps World Map, Remove All, the primary action, save/error status, and keyboard/controller hints in consistent positions. Text stays in the existing readable font, with no scanline effects or new animation settings. These visual styles apply only to the shop; the campaign chooser and world map keep their existing styling.

Coins, owned accessories, and equipment are separate for Elementary, Middle, and High. Cosmetics appear on campaign selection, the world map, gameplay (including pause and boss reactions), and completion/failure results. They never change lives, timers, difficulty, progression, or rewards. Settings cat colors remain free and combine with accessories; Retro and Blitz cats do not wear Adventure equipment.

`adventure_catalog.gd` defines accessory IDs, names, prices, and slots. Each campaign saves `owned_accessories` (an array of catalog IDs) and `equipped_accessories` (a dictionary from slot to owned ID, e.g. `{"head": "crown", "neck": "bandana"}`). Legacy single-item `equipped_accessory` saves migrate into the appropriate slot without changing ownership or coins; pre-shop saves start with an empty outfit. Loading filters unknown/duplicate IDs, wrong slots, and unowned equipment. `ProfileManager.buy_adventure_accessory` validates funds and ownership; `equip_adventure_accessory` validates ownership and accepts `wear = false` to remove just that item. An empty item clears all slots. Both return an explicit error on rejection or save failure. Failed saves roll back the full transaction, preserving other slots and preventing double charges on retry.

The hub reuses its mouse, keyboard, D-pad, and stick navigation; Escape/B returns to the world map. Insufficient funds and save failures appear in the shop status line. Accessories use original procedural pixel art in `scripts/character/cat_accessory.gd`, attached by `MathCat.set_accessories` and synchronized with the existing sprite poses. Its icon mode reuses that artwork in inventory rows and equipment slots at integer pixel scales. `PixelMeterIcon.coin_texture()` supplies the same coin art to the wallet and completion animation.

## 13. Shared Save Schema

Storage remains `user://math_cat_profile.json`. Settings, records, lifetime totals, achievements, and Adventure are one profile. Example extension:

```json
{
  "adventure": {
    "elementary": {
      "highest_unlocked_level": 2,
      "completed_levels": [1],
      "campaign_completed": false,
      "level_results": {"1": {"best_score": 100, "best_lives": 9, "clears": 1}},
      "currency": 25,
      "owned_accessories": [],
      "equipped_accessories": {},
      "correct_answers": 10,
      "best_streak": 10
    }
  }
}
```

Middle and High use independent entries with the same schema. Old profiles gain defaults without removing other categories. Invalid Adventure types fall back safely; counters are clamped nonnegative; completed levels are normalized to a valid contiguous prefix; unlock and campaign-complete status are derived from that prefix. Numeric JSON levels normalize back to integers.

Saving writes and flushes a temporary file, rotates the previous profile to `.bak`, then renames the temporary file into place. The loader tries the backup after invalid primary JSON. Per-question totals, clears, rewards, and settings save immediately. Failed writes retain in-memory progress and expose an error; completion/map exit retries persistence. No application can guarantee saving with inaccessible storage or forced process termination. This is a local profile, not cloud synchronization or an anti-cheat format.

## 14. Named Stage Backgrounds

Stages 1-8 use [scripts/adventure/adventure_stage_background.gd](../scripts/adventure/adventure_stage_background.gd). Their eight locations share Rooftop Rescue and the world map's midnight sky, pixel architecture, striped sunset, and perspective-grid styling, but have distinct landmark geometry tied to the map names rather than the question grade. Elementary, Middle, and High visit the same eight locations.

| Stage | Shared visual landmark | Map/scenery accent |
| --- | --- | --- |
| 1 - Garden Blocks | City gardens and planted blocks | Cyan `#59F7FF` |
| 2 - Canal Market | Waterfront market and canal | Sky blue `#64DFFF` |
| 3 - Tram Quarter | Tram and urban rail details | Periwinkle `#83BCFF` |
| 4 - Library Square | Library architecture and plaza | Mint `#7FFFD4` |
| 5 - Harbor Lights | Harbor structures and waterside lights | Lemon `#EFFF7F` |
| 6 - Clockwork District | Clock-tower district | Gold `#FFD76A` |
| 7 - Sky Gardens | Elevated planted terraces | Pink `#FF9CDA` |
| 8 - Crystal Avenue | Faceted crystal architecture | Coral `#FFB3A3` |

The catalog's `highlight_color` is the single source for both map rectangle borders and scenery accents. Landmarks frame the question and answer area rather than replacing the existing UI. The background Control ignores mouse input and scales with the gameplay viewport. **Animated Background** freezes/resumes its local animation clock without removing the art. Level changes and restarts refresh the location; switching to bosses, Retro, or Blitz hides and stops the stage scenery and restores the existing background.

The striped sun rises in equal steps across stages 1-8, beginning low near the horizon at design-space `(1120, 416)` and ending at the world map's `(1120, 225)`. Stage 8 and the map share the catalog's `WORLD_MAP_SUN_CENTER`; intermediate stages interpolate their height. Height depends on stage number, not elapsed time or question grade, so replays, restarts, and the Animated Background preference preserve it across all campaigns. Both use [scripts/adventure/adventure_sun.gd](../scripts/adventure/adventure_sun.gd): the map's original **196-pixel diameter**, peach-to-pink gradient, and two-pixel stripe detail at the 1280x720 design resolution. During stages 1-8, sun colors are **30% darker** (RGB multiplied by 0.7, with opacity unchanged) so the sun does not compete with the cat; the world map and campaign picker keep their original brightness. The stage sun is drawn independently of the scenery's 320x180 pixel grid, retaining the map's fine detail rather than enlarged four-pixel steps. Skyline and landmarks still draw in front of it. Normal-stage questions have a dark outline to retain contrast when long text reaches the sun; bosses and other modes keep their original text styling.

Every boss continues to use [shaders/synthwave_background.gdshader](../shaders/synthwave_background.gdshader) with Grade 12's original palette, grid color, and shooting-star parameters, without Grade 13's equation overlays. Promotion, demotion, restart, and re-enabling Animated Background retain that presentation without changing the question grade or campaign cat. Bosses and non-Adventure modes retain their existing Animated Background behavior. The catalog's legacy `background` IDs and [scripts/adventure/adventure_city.gd](../scripts/adventure/adventure_city.gd) are retained but do not drive gameplay visuals.

The gameplay location banner is removed. Its label is retained solely for `SAVE PENDING: CHECK STORAGE` when persistence fails; successful saves hide it again. Map names and level configuration are unchanged.

## 15. Character, Audio, Controls, and Options

Existing MathCat SpriteFrames and frame rates are unchanged. Campaigns select Kitten, Big Cat, or Tiger and preserve that form through boss promotion, demotion, restart, and victory. Cat Color applies from the shared profile.

Levels 1-8 use their campaign's configured existing music track. Bosses use Grade 13's `nerdcat_theme`, including its existing playback loop. Adventure guards keep that music fixed through boss promotion and demotion. Background and music selection never select Professor Wiskers: the campaign cat remains Kitten, Big Cat, or Tiger. Existing correct/wrong/promotion/confirmation SFX, pause/resume, and Master/Music/SFX settings are reused. No new volume controls are needed.

On boss victory, `AudioManager.play_music(MUSIC_VICTORY_THEME)` replaces the gameplay track. The existing audio manager sets this Ogg stream's loop flag to false, and its custom Grade 12/13 loop rules do not apply. The track plays once and remains stopped at the end; save retries and duplicate completion events do not replay it. Leaving the victory screen stops playback if it has not finished.

The shared answer diamond retains keyboard arrows/Enter, direct Xbox face buttons, and the saved controller-navigation option. The existing Pause menu supplies Resume, Restart, Options, and World Map. Results support keyboard/controller and mouse. A visible save notice prevents silent failure when leaving an attempt.

## 16. Statistics and Achievements

Adventure persists accepted correct answers in the existing per-grade lifetime buckets once per answer and tracks campaign totals/best streak. Resolved-question active time adds to lifetime time played, excluding pause. It does not count unfinished question time or reward/menu time.

Hot Streak, That Was Fast, Pi Day, and lifetime thresholds remain eligible. The lifetime evaluator does not add the already-persisted current session twice. Math Kitten, Math Cat, Math Tiger, Victory, and Perfect Game remain Retro-only. Adventure cannot reach playable Grade 13, so it cannot earn a Grade 13 question streak. Retro high score, highest grade, run record, game count, and victory count are not overwritten. Blitz behavior remains unchanged, including its previously requested entry achievement.

## 17. Exact File Changes

New Adventure runtime files:

- [scripts/adventure/adventure_catalog.gd](../scripts/adventure/adventure_catalog.gd)
- [scripts/adventure/adventure_city.gd](../scripts/adventure/adventure_city.gd): retained prototype, no longer instantiated after the grade-matched grid update.
- [scripts/adventure/adventure_stage_background.gd](../scripts/adventure/adventure_stage_background.gd): eight shared pixel-art landmarks using the map-border accents.
- [scripts/adventure/adventure_sun.gd](../scripts/adventure/adventure_sun.gd): shared full-resolution sun drawing for the map and normal stages.
- [scripts/adventure/adventure_gameplay.gd](../scripts/adventure/adventure_gameplay.gd)
- [scenes/adventure/adventure_hub.gd](../scenes/adventure/adventure_hub.gd)
- [scenes/adventure/adventure_hub.tscn](../scenes/adventure/adventure_hub.tscn)

Modified shared runtime files:

- [autoload/game_manager.gd](../autoload/game_manager.gd): Adventure states, tokens, timer, lives, completion, restart.
- [autoload/progression_manager.gd](../autoload/progression_manager.gd): reusable grade floor.
- [autoload/profile_manager.gd](../autoload/profile_manager.gd): save extension, validation, atomic save/backup, Adventure totals/results.
- [autoload/achievement_manager.gd](../autoload/achievement_manager.gd): prevent double counting persisted Adventure totals.
- [autoload/audio_manager.gd](../autoload/audio_manager.gd): campaign music selection and progression guards.
- [scenes/game/game.gd](../scenes/game/game.gd): attach controller and route Adventure-specific hooks.
- [scenes/title/title.gd](../scenes/title/title.gd) and [scenes/title/title.tscn](../scenes/title/title.tscn): Adventure entry and menu order.
- [scripts/character/character_evolution_manager.gd](../scripts/character/character_evolution_manager.gd): preserve campaign forms.
- [scripts/background/background_evolution_manager.gd](../scripts/background/background_evolution_manager.gd): share grade palettes and pin Adventure boss presentation to Grade 12.

Tests and documentation:

- New [tests/adventure_system_smoke_test.gd](../tests/adventure_system_smoke_test.gd) and [tests/adventure_system_smoke_test.tscn](../tests/adventure_system_smoke_test.tscn).
- New [tests/adventure_ui_smoke_test.gd](../tests/adventure_ui_smoke_test.gd) and [tests/adventure_ui_smoke_test.tscn](../tests/adventure_ui_smoke_test.tscn).
- New [tests/adventure_background_smoke_test.gd](../tests/adventure_background_smoke_test.gd) and [tests/adventure_background_smoke_test.tscn](../tests/adventure_background_smoke_test.tscn): all 24 stage configurations, exact map accents, freeze/resume, restart, direct boss entry, boss preservation, and mode switching; rendered captures additionally compare scenery-only regions for distinct artwork.
- [tests/title_pause_ui_smoke_test.gd](../tests/title_pause_ui_smoke_test.gd): menu order; corrected music-volume assertion to include the existing baseline gain.
- [tests/blitz_duel_session_smoke_test.gd](../tests/blitz_duel_session_smoke_test.gd): permit only the previously requested Blitz-entry achievement in profile isolation, matching the solo test.
- [README.md](../README.md) and this document.

Other dirty Blitz feedback/menu/achievement files predate Adventure and are preserved. No engine settings, input mappings, asset frame rates, dependencies, or autoload registrations were changed for Adventure.

## 18. Verification and Remaining Risks

Verified with Godot 4.7.1 on Windows, isolated test profiles, and the Dummy audio driver:

The named-background update was checked with Godot 4.7.2 at 1280x720 and 960x540: the focused background suite reported zero failures and exited successfully, covering all 24 normal-stage configurations, distinct rendered scenery, exact map accents, animation settings, restart, boss preservation, and Retro/Blitz switching. A separate rubber-duck visual review inspected all eight scenes against the map and Rooftop Rescue captures; follow-up captures confirmed improved lighthouse/cat clearance and clearer crystal facets across all campaign cats. The Retro background-evolution suite passed. The full Adventure UI suite reported zero failures but stalled during native shutdown and was stopped; that existing shutdown issue is not claimed fixed. Focused runs also reported the existing resource-in-use shutdown warnings.

The replay/HUD update passed the Adventure system suite and rendered 1280x720 Adventure UI suite with zero failures. Coverage includes normal and boss replay payouts in all three campaigns, persisted currency, duplicate-completion/save-retry guards, replay coin animation, hidden location labels, retained save warnings, and `FINAL BOSS` text fitting the header at the Grade/LIVES font size. Representative gameplay and replay-reward screenshots were inspected.

The boss update passed the Adventure system suite and rendered 1280x720 UI suite with zero failures and a clean exit. Coverage includes all 24 normal-level palettes; all three Grade 12 boss backgrounds; the 120-second session countdown, pause, time bonuses, promotion/demotion holds, time-up failure and restart; green Level Up feedback and uninterrupted campaign-cat animation; dedicated victory results, save retry, and actual non-looping victory playback through the end of the stream. The subsequent reveal/text update passed the rendered Adventure UI rerun at 60 FPS and Retro Game Over UI suite: final answers and moving evolutions remain visible for one second, victory headings are green, premature input is ignored, and restart cancels pending reveals. Captures cover the clock, level-up, final-answer celebration, time-up, and payment-ready victory screens. Existing GameManager, character, full background transition, Game Over UI, Grade 12/13 music, and solo/duel Blitz session regressions also passed during the boss implementation. The table includes previously verified Adventure integration coverage as well.

| Suite | Final result |
| --- | --- |
| Adventure system | 0 failures: all 27 configs, campaigns, target completion, timeout race, pause, lives, real boss promotion/demotion, victory boundaries, replay, migration, save failure/backup, exact lifetime thresholds and Retro isolation |
| Adventure UI | 0 failures, clean standalone rerun: map focus/lockouts, keyboard and injected joystick events, readiness, timed/untimed UI, feedback/pause, options/cat color, all three bosses, rewards/save retry, real title-to-map-to-level-to-payment navigation, ten-question default target, incomplete exit |
| GameManager / AchievementManager | Passed |
| CharacterEvolutionManager / BackgroundEvolutionManager | Passed, including complete long background transition sequence |
| Game Over UI / Title and Pause UI | Passed |
| Grade 12 and Grade 13 music loop | Passed |
| Blitz session / UI / leaderboard | Passed |
| Blitz duel session / input / UI | Passed |
| Script diagnostics / `git diff --check` | No reported new errors / passed |

Rendered captures were generated at 1280x720 and 960x540. Campaign selection, title, maps, timed levels, bosses, payment, and failure screens were captured; representative captures were visually inspected for nonblank assets, readable text, and overlap. These are native Windows game windows, not mobile-browser coverage. Physical-controller feel and audible hardware playback remain manual checks; automated tests inject controller events and verify audio selection/settings.

Some existing suites report ObjectDB/resource-in-use warnings at shutdown. Earlier hardware-audio headless runs stalled after passing assertions and were terminated. One later Dummy-driver UI run returned native Windows code `0xC0000005` after printing zero failures; the standalone rerun exited cleanly. A headless boss UI run also stalled after reporting results; rendered reruns exited cleanly. This intermittent native shutdown issue is not claimed fixed. Audio end-of-stream tests use a bounded wall-clock deadline because simulated SceneTreeTimer time can run ahead of the audio thread. Intentional leaderboard save-failure tests also emit expected warnings.

Run a focused suite from the project folder (set `$godot` to the installed console executable):

```powershell
$originalAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $env:TEMP 'MathCat-Adventure-Tests'
    & $godot --headless --audio-driver Dummy --path . tests/adventure_system_smoke_test.tscn
    & $godot --headless --audio-driver Dummy --path . tests/adventure_ui_smoke_test.tscn
} finally {
    $env:APPDATA = $originalAppData
}
```

For captures, omit `--headless` and append `-- --capture` to the UI command. Images are saved under that isolated Godot user-data directory. Let tests terminate themselves: a low `--quit-after` frame limit can stop long animation tests before their final assertions. Check output for script errors and verify exit status; an assertion message alone does not guarantee Godot returns nonzero.

For map-only changes, append `-- --map-only` (or `-- --map-only --capture` in a rendered run). This runs campaign selection, all three maps, unlock/focus/controller checks, background freeze/resume, scaled hit targets, and the fully completed boss map without the gameplay suite.

For stage artwork, run `tests\adventure_background_smoke_test.tscn` with an isolated `APPDATA` and `--audio-driver Dummy`. Add `-- --capture` in a rendered run to save all eight gameplay backgrounds, the world map, representative Middle/High stages, and the unchanged boss. The same scene supports `--headless` without capture for behavioral checks.