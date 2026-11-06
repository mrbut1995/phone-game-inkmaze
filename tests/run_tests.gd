extends SceneTree
## Zero-dependency test runner.
##   godot --headless --path . --import                                    (once, after adding class_name files)
##   godot --headless --path . -s res://tests/run_tests.gd
##   godot --headless --path . -s res://tests/run_tests.gd -- --filter=command_handler
## Exit code: 0 = all passed. 1 = at least one failure, or no tests were found.
## NOTE: engine "ERROR:" lines in the output must also be treated as failures (the runner cannot intercept them).

const TESTS_DIR: String = "res://tests"
const TEST_FILE_PREFIX: String = "test_"
const TEST_METHOD_PREFIX: String = "test_"
const FILTER_ARG: String = "--filter="

func _initialize() -> void:
	var exit_code: int = await _run_all()
	quit(exit_code)

func _run_all() -> int:
	var filter: String = _get_filter()
	var files: Array[String] = []
	_collect_test_files(TESTS_DIR, files)
	files.sort()

	var passed: int = 0
	var failed: int = 0
	var assertions: int = 0

	for path in files:
		var script := load(path) as GDScript
		if script == null:
			printerr("[ERROR] cannot load " + path)
			failed += 1
			continue
		for method_name in _get_test_methods(script):
			var label: String = "%s::%s" % [path.trim_prefix("res://"), method_name]
			if filter != "" and not label.contains(filter):
				continue
			var test = script.new()
			if not (test is TestCase):
				printerr("[ERROR] %s does not extend TestCase" % path)
				failed += 1
				break
			test.tree = self
			await test.call(&"before_each")
			await test.call(method_name)
			await test.call(&"after_each")
			test.cleanup()
			assertions += test.get_assert_count()
			var failures: Array[String] = test.get_failures()
			if failures.is_empty():
				passed += 1
				print("[PASS] ", label)
			else:
				failed += 1
				print("[FAIL] ", label)
				for failure in failures:
					print("       ", failure)

	var total: int = passed + failed
	print("")
	print("Tests: %d passed, %d failed, %d total (%d assertions)" % [passed, failed, total, assertions])
	if total == 0:
		printerr("[ERROR] no tests found")
		return 1
	return 1 if failed > 0 else 0

func _get_test_methods(script: GDScript) -> Array[StringName]:
	var result: Array[StringName] = []
	for method in script.get_script_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with(TEST_METHOD_PREFIX):
			result.append(StringName(method_name))
	result.sort()
	return result

func _collect_test_files(dir_path: String, out: Array[String]) -> void:
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.begins_with(TEST_FILE_PREFIX) and file_name.ends_with(".gd"):
			out.append(dir_path.path_join(file_name))
	for sub_dir in DirAccess.get_directories_at(dir_path):
		_collect_test_files(dir_path.path_join(sub_dir), out)

func _get_filter() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(FILTER_ARG):
			return arg.substr(FILTER_ARG.length())
	return ""
