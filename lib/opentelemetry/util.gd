extends RefCounted

var gettimeofday_struct = null

func _ready():
	randomize()

# performance better, but may cause clock skew
func ngx_time_nano():
	return Time.get_ticks_msec() * 1000000

func ffi_gettimeofday():
	return Time.get_ticks_usec()

# Return current time in nanoseconds
static func gettimeofday_ns() -> float:
	return Time.get_unix_time_from_system() * 1e9

# Return current time in milliseconds
static func gettimeofday_ms() -> float:
	return Time.get_unix_time_from_system() * 1e3

# Localize randf calls to this file so we don't have scattered
# randomize calls.
func random():
	return randf()

# Godot's randf generates random floats within a given range
func random_float(p_max):
	return randf() * p_max

func shallow_copy_table(t):
	var t2 = {}
	for k in t.keys():
		t2[k] = t[k]
	return t2

func hex_to_char(hex):
	return char(int("0x" + hex))

func char_to_hex(c):
	var hex = "%02X" % char(c)
	return "%" + hex

# Baggage headers values can be percent encoded. We need to unescape them.
func decode_percent_encoded_string(str):
	return str.replace("%" + "(%x%x)", hex_to_char)

# Percent encode a baggage string. It's not generic for all percent encoding,
# since we don't want to percent-encode equals signs, semicolons, or commas in
# baggage strings.
func percent_encode_baggage_string(str):
	if str == null:
		return
	str = str.replace("\n", "\r\n")
	str = str.replace("([^%w ,;=_%%%-%.~])", char_to_hex)
	str = str.replace(" ", "+")
	return str

# Recursively render a table as a string
func table_as_string(tt, indent=0, done={}):
	if typeof(tt) == TYPE_DICTIONARY:
		var sb = []
		for key in tt.keys():
			sb.append(" ".repeat(indent)) # indent it
			if typeof(tt[key]) == TYPE_DICTIONARY and not done.has(tt[key]):
				done[tt[key]] = true
				sb.append(str(key) + " = {\n")
				sb.append(table_as_string(tt[key], indent + 2, done))
				sb.append(" ".repeat(indent)) # indent it
				sb.append("}\n")
			elif typeof(key) == TYPE_INT:
				sb.append("\"" + str(tt[key]) + "\"\n")
			else:
				sb.append(str(key) + " = \"" + str(tt[key]) + "\"\n")
		return "".join(sb)
	else:
		return str(tt) + "\n"

func split(inputstr, sep=" "):
	return inputstr.split(sep)

# Strip whitespace from the beginning and end of a string
func trim(s):
	return s.strip_edges()

# default time function, will be used in this SDK
# change it if needed
func time_nano():
	return gettimeofday_ns()
