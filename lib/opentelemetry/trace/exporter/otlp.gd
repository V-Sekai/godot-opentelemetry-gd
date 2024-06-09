extends RefCounted

var encoder = preload("res://opentelemetry/trace/exporter/encoder.gd")
var pb = preload("res://opentelemetry/trace/exporter/pb.gd")
var otel_global = preload("res://opentelemetry/global.gd")
var util = preload("res://opentelemetry/util.gd")
var BACKOFF_RETRY_LIMIT = 3
var DEFAULT_TIMEOUT_MS = 10000
var exporter_request_duration_metric = "otel.otlp_exporter.request_duration"
var circuit = preload("res://opentelemetry/trace/exporter/circuit.gd")

var client
var timeout_ms
var circuit_instance

func _init(http_client, timeout_ms, circuit_reset_timeout_ms, circuit_open_threshold):
	self.client = http_client
	self.timeout_ms = timeout_ms
	self.circuit_instance = circuit.new({
		"reset_timeout_ms": circuit_reset_timeout_ms,
		"failure_threshold": circuit_open_threshold
	})

# Repeatedly make calls to collector until success, failure threshold or timeout
func call_collector(pb_encoded_body):
	var start_time_ms = OS.get_ticks_msec()
	var failures = 0
	var res
	var res_error

	while failures < BACKOFF_RETRY_LIMIT:
		var current_time = OS.get_ticks_msec()
		if current_time - start_time_ms > timeout_ms:
			var err_message = "Collector retries timed out (timeout %s)" % timeout_ms
			print(err_message)
			return [false, err_message]

		if not circuit_instance.should_make_request():
			print("Circuit breaker is open")
			return [false, "Circuit breaker is open"]

		# Make request
		res, res_error = client.do_request(pb_encoded_body)
		var after_time = OS.get_ticks_msec()
		otel_global.metrics_reporter.record_value(
			exporter_request_duration_metric, after_time - current_time)

		if not res:
			circuit_instance.record_failure()
			failures += 1
			await get_tree().create_timer(2 ** failures).timeout
			print("Retrying call to collector (retry #%s)" % failures)
		else:
			circuit_instance.record_success()
			return true, null

	return [false, res_error if res_error else "unknown"]

func encode_spans(spans):
	assert(spans.size() > 0)

	var body = {
		"resource_spans": [{
			"resource": {
				"attributes": spans[0].tracer.provider.resource.attrs,
				"dropped_attributes_count": 0,
			},
			"instrumentation_library_spans": [{
				"instrumentation_library": {
					"name": spans[0].tracer.il.name,
					"version": spans[0].tracer.il.version,
				},
				"spans": []
			}],
		}]
	}
	var tracers = {}
	var providers = {}
	tracers[spans[0].tracer] = 1
	providers[spans[0].tracer.provider] = 1
	for span in spans:
		var rs_idx = providers.get(span.tracer.provider)
		var ils_idx = tracers.get(span.tracer)
		if not rs_idx:
			rs_idx = body["resource_spans"].size() + 1
			ils_idx = 1
			providers[span.tracer.provider] = rs_idx
			tracers[span.tracer] = ils_idx
			body["resource_spans"].append({
				"resource": {
					"attributes": span.tracer.provider.resource.attrs,
					"dropped_attributes_count": 0,
				},
				"instrumentation_library_spans": [{
					"instrumentation_library": {
						"name": span.tracer.il.name,
						"version": span.tracer.il.version,
					},
					"spans": []
				}],
			})
		elif not ils_idx:
			ils_idx = body["resource_spans"][rs_idx - 1]["instrumentation_library_spans"].size() + 1
			tracers[span.tracer] = ils_idx
			body["resource_spans"][rs_idx - 1]["instrumentation_library_spans"].append({
				"instrumentation_library": {
					"name": span.tracer.il.name,
					"version": span.tracer.il.version,
				},
				"spans": []
			})
		body["resource_spans"][rs_idx - 1]["instrumentation_library_spans"][ils_idx - 1]["spans"].append(encoder.for_otlp(span))
	return body

func export_spans(spans):
	return call_collector(pb.encode(encode_spans(spans)))

func shutdown():
	pass
