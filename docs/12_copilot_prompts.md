# 12. Copilot Prompts — Godot Code Generation

Paste these into Copilot Chat (or inline) one at a time, in roughly this order, working in a Godot 4 / GDScript project. Each prompt references the design decisions locked in docs 1–5 so the generated code matches the plan. Adjust file paths if your project structure differs from doc 2.

---

### 1. Project bootstrap & Input Map
```
Set up a Godot 4 GDScript autoload skeleton for a 2D game called "Math Cat".
Create empty autoload scripts (just class declarations + placeholder signals for now,
no logic yet) at:
- res://autoload/game_manager.gd
- res://autoload/progression_manager.gd
- res://autoload/question_bank.gd
- res://autoload/audio_manager.gd
- res://autoload/save_manager.gd
GameManager should define an enum GameState { TITLE, PLAYING, LEVEL_UP, DEMOTION, PAUSED, GAME_OVER }
and a signal state_changed(old_state: int, new_state: int).
Also list the exact Project Settings > Input Map actions I need to add manually
(answer_1..answer_4, ui_confirm, ui_cancel, ui_up/down/left/right, pause) with
these keyboard AND Xbox controller joypad bindings: A + Xbox A for answer_1, B + Xbox B
for answer_2, X + Xbox X for answer_3, and Y + Xbox Y for answer_4. During gameplay,
arrow keys highlight the spatial answer (Up = Y, Left = X, Right = B, Down = A) and Enter
submits that highlighted answer.
```

### 2. ProgressionManager (grade algorithm)
```
Implement res://autoload/progression_manager.gd as a Godot 4 GDScript autoload singleton
implementing this exact grade progression algorithm:

- current_grade starts at 1, MIN_GRADE = 1, MAX_GRADE = 13
- PROMOTE_THRESHOLD = 5 correct answers accumulated in the current grade
- DEMOTE_THRESHOLD = 3 incorrect answers accumulated in the current grade
- On reaching PROMOTE_THRESHOLD: current_grade += 1 (clamped to MAX_GRADE), reset correct_count
  and incorrect_count to 0, emit signal promoted(old_grade: int, new_grade: int)
- On reaching DEMOTE_THRESHOLD: current_grade -= 1 (clamped to MIN_GRADE) — a flat, non-escalating
  1-grade drop every time, reset correct_count and incorrect_count to 0, emit signal
  demoted(old_grade: int, new_grade: int)
- Public method: register_answer(is_correct: bool) -> void that runs this logic
- Expose read-only getters for current_grade, correct_count, incorrect_count

Add clear one-line comments only where the "why" isn't obvious from the code
(e.g., why incorrect_count resets on promotion).
```

### 3. Question data model + base generator
```
Create res://scripts/question_data.gd as a Godot 4 GDScript class_name QuestionData
(extends RefCounted) with fields: id: String, grade: int, topic: String,
question_text: String, correct_answer: String, choices: Array[String], source: String.

Then create res://scripts/generators/base_generator.gd as class_name BaseQuestionGenerator
(extends RefCounted) with a virtual method generate() -> QuestionData that pushes an error
if not overridden, plus a protected/static helper function build_choices(correct: String,
distractors: Array[String]) -> Array[String] that deduplicates, ensures exactly 4 unique
entries (falling back to numeric offset distractors if needed after 10 failed attempts),
and shuffles the result.
```

