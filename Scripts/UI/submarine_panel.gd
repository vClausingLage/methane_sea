extends CanvasLayer

const LAMP_ON := Color(0.79, 0.93, 0.72, 1.0)
const LAMP_OFF := Color(0.18, 0.23, 0.18, 0.8)
const CHROME_ON := Color(1, 1, 1, 1)
const CHROME_DIM := Color(0.38, 0.43, 0.41, 0.95)
const CONTROL_ACTIVE := Color(0.9, 1.0, 0.9, 1.0)
const CONTROL_IDLE := Color(0.72, 0.78, 0.74, 0.92)
const CONTROL_DISABLED := Color(0.27, 0.31, 0.3, 0.92)
const SONAR_ANGLE_TEXTURE_OFFSET := 180
const SOUND_PANEL_TAP := preload("res://Assets/Audio/Sub/Ship/hull_1.wav")
const SOUND_PANEL_CLUNK := preload("res://Assets/Audio/Sub/Ship/hull_2.wav")
const SOUND_PANEL_HEAVY := preload("res://Assets/Audio/Sub/Ship/hull_3.wav")
const SOUND_PANEL_READY := preload("res://Assets/Audio/Sub/Comms/sonar_contact.mp3")
const STARTUP_COMMS := {
	"generator": {
		"start": preload("res://Assets/Audio/Sub/Comms/Startup/T_start_generator.mp3"),
		"complete": preload("res://Assets/Audio/Sub/Comms/Startup/J_check_generator.mp3")
	},
	"cooling": {
		"start": preload("res://Assets/Audio/Sub/Comms/Startup/T_start_cooling_pumps.mp3"),
		"complete": preload("res://Assets/Audio/Sub/Comms/Startup/J_check_cooling_pumps.mp3")
	},
	"reactor": {
		"start": preload("res://Assets/Audio/Sub/Comms/Startup/T_start_reactor.mp3"),
		"complete": preload("res://Assets/Audio/Sub/Comms/Startup/J_check_reactor.mp3")
	},
	"diagnostics": {
		"start": preload("res://Assets/Audio/Sub/Comms/Startup/T_start_diagnosis.mp3"),
		"complete": preload("res://Assets/Audio/Sub/Comms/Startup/J_diagnosis_complete_green.mp3")
	}
}
const STARTUP_ORDER := [&"generator", &"cooling", &"reactor", &"diagnostics"]
const STARTUP_QUEUED_MESSAGES := {
	&"generator": "Closing generator relay...",
	&"cooling": "Spinning coolant pumps...",
	&"reactor": "Reactor startup sequence running...",
	&"diagnostics": "Running startup diagnostics..."
}
const STARTUP_READY_STATUS := {
	&"generator": "BUS OFFLINE\nClose generator relay to wake the boat.",
	&"cooling": "GENERATOR ONLINE\nStart reactor cooling.",
	&"reactor": "COOLANT STABLE\nStart reactor.",
	&"diagnostics": "REACTOR ONLINE\nRun diagnostics."
}
const STARTUP_COMPLETION_STATUS := {
	&"generator": "Generator bus online. Bring coolant pumps up.",
	&"cooling": "Coolant loop stable. Reactor can be started.",
	&"reactor": "Reactor online. Run system diagnostics.",
	&"diagnostics": "Diagnostics passed. Helm controls unlocked."
}
const STARTUP_SOUND_BY_STEP := {
	&"generator": "clunk",
	&"cooling": "clunk",
	&"reactor": "heavy",
	&"diagnostics": "ready"
}

@export_node_path("Node") var player_path: NodePath = ^"../Player"

var generator_online := false
var cooling_online := false
var reactor_online := false
var diagnostics_complete := false
var status_hold_time := 0.0
var startup_pending_step := ""
var startup_announcing_step := ""
var startup_pending_remaining := 0.0
var startup_pending_duration := 0.0
var panel_anim_time := 0.0
var press_feedback: Dictionary = {}
var panel_audio: AudioStreamPlayer

