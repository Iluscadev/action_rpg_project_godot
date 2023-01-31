extends KinematicBody2D

const EnemyDeathEffect = preload("res://Scenes/Enemys/EnemyDeathEffect.tscn")

export var ACCELETARION = 300
export var MAX_SPEED = 60
export var FRICTION = 200
export var WANDER_TARGET_DIFF = 4

enum {
	IDLE,
	WANDER,
	CHASE
}

var state = CHASE

var knockback = Vector2.ZERO
var velocity = Vector2.ZERO

onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var sprite = $AnimatedSprite
onready var hurtbox = $Hurtbox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController
onready var animationPlayer = $AnimationPlayer

func _ready():
	randomize()
	sprite.frame = rand_range(0, sprite.frames.get_frame_count("Fly")-1)
	state = pick_new_state([IDLE, WANDER])

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	knockback = move_and_slide(knockback)
	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()
			if wanderController.get_time_left() == 0:
				update_state()
			
		WANDER:
			seek_player()
			if wanderController.get_time_left() == 0 or global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_DIFF:
				update_state()
			var direction = global_position.direction_to(wanderController.target_position)
			velocity = velocity.move_toward(direction * MAX_SPEED, ACCELETARION * delta)
			
			sprite.flip_h = velocity.x < 0
			
		CHASE:
			var player = playerDetectionZone.player
			if player != null:
				var direction = global_position.direction_to(player.global_position)
				velocity = velocity.move_toward(direction * MAX_SPEED, ACCELETARION * delta)
			else:
				state = IDLE
				
			sprite.flip_h = velocity.x < 0 
			
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 400
	velocity = move_and_slide(velocity)
	
func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE
		
func update_state():
	state = pick_new_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 3))
		
func pick_new_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	knockback = area.knockback_vector * 115
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.6)
	
func show_death_effect():
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position
	
func _on_Stats_no_health():
	queue_free()
	show_death_effect()

func _on_Hurtbox_invincibility_started():
	animationPlayer.play("Start")

func _on_Hurtbox_invincibility_ended():
	animationPlayer.play("Stop")