### 4. Grade-specific generators
```
Using res://scripts/generators/base_generator.gd (BaseQuestionGenerator) as the parent class,
implement these GDScript generator subclasses, each overriding generate() -> QuestionData.
Use QuestionData from res://scripts/question_data.gd. Format question_text as a clean equation like "7 + 8 =", with an equals sign but no question mark, trailing punctuation, or explanatory text.
For each, generate plausible "common mistake" distractors, not just random offsets, then
fall back to build_choices()'s safety net:

1. res://scripts/generators/addition_generator.gd — grade 1, two operands from 1–10, producing
  a shuffled deck of 200 unique prompt-and-choice sets from 100 ordered prompts with two
  distractor variants each. Each answer set has one correct answer and three unique distractors
  within 3 of it; make the correct result lowest in 25% of sets, highest in 25%, and in the middle in 50%.
2. res://scripts/generators/subtraction_generator.gd — grade 2, a shuffled 200-set deck from
  100 non-negative subtraction prompts with minuends 1–20; prioritize single-digit pairs.
  Use close shuffled distractors, with the correct answer lowest in 25%, highest in 25%, and middle in 50%.
3. res://scripts/generators/multiplication_generator.gd — grade 3, a shuffled 220-set deck from
  110 ordered multiplication prompts with operands 0–10 and two variants each, displayed with `×`. Choices must never
  be negative. Use close shuffled distractors, except a zero-product second variant may use `4` to
  stay distinct; make the correct answer lowest in 25%, highest in 25%, and middle in 50%.
4. res://scripts/generators/long_division_generator.gd — grade 4, a shuffled 200-set deck from
  100 exact-division prompts with divisors 1–10 and answers 0–9, displayed with `÷`. Use close shuffled distractors,
  with the correct answer lowest in 25%, highest in 25%, and middle in 50%.
5. res://scripts/generators/grade_five_generator.gd — grade 5, a shuffled 200-set deck with
  50 two-digit addition/subtraction questions (negative subtraction results allowed), 50 two-digit
  `×` one-digit multiplication questions, 50 like-denominator fraction-addition questions, and 50
  decimal addition/subtraction questions with operands below 100. Generate four unique shuffled choices
  for every question; answer ranks must be exactly 25% lowest, 25% highest, and 50% middle across the deck.

Then create res://autoload/question_bank.gd implementing this autoload singleton:
it should hold a Dictionary mapping grade(int) -> Array of generator instances
(only include the generators valid for that grade per this table: grade 1 = addition,
grade 2 = subtraction, grade 3 = multiplication, grade 4 = division, grade 5 = mixed Grade 5 deck;
defer basic geometry until the current decks are play-tested),
and a method get_question(grade: int) -> QuestionData that picks a random generator
valid for that grade and calls generate() on it.
```

### 5. Curated JSON question bank (Grade 4 geometry)
```
Add a curated JSON question bank loader to res://autoload/question_bank.gd (or a small
helper script it uses). Load res://data/questions/grade4_geometry.json at startup
(_ready()), where each entry has shape: { "id": String, "grade": int, "topic": String,
"question_text": String, "correct_answer": String, "distractors": Array[String] (length 3) }.
Parse with JSON.parse_string(), handle malformed/missing file gracefully (log a warning,
continue with an empty list), and convert each entry into a QuestionData object
(shuffling distractors + correct_answer into the choices array). Register grade 4's
"basic_geometry" topic so get_question(4) can also return one of these curated questions
alongside the procedural grade-4 generators (weight it evenly with the other grade 4
generators). Also generate 8 sample entries of grade4_geometry.json content for rectangle/
square perimeter and area questions with small integer side lengths (2-12), and write
them to that JSON file.
```

### 6. GameManager state machine + session timer
```
Implement res://autoload/game_manager.gd (Godot 4 GDScript autoload) as a state machine
with GameState enum { TITLE, PLAYING, LEVEL_UP, DEMOTION, PAUSED, GAME_OVER }.
Requirements:
- var current_state: GameState = GameState.TITLE, with a set_state(new_state) method that
  emits state_changed(old_state, new_state) and handles any state-entry side effects.
- const SESSION_TIME_SEC = 120. A time_left: float that only counts down while
  current_state == PLAYING (paused during LEVEL_UP, DEMOTION, PAUSED states).
  Emit signal timer_tick(seconds_left: int) once per second of change.
- const START_LIVES = 9. A var lives: int with signal lives_changed(new_lives: int).
  A method lose_life() -> void that decrements lives by 1, emits lives_changed, and
  ends the session (see below) if lives reaches 0.
- When time_left reaches 0 OR lives reaches 0 (whichever happens first), call
  set_state(GameState.GAME_OVER) and emit signal
  session_ended(final_score: int, final_grade: int, reason: String) where reason is
  "time_up" or "out_of_lives" depending on which condition triggered it.
- var score: int = 0 with a method add_score(points: int).
- A method start_session() that resets score, time_left, and lives to START_LIVES, and calls
  ProgressionManager.reset() (assume this method exists) then set_state(PLAYING).
- A method goto_scene(path: String) that wraps get_tree().change_scene_to_file(path)
  for Title <-> Game <-> GameOver transitions only (Level-Up/Demotion/Pause stay as
  child overlays within the Game scene, not scene changes).
- Connect to ProgressionManager's promoted and demoted signals: on promoted, add
  50 bonus points via add_score() and call set_state(GameState.LEVEL_UP); on demoted,
  call set_state(GameState.DEMOTION). Assume a mechanism elsewhere returns to
  GameState.PLAYING after each popup's auto-dismiss timer.
- Wherever an incorrect answer is registered (e.g., from the Game scene calling both
  ProgressionManager.register_answer(false) and GameManager.lose_life()), make sure
  lose_life() is called exactly once per incorrect answer, independent of whether that
  answer also triggers a demotion.
```

