const trace = preload("res://opentelemetry/proto/common/v1/trace.gd")

static func encode(payload):
	var traces_data = trace.TracesData.new()
	traces_data.data = payload
	return traces_data.to_bytes()

static func decode(buffer: PackedByteArray):
	var traces_data = trace.TracesData.new()
	var result_code = traces_data.from_bytes(buffer)
	if result_code == trace.PB_ERR.NO_ERRORS:
		return traces_data
	else:
		return null
