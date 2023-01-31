extends KinematicBody2D

const PlayerHurtSound = preload("res://Scenes/Player/PlayerHurtSound.tscn")

export var MAX_SPEED = 100
export var ACCELERATION = 800
export var FRICTION = 650
export var ROLL_SPEED = 125

enum {
	MOVE,
	ROLL,
	ATTACK
}

var state = MOVE
var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN
var stats = PlayerStats
var is_roll = false

onready var playerAnimation = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox
onready var blinkAnimationPlayer = $BlinkAnimatioPlayer

func _ready():
	stats.connect("no_health", self, "queue_free")
	animationTree.active = true
	swordHitbox.knockback_vector = roll_vector

func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
		ROLL:
			roll_state()
		ATTACK:
			attack_state()

func move_state(delta):
	var result = Vector2.ZERO
	
	result.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	result.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	result = result.normalized()
	
	if result != Vector2.ZERO: 
		roll_vector = result
		swordHitbox.knockback_vector = result
		animationTree.set("parameters/Idle/blend_position", result)
		animationTree.set("parameters/Running/blend_position", result)
		animationTree.set("parameters/Attack/blend_position", result)
		animationTree.set("parameters/Roll/blend_position", result)
		
		velocity = velocity.move_toward(result * MAX_SPEED, ACCELERATION * delta)
		
		animationState.travel("Running")
	else: 
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)	
		
		animationState.travel("Idle")
		
	move()
	
	if Input.is_action_just_pressed("roll"):
		state = ROLL
	
	if Input.is_action_just_pressed("attack"):
		state = ATTACK

func move():
	velocity = move_and_slide(velocity)

func roll_state():
	is_roll = true
	if !hurtbox.invincible:
		hurtbox.set_invincible(true)
	velocity = roll_vector * ROLL_SPEED
	animationState.travel("Roll")
	move()

func roll_state_finished():
	is_roll = false
	hurtbox.set_invincible(false)
	velocity = velocity * 0.7
	state = MOVE

func attack_state():
	velocity = Vector2.ZERO
	animationState.travel("Attack")
	
func attack_state_finished():
	state = MOVE
	
func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invincibility(1)
	hurtbox.create_hit_effect()
	blinkAnimationPlayer.play("Start")
	var playerHurtSound = PlayerHurtSound.instance()
	get_tree().current_scene.add_child(playerHurtSound)



func _on_Hurtbox_invincibility_started():
	if !is_roll:
		blinkAnimationPlayer.play("Start")


func _on_Hurtbox_invincibility_ended():
	if !is_roll:
		blinkAnimationPlayer.play("Stop")
