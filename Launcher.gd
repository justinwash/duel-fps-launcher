extends Control

@onready var http = $HTTPRequest

@onready var _version_label = $UI/BottomPanel/UpdatePanel/VBox/VersionLabel
@onready var _update_label = $UI/BottomPanel/UpdatePanel/VBox/UpdateLabel
@onready var _update_button = $UI/BottomPanel/UpdatePanel/VBox/UpdateButton

@onready var _play_button = $UI/BottomPanel/PlayPanel/VBox/PlayButton
@onready var _quit_button = $UI/BottomPanel/PlayPanel/VBox/QuitButton

var last_bytes = 0
var tick = 0

var checking_for_update = true
var downloading = false

var client_version = "None"
var current_version = "Checking for update..."
var up_to_date = false

var version_file_name = "user://duel-fps-version.txt"
var pck_file_name = "user://duel-fps.pck"

var game_scene_path = "res://Main.tscn"

var download_speed = "0 MB/s"


func _ready():
	if FileAccess.file_exists("user://duel-fps-version.txt"):
		var version_file = FileAccess.open(version_file_name, FileAccess.READ)
		client_version = version_file.get_line()
		print("Client version on startup: ", client_version if client_version else "Not downloaded")

	http.use_threads = true
	http.download_file = version_file_name
	http.connect("request_completed", self._on_version_request_completed)
	http.request("https://d2jy3mtl5cg8rl.cloudfront.net/duel-fps-version.txt")


func _physics_process(delta):
	if downloading && tick % 20 == 0:
		var speed_in_bytes = http.get_downloaded_bytes() - last_bytes
		var speed_in_mega_bytes = speed_in_bytes / 1000000.0

		_update_label.text = "Downloading: " + ("%.2f" % speed_in_mega_bytes) + " MB/s"

		last_bytes = http.get_downloaded_bytes()

	tick += 1


func _on_version_request_completed(result, response_code, headers, body):
	if !FileAccess.file_exists("user://duel-fps-version.txt"):
		return

	var version_file = FileAccess.open(version_file_name, FileAccess.READ)
	current_version = version_file.get_line()
	print("client version: ", client_version, ", current version: ", current_version)
	_version_label.text = client_version if FileAccess.file_exists("user://duel-fps.pck") else "Not downloaded"

	if client_version != current_version || !FileAccess.file_exists("user://duel-fps.pck"):
		_update_label.text = "Update available: " + current_version
		_update_button.disabled = false
	else:
		_update_label.text = "Up to date!"
		_version_label.text = "Client version: " + client_version
		up_to_date = true
		_play_button.disabled = false

	checking_for_update = false


func _download_new_version():
	_update_button.disabled = true
	http.disconnect("request_completed", self._on_version_request_completed)
	http.download_file = pck_file_name
	http.connect("request_completed", self._on_pck_request_completed)
	http.request("https://d2jy3mtl5cg8rl.cloudfront.net/duel-fps.pck")
	downloading = true


func _on_pck_request_completed(result, response_code, headers, body):
	downloading = false
	if response_code == 200:
		client_version = current_version
		print("Downloaded new game version: ", current_version)
		_version_label.text = "Client version: " + client_version
		_update_label.text = "Up to date!"
		_play_button.disabled = false
		_update_button.disabled = true
	else:
		print("Download of new game version failed: ", current_version)
		_version_label.text = "Not downloaded"
		_update_label.text = "Error: try updating again"
		_play_button.disabled = true
		_update_button.disabled = false


func _on_play_button_pressed():
	OS.create_instance(["--main-pack", OS.get_user_data_dir() + "/duel-fps.pck"])
	get_tree().quit()


func _on_quit_button_pressed():
	get_tree().quit()


func _on_update_button_pressed():
	_download_new_version()
