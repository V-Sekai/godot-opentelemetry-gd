extends RefCounted

# Enum for the status codes
enum StatusCode {UNSET = 0, OK = 1, ERROR = 2}

# SpanStatus class
class SpanStatus:
	var code: int
	var description: String

	func _init(code: int = StatusCode.UNSET):
		self.code = code
		self.description = ""

static func new(code: int = StatusCode.UNSET) -> SpanStatus:
	return SpanStatus.new(code)
