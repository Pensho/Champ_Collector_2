class_name Character extends Node

const Types = preload("res://Scripts/Character/character_types.gd")

func Character() -> void:
	pass

# Preset Data
var m_Name: String = ""

var m_Rarity: Types.Rarity
var m_Faction: Types.Faction
var m_Role: Types.Role

var m_InstanceID : int = 0
var m_Experience : int = 0
var m_level: int = 1

var m_Skills: Array[Skill] = []

# Attributes
var m_Health: int = 0

var m_Speed: int = 0
var m_Attack: int = 0
var m_Defence: int = 0
var m_Accuracy: int = 0
var m_Resistance: int = 0
var m_Mysticism: int = 0
var m_Knowledge: int = 0
var m_Pressence: int = 0
var m_critChance: int = 0
var m_critDamage: int = 0
