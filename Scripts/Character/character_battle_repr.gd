class_name CharacterRepresentation extends Node2D

@warning_ignore_start("unused_private_class_variable")

@onready var _character_texture: TextureRect = $TextureRect
@onready var _lifebar: ProgressBar = $ProgressBar
@onready var _lifebar_text: Label = $ProgressBar/Label

@onready var _level: Label = $ColorRect/Label

@warning_ignore_restore("unused_private_class_variable")
