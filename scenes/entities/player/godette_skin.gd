extends Node3D

@onready var move_state_machine = $AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var attack_state_machine = $AnimationTree.get("parameters/AttackStateMachine/playback")
@onready var extra_animation = $AnimationTree.get_tree_root().get_node('ExtraAnimation')
@onready var face_material: StandardMaterial3D = $Rig/Skeleton3D/Godette_Head.get_surface_override_material(0)

var attacking := false
var squash_and_stretch := 1.0:
	set(value):
		squash_and_stretch = value
		var negative = 1.0 + (1.0 - squash_and_stretch)
		scale = Vector3(negative,squash_and_stretch,negative)
const faces = {
	'default': Vector3.ZERO,
	'blink': Vector3(0,0.5,0)
}
var rng = RandomNumberGenerator.new()


func set_move_state(state_name: String) -> void:
	move_state_machine.travel(state_name)


func attack() -> void:
	if not attacking:
		attack_state_machine.travel('Slice' if $SecondAttackTimer.time_left else 'Chop')
		$AnimationTree.set("parameters/AttackOneShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func attack_toggle(value: bool):
	attacking = value


func defend(forward: bool) -> void:
	var tween = create_tween()
	tween.tween_method(_defend_change, 1.0 - float(forward), float(forward), 0.25)


func _defend_change(value: float) -> void:
	$AnimationTree.set("parameters/ShieldBlend/blend_amount", value)


func switch_weapon(weapon_active: bool) -> void:
	if weapon_active:
		$Rig/Skeleton3D/RightHandSlot/Sword.show()
		$Rig/Skeleton3D/RightHandSlot/wand2.hide()
	else:
		$Rig/Skeleton3D/RightHandSlot/Sword.hide()
		$Rig/Skeleton3D/RightHandSlot/wand2.show()


func cast_spell() -> void:
	if not attacking:
		extra_animation.animation = 'Spellcast_Shoot'
		$AnimationTree.set("parameters/ExtraOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func shoot_magic() -> void:
	get_parent().shoot_magic($Rig/Skeleton3D/RightHandSlot/wand2/wand/Marker3D.global_position)


func hit() -> void:
	extra_animation.animation = 'Hit_A'
	$AnimationTree.set("parameters/ExtraOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	$AnimationTree.set("parameters/AttackOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	attacking = false
	var tween = create_tween()
	tween.tween_method(_hit_effect, 0.0, 0.5, 0.3)
	tween.tween_method(_hit_effect, 0.5, 0.0, 0.1)


func _hit_effect(value: float) -> void:
	$Rig/Skeleton3D/Godette_Body.material_overlay.set_shader_parameter('color', Color.FIREBRICK)
	$Rig/Skeleton3D/Godette_Body.material_overlay.set_shader_parameter('alpha', value)


func change_face(expression):
	face_material.uv1_offset = faces[expression]


func _on_blink_timer_timeout() -> void:
	change_face('blink')
	await get_tree().create_timer(0.2).timeout
	change_face('default')
	$BlinkTimer.wait_time = rng.randf_range(1.5, 3.0)


func can_damage(value: bool):
	$Rig/Skeleton3D/RightHandSlot/Sword.can_damage = value


func heal_tween() -> void:
	var tween = create_tween()
	tween.tween_method(_heal_effect, 0.0, 0.7, 0.5)
	tween.tween_method(_heal_effect, 0.7, 0.0, 0.2)


func _heal_effect(value: float) -> void:
	$Rig/Skeleton3D/Godette_Body.material_overlay.set_shader_parameter('color', Color.LIGHT_GREEN)
	$Rig/Skeleton3D/Godette_Body.material_overlay.set_shader_parameter('alpha', value)