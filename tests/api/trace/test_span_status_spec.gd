extends "res://addons/gut/test.gd"

# Assuming that the "lib.opentelemetry.api.trace.span_status" is a class in GDScript
var SpanStatus = preload("res://lib/opentelemetry/api/trace/span_status.gd")

func test_new_defaults_to_unset():
	var s = SpanStatus.new()
	assert_eq(s.code, SpanStatus.StatusCode.UNSET)
