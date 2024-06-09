extends "res://addons/gut/test.gd"

var exporter = preload("opentelemetry/trace/exporter/otlp.gd")
var client = preload("opentelemetry/trace/exporter/http_client.gd")
var context = preload("opentelemetry/context.gd")
var tp = Global.get_tracer_provider()
var tracer_provider_new = preload("opentelemetry/trace/tracer_provider.gd").new
var tracer = tp.tracer("test")

func test_encode_spans():
	var span
	var ctx = context.new()
	ctx, span = tracer.start(ctx, "test span")
	span.finish()
	var cb = exporter.new(null)
	var encoded = cb.encode_spans([span, other_spans])
	# One resource, one il, one span
	assert(encoded.resource_spans.size() == 1)
	var resource = encoded.resource_spans[0]
	assert(resource.instrumentation_library_spans.size() == 1)
	assert(resource.instrumentation_library_spans[0].spans.size() == 1)

func test_one_resource_span_and_one_ils_for_multiple_span_same_tracer():
	var span
	var ctx = context.new()
	var spans = []
	for i in range(10, 1, -1):
		ctx, span = tracer.start(ctx, "test span" + str(i), {}, 123456788)
		span.finish(123456789)
		spans.append(span)
	var cb = exporter.new(null)
	var encoded = cb.encode_spans(spans)
	# One resource, one il, 10 spans
	assert(encoded.resource_spans.size() == 1)
	var resource = encoded.resource_spans[0]
	assert(resource.instrumentation_library_spans.size() == 1)
	assert(resource.instrumentation_library_spans[0].spans.size() == 10)
	assert(resource.instrumentation_library_spans[0].spans[0].start_time_unix_nano == "123456788")
	assert(resource.instrumentation_library_spans[0].spans[0].end_time_unix_nano == "123456789")

func test_one_resource_span_and_two_ils_for_spans_from_distinct_tracers():
	var span
	var ctx = context.new()
	var spans = []
	ctx, span = tracer.start(ctx, "test span")
	span.finish()
	spans.append(span)
	var other_tracer = tp.tracer("exam")
	ctx, other_span = other_tracer.start(ctx, "exam span")
	spans.append(other_span)
	var cb = exporter.new(null)
	var encoded = cb.encode_spans(spans)
	# One resource, two il, 1 span each
	assert(encoded.resource_spans.size() == 1)
	var resource = encoded.resource_spans[0]
	assert(resource.instrumentation_library_spans.size() == 2)
	assert(resource.instrumentation_library_spans[0].spans.size() == 1)
	assert(resource.instrumentation_library_spans[1].spans.size() == 1)

func test_distinct_trace_providers_provide_distinct_resources():
	var span
	var ctx = context.new()
	var spans = []
	ctx, span = tracer.start(ctx, "test span")
	span.finish()
	spans.append(span)
	var op = tracer_provider_new(null, null)
	var other_tracer = op.tracer("exam")
	ctx, other_span = other_tracer.start(ctx, "exam span")
	spans.append(other_span)
	var cb = exporter.new(null)
	var encoded = cb.encode_spans(spans)
	# two resources with one il, 1 span each
	assert(encoded.resource_spans.size() == 2)
	var resource = encoded.resource_spans[0]
	assert(resource.instrumentation_library_spans.size() == 1)
	assert(resource.instrumentation_library_spans[0].spans.size() == 1)
	resource = encoded.resource_spans[1]
	assert(resource.instrumentation_library_spans.size() == 1)
	assert(resource.instrumentation_library_spans[0].spans.size() == 1)


-- describe("export_spans", function()
--     it("invokes do_request when there are no failures", function()
--         local span
--         local ctx = context.new()
--         ctx, span = tracer:start(ctx, "test span")
--         span:finish()
--         local c = client.new("http://localhost:8080", 10)
--         spy.on(c, "do_request")
--         local cb = exporter.new(c)
--         -- Supress log message, since we expect it
--         stub(ngx, "log")
--         cb:export_spans({ span })
--         ngx.log:revert()
--         assert.spy(c.do_request).was_called_with(c, match.is_string())
--     end)

--     it("doesn't invoke protected_call when failures is equal to retry limit", function()
--         local span
--         local ctx = context.new()
--         ctx:attach()
--         ctx, span = tracer:start(ctx, "test span")
--         span:finish()
--         local c = client.new("http://localhost:8080", 10)
--         c.do_request = function() return nil, "there was a problem" end
--         mock(c, "do_request")
--         local cb = exporter.new(c, 10000)
--         cb:export_spans({ span })
--         assert.spy(c.do_request).was_called(3)
--     end)

--     it("doesn't invoke do_request when start time is more than timeout_ms ago", function()
--         local span
--         local ctx = context.new()
--         ctx:attach()
--         ctx, span = tracer:start(ctx, "test span")
--         span:finish()
--         local c= client.new("http://localhost:8080", 10)
--         -- Set default timeout to -1, so that we're already over the timeout
--         local cb = exporter.new(client, -1)
--         spy.on(c, "do_request")
--         stub(ngx, "log")
--         cb:export_spans({ span})
--         ngx.log:revert()
--         assert.spy(c.do_request).was_not_called()
--     end)
-- end)

-- describe("circuit breaker", function()
--     it("doesn't call do_request when should_make_request() is false", function()
--         local span
--         local ctx = context.new()
--         ctx:attach()
--         ctx, span = tracer:start(ctx, "test span")
--         span:finish()
--         local client = client.new("http://localhost:8080", 10)
--         local ex = exporter.new(client, 1)
--         ex.circuit.should_make_request = function() return false end
--         spy.on(client, "do_request")
--         ex:export_spans({ span})
--         assert.spy(client.do_request).was_not_called()
--     end)

--     it("calls do_request when should_make_request() is true", function()
--         local span
--         local ctx = context.new()
--         ctx:attach()
--         ctx, span = tracer:start(ctx, "test span")
--         span:finish()
--         local client = client.new("http://localhost:8080", 10)
--         local ex = exporter.new(client, 1)
--         ex.circuit.should_make_request = function() return true end
--         client.do_request = function(arg) return "hi", nil end
--         spy.on(client, "do_request")
--         ex:export_spans({ span})
--         assert.spy(client.do_request).was_called(1)
--     end)
-- end)
