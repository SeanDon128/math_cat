class_name NumericDisplayFormatter
extends RefCounted

static func format_integer(value: int) -> String:
    var digits := str(absi(value))
    var formatted := ""
    for digit_index in range(digits.length()):
        if digit_index > 0 and (digits.length() - digit_index) % 3 == 0:
            formatted += ","
        formatted += digits[digit_index]
    return ("-" if value < 0 else "") + formatted

static func format_text(text: String) -> String:
    var number_pattern := RegEx.new()
    number_pattern.compile("(?<![\\d,])\\d{1,3}(?:\\d{3})+(?![\\d,])")
    var formatted := ""
    var previous_end := 0
    for match in number_pattern.search_all(text):
        formatted += text.substr(previous_end, match.get_start() - previous_end)
        formatted += format_integer(match.get_string().to_int())
        previous_end = match.get_end()
    return formatted + text.substr(previous_end)