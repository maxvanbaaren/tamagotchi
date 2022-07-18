extends KinematicBody2D

################################ movement 
enum {
	IDLE,
	WANDER
}

var velocity = Vector2.ZERO
var state = IDLE
var idle_timer_started = false

const ACCELERATION = 300
const MAX_SPEED = 50
const TOLERANCE = 4.0

onready var start_position = global_position
onready var target_position = global_position
################################

onready var anim = get_node("AnimationPlayer")
onready var timer = get_node("Timer") # sleep
onready var timer2 = get_node("Timer2") # idle 
onready var timer3 = get_node("Timer3") # eating/excercising animations 
onready var actions = get_node("Actions")
onready var label = get_node("Label")
var min_sleep_duration = 300 # 5 minutes 
var min_next_sleep = 600
var max_sleep_duration = 600
var max_next_sleep = 1200
var mood_interval = 3600
var idle_time = 10 # time spent between wandering 
var fitness # last time excercised 
var happiness
var hunger
var sad_hunger = 8 # hours it takes for slime to become sad 
var sad_fitness = 12
var sad_love = 4
var harvest_counter = 0 ################## needs to be saved?
var wants_love = "they look like they want to be pet"
var wants_food = "you can hear their belly growling"
var wants_excercise = "they look restless"
var unhelpful_hint = "they look unhappy"


#updates mood, starts sleep cycle
func start_slime():
	update_mood()
	var random_generator = RandomNumberGenerator.new()
	random_generator.randomize()
	var random = random_generator.randf_range(0,3)
	if random < 1:
		anim.play("Sleeping")
		random_generator.randomize()
		var sleep_time = random_generator.randf_range(min_sleep_duration, max_sleep_duration)
		print("sleeping for " + String(sleep_time) + " seconds")
		timer2.set_paused(true)
		timer.set_wait_time(sleep_time)
		timer.start()
	else:
		random_generator.randomize()
		var awake_time = random_generator.randf_range(min_next_sleep, max_next_sleep)
		print("awake for " + String(awake_time) + " seconds")
		timer.set_wait_time(awake_time)
		timer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
# check for right click
func _process(_delta):
	if Input.is_action_pressed("RightClick") && (anim.current_animation == "Idle" or anim.current_animation == "Idle_Happy" or anim.current_animation == "Idle_Sad"):
		actions.visible = false
		label.visible = false
		timer.set_paused(false)
		timer2.set_paused(false) 


# checks happiness, updates animation 
func update_mood():
	var timeDict = OS.get_datetime()
	var time = OS.get_unix_time_from_datetime(timeDict)
	print(timeDict)
	var hunger_difference = (time - hunger) / 3600
	var fitness_difference = (time - fitness) / 3600
	var happiness_difference = (time - happiness) / 3600
	print("hours since fed: " + String(hunger_difference))
	print("hours since excercised: " + String(fitness_difference))
	print("hours since loved: " + String(happiness_difference))
	if hunger_difference > sad_hunger or fitness_difference > sad_fitness or happiness_difference > sad_love or harvest_counter > 3:
		anim.play("Idle_Sad")
	elif hunger_difference > sad_hunger/4 or fitness_difference > sad_fitness/4 or happiness_difference > sad_love/4 or harvest_counter > 1:
		anim.play("Idle")
	else: 
		anim.play("Idle_Happy")


func feed():
	actions.visible = false
	label.visible = false
	anim.play("Eating")
	var time = OS.get_datetime()
	hunger = OS.get_unix_time_from_datetime(time)
	timer3.set_wait_time(5)
	timer3.start()


func love():
	actions.visible = false
	label.visible = false
	anim.play("Happy")
	yield(anim, "animation_finished")
	var time = OS.get_datetime()
	happiness = OS.get_unix_time_from_datetime(time)
	update_mood()
	timer.set_paused(false)
	timer2.set_paused(false)


func excercise():
	actions.visible = false
	label.visible = false
	anim.play("Excercising")
	var time = OS.get_datetime()
	fitness = OS.get_unix_time_from_datetime(time)
	timer3.set_wait_time(5)
	timer3.start()


