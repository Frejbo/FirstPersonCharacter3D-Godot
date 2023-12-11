extends CharacterBody3D

## The sensitivity of camera movement.[br]Lower values means slower movements.
@export var MOUSE_SENSITIVITY : float = .5
## Automatically add actions to InputMap for movement and sprint
@export var add_input_actions : bool = true

# moving
@export_category("Movement")
## The fastest speed at which the character can WALK at.
@export var MAX_SPEED := 4.0
## The fastest speed at which the character can RUN at.
@export var MAX_SPRINT_SPEED := 8.0
var speed = MAX_SPEED
var running : bool = false
##  The acceleration from still to moving.[br]Lower values means slower acceleration.
@export var ACCELERATION := .15
##  The acceleration from moving to standing still.[br]Lower values means stopping faster.
@export var DEACCELERATION := 0.8

# jumping
@export_category("Jump")
## The height of which the character can jump.
@export var jump_height : float = 2.1
## The time it takes for the character to jump from ground to peak.
@export var jump_time_to_peak : float = 0.5
## The time it takes for the character to fall from peak to ground.
@export var jump_time_to_descent : float = 0.4

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak)
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak))
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent))

func get_gravity() -> float:
	if velocity.y < 0:
		return jump_gravity# * ProjectSettings.get_setting("physics/3d/default_gravity")
	else:
		return fall_gravity# * ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	switch_mouse_mode()
	
	if add_input_actions:
		InputMap.add_action("Sprint")
		var ev = InputEventKey.new()
		ev.keycode = KEY_SHIFT
		InputMap.action_add_event("Sprint", ev)
		

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	if running:
		speed = lerp(speed, MAX_SPRINT_SPEED, ACCELERATION)
	else:
		speed = lerp(speed, MAX_SPEED, DEACCELERATION)
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		var y := velocity.y
		velocity.y = 0
		velocity += (direction * (ACCELERATION * speed))
		velocity = velocity.limit_length(speed)
		velocity.y = y
		velocity = velocity.normalized() * velocity.length()
	else:
		# slowing down after key is released
		velocity.x *= DEACCELERATION
		velocity.z *= DEACCELERATION
	
	print(velocity.length())
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		switch_mouse_mode()
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look_around(event)
	
	running = Input.is_action_pressed("Sprint")

func switch_mouse_mode():
	match Input.mouse_mode:
		Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func look_around(event: InputEventMouseMotion):
	$rotation_helper.rotation.x = clamp($rotation_helper.rotation.x + deg_to_rad(event.relative.y * -MOUSE_SENSITIVITY), -1.5, 1.5)
	self.rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))