@onready var player: Node = get_node_or_null(player_path)
@onready var header_display: TextureRect = $Root/Dock/Shell/Padding/Content/TopRow/HeaderCluster/HeaderDisplay
@onready var monitor_rect: TextureRect = $Root/Dock/Shell/Padding/Content/MonitorSection/MonitorPadding/MonitorStack/MonitorRect
@onready var scope_overlay: Control = $Root/Dock/Shell/Padding/Content/MonitorSection/MonitorPadding/MonitorStack/MonitorRect/ScopeOverlay
@onready var status_label: Label = $Root/Dock/Shell/Padding/Content/MonitorSection/MonitorPadding/MonitorStack/StatusLabel
@onready var battery_readout: Label = $Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/TelemetryRow/BatteryCard/BatteryReadout
@onready var load_readout: Label = $Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/TelemetryRow/LoadCard/LoadReadout
@onready var aux_readout: Label = $Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/AuxStatusRow/AuxReadout

@onready var generator_button: TextureButton = $Root/Dock/Shell/Padding/Content/TopRow/HeaderCluster/StartupRack/StartupPadding/StartupStack/StartupGrid/GeneratorButton
@onready var cooling_button: TextureButton = $Root/Dock/Shell/Padding/Content/TopRow/HeaderCluster/StartupRack/StartupPadding/StartupStack/StartupGrid/CoolingButton
@onready var reactor_button: TextureButton = $Root/Dock/Shell/Padding/Content/TopRow/HeaderCluster/StartupRack/StartupPadding/StartupStack/StartupGrid/ReactorButton
@onready var diagnostics_button: TextureButton = $Root/Dock/Shell/Padding/Content/TopRow/HeaderCluster/StartupRack/StartupPadding/StartupStack/StartupGrid/DiagnosticsButton

@onready var lamp_generator: TextureRect = $Root/Dock/Shell/Padding/Content/TopRow/HeaderCluster/StartupRack/StartupPadding/StartupStack/StatusStrip/GeneratorStatus/LampGenerator
@onready var lamp_cooling: TextureRect = $Root/Dock/Shell/Padding/Content/TopRow/HeaderCluster/StartupRack/StartupPadding/StartupStack/StatusStrip/CoolingStatus/LampCooling
@onready var lamp_reactor: TextureRect = $Root/Dock/Shell/Padding/Content/TopRow/HeaderCluster/StartupRack/StartupPadding/StartupStack/StatusStrip/ReactorStatus/LampReactor
@onready var lamp_diagnostics: TextureRect = $Root/Dock/Shell/Padding/Content/TopRow/HeaderCluster/StartupRack/StartupPadding/StartupStack/StatusStrip/DiagnosticsStatus/LampDiagnostics
@onready var lamp_bus: TextureRect = $Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/AuxStatusRow/AuxLamps/LampBus
@onready var lamp_sonar: TextureRect = $Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/AuxStatusRow/AuxLamps/LampSonar
@onready var lamp_command: TextureRect = $Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/AuxStatusRow/AuxLamps/LampCommand

@onready var battery_lamps: Array[TextureRect] = [
	$Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/TelemetryRow/BatteryCard/BatteryLights/BatteryLamp1,
	$Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/TelemetryRow/BatteryCard/BatteryLights/BatteryLamp2,
	$Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/TelemetryRow/BatteryCard/BatteryLights/BatteryLamp3,
	$Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/TelemetryRow/BatteryCard/BatteryLights/BatteryLamp4,
	$Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/TelemetryRow/BatteryCard/BatteryLights/BatteryLamp5
]
@onready var load_lamps: Array[TextureRect] = [
	$Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/TelemetryRow/LoadCard/LoadLights/LoadLamp1,
	$Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/TelemetryRow/LoadCard/LoadLights/LoadLamp2,
	$Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/TelemetryRow/LoadCard/LoadLights/LoadLamp3,
	$Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/TelemetryRow/LoadCard/LoadLights/LoadLamp4,
	$Root/Dock/Shell/Padding/Content/TopRow/PowerColumn/TelemetrySection/TelemetryPadding/TelemetryContent/TelemetryRow/LoadCard/LoadLights/LoadLamp5
]

