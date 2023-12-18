extends CharacterBody3D

@onready var head = $head
@onready var standing_collider = $standing_collider
@onready var crouching_collider = $crouching_collider
@onready var ray_cast_3d = $RayCast3D

var direction = Vector3.ZERO
var  CURRENT_SPEED = 5.0

const WALKING_SPEED = 5.0
const SPRINTING_SPEED = 8.0
const CROUCHING_SPEED = 3.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.25
const LERP_SPEED = 7.5
const CROUCHING_DEPTH = 0.5
const HEAD_POSITION = 1.75


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
		head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENSITIVITY))
		head.rotation.x = clamp(head.rotation.x,deg_to_rad(-89), deg_to_rad(89))
	
func _physics_process(delta):
	
	# Crouch and sprint
	if Input.is_action_pressed("crouch"):
		CURRENT_SPEED = CROUCHING_SPEED
		head.position.y = lerp(head.position.y, HEAD_POSITION - CROUCHING_DEPTH,delta*LERP_SPEED)
		standing_collider.disabled = true
		crouching_collider.disabled = false
	elif !ray_cast_3d.is_colliding():
		standing_collider.disabled = false
		crouching_collider.disabled = true
		head.position.y = lerp(head.position.y, HEAD_POSITION, delta*LERP_SPEED)
		if Input.is_action_pressed("sprint"):
			CURRENT_SPEED = SPRINTING_SPEED
		else:
			CURRENT_SPEED = WALKING_SPEED

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * LERP_SPEED) 
	if direction:
		velocity.x = direction.x * CURRENT_SPEED
		velocity.z = direction.z * CURRENT_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, CURRENT_SPEED)
		velocity.z = move_toward(velocity.z, 0, CURRENT_SPEED)

	move_and_slide()
