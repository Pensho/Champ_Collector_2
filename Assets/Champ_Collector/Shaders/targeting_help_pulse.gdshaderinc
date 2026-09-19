// Shared by every targeting help highlight so zone rects and character outlines pulse in step.
const float TARGETING_HELP_PULSE_PERIOD = 1.6;
const float TARGETING_HELP_PULSE_MINIMUM_ALPHA = 0.25;
const float TARGETING_HELP_PULSE_MAXIMUM_ALPHA = 0.7;

float targeting_help_pulse(float time) {
	float wave = sin(time * TAU / TARGETING_HELP_PULSE_PERIOD) * 0.5 + 0.5;
	return mix(TARGETING_HELP_PULSE_MINIMUM_ALPHA, TARGETING_HELP_PULSE_MAXIMUM_ALPHA, wave);
}
