# 2. Technical Architecture (Godot 4)

## Engine & Project Settings
- **Engine:** Godot 4.7.1, **GDScript**. The project was opened and converted with Godot 4.7.1; use this version for development and exports to avoid conversion churn during the jam.
- **Display:** Project Settings → Display → Window
  - Viewport Width/Height: `1280 x 720`
  - Stretch Mode: `viewport` or `canvas_items` — either works since we're not downscaling; `canvas_items` is simplest and safest for UI-heavy scenes.
  - Stretch Aspect: `keep`
- **Texture import default:** Filter = **Off**, Mipmaps = **Off** (Project Settings → Import Defaults, or per-texture `.import` override) so pixel art stays crisp at 1280×720.
- **Rendering:** Forward+ or Mobile renderer both fine (2D only); Mobile is lighter if laptop GPU is a concern during dev.
- Input Map actions (configured at startup): `answer_1..4`, `ui_accept`, `ui_cancel`, `ui_up`, `ui_down`, and `pause`. Bind `A`, `B`, `X`, and `Y` to their matching answer actions and Xbox face buttons. During gameplay, arrow keys highlight the spatially matching answer (`Up` = Y, `Left` = X, `Right` = B, `Down` = A) and `Enter` submits it. Menus use Enter or Xbox A to confirm, Up/Down Arrow or the D-pad to navigate, and Esc/Start to pause or resume.

## Autoload Singletons
| Autoload | Responsibility |
|---|---|
| `GameManager` | Top-level state machine (TITLE, PLAYING, LEVEL_UP, DEMOTION, PAUSED, GAME_OVER); owns score, timer, lives, current session data; ends the session when the timer hits 0 or lives hit 0; emits high-level signals; handles scene transitions. |
| `ProgressionManager` | Grade-counter/demotion logic only (pure logic, no UI). Exposes `register_answer(is_correct: bool)`, tracks `current_grade`, `correct_count`, `incorrect_count`. Emits `promoted(old_grade, new_grade)`, `demoted(old_grade, new_grade)` — demotion is always a flat 1-grade drop. |
| `QuestionBank` | Loads/holds question generators per grade; `get_question(grade: int) -> QuestionData`; handles distractor shuffling/dedup. |
| `AudioManager` | Synthesizes five core chip cues through a five-player SFX pool and plays loopable OGG music through one Music-bus player. Grades 1-4/5-8/9-12/13+ use Math Kitten/Math Cat/Math Tiger/Nerd Cat themes; title music is disabled for now. |
| `SaveManager` | Reads/writes `user://mathcat_save.json` (high scores + settings); safe defaults on missing/corrupt file. |

Keep `ProgressionManager` and `QuestionBank` UI-agnostic so the grade algorithm can be unit-tested from a throwaway script.

## Core Signals (suggested contract)
### Blitz implementation

`GameManager.SessionMode.BLITZ` extends the existing manager rather than introducing a second game loop. Startup enters `BLITZ_READY`; the game scene loads and fits the first question, then arms a 120,000 ms deadline using a monotonic clock. `GameManager.BLITZ_TIME_MSEC` also supplies setup and result duration labels. A session serial rejects readiness and delayed feedback callbacks from an earlier run.

During Blitz, both PLAYING and PAUSED synchronize against the deadline. Answer submission and menu resume synchronize too, preventing late input from slipping through before the next frame. Time-up records a copied result snapshot exactly once; only that pending result can be submitted, skipped, or discarded on restart/quit. Standard-only progression and high-score paths use explicit mode checks.

`BlitzLeaderboard` is an additional autoload responsible for validated, versioned local per-grade boards. It uses separate storage from `ProfileManager` and exposes ranking, submission, and copied board reads. Save failures produce a warning and a `storage_failed` signal, and remain visible in the UI.

The existing game scene reuses its question bank and answer controls but bypasses delayed feedback for Blitz. Shared UI scripts in `scripts/ui/blitz_*` provide results, keyboard/controller initials entry, and a board view reused by the title menu. Initials handling precedes gameplay and retry shortcuts.

Smoke scenes: `tests/blitz_session_smoke_test.tscn`, `tests/blitz_leaderboard_smoke_test.tscn`, and `tests/blitz_ui_smoke_test.tscn`. Run with Godot 4.7.x, `--headless --audio-driver Dummy --path .`, and isolated APPDATA so tests never modify the player's profile. The UI test accepts `-- --real-time` to exercise a real two-minute round, and `-- --capture` for rendered menu, gameplay, and results screenshots (omit `--headless` for capture). Pure session tests disconnect audio callbacks to isolate bulk, single-frame rule checks; UI tests retain the real audio connections.