### 7. HUD script
```
Write a Godot 4 GDScript script for a HUD Control node (res://scenes/game/hud.gd,
attached to hud.tscn) with these @onready node references (assume unique names %GradeLabel,
%ScoreLabel, %TimerLabel, %CorrectPips (HBoxContainer), %IncorrectPips (HBoxContainer),
%LivesDisplay (HBoxContainer)):
- On _ready(), connect to GameManager.timer_tick to update %TimerLabel as MM:SS format.
- Connect to GameManager score changes (assume a score_changed(new_score: int) signal
  exists on GameManager, add it there if missing) to update %ScoreLabel.
- Connect to GameManager.lives_changed(new_lives: int) to update the filled/empty state
  of 9 child heart icons in %LivesDisplay (leftmost hearts empty first as lives are lost).
- Connect to ProgressionManager signals to update %GradeLabel ("Grade 3") on promoted/demoted.
- Connect to a ProgressionManager.answer_registered(is_correct: bool, correct_count: int,
  incorrect_count: int) signal (add it if missing, emitted from register_answer) to update
  the filled/empty state of child pip icons in %CorrectPips (5 total) and %IncorrectPips
  (3 total) based on the accumulated current-grade counters.
```

### 8. AnswerButton + question panel wiring
```
Create res://scenes/ui/answer_button.gd for a reusable AnswerButton scene (root is a
Button). It should:
- Have an exported var choice_text: String that updates a child Label
- Emit signal answer_selected(button_ref: Button) when pressed (connect Button's own
  "pressed" signal internally and re-emit with self as the argument)
- Expose methods flash_correct() and flash_incorrect() that briefly tween a child
  ColorRect overlay's modulate/alpha to green or red and back to transparent using
  an AnimationPlayer or a Tween, over about 0.4 seconds

Then write res://scenes/game/game.gd (attached to the main Game scene) showing how to:
- Request a new QuestionData from QuestionBank.get_question(ProgressionManager.current_grade)
  and populate the QuestionLabel and 4 AnswerButton instances' choice_text from
  question.choices, keeping track of which button index holds question.correct_answer
- Connect to all 4 AnswerButton.answer_selected signals, on press: disable all 4 buttons,
  flash the pressed one correct/incorrect (and flash the correct one green if the player
  was wrong), call ProgressionManager.register_answer(is_correct), wait ~0.6 seconds via
  get_tree().create_timer, then load the next question (or let GameManager's state change
  to LEVEL_UP/DEMOTION intercept first if a promotion/demotion just happened)
- Handle both mouse/keyboard Button presses AND the answer_1..answer_4 Input Map actions
  triggering the same 4 buttons programmatically (e.g., button.emit_signal("pressed") or
  calling a shared _select_answer(index) function from both input paths)
```

### 9. Cat animation controller
```
Write res://scenes/cat/cat.gd for a CharacterCat scene (root Node2D with a child
AnimatedSprite2D named %Sprite that has animations named "idle", "blink", "happy", "sad").
Implement:
- func play_idle() -> void: plays "idle", loops
- func play_happy() -> void: plays "happy" once, then automatically returns to play_idle()
  when finished (connect to the AnimatedSprite2D's animation_finished signal once, or use
  await %Sprite.animation_finished)
- func play_sad() -> void: same pattern as play_happy but with "sad"
- On _ready(), connect to ProgressionManager.answer_registered-style feedback (or have
  Game.gd call play_happy()/play_sad() directly after register_answer — pick whichever
  is simpler and explain the tradeoff briefly in a comment)
```

