extends "res://addons/gut/test.gd"

var SpanContext = preload("res://lib/opentelemetry/trace/span_context.gd")

func test_is_valid_returns_false_when_traceid_is_zero():
	var sp_ctx = SpanContext.new("00000000000000000000000000000000", "1234567890123456", 1, null, false)
	assert_false(sp_ctx.is_valid(), "Expected is_valid() to return false when traceid is all zeros")

func test_is_valid_returns_false_when_spanid_is_zero():
	var sp_ctx = SpanContext.new("00000000000000000000000000000001", "0000000000000000", 1, null, false)
	assert_false(sp_ctx.is_valid(), "Expected is_valid() to return false when spanid is all zeros")
