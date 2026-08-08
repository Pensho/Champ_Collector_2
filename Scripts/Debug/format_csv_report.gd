extends SceneTree

## Formats a CSV report's columns into fixed-width, aligned plain text — readable directly in
## a terminal or text editor without opening a spreadsheet app. Reads the RFC 4180-quoted CSV
## Tests/manual/team_corpus_sweep.gd's CSV export writes and pads each column to its widest
## value. A bare `-s` script is safe here (unlike team_corpus_sweep.gd's own entry point):
## this file never touches Character, only string/file operations.
##
## Run headless:
##   godot --headless -s res://Scripts/Debug/format_csv_report.gd

const INPUT_PATH: String = "res://Tests/manual/output/team_corpus_ranking.csv"
const OUTPUT_PATH: String = "res://Tests/manual/output/team_corpus_ranking_aligned.txt"
const COLUMN_SEPARATOR: String = "  "


func _initialize() -> void:
	var rows: Array[Array] = _ReadCSV(INPUT_PATH)
	if(rows.is_empty()):
		printerr("No rows read from %s" % INPUT_PATH)
		quit(1)
		return
	_WriteAligned(rows, OUTPUT_PATH)
	print("Wrote %d aligned rows to %s" % [rows.size(), ProjectSettings.globalize_path(OUTPUT_PATH)])
	quit()


func _ReadCSV(p_path: String) -> Array[Array]:
	var file: FileAccess = FileAccess.open(p_path, FileAccess.READ)
	if(null == file):
		printerr("Could not open %s" % p_path)
		return []
	var rows: Array[Array] = []
	while(not file.eof_reached()):
		var line: String = file.get_line()
		if(not line.is_empty()):
			rows.append(_ParseCSVLine(line))
	file.close()
	return rows


## Minimal RFC 4180 parser matching what the writer produces: every field double-quoted,
## internal quotes doubled, comma-separated, one record per line. Not a general-purpose CSV
## parser (no bare/unquoted fields, no embedded newlines) — sufficient for this file's own
## exports and nothing else is expected to feed it.
func _ParseCSVLine(p_line: String) -> Array[String]:
	var fields: Array[String] = []
	var current: String = ""
	var in_quotes: bool = false
	var i: int = 0
	while(i < p_line.length()):
		var character: String = p_line[i]
		if(in_quotes):
			if('"' == character and i + 1 < p_line.length() and '"' == p_line[i + 1]):
				current += '"'
				i += 1
			elif('"' == character):
				in_quotes = false
			else:
				current += character
		elif('"' == character):
			in_quotes = true
		elif(',' == character):
			fields.append(current)
			current = ""
		else:
			current += character
		i += 1
	fields.append(current)
	return fields


func _WriteAligned(p_rows: Array[Array], p_output_path: String) -> void:
	var column_count: int = 0
	for row: Array in p_rows:
		column_count = maxi(column_count, row.size())
	var widths: Array[int] = []
	widths.resize(column_count)
	widths.fill(0)
	for row: Array in p_rows:
		for i in row.size():
			widths[i] = maxi(widths[i], String(row[i]).length())

	var file: FileAccess = FileAccess.open(p_output_path, FileAccess.WRITE)
	for row: Array in p_rows:
		var padded: Array[String] = []
		for i in row.size():
			var field: String = String(row[i])
			padded.append(field + " ".repeat(widths[i] - field.length()))
		file.store_line(COLUMN_SEPARATOR.join(padded))
	file.close()
