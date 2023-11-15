extends Node3D

const ADS_LERP = 13
@export var default_position : Vector3
@export var ads_position : Vector3
@export var damage: int
@export var ammo: int
@export var max_ammo: int
@export var spare_ammo: int
@export var ammo_per_shot: int
@export var full_auto: bool
@export var reload_time: float
@export var firerate: float
@export var rayCast: NodePath
@onready var raycast = get_node(rayCast)

var can_fire = true
var reloading = false
@onready var camera = $".."
@onready var Anim = $AnimationPlayer
@onready var decal = preload("res://decal.tscn")

@export var vertical_angle : float = 5.0
@export var horizontal_angle : float = 0.05
@export var min_recoil_amount : float = 1.0
@export var max_recoil_amount : float = 2.0
var recoil_recovery_speed : float = 1.0



func _process(delta):
	recoil_recovery(delta)
	ADS(delta)
	if ammo <= 0:
		can_fire = false
	if Input.is_action_just_pressed("R") and not reloading and ammo < max_ammo:
		reload()
	if Input.is_action_pressed("fire") and can_fire and full_auto:
		fire()
		if not reloading and ammo <= 0: 
			reload()
	elif Input.is_action_just_pressed("fire") and can_fire and not full_auto:
		fire()
		if not reloading and ammo <= 0: 
			reload()



func fire():
	can_fire = false
	ammo -= ammo_per_shot
	if raycast.get_collider() != null and raycast.get_collider().is_in_group("enemy"):
		raycast.get_collider().hp -= damage
	if Anim != null:
		Anim.stop(true)
		Anim.play("Shoot")
	await get_tree().create_timer(firerate).timeout
	if raycast.is_colliding():
		var col_nor = raycast.get_collision_normal()
		var col_point = raycast.get_collision_point()
		var b = decal.instantiate()
		raycast.get_collider().add_child(b)
		b.global_transform.origin = col_point
		if col_nor == Vector3.DOWN:
			b.rotation_degrees.x = 90
		elif col_nor != Vector3.UP:
			b.look_at(col_point - col_nor, Vector3(0,1,0))
	if not reloading:
		can_fire = true
		recoil()
	force()


func recoil():
	var recoil_amount = randf_range(min_recoil_amount, max_recoil_amount)
	vertical_angle += recoil_amount
	horizontal_angle += randf_range(-recoil_amount, recoil_amount)

func recoil_recovery(delta):
	vertical_angle = lerp(vertical_angle, 0.0, recoil_recovery_speed * delta)
	horizontal_angle = lerp(horizontal_angle, 0.0, recoil_recovery_speed * delta)
	camera.rotation_degrees.x = vertical_angle
	camera.rotation_degrees.y = horizontal_angle

func reload():
	reloading = true
	can_fire = false
	if Anim != null:
		Anim.play("Reload")
	await get_tree().create_timer(reload_time).timeout
	if reloading == true:
		var ammo_to_add = min(max_ammo - ammo, spare_ammo)
		ammo += ammo_to_add
		spare_ammo -= ammo_to_add
	if ammo > 0:
		can_fire = true
	reloading = false


func ADS(delta):
	if Input.is_action_pressed("ADS"):
		transform.origin = transform.origin.lerp(ads_position, ADS_LERP * delta)
	else:
		transform.origin = transform.origin.lerp(default_position, ADS_LERP * delta)



func force():
	if raycast.get_collider() != null and raycast.get_collider() is RigidBody3D:
		var ray = raycast.get_collision_point()
		var body = raycast.get_collider()
		if body:
			var direction = (ray - global_transform.origin).normalized()
			body.apply_impulse(Vector3(direction.x, direction.y, direction.z) * 5)

