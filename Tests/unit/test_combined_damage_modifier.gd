extends GutTest

# Coverage for CombinedDamageModifier's grouping rule (Concept_Document.md 1.1.3): contributions
# sharing a key add into one bucket, distinct keys multiply, and an empty modifier is a no-op.

func test_empty_modifier_has_a_product_of_one() -> void:
	var modifier: CombinedDamageModifier = CombinedDamageModifier.new()
	assert_almost_eq(modifier.Product(), 1.0, 0.0001)

func test_contributions_sharing_a_key_add() -> void:
	var modifier: CombinedDamageModifier = CombinedDamageModifier.new()
	modifier.Contribute(&"same_key", 0.2)
	modifier.Contribute(&"same_key", 0.3)
	# (1 + 0.2 + 0.3) = 1.5, a single factor.
	assert_almost_eq(modifier.Product(), 1.5, 0.0001)

func test_contributions_under_distinct_keys_multiply() -> void:
	var modifier: CombinedDamageModifier = CombinedDamageModifier.new()
	modifier.Contribute(&"key_a", 0.2)
	modifier.Contribute(&"key_b", 0.3)
	# (1 + 0.2) * (1 + 0.3) = 1.56, two independent factors.
	assert_almost_eq(modifier.Product(), 1.56, 0.0001)

func test_a_buckets_factor_clamps_at_zero() -> void:
	var modifier: CombinedDamageModifier = CombinedDamageModifier.new()
	modifier.Contribute(&"key_a", -0.6)
	modifier.Contribute(&"key_a", -0.9)
	# -1.5 would invert the sign of (1 + bucket); it must clamp at -1.0 instead.
	assert_almost_eq(modifier.Product(), 0.0, 0.0001)

func test_buckets_are_readable_for_presentation() -> void:
	var modifier: CombinedDamageModifier = CombinedDamageModifier.new()
	modifier.Contribute(&"key_a", 0.2)
	modifier.Contribute(&"key_a", 0.1)
	modifier.Contribute(&"key_b", 0.5)
	var buckets: Dictionary[StringName, float] = modifier.Buckets()
	assert_almost_eq(buckets[&"key_a"], 0.3, 0.0001)
	assert_almost_eq(buckets[&"key_b"], 0.5, 0.0001)