@onready var one_third_button: TextureButton = $Root/Dock/Shell/Padding/Content/ControlsSection/ControlsPadding/ControlsRow/ThrottleColumn/ThrottleGrid/OneThirdButton
@onready var two_third_button: TextureButton = $Root/Dock/Shell/Padding/Content/ControlsSection/ControlsPadding/ControlsRow/ThrottleColumn/ThrottleGrid/TwoThirdButton
@onready var full_button: TextureButton = $Root/Dock/Shell/Padding/Content/ControlsSection/ControlsPadding/ControlsRow/ThrottleColumn/ThrottleGrid/FullButton
@onready var flank_button: TextureButton = $Root/Dock/Shell/Padding/Content/ControlsSection/ControlsPadding/ControlsRow/ThrottleColumn/ThrottleGrid/FlankButton
@onready var reverse_button: TextureButton = $Root/Dock/Shell/Padding/Content/ControlsSection/ControlsPadding/ControlsRow/ThrottleColumn/ThrottleGrid/ReverseButton
@onready var stop_button: TextureButton = $Root/Dock/Shell/Padding/Content/ControlsSection/ControlsPadding/ControlsRow/ThrottleColumn/ThrottleGrid/StopButton
@onready var ascend_button: TextureButton = $Root/Dock/Shell/Padding/Content/ControlsSection/ControlsPadding/ControlsRow/DepthColumn/DepthGrid/AscendButton
@onready var hold_button: TextureButton = $Root/Dock/Shell/Padding/Content/ControlsSection/ControlsPadding/ControlsRow/DepthColumn/DepthGrid/HoldButton
@onready var descend_button: TextureButton = $Root/Dock/Shell/Padding/Content/ControlsSection/ControlsPadding/ControlsRow/DepthColumn/DepthGrid/DescendButton
@onready var sonar_button: TextureButton = $Root/Dock/Shell/Padding/Content/ControlsSection/ControlsPadding/ControlsRow/DepthColumn/DepthGrid/SonarButton
@onready var sonar_angle_button: TextureButton = $Root/Dock/Shell/Padding/Content/ControlsSection/ControlsPadding/ControlsRow/DepthColumn/DepthGrid/SonarAngleButton

var thrust_buttons: Dictionary
var depth_buttons: Dictionary
var startup_buttons: Array[TextureButton]
var helm_buttons: Array[TextureButton]
var startup_durations := {
	"generator": 1.2,
	"cooling": 0.9,
	"reactor": 1.5,
	"diagnostics": 1.1
}
var thrust_button_angles := {
	KEY_1: -32.0,
	KEY_2: -12.0,
	KEY_3: 10.0,
	KEY_4: 28.0,
	KEY_R: 150.0,
	KEY_S: 0.0
}
func _ready() -> void:
	$Root.mouse_filter = Control.MOUSE_FILTER_PASS
	thrust_buttons = {
		KEY_1: one_third_button,
		KEY_2: two_third_button,
		KEY_3: full_button,
		KEY_4: flank_button,
		KEY_R: reverse_button,
		KEY_S: stop_button
	}
	depth_buttons = {
		KEY_X: ascend_button,
		KEY_V: hold_button,
		KEY_Y: descend_button
	}
	startup_buttons = [generator_button, cooling_button, reactor_button, diagnostics_button]
	helm_buttons = [one_third_button, two_third_button, full_button, flank_button, reverse_button, stop_button, ascend_button, hold_button, descend_button, sonar_button, sonar_angle_button]
	for button in startup_buttons + helm_buttons:
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.pivot_offset = _get_button_pivot(button)
		press_feedback[button] = 0.0

	generator_button.pressed.connect(_queue_startup_step_request.bind(&"generator"))
	cooling_button.pressed.connect(_queue_startup_step_request.bind(&"cooling"))
	reactor_button.pressed.connect(_queue_startup_step_request.bind(&"reactor"))
	diagnostics_button.pressed.connect(_queue_startup_step_request.bind(&"diagnostics"))
	generator_button.pressed.connect(_mark_button_press.bind(generator_button, "heavy"))
	cooling_button.pressed.connect(_mark_button_press.bind(cooling_button, "clunk"))
	reactor_button.pressed.connect(_mark_button_press.bind(reactor_button, "heavy"))
	diagnostics_button.pressed.connect(_mark_button_press.bind(diagnostics_button, "ready"))

	one_third_button.pressed.connect(_issue_command.bind(KEY_1, "Ahead one third."))
	two_third_button.pressed.connect(_issue_command.bind(KEY_2, "Ahead two thirds."))
	full_button.pressed.connect(_issue_command.bind(KEY_3, "Full ahead."))
	flank_button.pressed.connect(_issue_command.bind(KEY_4, "Flank speed."))
	reverse_button.pressed.connect(_issue_command.bind(KEY_R, "Reverse thrusters."))
	stop_button.pressed.connect(_issue_command.bind(KEY_S, "Full stop."))
	ascend_button.pressed.connect(_issue_command.bind(KEY_X, "Ascending."))
	hold_button.pressed.connect(_issue_command.bind(KEY_V, "Holding depth."))
	descend_button.pressed.connect(_issue_command.bind(KEY_Y, "Diving."))
	sonar_button.pressed.connect(_issue_command.bind(KEY_I, "Sonar toggle queued."))
	for button in [one_third_button, two_third_button, full_button, flank_button, reverse_button, stop_button, ascend_button, hold_button, descend_button]:
		button.pressed.connect(_mark_button_press.bind(button, "tap"))
	sonar_button.pressed.connect(_mark_button_press.bind(sonar_button, "ready"))
	sonar_angle_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel_audio = AudioStreamPlayer.new()
	panel_audio.bus = "Master"
	panel_audio.volume_db = -18.0
	add_child(panel_audio)

	_refresh_ui()
	_apply_startup_to_player()


