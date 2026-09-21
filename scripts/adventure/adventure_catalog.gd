extends RefCounted

const CAMPAIGNS := {
    "elementary": {"name": "ELEMENTARY", "start_grade": 1, "victory_grade": 5, "character": 0, "seconds": 12.0, "music": "mathkitten_theme"},
    "middle": {"name": "MIDDLE", "start_grade": 5, "victory_grade": 9, "character": 1, "seconds": 24.0, "music": "mathcat_theme"},
    "high": {"name": "HIGH", "start_grade": 9, "victory_grade": 13, "character": 2, "seconds": 36.0, "music": "mathtiger_theme"},
}
const LEVEL_NAMES := {
    "elementary": ["The Oregon Math Trail", "Duck Count", "River City Subtraction", "ExciteMath", "Mathlevania", "StarCat 64", "Divide Horizon", "Metal Gear Kitten", "The Legend of Math Cat"],
    "middle": ["Mega Math Cat", "Street Fraction II", "Double Decimal", "Super Mathorid", "Streets of Algebra", "The Elder Sums", "Microsoft Flight Calculator", "Gears of Bar Charts", "Teenage Mutant Ninja Mathematicians"],
    "high": ["Super Variable Bros.", "Final Factoring", "F(x)-Zero", "Conker's Bad Equation Day", "Resident Equal", "Derivative Kong Country", "Halo: Calculus Evolved", "Killer Integral", "Chrono Trigonometry"],
}
const WORLD_MAP_SUN_CENTER := Vector2(1120, 225)
const STAGE_HIGHLIGHT_COLORS := [
    Color("59f7ff"), Color("64dfff"), Color("83bcff"),
    Color("7fffd4"), Color("efff7f"), Color("ffd76a"),
    Color("ff9cda"), Color("ffb3a3"), Color("ffbc87"),
]
const LEVEL_COUNT := 9
const CORRECT_TARGET := 10
const ACCESSORIES := {
    "bow_tie": {"name": "BOW TIE", "price": 50, "slot": "neck"},
    "bandana": {"name": "BANDANA", "price": 100, "slot": "neck"},
    "crown": {"name": "GOLDEN CROWN", "price": 200, "slot": "head"},
    "top_hat": {"name": "TOP HAT", "price": 150, "slot": "head"},
    "flower": {"name": "FLOWER", "price": 75, "slot": "head"},
    "sunglasses": {"name": "SUNGLASSES", "price": 125, "slot": "face"},
    "bell_collar": {"name": "BELL COLLAR", "price": 75, "slot": "neck"},
}

static func level(campaign: String, number: int) -> Dictionary:
    if not CAMPAIGNS.has(campaign) or number < 1 or number > LEVEL_COUNT:
        return {}
    var settings: Dictionary = CAMPAIGNS[campaign]
    var boss := number == LEVEL_COUNT
    return {
        "campaign": campaign, "number": number,
        "grade": int(settings.start_grade) if boss else int(settings.start_grade) + (number - 1) / 2,
        "character": int(settings.character), "timed": not boss and number % 2 == 0,
        "timer_seconds": float(settings.seconds) if not boss and number % 2 == 0 else 0.0,
        "correct_target": CORRECT_TARGET, "background": "%s_%d" % [campaign, number],
        "highlight_color": STAGE_HIGHLIGHT_COLORS[number - 1],
        "city_name": LEVEL_NAMES[campaign][number - 1], "level_type": "boss" if boss else "standard",
        "boss_start_grade": int(settings.start_grade), "boss_victory_grade": int(settings.victory_grade),
        "reward": 100 if boss else 20 + number * 5, "music": "nerdcat_theme" if boss else str(settings.music),
    }

static func default_progress() -> Dictionary:
    return {"highest_unlocked_level": 1, "completed_levels": [], "campaign_completed": false, "level_results": {}, "currency": 0, "correct_answers": 0, "best_streak": 0, "owned_accessories": [], "equipped_accessories": {}}

static func with_accessory(equipped: Dictionary, item: String, wear: bool = true) -> Dictionary:
    if item.is_empty():
        return {}
    var result := equipped.duplicate()
    var slot: String = ACCESSORIES[item].slot
    if wear:
        result[slot] = item
    elif result.get(slot, "") == item:
        result.erase(slot)
    return result

static func defaults() -> Dictionary:
    var progress := {}
    for campaign in CAMPAIGNS:
        progress[campaign] = default_progress()
    return progress

static func nonnegative(value: Variant, maximum: int = 1000000000) -> int:
    if (value is int or value is float) and is_finite(float(value)):
        return clampi(int(value), 0, maximum)
    return 0

static func normalize(source: Variant) -> Dictionary:
    var progress := defaults()
    if not source is Dictionary:
        return progress
    for campaign in CAMPAIGNS:
        var saved: Variant = source.get(campaign, {})
        if not saved is Dictionary:
            continue
        var target: Dictionary = progress[campaign]
        var completed: Variant = saved.get("completed_levels", [])
        if completed is Array:
            var valid_levels: Array[int] = []
            for value in completed:
                var number := nonnegative(value, LEVEL_COUNT + 1)
                if number >= 1 and number <= LEVEL_COUNT:
                    valid_levels.append(number)
            for number in range(1, LEVEL_COUNT + 1):
                if not number in valid_levels:
                    break
                target.completed_levels.append(number)
        target.highest_unlocked_level = mini(target.completed_levels.size() + 1, LEVEL_COUNT)
        target.campaign_completed = target.completed_levels.size() == LEVEL_COUNT
        for key in ["currency", "correct_answers", "best_streak"]:
            target[key] = nonnegative(saved.get(key, 0))
        var owned: Variant = saved.get("owned_accessories", [])
        if owned is Array:
            for item in owned:
                if item is String and ACCESSORIES.has(item) and not item in target.owned_accessories:
                    target.owned_accessories.append(item)
        var equipped: Variant = saved.get("equipped_accessories", {})
        if not saved.has("equipped_accessories"):
            var legacy: Variant = saved.get("equipped_accessory", "")
            if legacy is String and legacy in target.owned_accessories:
                equipped = with_accessory({}, legacy)
        if equipped is Dictionary:
            for slot in equipped:
                var item: Variant = equipped[slot]
                if item is String and item in target.owned_accessories and ACCESSORIES[item].slot == slot:
                    target.equipped_accessories[slot] = item
        var results: Variant = saved.get("level_results", {})
        if results is Dictionary:
            for number in target.completed_levels:
                var result: Variant = results.get(str(number), {})
                if result is Dictionary:
                    target.level_results[str(number)] = {
                        "best_score": nonnegative(result.get("best_score", 0)),
                        "best_lives": nonnegative(result.get("best_lives", 0), 9),
                        "clears": maxi(nonnegative(result.get("clears", 1)), 1),
                    }
    return progress