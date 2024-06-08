extends "res://addons/gut/test.gd"

var util = preload("res://lib/opentelemetry/util.gd")
var circuit = preload("res://lib/opentelemetry/trace/exporter/circuit.gd")

func test_should_make_request():
	var c = circuit.new()
	c._state = c.CircuitState.CLOSED
	assert_true(c.should_make_request(), "returns true when circuit is closed")

	c = circuit.new({"reset_timeout_ms": 5000})
	c._state = c.CircuitState.OPEN
	c._open_start_time_ms = util.gettimeofday_ms()
	assert_false(c.should_make_request(), "returns false when circuit is open and halfopen_threshold not exceeded")

	c = circuit.new({"reset_timeout_ms": 5000})
	c._state = c.CircuitState.OPEN
	c._open_start_time_ms = util.gettimeofday_ms() - 6000
	assert_true(c.should_make_request(), "returns true when circuit is open and halfopen_threshold is exceeded")

func test_record_failure():
	var c = circuit.new({"failure_threshold": 1})
	assert_eq(c._state, c.CircuitState.CLOSED)
	assert_eq(c._open_start_time_ms, null)
	c.record_failure()
	assert_eq(c._state, c.CircuitState.OPEN)
	assert_ne(c._open_start_time_ms, null)

	c = circuit.new({"failure_threshold": 5})
	c._state = c.CircuitState.HALF_OPEN
	c.record_failure()
	assert_eq(c._state, c.CircuitState.OPEN)
	assert_ne(c._open_start_time_ms, null)

func test_record_success():
	var c = circuit.new({"failure_threshold": 1})
	c._state = c.CircuitState.HALF_OPEN
	c.record_success()
	assert_eq(c._state, c.CircuitState.CLOSED)