### 10. AudioManager
```
Implement res://autoload/audio_manager.gd as a Godot 4 autoload singleton that:
- Preloads a Dictionary mapping SFX names (strings like "correct", "incorrect",
  "level_up", "demotion", "ui_confirm") to AudioStream resource paths under
  res://assets/audio/sfx/
- Maintains a pool of 6 AudioStreamPlayer child nodes created in _ready(), round-robining
  between them in func play_sfx(name: String) so overlapping sounds don't cut each other off
- Has two dedicated AudioStreamPlayer nodes for music (music_a, music_b) with
  func play_music(name: String) that stops any currently playing music track and starts
  the new one looping (set AudioStreamOggVorbis.loop = true)
- Has func set_sfx_volume(linear: float) and set_music_volume(linear: float) that convert
  to decibels (linear_to_db) and apply to the appropriate Godot audio bus
```

### 11. SaveManager (high scores)
```
Implement res://autoload/save_manager.gd as a Godot 4 autoload singleton persisting to
"user://mathcat_save.json" with this schema:
{ "high_scores": [ { "score": int, "grade": int, "date": String } ], "settings":
{ "sfx_volume": float, "music_volume": float } }
Requirements:
- func load_data() -> Dictionary: reads the file via FileAccess, parses with
  JSON.parse_string(), and returns safe defaults (empty high_scores array,
  sfx_volume/music_volume = 0.8/0.6) if the file is missing, empty, or fails to parse
  (never throw/crash)
- func save_data(data: Dictionary) -> void: overwrites the whole file with
  JSON.stringify(data, "\t")
- func add_high_score(score: int, grade: int) -> bool: loads current data, appends a new
  entry with the current date (Time.get_datetime_string_from_system()), sorts descending
  by score, trims to top 10, saves, and returns true if the new entry made the top 10
  (false otherwise) so the UI can show a "NEW HIGH SCORE!" indicator
```

### 12. Title / Pause / Level-Up / Demotion / Game Over screens
```
Write GDScript scripts for these Godot 4 Control-based scenes, keeping each focused only
on wiring UI to the autoloads already defined (GameManager, ProgressionManager,
SaveManager, AudioManager):

1. res://scenes/title/title.gd — on the green "Start Game" button pressed (or ui_confirm action),
   call GameManager.goto_scene("res://scenes/game/game.tscn") then GameManager.start_session().
   On _ready(), load SaveManager.load_data() and show the top high score in a label.

2. res://scenes/game/pause_menu.gd — root Control starts hidden. Listen for the "pause"
   input action to toggle visibility and call GameManager.set_state(PAUSED) / restore the
   previous state on resume. Wire Resume (hide + resume), Restart (call
   GameManager.start_session() again), and Quit to Title
   (GameManager.goto_scene("res://scenes/title/title.tscn")) buttons.

3. res://scenes/game/level_up_popup.gd and res://scenes/game/demotion_popup.gd — root
   Control starts hidden. Expose func show_popup(old_grade: int, new_grade: int) that sets
   label text (e.g., "Promoted to Grade %d!" or "Demoted to Grade %d"), plays the
   appropriate cat big-pose animation and AudioManager SFX, shows the popup, waits ~1.8
   seconds via get_tree().create_timer, hides the popup, and calls
   GameManager.set_state(PLAYING). Connect these to ProgressionManager.promoted /
   ProgressionManager.demoted signals respectively from the parent Game scene.

4. res://scenes/game_over/game_over.gd — on _ready(), read final score/grade/reason from
   GameManager (assume GameManager exposes last_final_score / last_final_grade /
   last_end_reason after session_ended), call SaveManager.add_high_score(score, grade),
   display the end reason as "Time's Up!" or "Out of Lives!" depending on last_end_reason,
   display the returned top-10 list with the current run highlighted if add_high_score
  returned true, and wire Retry (goto_scene game.tscn + start_session) and Title Screen
  (goto_scene title.tscn) buttons. Keep Retry and Resume button labels free of inline input hints.
```

---

## Usage Tips
- Generate and test in the order above — later prompts assume earlier autoloads/signals exist.
- After each prompt, run the project and sanity-check before moving to the next (small, verifiable steps beat one giant generation).
- Feel free to paste the relevant section of doc 5 (grade algorithm) or doc 4 (data model) alongside a prompt if Copilot's first attempt drifts from the spec — pinning the exact rules in-context improves accuracy.
