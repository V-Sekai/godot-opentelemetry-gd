extends "res://addons/gut/test.gd"

var id_generator = preload("res://lib/opentelemetry/trace/id_generator.gd")

func test_new_span_id():
	for i in range(100):
		var span_id = id_generator.new_span_id()
		assert_eq(span_id.length(), 16, "new_span_id should generate a 16 character hex string")

func test_new_ids():
	for i in range(100):
		var ids = id_generator.new_ids().split("")
		var trace_id = "".join(ids.slice(0, 32))
		var span_id = "".join(ids.slice(32, 48))
		assert_eq(trace_id.length(), 32, "new_ids should generate a 32 character trace_id")
		assert_eq(span_id.length(), 16, "new_ids should generate a 16 character span_id")
