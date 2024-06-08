extends RefCounted

var gettimeofday_struct = null

func _ready():
    randomize()

# performance better, but may cause clock skew
func ngx_time_nano():
    return OS.get_ticks_msec() * 1000000

func ffi_gettimeofday():
    var current_time = OS.get_ticks_usec()
    return current_time

# Return current time in nanoseconds (there are 1000 nanoseconds
# in a microsecond)
func gettimeofday_ns():
    return ffi_gettimeofday() * 1000

# Return current time in milliseconds (there are 1000 milliseconds in a
# microsecond
func gettimeofday_ms():
    return ffi_gettimeofday() / 1000

# Localize randf calls to this file so we don't have scattered
# randomize calls.
func random(...):
    return randf()

# Godot's randf generates random floats within a given range
func random_float(max):
    return randf() * max

func shallow_copy_table(t):
    var t2 = {}
    for k in t.keys():
        t2[k] = t[k]
    return t2

func hex_to_char(hex):
    return chr(int(hex, 16))

func char_to_hex(c):
    return "%" + str(ord(c)).right(2)

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
