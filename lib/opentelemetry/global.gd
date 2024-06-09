extends Node

var _metrics_reporter = preload("metrics_reporter.gd")

var _tracer_provider = null
var _context_storage = null

func set_tracer_provider(tp):
	_tracer_provider = tp

func get_tracer_provider():
	return _tracer_provider

func set_metrics_reporter(metrics_reporter):
	_metrics_reporter = metrics_reporter
	
func tracer(tracer_name, opts):
	return _tracer_provider.tracer(tracer_name, opts)

func get_context_storage():
	return _context_storage or Engine.get_main_loop()

func set_context_storage(context_storage):
	_context_storage = context_storage