func _process(delta: float) -> void:
	panel_anim_time += delta
	status_hold_time = max(status_hold_time - delta, 0.0)
	_process_startup_transition(delta)
	_decay_press_feedback(delta)

	if player == null or not player.has_method("get_panel_state"):
		_animate_controls(KEY_NONE, KEY_NONE, false, 0.0, false)
		return

	var state: Dictionary = player.get_panel_state()
	_apply_player_state(state)


func _queue_startup_step_request(step: StringName) -> void:
	if _is_startup_busy():
		_set_status("Startup bus busy. Await current relay action.")
		return

	if _is_startup_step_complete(step):
		_set_status(_get_startup_already_online_message(step))
		return

	if not _can_start_startup_step(step):
		_set_status(_get_startup_blocked_message(step))
		return

	_queue_startup_step(String(step), String(STARTUP_QUEUED_MESSAGES.get(step, "Starting system...")))


func _issue_command(keycode: Key, message: String) -> void:
	if player == null:
		_set_status("Panel link to player is unavailable.")
		return

	if not diagnostics_complete:
		_set_status("Helm controls are offline. Complete startup first.")
		return

	var accepted: bool = player.issue_panel_command(keycode)
	if accepted:
		_set_status(message)
	else:
		_play_panel_sound("tap")
		_set_status("Command channel busy or offline.")


func _refresh_ui() -> void:
	var active_startup_step := _get_active_startup_step()
	_set_startup_button_state(generator_button, generator_online, active_startup_step in ["", "generator"] and not generator_online)
	_set_startup_button_state(cooling_button, cooling_online, active_startup_step in ["", "cooling"] and generator_online and not cooling_online)
	_set_startup_button_state(reactor_button, reactor_online, active_startup_step in ["", "reactor"] and cooling_online and not reactor_online)
	_set_startup_button_state(diagnostics_button, diagnostics_complete, active_startup_step in ["", "diagnostics"] and reactor_online and not diagnostics_complete)

	for button in helm_buttons:
		_set_control_state(button, false, diagnostics_complete and not _is_startup_busy())

	_set_lamp(lamp_generator, generator_online)
	_set_lamp(lamp_cooling, cooling_online)
	_set_lamp(lamp_reactor, reactor_online)
	_set_lamp(lamp_diagnostics, diagnostics_complete)

	header_display.modulate = CHROME_ON if generator_online else CHROME_DIM
	monitor_rect.modulate = CHROME_ON if reactor_online else CHROME_DIM

	var pending_step := _get_first_pending_startup_step()
	if pending_step != StringName():
		status_label.text = String(STARTUP_READY_STATUS[pending_step])


