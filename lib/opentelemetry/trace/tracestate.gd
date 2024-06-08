class_name TraceState
extends Reference

const MAX_KEY_LEN = 256
const MAX_VAL_LEN = 256
const MAX_ENTRIES = 32

var values : Array

func _init(values: Array):
    self.values = values

static func validate_member_key(key: String) -> String:
    if key.length() > MAX_KEY_LEN:
        return ""

    var valid_key = key.strip_edges().match("^([a-z][_0-9a-z%-*/]*)$")
    if not valid_key:
        var tenant_id = key.strip_edges().match("^([a-z0-9][_0-9a-z%-*/]*)@([a-z][_0-9a-z%-*/]*)$")
        if not tenant_id or tenant_id.size() != 2 or tenant_id[0].length() > 241 or tenant_id[1].length() > 14:
            return ""
        return tenant_id[0] + "@" + tenant_id[1]

    return valid_key

static func validate_member_value(value: String) -> String:
    if value.length() > MAX_VAL_LEN:
        return ""
    return value.match("^([ !\"#$%%&'()*+%-./0-9:;<>?@A-Z[\%]^_`a-z{|}~]*[!\"#$%%&'()*+%-./0-9:;<>?@A-Z[\%]^_`a-z{|}~])\s*$")

static func new(values: Array) -> TraceState:
    return TraceState.new(values)

static func parse_tracestate(tracestate) -> TraceState:
    if tracestate == null:
        return TraceState.new([])

    if typeof(tracestate) == TYPE_STRING:
        tracestate = [tracestate]

    var new_tracestate = []
    var members_count = 0
    var error_message = "failed to parse tracestate"
    for item in tracestate:
        for member in item.split(","):
            if member != "":
                var start_pos = member.find("=")
                if start_pos == -1 or start_pos == 0:
                    print(error_message)
                    return TraceState.new([])
                var key = validate_member_key(member.left(start_pos))
                if key == "":
                    print(error_message)
                    return TraceState.new([])
                var value = validate_member_value(member.right(member.length() - start_pos - 1))
                if value == "":
                    print(error_message)
                    return TraceState.new([])
                members_count += 1
                if members_count > MAX_ENTRIES:
                    print(error_message)
                    return TraceState.new([])
                new_tracestate.append([key, value])
    return TraceState.new(new_tracestate)

func set(key: String, value: String) -> TraceState:
    if validate_member_key(key) == "":
        return self
    if validate_member_value(value) == "":
        return self
    del(key)
    if values.size() >= MAX_ENTRIES:
        values.pop_back()
        print("tracestate max values exceeded, removing rightmost entry")
    values.push_front([key, value])
    return self

func get(key: String) -> String:
    for item in values:
        if item[0] == key:
            return item[1]
    return ""

func del(key: String) -> TraceState:
    var index = -1
    for i in range(values.size()):
        if values[i][0] == key:
            index = i
            break
    if index != -1:
        values.remove(index)
    return self

func as_string() -> String:
    var output = []
    for item in values:
        output.append(item[0] + "=" + item[1])
    return ",".join(output)
