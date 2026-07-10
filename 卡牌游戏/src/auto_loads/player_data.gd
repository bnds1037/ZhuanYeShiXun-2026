extends Node

## 玩家持久数据（autoload: PlayerData）。
## 跨场景保存玩家的角色属性、牌组、手牌、弃牌堆、抽牌堆、遗物、
## 资源（金币/升级点）以及战斗/剧情历史。提供新游戏初始化、抽弃牌、
## 存档序列化等能力。

const MAX_DECK_SIZE: int = 30    ## 牌组最大卡牌数
const MAX_RELICS: int = 10       ## 可携带遗物上限

var character: CharacterBase = null       ## 玩家角色（HP/真气/护甲等）
var deck: Array[CardBase] = []            ## 玩家牌组（一局携带的全部卡）
var hand: Array[CardBase] = []            ## 当前手牌
var discard_pile: Array[CardBase] = []    ## 弃牌堆
var draw_pile: Array[CardBase] = []       ## 抽牌堆（洗牌后从此抽）
var relics: Array = []                       ## 已获得遗物列表
var current_act: int = 1                  ## 当前幕数
var current_level_id: String = ""         ## 当前所在关卡 id
var gold: int = 0                         ## 金币
var upgrade_points: int = 0               ## 卡牌升级点数
var battle_history: Array = []            ## 战斗结果历史（{victory, enemy_id, act}）
var story_choices: Array = []             ## 剧情选择历史（{choice_id, act}）


func _ready() -> void:
	# 创建默认角色（摸金传人，80 HP / 3 真气）
	character = CharacterBase.new()
	character.display_name = "摸金传人"
	character.max_hp = 80
	character.current_hp = 80
	character.max_mana = 3
	character.current_mana = 3


## 开始新游戏时清空所有进度并重置角色战斗状态。
func initialize_new_game() -> void:
	character.reset_for_battle()
	deck.clear()
	hand.clear()
	discard_pile.clear()
	draw_pile.clear()
	relics.clear()
	current_act = 1
	current_level_id = "level_1_outer_tomb"
	gold = 0
	upgrade_points = 0
	battle_history.clear()
	story_choices.clear()
	SignalBus.save_created.emit(0)


## 从 res://src/resources/cards/ 加载全部 .tres 卡牌作为初始牌组，并洗牌。
func load_starting_deck() -> void:
	var dir: DirAccess = DirAccess.open("res://src/resources/cards/")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var card: CardBase = load("res://src/resources/cards/" + file_name)
			if card is CardBase:
				deck.append(card)
		file_name = dir.get_next()
	dir.list_dir_end()
	shuffle_draw_pile()


## 抽 count 张牌到手牌；抽牌堆空了先洗弃牌堆，仍空则停止。
## 返回本次实际抽到的卡牌数组。
func draw_cards(count: int) -> Array[CardBase]:
	var drawn: Array[CardBase] = []
	for i in range(count):
		if draw_pile.is_empty():
			reshuffle_discard()
		if draw_pile.is_empty():
			break
		var card: CardBase = draw_pile.pop_back()
		hand.append(card)
		drawn.append(card)
		SignalBus.card_drawn.emit(card)
	return drawn


## 弃掉全部手牌到弃牌堆。
func discard_hand() -> void:
	for card in hand:
		discard_pile.append(card)
		SignalBus.card_discarded.emit(card)
	hand.clear()


## 弃掉指定手牌到弃牌堆。
func discard_card(card: CardBase) -> void:
	var idx: int = hand.find(card)
	if idx >= 0:
		hand.remove_at(idx)
		discard_pile.append(card)
		SignalBus.card_discarded.emit(card)


## 用牌组副本填充抽牌堆并洗牌（回合开始/新游戏时调用）。
func shuffle_draw_pile() -> void:
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	SignalBus.deck_shuffled.emit()


## 把弃牌堆洗入抽牌堆（抽牌堆空时自动触发）。
func reshuffle_discard() -> void:
	draw_pile = discard_pile.duplicate()
	draw_pile.shuffle()
	discard_pile.clear()
	SignalBus.deck_shuffled.emit()


## 向牌组添加一张卡（不超过 MAX_DECK_SIZE）。
func add_card_to_deck(card: CardBase) -> void:
	if deck.size() < MAX_DECK_SIZE:
		deck.append(card)


## 从牌组移除一张卡。
func remove_card_from_deck(card: CardBase) -> void:
	var idx: int = deck.find(card)
	if idx >= 0:
		deck.remove_at(idx)


## 获得一个遗物（不超过 MAX_RELICS）。
func add_relic(relic: Dictionary) -> void:
	if relics.size() < MAX_RELICS:
		relics.append(relic)


## 增加金币。
func add_gold(amount: int) -> void:
	gold += amount


## 增加升级点数。
func add_upgrade_points(amount: int) -> void:
	upgrade_points += amount


## 记录一场战斗结果到历史。
func record_battle_result(victory: bool, enemy_id: String) -> void:
	battle_history.append({"victory": victory, "enemy_id": enemy_id, "act": current_act})


## 记录一个剧情选择到历史。
func record_story_choice(choice_id: String) -> void:
	story_choices.append({"choice_id": choice_id, "act": current_act})


## 进入下一幕。
func advance_act() -> void:
	current_act += 1


## 序列化全部玩家数据为字典（供存档）。
func serialize() -> Dictionary:
	var deck_data: Array = []
	for card in deck:
		deck_data.append(card.serialize())
	var relic_data: Array = []
	for relic in relics:
		relic_data.append(relic)
	return {
		"character": character.serialize(),
		"deck": deck_data,
		"relics": relic_data,
		"current_act": current_act,
		"current_level_id": current_level_id,
		"gold": gold,
		"upgrade_points": upgrade_points,
		"battle_history": battle_history.duplicate(true),
		"story_choices": story_choices.duplicate(true),
	}


## 从字典反序列化恢复玩家数据（供读档）。
func deserialize(data: Dictionary) -> void:
	character.deserialize(data.get("character", {}))
	deck.clear()
	var deck_data: Array = data.get("deck", [])
	for card_data in deck_data:
		var card: CardBase = CardBase.new()
		card.deserialize(card_data)
		deck.append(card)
	relics = data.get("relics", [])
	current_act = data.get("current_act", 1)
	current_level_id = data.get("current_level_id", "")
	gold = data.get("gold", 0)
	upgrade_points = data.get("upgrade_points", 0)
	battle_history = data.get("battle_history", [])
	story_choices = data.get("story_choices", [])