func _apply_startup_to_player() -> void:
	if player == null:
		return

	player.set_startup_state(generator_online, cooling_online, reactor_online, diagnostics_complete)


func _apply_player_state(state: Dictionary) -> void:
	if state.is_empty():
		return

	var battery_charge: float = float(state.get("battery_charge", 0.0))
	var current_draw: float = float(state.get("current_draw", 0.0))
	var speed_ratio: float = float(state.get("speed_ratio", 0.0))
	var sonar_online: bool = bool(state.get("sonar_online", false))
	var sonar_scan_degrees: float = float(state.get("sonar_scan_degrees", 0.0))
	var command_busy: bool = bool(state.get("command_locked", false))
	var controls_ready: bool = bool(state.get("controls_online", false))
	var active_thrust_key: Key = int(state.get("active_thrust_key", KEY_NONE))
	var active_depth_key: Key = int(state.get("active_depth_key", KEY_NONE))
	var last_command_key: Key = int(state.get("last_command_key", KEY_NONE))

	_set_lamp_count(battery_lamps, battery_charge)
	_set_lamp_count(load_lamps, current_draw)
	_set_lamp(lamp_bus, bool(state.get("generator_online", false)))
	_set_lamp(lamp_sonar, sonar_online)
	_set_lamp(lamp_command, command_busy)

	battery_readout.text = "BAT %02d%%" % int(round(battery_charge * 100.0))
	load_readout.text = "LOAD %02d%%" % int(round(current_draw * 100.0))
	aux_readout.text = "CTRL %s  SPD %02d%%" % ["READY" if controls_ready else "LOCK", int(round(speed_ratio * 100.0))]

	if scope_overlay and scope_overlay.has_method("set_levels"):
		scope_overlay.call("set_levels", battery_charge, current_draw, speed_ratio)

	for keycode in thrust_buttons.keys():
		var button: TextureButton = thrust_buttons[keycode] as TextureButton
		var is_pending: bool = command_busy and keycode == last_command_key
		_set_control_state(button, keycode == active_thrust_key or is_pending, controls_ready)

	for keycode in depth_buttons.keys():
		var button: TextureButton = depth_buttons[keycode] as TextureButton
		var is_pending: bool = command_busy and keycode == last_command_key
		_set_control_state(button, keycode == active_depth_key or is_pending, controls_ready)

	_set_control_state(sonar_button, sonar_online or (command_busy and last_command_key == KEY_I), controls_ready)
	_set_control_state(sonar_angle_button, sonar_online, controls_ready)
	_animate_controls(active_thrust_key, active_depth_key, sonar_online, sonar_scan_degrees, command_busy)
	_animate_startup_feedback()

	if status_hold_time > 0.0:
		return

	if not controls_ready:
		var pending_step := _get_first_pending_startup_step()
		if pending_step != StringName():
			status_label.text = String(STARTUP_READY_STATUS[pending_step])
		return

	if command_busy:
		status_label.text = "COMMAND PIPELINE BUSY\nAwait helm acknowledgement."
	elif sonar_online:
		status_label.text = "SYSTEMS NOMINAL\nSonar energized. Helm ready."
	else:
		status_label.text = "SYSTEMS NOMINAL\nHelm ready. Sonar is offline."


func _set_startup_button_state(button: TextureButton, is_active: bool, is_enabled: bool) -> void:
	_set_control_state(button, is_active, is_enabled)


func _set_control_state(button: TextureButton, is_active: bool, is_enabled: bool) -> void:
	if button == null:
		return

	if not is_enabled:
		button.modulate = CONTROL_DISABLED
	elif is_active:
		button.modulate = CONTROL_ACTIVE
	else:
		button.modulate = CONTROL_IDLE


func _set_lamp(lamp: TextureRect, is_on: bool) -> void:
	if lamp == null:
		return
	lamp.modulate = LAMP_ON if is_on else LAMP_OFF


func _set_lamp_count(lamps: Array[TextureRect], normalized_value: float) -> void:
	var lit_count: int = int(round(clamp(normalized_value, 0.0, 1.0) * float(lamps.size())))
	for index in range(lamps.size()):
		_set_lamp(lamps[index], index < lit_count)


func _set_status(message: String) -> void:
	status_label.text = message
	status_hold_time = 2.4


