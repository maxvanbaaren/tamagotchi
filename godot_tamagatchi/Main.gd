extends Node2D

onready var timer = get_node("Timer")
onready var label = get_node("Label")
onready var slime = get_node("Slime")
onready var background = get_node("Background")
onready var beaker = get_node("Beaker")
onready var goo = get_node("Goo")
onready var goo_anim = get_node("Goo/AnimationPlayer")
onready var indicator = get_node("Indicator")
onready var indicator_anim = get_node("Indicator/AnimationPlayer")
onready var coin_label = get_node("Label3")
onready var finish = get_node("Label5")
onready var fail_timer = get_node("FailedHarvest")
var game_started = false
var age
var birth_date
#########harvest
var current_goo
var coins = 0
var harvesting = false
var harvests = 0
var failed_harvest = false


# Called when the node enters the scene tree for the first time.
func _ready():
	load_game()
	if game_started == false:
		print("starting new game")
		game_started = true
		var time = OS.get_datetime()
		birth_date = OS.get_unix_time_from_datetime(time)
		slime.fitness = birth_date
		slime.happiness = birth_date
		slime.hunger = birth_date
	update_age()
	slime.start_slime()


# updates age
func update_age():
	var time = OS.get_datetime()
	var u_time = OS.get_unix_time_from_datetime(time)
	age = int((u_time - birth_date)/86400)
	label.text = ("Age: " + String(age))
	timer.set_wait_time(86400)
	timer.start()


# age timer
func _on_Timer_timeout():
	print("updating age")
	update_age()


# saves state
func save():
	print("saving")
	var data = {
	"game started": true,
	"birth date": birth_date,
	"fitness": slime.fitness,
	"happiness": slime.happiness,
	"hunger": slime.hunger,
	"background": background.frame,
	"coins": coins
	}
	var save_file = File.new()
	save_file.open("user://savegame.save", File.WRITE)
	save_file.store_line(to_json(data))
	save_file.close()


# called when exiting window
func _on_Main_tree_exiting():
	save()


# loads state
func load_game():
	print("loading")
	var save_game = File.new()
	if not save_game.file_exists("user://savegame.save"):
		print("no save file found")
		return # Error! We don't have a save to load.
	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	save_game.open("user://savegame.save", File.READ)
	while save_game.get_position() < save_game.get_len():
		# Get the saved dictionary from the next line in the save file
		var node_data = parse_json(save_game.get_line())
		print(node_data)
		# change loaded variables 
		game_started = node_data["game started"]
		birth_date = node_data["birth date"]
		slime.fitness = node_data["fitness"]
		slime.happiness = node_data["happiness"]
		slime.hunger = node_data["hunger"]
		background.frame = node_data["background"]
		coins = node_data["coins"]
		coin_label.text = "Coins: " + String(coins)
	save_game.close()


# change bakcground color
func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if(event is InputEventMouseButton && event.pressed && Input.is_action_pressed("LeftClick")):
		if background.frame == 7:
			background.frame = 0
		else:
			background.frame = background.frame + 1


# harvest slime 
func _on_Area2D2_input_event(_viewport, event, _shape_idx):
	if(event is InputEventMouseButton && event.pressed && Input.is_action_pressed("LeftClick") && slime.anim.current_animation != "Sleeping"):
		if harvesting == false:
			harvesting = true
			harvests += 1
			beaker.visible = true
			goo.visible = true
			finish.visible = true
		else:
			var random_generator = RandomNumberGenerator.new()
			random_generator.randomize()
			var random = int(random_generator.randf_range(1,15))
			for _i in range(0, random):
				increase_goo()


# increase goo levels
func increase_goo():
	if goo.position.y - 5 < 340:
		goo.position = Vector2(goo.position.x, 340)
		# spill
		indicator_anim.play("Invisible")
		goo_anim.play("Spill")
		current_goo = 0
		failed_harvest = true
		finish_harvest()
	else:
		goo.position = Vector2(goo.position.x, goo.position.y - 4)
		if goo.position.y > 382 and goo.position.y <= 406:
			indicator_anim.play("Blink")
			indicator.position = Vector2(indicator.position.x, 466)
			current_goo = 1
		elif goo.position.y > 364 and goo.position.y <= 382:
			indicator_anim.play("Blink")
			indicator.position = Vector2(indicator.position.x, 442)
			current_goo = 2
		elif goo.position.y > 350 and goo.position.y <= 364:
			indicator_anim.play("Blink")
			indicator.position = Vector2(indicator.position.x, 423.5)
			current_goo = 3
		elif goo.position.y > 340 and goo.position.y <= 350:
			indicator_anim.play("Blink")
			indicator.position = Vector2(indicator.position.x, 409.7)
			current_goo = 5


# click finish
func _on_Area2D3_input_event(_viewport, event, _shape_idx):
	if(event is InputEventMouseButton && event.pressed && Input.is_action_pressed("LeftClick")):
		finish_harvest()


# finish harvest
func finish_harvest():
	if failed_harvest == true:
		slime.harvest_counter += 2
		fail_timer.set_wait_time(3)
		fail_timer.start()
	else:
		slime.harvest_counter += 1
		coins += current_goo
		current_goo = 0
		beaker.visible = false
		goo_anim.play("Idle")
		goo.visible = false
		goo.position = Vector2(goo.position.x, 466)
		indicator_anim.play("Invisible")
		coin_label.text = "Coins: " + String(coins)
		finish.visible = false
		harvesting = false 
	slime.update_mood()


# play fail animation for a few seconds
func _on_FailedHarvest_timeout():
	failed_harvest = false
	finish_harvest()
