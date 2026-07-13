local runner = {}

local passed, failed = 0, 0
local failures = {}
local current_suite = "?"

function runner.suite(name)
	current_suite = name
	print("\n== " .. name .. " ==")
end

function runner.it(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed = passed + 1
		print("  ok   " .. name)
	else
		failed = failed + 1
		local msg = string.format("%s :: %s\n       %s", current_suite, name, tostring(err))
		failures[#failures + 1] = msg
		print("  FAIL " .. name)
		print("       " .. tostring(err))
	end
end

local function fail(msg, expected, actual)
	error(string.format("%s (expected %s, got %s)", msg, tostring(expected), tostring(actual)), 3)
end

function runner.eq(actual, expected, msg)
	if actual ~= expected then
		fail(msg or "values differ", expected, actual)
	end
end

function runner.truthy(actual, msg)
	if not actual then
		fail(msg or "expected truthy", "truthy", actual)
	end
end

function runner.falsy(actual, msg)
	if actual then
		fail(msg or "expected falsy", "falsy", actual)
	end
end

function runner.near(actual, expected, tolerance, msg)
	tolerance = tolerance or 0.001
	if type(actual) ~= "number" or math.abs(actual - expected) > tolerance then
		fail(msg or "numbers differ", expected, actual)
	end
end

function runner.report()
	print("\n----------------------------------------")
	print(string.format("passed: %d   failed: %d", passed, failed))
	if failed > 0 then
		print("\nFAILURES:")
		for _, f in ipairs(failures) do
			print("  " .. f)
		end
	end
	print("----------------------------------------")
	return failed == 0
end

return runner
