extends RefCounted

var util = preload("res://lib/opentelemetry/util.gd")

class Encoder:
    func _init():
        pass

    # hex2bytes converts a hex string into bytes (used for transit over OTLP).
    #
    # @param str Hex string.
    # @return Table to be used as basis for more specific exporters.
    static func hex2bytes(str):
        var result = ""
        for i in range(0, len(str), 2):
            var cc = str.substr(i, 2)
            var n = int("0x" + cc)
            if n != null:
                result += char(n)
        return result

    # for_export structures span data for export; used as basis for more specific
    # exporters.
    #
    # @param span The span to export
    # @return Table to be used as basis for more specific exporters.
    func for_export(span):
        return {
            "trace_id": span.ctx.trace_id,
            "span_id": span.ctx.span_id,
            "trace_state": span.ctx.trace_state.as_string(),
            "parent_span_id": span.parent_ctx.span_id if span.parent_ctx.span_id else "",
            "name": span.name,
            "kind": span.kind,
            "start_time_unix_nano": str(span.start_time),
            "end_time_unix_nano": str(span.end_time),
            "attributes": span.attributes,
            "dropped_attributes_count": 0,
            "events": span.events,
            "dropped_events_count": 0,
            "links": [],
            "dropped_links_count": 0,
            "status": span.status
        }

    # for_otlp returns a table that can be protobuf-encoded for transmission over
    # OTLP.
    #
    # @param span The span to export
    # @return Table to be protobuf-encoded
    func for_otlp(span):
        var ret = for_export(span)
        ret.trace_id = hex2bytes(ret.trace_id)
        ret.span_id = hex2bytes(ret.span_id)
        ret.parent_span_id = hex2bytes(ret.parent_span_id)
        return ret

    # for_console renders a string representation of span for console output.
    #
    # @param span The span to export
    # @return String representation of span.
    func for_console(span):
        var ret = "\n---------------------------------------------------------\n"
        var ex = for_export(span)
        ex["resource_attributes"] = span.tracer.provider.resource.attrs
        ret += util.table_as_string(ex, 2)
        ret += "---------------------------------------------------------\n"
        return ret