# slime wakes up or goes to sleep, new timer starts
func _on_Timer_timeout():
	var random_generator = RandomNumberGenerator.new()
	random_generator.randomize()
	if anim.current_animation == "Sleeping":
		update_mood()
		var awake_time = random_generator.randf_range(min_next_sleep, max_next_sleep)
		print("awake for " + String(awake_time) + " seconds")
		timer2.set_paused(false)
		timer.set_wait_time(awake_time)
		timer.start()
	else:
		anim.play("Sleeping")
		var sleep_time = random_generator.randf_range(min_sleep_duration, max_sleep_duration)
		print("sleeping for " + String(sleep_time) + " seconds")
		timer2.set_paused(true)
		timer.set_wait_time(sleep_time)
		timer.start()


# food icon clicked
func _on_Food_input_event(_viewport, event, _shape_idx):
	if (event is InputEventMouseButton && event.pressed && actions.visible == true && Input.is_action_pressed("LeftClick")):
		print("Food Clicked")
		feed()


# love icon clicked
func _on_Love_input_event(_viewport, event, _shape_idx):
	if (event is InputEventMouseButton && event.pressed && actions.visible == true && Input.is_action_pressed("LeftClick")):
		print("Pet Clicked")
		love()


# excercise icon clicked
func _on_Excercise_input_event(_viewport, event, _shape_idx):
	if (event is InputEventMouseButton && event.pressed && actions.visible == true && Input.is_action_pressed("LeftClick")):
		print("Excercise Clicked")
		excercise()


# ends animations 
func _on_Timer3_timeout():
	update_mood()
	timer.set_paused(false)
	timer2.set_paused(false) 


################################################# movement 
func update_target_position():
	var target_vector = Vector2(rand_range(-100, 100), rand_range(-100, 100)) # -32, 32
	target_position = start_position + target_vector

func is_at_target_position(): 
	# Stop moving when at target +/- tolerance
	return (target_position - global_position).length() < TOLERANCE

func _physics_process(delta):
	match state:
		IDLE:
			velocity = Vector2(0, 0)
			if idle_timer_started == false:
				# print("starting idle timer")
				idle_timer_started = true
				timer2.set_wait_time(idle_time) 
				timer2.start()
		WANDER:
			accelerate_to_point(target_position, ACCELERATION * delta)
			if is_at_target_position():
				# print("reached target")
				state = IDLE
	velocity = move_and_slide(velocity)

func accelerate_to_point(point, acceleration_scalar):
	var direction = (point - global_position).normalized()
	var acceleration_vector = direction * acceleration_scalar
	accelerate(acceleration_vector)

func accelerate(acceleration_vector):
	velocity += acceleration_vector
	velocity = velocity.clamped(MAX_SPEED)
#############################################################


# slime clicked
func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if (event is InputEventMouseButton && event.pressed && Input.is_action_pressed("LeftClick") && (anim.current_animation == "Idle" or anim.current_animation == "Idle_Happy" or anim.current_animation == "Idle_Sad")):
		timer.set_paused(true)
		state = IDLE
		timer2.set_paused(true) 
		actions.visible = true
		# chooses label
		if anim.current_animation == "Idle_Sad":
			var random_generator = RandomNumberGenerator.new()
			random_generator.randomize()
			var random = random_generator.randf_range(0,2)
			if random < 1:
				label.text = unhelpful_hint
			else:
				var timeDict = OS.get_datetime()
				var time = OS.get_unix_time_from_datetime(timeDict)
				var hunger_difference = (time - hunger) / 3600
				var fitness_difference = (time - fitness) / 3600
				var happiness_difference = (time - happiness) / 3600
				if hunger_difference > sad_hunger:
					label.text = wants_food
				elif happiness_difference > sad_love:
					label.text = wants_love
				elif fitness_difference > sad_fitness:
					label.text = wants_excercise
		else: label.text = ""
		label.visible = true

# idle timer
func _on_Timer2_timeout():
	# print("wandering")
	update_target_position()
	state = WANDER
	idle_timer_started = false
