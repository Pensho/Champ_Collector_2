class_name KeyWordColors
extends Node

const KEYWORDS: Dictionary[String, Color] = {
	"Speed": Color(0.929, 0.8, 0.0, 1.0),
	"Attack": Color(1.0, 0.0, 0.0, 1.0),
	"Defence": Color(0.178, 0.515, 1.0, 1.0),
	"Defense": Color(0.178, 0.515, 1.0, 1.0),
	"Health": Color(0.0, 0.73, 0.253, 1.0),
	"Accuracy": Color(0.808, 0.002, 0.988, 1.0),
	"Resistance": Color(0.582, 0.136, 1.0, 1.0),
	"Mysticism": Color(0.932, 0.0, 0.643, 1.0),
	"Knowledge": Color(0.934, 0.254, 0.0, 1.0),
	
	"Critical": Color(0.476, 0.714, 1.0, 1.0),
	
	"Stack": Color(0.441, 0.777, 0.668, 1.0),
	"Stacks": Color(0.441, 0.777, 0.668, 1.0),
	"Charge": Color(0.441, 0.777, 0.668, 1.0),
	"Charges": Color(0.441, 0.777, 0.668, 1.0),

	"Burn": Color(1.0, 0.0, 0.0, 1.0),
	"Burning": Color(1.0, 0.0, 0.0, 1.0),

	"Bleed": Color(1.0, 0.29, 0.29, 1.0),

	"Barrier": Color(0.6, 0.85, 1.0, 1.0),
}

static func ApplyKeywordColors(p_text: String) -> String:
	var regex = RegEx.new()
	var processed_text = p_text

	for keyword in KEYWORDS.keys():
		var color_code = KEYWORDS[keyword].to_html()
		var pattern = "(?i)\\b(" + keyword + ")\\b"
		regex.compile(pattern)

		# $1 inserts the text found in the first set of parentheses
		var replacement = "[color=" + color_code + "]$1[/color]"

		processed_text = regex.sub(processed_text, replacement, true)

	return processed_text
