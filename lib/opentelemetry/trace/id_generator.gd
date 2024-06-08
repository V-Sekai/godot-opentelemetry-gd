extends RefCounted


static func new_span_id():
	var crypto = Crypto.new()
	var rand1 = crypto.generate_random_bytes(4).hex_encode()
	var rand2 = crypto.generate_random_bytes(4).hex_encode()
	return "%s%s" % [rand1, rand2]

static func new_ids():
	var crypto = Crypto.new()
	var rand1 = crypto.generate_random_bytes(4).hex_encode()
	var rand2 = crypto.generate_random_bytes(4).hex_encode()
	var rand3 = crypto.generate_random_bytes(4).hex_encode()
	var rand4 = crypto.generate_random_bytes(4).hex_encode()
	return "%s%s%s%s%s" % [rand1, rand2, rand3, rand4, new_span_id()]
