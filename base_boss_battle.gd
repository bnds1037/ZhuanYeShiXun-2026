extends Node2D

@export var boss_name: String = "未命名妖兽"

func _ready() -> void:
	print("【战斗系统】成功切入战斗！当前面对的强敌是: ", boss_name)
	# 💡 这里预留给你的队友以后编写具体的卡牌战斗界面