func _begin_startup_step(step: String, message: String) -> void:
	if _is_startup_busy():
		return

	startup_pending_step = step
	startup_pending_duration = float(startup_durations.get(step, 1.0))
	startup_pending_remaining = startup_pending_duration
	_set_status(message)
	_refresh_ui()


func _queue_startup_step(step: String, message: String) -> void:
	if _is_startup_busy():
		return

	startup_announcing_step = step
	_set_status(message)
	_refresh_ui()

	var speech_length := _play_startup_comms(step, "start")
	if speech_length > 0.0:
		await get_tree().create_timer(speech_length).timeout

	if startup_announcing_step != step or startup_pending_step != "":
		return

	startup_announcing_step = ""
	_begin_startup_step(step, message)


func _process_startup_transition(delta: float) -> void:
	if startup_pending_step == "":
		return

	startup_pending_remaining = max(startup_pending_remaining - delta, 0.0)
	if startup_pending_remaining > 0.0:
		return

	_complete_startup_step(StringName(startup_pending_step))

	startup_pending_step = ""
	startup_pending_duration = 0.0
	startup_pending_remaining = 0.0
	_refresh_ui()
	_apply_startup_to_player()


func _animate_startup_feedback() -> void:
	var flicker_phase: float = sin(panel_anim_time * 18.0) * 0.5 + 0.5
	var pending_intensity: bool = flicker_phase > 0.35
	var active_startup_step := _get_active_startup_step()

	if active_startup_step == "generator":
		_set_lamp(lamp_generator, pending_intensity)
	elif active_startup_step == "cooling":
		_set_lamp(lamp_cooling, pending_intensity)
	elif active_startup_step == "reactor":
		_set_lamp(lamp_reactor, pending_intensity)
	elif active_startup_step == "diagnostics":
		_set_lamp(lamp_diagnostics, pending_intensity)

	_apply_button_flicker(generator_button, active_startup_step == "generator")
	_apply_button_flicker(cooling_button, active_startup_step == "cooling")
	_apply_button_flicker(reactor_button, active_startup_step == "reactor")
	_apply_button_flicker(diagnostics_button, active_startup_step == "diagnostics")


func _apply_button_flicker(button: TextureButton, is_pending: bool) -> void:
	if not is_pending:
		return
	var pulse: float = 0.72 + (sin(panel_anim_time * 14.0) * 0.5 + 0.5) * 0.4
	button.modulate = Color(pulse, pulse, pulse * 0.92, 1.0)


func _animate_controls(active_thrust_key: Key, active_depth_key: Key, sonar_online: bool, sonar_scan_degrees: float, command_busy: bool) -> void:
	for keycode in depth_buttons.keys():
		var button: TextureButton = depth_buttons[keycode] as TextureButton
		var press_scale: float = 1.0 - _get_press_amount(button) * 0.06
		button.scale = button.scale.lerp(Vector2.ONE * (1.03 if keycode == active_depth_key else 1.0) * press_scale, 0.18)

	var sonar_scale: float = 1.0
	if sonar_online:
		sonar_scale = 1.04 + sin(panel_anim_time * 4.5) * 0.03
	elif command_busy:
		sonar_scale = 1.02 + sin(panel_anim_time * 7.0) * 0.02
	sonar_scale *= 1.0 - _get_press_amount(sonar_button) * 0.08
	sonar_button.scale = sonar_button.scale.lerp(Vector2.ONE * sonar_scale, 0.18)

	var target_sonar_angle := SONAR_ANGLE_TEXTURE_OFFSET
	if sonar_online:
		target_sonar_angle += sonar_scan_degrees
	sonar_angle_button.rotation_degrees = lerp_angle(sonar_angle_button.rotation_degrees, target_sonar_angle, 0.18)
	var sonar_angle_scale := 0.96
	if sonar_online:
		sonar_angle_scale = 1.02 + sin(panel_anim_time * 4.0) * 0.02
	sonar_angle_button.scale = sonar_angle_button.scale.lerp(Vector2.ONE * sonar_angle_scale, 0.18)

	for button in startup_buttons:
		var press_scale: float = 1.0 - _get_press_amount(button) * 0.05
		button.scale = button.scale.lerp(Vector2.ONE * press_scale, 0.18)