### Optional two-player Blitz

`start_blitz_session(grade, players = 1)` retains the solo default and the existing BLITZ state/timer. `blitz_duel_round.gd` owns player totals, per-question attempts, correct-choice index, readiness, and closure. GameManager validates the session/question identity and synchronizes the deadline before calling the player-aware submission API. Score updates and question closure are committed before emitting `duel_answered`, so reentrant or queued input cannot award two correct points.

The game scene reuses the solo question label, answer buttons, and control diamond for two-player play. Two instances of `blitz_duel_panel.gd` supply the left/right cats, scores, and feedback only. The shared equation fits between them; answers retain the solo positions and dimensions. Replacement questions load outside the resolving input callback and become answerable only after a presentation-frame boundary. The solo cat and global score are hidden only in two-player mode, with solo question sizing, input, and HUD properties restored for other modes.

Both modes use the same full-width background grid. Each game instance duplicates its background material to prevent setting changes leaking across instances. `blitz_cat_palette.gdshader` replaces only the three existing fur shades for separate orange/blue cats, preserving outlines, eyes, cream markings, and stage-specific accessories. Solo appearance preferences and materials remain unchanged.

Two-player text fitting measures wrapped text against fixed tile bounds, then restores original centers so long strings cannot enlarge or move the answer diamond. Shared buttons remain visually enabled but reject GUI/mouse input and focus; only player-attributed input submits answers. UI coverage verifies exact dimensions/centers, long text, per-cat feedback, unchanged shared answer styling during lockout, and restoration of solo controls.

`blitz_duel_input.gd` separates physical WASD/arrows and assigned controller device IDs from global GUI actions. Face buttons and D-pad directions map to the same four answers, with fresh-press tracking across questions and shared menus. Switching input sets does not bypass per-player lockout or device ownership. Gameplay glyphs remain Y/X/B/A in every two-player control configuration. GameManager owns assignments across scenes/retries; input connection changes vacate disconnected slots without stealing occupied slots. Setup/recovery consumes a joining A press before gameplay or GUI confirmation. Global controller menu actions use device `-1`, allowing all controllers to navigate; only assigned devices answer during controller gameplay.

`BlitzLeaderboard` and `BlitzDuelLeaderboard` are thin autoload wrappers over the same validated `blitz_leaderboard_store.gd`, with independent paths, errors, and in-memory boards. Results/board views select the appropriate store explicitly. GameManager enforces winner-only positive submission for two-player results; the store enforces per-grade top-10 eligibility.

Additional smoke scenes are `tests\blitz_duel_session_smoke_test.tscn`, `tests\blitz_duel_input_smoke_test.tscn`, and `tests\blitz_duel_ui_smoke_test.tscn`. The duel UI test accepts `-- --real-time` and `-- --capture`; its bulk scenarios disconnect answer/session audio callbacks. The leaderboard test accepts `-- --duel`, combinable with `--persistence-write` or `--persistence-read`, to exercise the second store in separate processes. Run against isolated APPDATA. Check output for script/assertion errors as well as the process exit code: Godot assertions can stop a test function without returning a failing process exit code.

Input automation covers nonsequential device IDs, duplicate joins, all-controller loss, replacement IDs, and controller-only initials/save retry. Physical two-controller hot-plug and keyboard rollover still require hardware checks.

### Existing signals

```
ProgressionManager.answer_registered(is_correct: bool, correct_count: int, incorrect_count: int)
ProgressionManager.promoted(old_grade: int, new_grade: int)
ProgressionManager.demoted(old_grade: int, new_grade: int)
GameManager.state_changed(old_state: int, new_state: int)
GameManager.session_started()
GameManager.lives_changed(new_lives: int)
GameManager.session_ended(final_score: int, final_grade: int, reason: String)
GameManager.timer_tick(seconds_left: int)
QuestionBank.question_ready(question: QuestionData)
```

## State Machine (GameManager)
```
TITLE -> PLAYING -> (LEVEL_UP | DEMOTION -> back to PLAYING) -> GAME_OVER -> TITLE
PLAYING <-> PAUSED (any time except during Level-Up/Demotion popup transitions)
```
`GAME_OVER` is reached from `PLAYING` when **either** `time_left` hits 0 **or** `lives` hits 0 — whichever happens first (the triggering `reason` is passed along in `session_ended`).
Implement as an enum + `match` statement in `_process`/input handlers, or a tiny hand-rolled state machine class. Full finite-state-machine frameworks are overkill for a 2-day jam — keep it simple.

