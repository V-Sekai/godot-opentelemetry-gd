extends Node

var TraceState = preload("tracestate.gd")

const INVALID_TRACE_ID = "00000000000000000000000000000000"
const INVALID_SPAN_ID = "0000000000000000"

var _trace_id : String
var _span_id : String
var _trace_flags : int
var _trace_state : Object
var _remote : bool

func init(tid: String, sid: String, trace_flags: int, trace_state: Object = null, remote: bool = false):
	_trace_id = tid
	_span_id = sid
	_trace_flags = trace_flags
	_trace_state = trace_state if trace_state else TraceState.new([])
	_remote = remote

func is_valid() -> bool:
	if _trace_id == INVALID_TRACE_ID or _trace_id == "":
		return false

	if _span_id == INVALID_SPAN_ID or _span_id == "":
		return false

	return true

func is_remote() -> bool:
	return _remote

func is_sampled() -> bool:
	return (_trace_flags & 1) == 1

func plain() -> Dictionary:
	return {
		"trace_id": _trace_id,
		"span_id": _span_id,
		"trace_flags": _trace_flags,
		"trace_state": _trace_state,
		"remote": _remote
	}
