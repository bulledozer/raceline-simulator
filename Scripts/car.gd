extends Node3D

@export var accel: float
@export var brake: float

@export var cam_follow_speed: float
@export var cam_rot_speed: float

@export var tire_rot_speed: float

var trajectory: Curve3D
var speed_curve: Curve

var s = 0
var speed = 0

var time = 0

@onready var cam_stand = $CamStand
@onready var speed_label = $UI/Label
@onready var stream_player = $AudioStreamPlayer3D

@onready var time_label = $UI/time_label

@onready var LF_tire = $"scene/720s GT3/Tire-LF_n3d/Tire-LF_n3d2"
@onready var RF_tire = $"scene/720s GT3/Tire-RF_n3d"
@onready var LR_tire = $"scene/720s GT3/Tire-LR_n3d"
@onready var RR_tire = $"scene/720s GT3/Tire-RR_n3d"

func _ready() -> void:
	stream_player.playing = true

func _process(delta: float) -> void:
	cam_stand.position = lerp(cam_stand.position, position, cam_follow_speed*delta)
	cam_stand.rotation.y = lerp_angle(cam_stand.rotation.y, rotation.y, cam_rot_speed*delta)
	
	speed_label.visible = false
	stream_player.volume_db = -100
	
	time_label.visible = false
	
	if trajectory == null or speed_curve == null:
		return
	
	if trajectory.point_count == 0 or speed_curve.point_count == 0:
		return
	
	speed_label.visible = true
	speed_label.text = "%d km/h" % (speed*3.6)
	
	time_label.visible = true
	time_label.text = "%f s" % snapped(time, 0.01)
	
	stream_player.volume_db = -10
	
	speed = speed_curve.sample(s)
	s += speed*delta
	
	time += delta
	
	stream_player.pitch_scale = lerp(1.0,2.6, inverse_lerp(0, speed_curve.max_value, speed))
	
	if s > speed_curve.max_domain:
		s = 0
		time = 0
	
	var new_pos = trajectory.sample_baked(s)
	var dir = new_pos-self.position
	
	position = trajectory.sample_baked(s)
	look_at(position + dir)
	
