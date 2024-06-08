extends RefCounted

enum CircuitState {
	OPEN,
	CLOSED,
	HALF_OPEN
}

var _reset_timeout_ms: int = 5000
var _failure_threshold: int = 5
var _failure_count: int = 0
var _open_start_time_ms: Variant = null
var _state: CircuitState = CircuitState.CLOSED

func _init(options: Dictionary = {}):
	if options.has("reset_timeout_ms"):
		_reset_timeout_ms = options["reset_timeout_ms"]
	if options.has("failure_threshold"):
		_failure_threshold = options["failure_threshold"]

func should_make_request() -> bool:
	match _state:
		CircuitState.CLOSED:
			return true
		CircuitState.OPEN:
			if Time.get_unix_time_from_system() * 1e3 - _open_start_time_ms < _reset_timeout_ms:
				return false
			else:
				_state = CircuitState.HALF_OPEN
				return true
		_:
			printerr("Circuit breaker could not determine if request should be made (current state: " + str(_state))
			return false

func record_failure():
	_failure_count += 1
	if _state == CircuitState.CLOSED and _failure_count >= _failure_threshold:
		# otel_global.metrics_reporter:add_to_counter("otel.bsp.circuit_breaker_opened", 1)
		_state = CircuitState.OPEN
		_open_start_time_ms = Time.get_unix_time_from_system() * 1e3
	elif _state == CircuitState.HALF_OPEN:
		# otel_global.metrics_reporter:add_to_counter("otel.bsp.circuit_breaker_opened", 1)
		_state = CircuitState.OPEN
		_open_start_time_ms = Time.get_unix_time_from_system() * 1e3

func record_success():
	if _state == CircuitState.CLOSED:
		return
	elif _state == CircuitState.HALF_OPEN:
		# otel_global.metrics_reporter:add_to_counter("otel.bsp.circuit_breaker_closed", 1)
		_failure_count = 0
		_state = CircuitState.CLOSED
