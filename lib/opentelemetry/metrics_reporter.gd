class_name MetricsInterface

# Adds an increment to a metric with the provided labels. This should be used
# with counter metrics
#
# @param metric The metric to increment
# @param increment The amount to increment the metric by
# @param labels The labels to use for the metric
# return nil
func add_to_counter(metric, increment, labels):
    return null

# Record a value for metric with provided labels. This should be used with
# histogram or distribution metrics.
#
# @param metric The metric to record a value for
# @param value The value to set for the metric
# @param labels The labels to use for the metric
# return nil
func record_value(metric, value, labels):
    return null

# Observe a value for a metric with provided labels. This corresponds to the
# gauge metric type in datadog
#
# @param metric The metric to record a value for
# @param value The value to set for the metric
# @param labels The labels to use for the metric
# return nil
func observe_value(metric, value, labels):
    return null
