class_name TimerController
extends Node
## ============================================================================
## Controller: Quản lý thời gian chạy (Stopwatch hoặc Countdown).
## ============================================================================

signal time_updated(total_elapsed: float, floor_elapsed: float)
signal timeout

var total_elapsed: float = 0.0
var floor_elapsed: float = 0.0
var time_remaining: float = 0.0
var is_countdown: bool = false
var is_running: bool = false


func start_new_run() -> void:
	total_elapsed = 0.0
	floor_elapsed = 0.0
	is_countdown = false
	is_running = true
	time_updated.emit(total_elapsed, floor_elapsed)


func start_countdown(duration: float) -> void:
	is_countdown = true
	time_remaining = duration
	is_running = true
	time_updated.emit(time_remaining, time_remaining)


func start_floor() -> void:
	floor_elapsed = 0.0
	is_running = true
	if is_countdown:
		time_updated.emit(time_remaining, time_remaining)
	else:
		time_updated.emit(total_elapsed, floor_elapsed)


func pause() -> void:
	is_running = false


func resume() -> void:
	is_running = true


func stop() -> void:
	is_running = false


func tick(delta: float) -> void:
	if not is_running:
		return

	if is_countdown:
		time_remaining -= delta
		if time_remaining <= 0.0:
			time_remaining = 0.0
			is_running = false
			time_updated.emit(0.0, 0.0)
			timeout.emit()
			return
		time_updated.emit(time_remaining, time_remaining)
	else:
		total_elapsed += delta
		floor_elapsed += delta
		time_updated.emit(total_elapsed, floor_elapsed)