## Synthwave Background
- `Background` is a full-rect `ColorRect` at the back of `game.tscn`, using `shaders/synthwave_background.gdshader` through one `ShaderMaterial`.
- The shader uses `TIME` for a low-speed procedural perspective grid, horizon glow, and optional star/symbol effects. Its horizontal grid phase moves toward the horizon at the original speed. It has no texture dependencies and no per-frame GDScript work.
- Scene-local `BackgroundEvolutionManager` listens to `ProgressionManager.promoted` and `demoted`, then maps grades to a background-only visual scale and updates the shader's continuous `stage` uniform: `0` Early (Grades 1–2), `1` Kitten (3–4), `2` Big Cat (5–8), `3` Tiger (9–12), `4` Nerd Cat (13+). Every visual-stage promotion or demotion, including Grade 2↔3, uses a 4.8-second sine-eased fade. Cat evolution remains independently controlled by `CharacterEvolutionManager`.
- The same manager updates `shooting_star_intensity` on every grade change, including changes within a visual stage: `0.0` before Grade 7, `0.35` for Grades 7–8, `0.65` for Grades 9–12, and `1.0` for Grade 13+. The shader uses this value as a spawn probability across six deterministic lanes, with pixel-quantized diagonal streaks, varied cycle times and trail lengths, and no spawned nodes or allocations.
- Stage effects remain intentionally restrained behind the gameplay controls: a black field with violet grid (Early), a faint purple horizon glow and sparse stars (Kitten), purple sky with denser blue stars and orange grid (Big Cat), magenta/gold horizon (Tiger), then sparse drifting arithmetic marks and twinkles (Nerd Cat). Shooting stars are clipped above the horizon and drawn as part of the backmost `ColorRect`, while a depth fade reduces every grid's line strength near the horizon.

## Folder Structure
```
res://
  autoload/
    game_manager.gd
    progression_manager.gd
    question_bank.gd
    audio_manager.gd
    save_manager.gd
  audio/
    default_bus_layout.tres
    music/
      placeholder_tracks.txt
      kitten_theme.ogg
      bigcat_theme.ogg
      tiger_theme.ogg
      satcat_theme.ogg
      final_level_theme.ogg
      nerdcat_theme.ogg
      victory_theme.ogg
  scenes/
    title/title.tscn
    game/game.tscn
    game/hud.tscn
    game/level_up_popup.tscn
    game/demotion_popup.tscn
    game/pause_menu.tscn
    game_over/game_over.tscn
    cat/cat.tscn
    ui/answer_button.tscn
  scripts/
    background/
      background_evolution_manager.gd
    question_data.gd          (Resource/class_name)
    generators/
      base_generator.gd
      addition_generator.gd
      subtraction_generator.gd
      multiplication_generator.gd
      multi_digit_add_sub_generator.gd
      multi_digit_multiplication_generator.gd
      long_division_generator.gd
      fraction_like_denominator_generator.gd
      decimal_generator.gd
      basic_geometry_generator.gd
  data/
    questions/                (curated JSON banks for geometry/word problems)
  assets/
    sprites/
    fonts/
    audio/sfx/
    audio/music/
  shaders/
    synthwave_background.gdshader
  main.tscn                    (bootstrap scene, loads Title)
```

## Scene Transitions
Use `GameManager.goto_scene(path: String)` wrapping `get_tree().change_scene_to_file()`. Avoid `queue_free`-ing autoloads; only swap the current scene root. Keep Level-Up/Demotion popups as child overlays of `game.tscn` (not full scene changes) so gameplay state isn't lost mid-session.

## Pixel-Perfect Rendering (Optional Stretch Polish)
Not needed for MVP. If time remains: render gameplay into a `SubViewport` at a low native resolution (e.g., 320×180), display via `SubViewportContainer` with `stretch_shrink` disabled and nearest filtering, scaled ×4 to fill 1280×720. This guarantees perfect pixel scaling but adds complexity (UI must live in the sub-viewport too, or be composited separately) — treat as Could-have, not Must-have.

## Data-Driven Questions
- **Procedural generators** (Grades 1–3, and most of Grade 4) compute a question + correct answer + 3 distractors at runtime — infinite variety, zero authoring time.
- **Curated JSON banks** (Grade 4 basic geometry, and any word-problem-style content) for content that's easier to hand-write than generate. Loaded into `QuestionData` at runtime via `QuestionBank`.
- See doc 4 for the exact `QuestionData` shape and generator contract.

## Persistence
- `user://mathcat_save.json`: `{ "high_scores": [{score, grade, date}], "settings": {sfx_volume, music_volume} }`
- Wrap load in try/`FileAccess` null-checks; fall back to empty defaults if missing or malformed — never crash on a bad save file.
