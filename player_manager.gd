extends Node

# 另起炉灶：专门用来存储玩家选中的英雄场景路径和名字
var selected_player_path: String = ""
var selected_player_name: String = ""

#  对应用“场景另存为”克隆出的三个场景路径
const HERO_1_PATH: String = "res://player_hero1.tscn"
const HERO_2_PATH: String = "res://player_hero2.tscn"
const HERO_3_PATH: String = "res://player_hero3.tscn"
