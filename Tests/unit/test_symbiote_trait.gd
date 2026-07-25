extends GutTest

var _trait: SymbioteTrait = null

func before_each() -> void:
	_trait = SymbioteTrait.new()

func test_init_sets_title_and_body() -> void:
	_trait.Init(Types.Rarity.Rare)
	assert_eq(_trait._title, "Graft")
	assert_ne(_trait._body, "")

func test_init_sets_a_trait_texture() -> void:
	_trait.Init(Types.Rarity.Rare)
	assert_not_null(_trait._trait_texture)

func test_registers_no_hooks() -> void:
	_trait.Init(Types.Rarity.Rare)
	assert_true(_trait._execution_steps.is_empty(),
			"The placeholder trait should have no combat behavior, only display text")
