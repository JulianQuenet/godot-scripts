extends CharacterBody3D

#Template refs
@onready var head = $neck/head
@onready var standing_collider = $standing_collider
@onready var crouching_collider = $crouching_collider
@onready var ray_cast_3d = $head_ray
@onready var neck = $neck
@onready var camera = $neck/head/eyes/camera
@onready var eyes = $neck/head/eyes

# Movement params
var direction = Vector3.ZERO
var  CURRENT_SPEED = 5.0

# State
var walking = false
var crouching = false
var sprinting = false
var panning = false
var sliding = false

# Timing contraints and slide params
var sliding_timer = 0.0
var sliding_timer_max = 1.0
var slide_vector = Vector2.ZERO
var sliding_speed = 10

# Head bob
const head_crouching_int = 0.05
const head_sprinting_int = 0.2
const head_walking_int = 0.1

const head_crouching_speed = 10
const head_sprinting_speed = 20
const head_walking_speed = 10

var head_vector = Vector2.ZERO
var head_bob_index = 0.0
var head_bob_current_int = 0.0


# Speeds and refs
const WALKING_SPEED = 5.0
const SPRINTING_SPEED = 8.0
const CROUCHING_SPEED = 3.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.25
const LERP_SPEED = 12.5
const CROUCHING_DEPTH = -0.5
const HEAD_POSITION = 1.75
const PANNING_TILT = 7.5


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# FPS function for camera
func _input(event):
	if event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if panning:
			neck.rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
			neck.rotation.y = clamp(neck.rotation.y,deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
		head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENSITIVITY))
		head.rotation.x = clamp(head.rotation.x,deg_to_rad(-89), deg_to_rad(89))

# Movement and player control function
func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	if Input.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Head bobbing logic
	if sprinting:
		head_bob_current_int = head_sprinting_int
		head_bob_index += head_sprinting_speed * delta
	elif walking:
		head_bob_current_int = head_walking_int
		head_bob_index += head_walking_speed * delta
	elif crouching:
		head_bob_current_int = head_crouching_int
		head_bob_index += head_crouching_speed * delta
	
	# Head bob logic implementation 
	
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_vector.y = sin(head_bob_index)
		head_vector.x = sin(head_bob_index/2) + 0.5
		
		eyes.position.y = lerp(eyes.position.y, head_vector.y *(head_bob_current_int/2),delta*LERP_SPEED )
		eyes.position.x = lerp(eyes.position.x, head_vector.x * head_bob_current_int,delta*LERP_SPEED )
	else:
		eyes.position.y = lerp(eyes.position.y , 0.0,delta*LERP_SPEED )
		eyes.position.x = lerp(eyes.position.x, 0.0,delta*LERP_SPEED )
	
	
	# Crouch and sprint
	if Input.is_action_pressed("crouch") || sliding:
		CURRENT_SPEED = CROUCHING_SPEED
		head.position.y = lerp(head.position.y,CROUCHING_DEPTH,delta*LERP_SPEED)
		standing_collider.disabled = true
		crouching_collider.disabled = false
		
		# SLide logic (begin)
		if sprinting && input_dir != Vector2.ZERO:
			slide_vector = input_dir
			sliding = true
			panning = true
			sliding_timer = sliding_timer_max
			
		
		
		walking = false
		crouching = true
		sprinting = false
		
	elif !ray_cast_3d.is_colliding():
		standing_collider.disabled = false
		crouching_collider.disabled = true
		head.position.y = lerp(head.position.y, 0.0, delta * LERP_SPEED)
		if Input.is_action_pressed("sprint"):
			CURRENT_SPEED = SPRINTING_SPEED
			walking = false
			crouching = false
			sprinting = true
		else:
			CURRENT_SPEED = WALKING_SPEED
			walking = true
			crouching = false
			sprinting = false
	
	# Panning
	if Input.is_action_pressed("pannig") || sliding:
		panning = true
		
		if sliding:
			camera.rotation.z = lerp(camera.rotation.z, -deg_to_rad(7.0), delta * LERP_SPEED)
		else:
			camera.rotation.z = -deg_to_rad(neck.rotation.y * PANNING_TILT)
	else:
		panning = false
		neck.rotation.y = lerp(neck.rotation.y,0.0,delta*LERP_SPEED)
		camera.rotation.z = lerp(camera.rotation.z, 0.0, delta * LERP_SPEED)
	
	# Sliding logic (end)
	if sliding:
		sliding_timer -= delta
		if sliding_timer <= 0:
			sliding = false
			panning = false
		
		
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		sliding = false

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * LERP_SPEED) 
	
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
	
	if direction:
		velocity.x = direction.x * CURRENT_SPEED
		velocity.z = direction.z * CURRENT_SPEED
		
		if sliding:
			velocity.x = direction.x * (sliding_timer + 0.1) * sliding_speed
			velocity.z = direction.z * (sliding_timer + 0.1) * sliding_speed
	else:
		velocity.x = move_toward(velocity.x, 0, CURRENT_SPEED)
		velocity.z = move_toward(velocity.z, 0, CURRENT_SPEED)

	move_and_slide()
