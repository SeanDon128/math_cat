# 4. Data Model — Questions & Save Data

## `QuestionData` (runtime object, not necessarily a saved Resource)
```gdscript
class_name QuestionData
extends RefCounted

var id: String            # e.g. "add_gen_20240101_123" or curated bank id
var grade: int             # 1-12 (current build produces 1-5)
var topic: String          # e.g. "addition_within_20", "basic_geometry"
var question_text: String  # e.g. "7 + 8 ="
var correct_answer: String # stored as String for uniform display (numbers, fractions, "12 cm²", etc.)
var choices: Array[String] # length 4, shuffled, contains correct_answer exactly once
var source: String         # "procedural" | "curated"
```

Rationale for `String` answers: keeps rendering/comparison uniform whether the answer is `"15"`, `"3/4"`, `"2.5"`, or `"12 cm²"`. Generators are responsible for formatting.

## Generator Contract
```gdscript
class_name BaseQuestionGenerator
extends RefCounted

func generate() -> QuestionData:
    push_error("override me")
    return null
```
Each topic gets a small subclass implementing `generate()`. `QuestionBank` picks a generator (or curated bank) at random, weighted by which topics belong to the player's current grade.

### Current Generators (Grades 1–13)
| Generator | Grade | Logic sketch |
|---|---|---|
| `AdditionGenerator` | 1 | Two operands from 1–10; 100 ordered prompts with two distinct distractor variants each, for 200 unique prompt-and-choice sets. Each shuffled answer set has three distinct wrong answers within 3: the correct result is numerically lowest in 25% of sets, highest in 25%, and between wrong answers in 50%. |
| `SubtractionGenerator` | 2 | 100 non-negative prompts with minuends 1–20. All 54 single-digit pairs with nonzero minuends are included first, then 46 higher-number pairs. Two ranked variants per prompt create 200 unique sets. |
| `MultiplicationGenerator` | 3 | 110 ordered prompts with operands from 0–10, displayed with `×`. Two ranked variants per prompt create 220 unique sets with no negative choices; zero-product second variants use `4` as the one non-close distractor needed for uniqueness. |
| `LongDivisionGenerator` | 4 | 100 exact-division prompts, displayed with `÷`: divisor 1–10 and quotient 0–9. Two ranked variants per prompt create 200 unique sets. |
| `GradeFiveGenerator` | 5 | A shuffled 200-set mixed deck: 50 two-digit add/subtract (negative subtraction answers allowed), 50 two-digit `×` one-digit multiplication, 50 like-denominator fraction additions, and 50 decimal additions/subtractions with operands below 100. Exact answer-rank split is 50 lowest, 50 highest, and 100 middle. |
| `AdvancedPlaceholderGenerator` | 6–13 | Placeholder practice content for the Math Cat/Math Tiger/Professor Whiskers evolution tiers: single-topic `×` deck (200 sets) with operand ranges that widen per grade. One instance per grade, lazily created and cached by `QuestionBank`. Swap with real per-grade curricula later without touching the routing contract. |
| `BasicGeometryGenerator` | 4 | Curated (see below) — perimeter/area of rectangles/squares with small integer sides. |

The active bank routes Grades 1–4 to their dedicated generators, Grade 5 to `GradeFiveGenerator`, and Grades 6–13 to a per-grade `AdvancedPlaceholderGenerator` instance. All active numeric decks place the correct answer lowest in 25% of sets, highest in 25%, and between wrong answers in 50%; the Grade 3 zero-product second variant may use `4` to remain nonnegative and distinct. Basic geometry remains deferred.

### Distractor Rules (applies to all generators)
1. Always produce exactly 3 distractors + 1 correct answer = 4 unique choices.
2. Deduplicate: if a "common mistake" distractor collides with the correct answer or another distractor, regenerate/skip it and fall back to `correct ± random_offset`.
3. Shuffle final 4-item array before assigning to `choices`.

## Curated JSON Bank (for content easier to hand-author, e.g. Grade 4 geometry)
`res://data/questions/grade4_geometry.json`
```json
[
  {
    "id": "geo_rect_area_01",
    "grade": 4,
    "topic": "basic_geometry",
    "question_text": "A rectangle is 5 cm by 3 cm. What is its area?",
    "correct_answer": "15 cm²",
    "distractors": ["8 cm²", "16 cm²", "10 cm²"]
  }
]
```
Loaded via `FileAccess` + `JSON.parse_string()` at startup into a `Dictionary` keyed by grade/topic; `QuestionBank` converts entries into `QuestionData` (shuffling `distractors + [correct_answer]` into `choices`).

## Future Grades (6–13) — Placeholder Content Active
Grades 6–13 currently use `AdvancedPlaceholderGenerator` (see table above) so the Math Cat/Math Tiger/Professor Whiskers evolution tiers are reachable end-to-end. Replace it with real per-grade curricula (JSON bank or dedicated generators) whenever authored; register the replacement in `QuestionBank`'s routing — no other architecture changes are needed.

## Save Data — `user://mathcat_save.json`
This historical design is not the current profile implementation: existing settings, career records, and achievements live in `user://math_cat_profile.json`, managed by `ProfileManager`. Blitz uses the separate format described below.

```json
{
  "high_scores": [
    { "score": 480, "grade": 4, "date": "2026-08-15T14:32:00" }
  ],
  "settings": {
    "sfx_volume": 0.8,
    "music_volume": 0.6
  }
}
```
- Keep top 10 entries, sorted descending by score.
- `SaveManager.load()` returns sane defaults (`high_scores: []`, default volumes) if the file is missing, empty, or fails `JSON.parse_string`.
- `SaveManager.save()` writes atomically enough for a jam: overwrite the whole file each time (no partial writes needed at this data size).

## Blitz Save Data - `user://math_cat_blitz_scores.json`

`BlitzLeaderboard` stores a versioned object with `version: 1` and `boards`, a dictionary containing all grade keys `"1"` through `"13"`. Each board is an array of at most ten entries of the form:

```json
{ "initials": "CAT", "score": 25 }
```

Initials must be exactly three uppercase ASCII letters. Scores are positive integers (at most 2,147,483,647); zero/negative final scores are displayed but not stored. Entries are sorted descending; new ties are inserted after existing ties, so array order preserves tie precedence without timestamps. Initials are not unique identifiers. JSON numbers are normalized to integers when loading.

Missing files initialize empty boards. Invalid schemas, unsupported versions, malformed JSON, and read errors are reported without overwriting the original file. Writes use a sibling `.tmp` file, check write/flush errors, then replace the destination; failed replacement preserves the existing target. The pending round is marked saved only after successful persistence, allowing Retry Save without duplicate insertion. Board readers receive deep copies.

Blitz data is independent of Standard records, lifetime counters, achievements, and the career-statistics reset.

### Two-player Blitz data

`BlitzDuelLeaderboard` uses the identical version-1 per-grade schema in **`user://math_cat_blitz_duel_scores.json`**. It shares implementation, not data, with the solo store. Existing solo files do not require migration. Grades 1-13 each have their own top 10; only a positive-scoring winner of a completed two-player round may submit. Losers and draws are never eligible, and duplicate initials remain independent entries.

The in-memory two-player result snapshot contains `two_player: true`, `grade`, `winner` (zero-based player index, or `-1` for a draw), `score` (the higher of the two scores), and `players` (two objects containing `score`, `correct`, and `incorrect`). Scalar legacy completion listeners receive the higher score; multiplayer UI reads the complete copied snapshot. Player attempts and input-device assignments are match-only state and are not persisted as profile settings or player identities.
