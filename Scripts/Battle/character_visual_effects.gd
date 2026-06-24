class_name CharacterVisualEffects extends Node2D

@export var _source_texture_rect: TextureRect
@export var _echo_textures: Array[TextureRect]

func SetSpriteEchoes(p_count: int) -> void:
	for index in _echo_textures.size():
		if index < p_count:
			_echo_textures[index].texture = _source_texture_rect.texture
			_echo_textures[index].show()
		else:
			_echo_textures[index].hide()
