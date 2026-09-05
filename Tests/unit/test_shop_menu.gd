extends GutTest

func test_format_shows_minutes_at_or_below_one_hour() -> void:
	assert_eq(ShopMenu.FormatRestockCountdown(3600), "60 minutes", "Exactly one hour should still show as minutes")
	assert_eq(ShopMenu.FormatRestockCountdown(90), "2 minutes", "Should round up to the next whole minute")


func test_format_shows_hours_past_one_hour() -> void:
	assert_eq(ShopMenu.FormatRestockCountdown(3601), "1h 0m", "Just past one hour should switch to hour formatting")
	assert_eq(ShopMenu.FormatRestockCountdown(5400), "1h 30m", "Should show the remaining minutes alongside the hour")
	assert_eq(ShopMenu.FormatRestockCountdown(90000), "25h 0m", "Should keep counting hours past a day")