func _get_button_pivot(button: TextureButton) -> Vector2:
	if button == null:
		return Vector2.ZERO
	if button.custom_minimum_size != Vector2.ZERO:
		return button.custom_minimum_size * 0.5
	return button.size * 0.5


func _mark_button_press(button: TextureButton, sound_kind: String) -> void:
	if button == null:
		return
	press_feedback[button] = 1.0
	_play_panel_sound(sound_kind)


func _decay_press_feedback(delta: float) -> void:
	for button in press_feedback.keys():
		var value: float = float(press_feedback[button])
		press_feedback[button] = max(value - delta * 5.0, 0.0)


func _get_press_amount(button: TextureButton) -> float:
	return float(press_feedback.get(button, 0.0))


func _play_panel_sound(kind: String) -> void:
	if panel_audio == null:
		return

	match kind:
		"tap":
			panel_audio.stream = SOUND_PANEL_TAP
			panel_audio.volume_db = -20.0
		"clunk":
			panel_audio.stream = SOUND_PANEL_CLUNK
			panel_audio.volume_db = -18.0
		"heavy":
			panel_audio.stream = SOUND_PANEL_HEAVY
			panel_audio.volume_db = -16.0
		"ready":
			panel_audio.stream = SOUND_PANEL_READY
			panel_audio.volume_db = -22.0
		_:
			panel_audio.stream = SOUND_PANEL_TAP
			panel_audio.volume_db = -20.0

	panel_audio.play()


func _play_startup_comms(step: String, phase: String) -> float:
	if player == null:
		return 0.0

	var comms_data: Dictionary = STARTUP_COMMS.get(step, {})
	if comms_data.is_empty():
		return 0.0

	var line := comms_data.get(phase, null) as AudioStream
	if line == null:
		return 0.0

	player.play_comms_line(line)
	return line.get_length()


func _get_active_startup_step() -> String:
	if startup_announcing_step != "":
		return startup_announcing_step
	return startup_pending_step


func _is_startup_busy() -> bool:
	return _get_active_startup_step() != ""


func _get_first_pending_startup_step() -> StringName:
	for step in STARTUP_ORDER:
		match step:
			&"generator":
				if not generator_online:
					return step
			&"cooling":
				if not cooling_online:
					return step
			&"reactor":
				if not reactor_online:
					return step
			&"diagnostics":
				if not diagnostics_complete:
					return step

	return StringName()


func _complete_startup_step(step: StringName) -> void:
	match step:
		&"generator":
			generator_online = true
		&"cooling":
			cooling_online = true
		&"reactor":
			reactor_online = true
		&"diagnostics":
			diagnostics_complete = true
		_:
			return

	_play_panel_sound(String(STARTUP_SOUND_BY_STEP.get(step, "tap")))
	_play_startup_comms(String(step), "complete")
	_set_status(String(STARTUP_COMPLETION_STATUS.get(step, "Startup step complete.")))


func _is_startup_step_complete(step: StringName) -> bool:
	match step:
		&"generator":
			return generator_online
		&"cooling":
			return cooling_online
		&"reactor":
			return reactor_online
		&"diagnostics":
			return diagnostics_complete
		_:
			return false


func _can_start_startup_step(step: StringName) -> bool:
	match step:
		&"generator":
			return true
		&"cooling":
			return generator_online
		&"reactor":
			return cooling_online
		&"diagnostics":
			return reactor_online
		_:
			return false


func _get_startup_already_online_message(step: StringName) -> String:
	match step:
		&"generator":
			return "Generator bus is already online."
		&"cooling":
			return "Cooling loop is already stable."
		&"reactor":
			return "Reactor is already online."
		&"diagnostics":
			return "Diagnostics already passed."
		_:
			return "System already online."


func _get_startup_blocked_message(step: StringName) -> String:
	match step:
		&"generator":
			return ""
		&"cooling":
			return "Generator must be online before cooling."
		&"reactor":
			return "Cooling must be online before reactor startup."
		&"diagnostics":
			return "Reactor must be online before diagnostics."
		_:
			return "Startup step unavailable."
