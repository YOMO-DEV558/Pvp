--!native
--!nolint BuiltinGlobalWrite
--!nolint UnknownGlobal

repeat
	task.wait()
until game:IsLoaded()

local DUPE_MODE = false
local DUPE_RECIPIENT = "Sasware0x679"

local SecureRequest = require("./modules/secure_request.luau")
require("./modules/bypasses.luau")

local hookfunction = shared.SafeHook

if not LPH_OBFUSCATED then
	LPH_ENCNUM = function(toEncrypt, ...)
		assert(
			type(toEncrypt) == "number" and #{ ... } == 0,
			"LPH_ENCNUM only accepts a single constant double or integer as an argument."
		)
		return toEncrypt
	end
	LPH_NUMENC = LPH_ENCNUM

	LPH_ENCSTR = function(toEncrypt, ...)
		assert(
			type(toEncrypt) == "string" and #{ ... } == 0,
			"LPH_ENCSTR only accepts a single constant string as an argument."
		)
		return toEncrypt
	end
	LPH_STRENC = LPH_ENCSTR

	LPH_ENCFUNC = function(toEncrypt, encKey, decKey, ...)
		assert(
			type(toEncrypt) == "function" and type(encKey) == "string" and #{ ... } == 0,
			"LPH_ENCFUNC accepts a constant function, constant string, and string variable as arguments."
		)
		return toEncrypt
	end
	LPH_FUNCENC = LPH_ENCFUNC

	LPH_JIT = function(f, ...)
		assert(
			type(f) == "function" and #{ ... } == 0,
			"LPH_JIT only accepts a single constant function as an argument."
		)
		return f
	end
	LPH_JIT_MAX = LPH_JIT

	LPH_NO_VIRTUALIZE = function(f, ...)
		assert(
			type(f) == "function" and #{ ... } == 0,
			"LPH_NO_VIRTUALIZE only accepts a single constant function as an argument."
		)
		return f
	end

	LPH_NO_UPVALUES = function(f, ...)
		assert(type(setfenv) == "function", "LPH_NO_UPVALUES can only be used on Lua versions with getfenv & setfenv")
		assert(
			type(f) == "function" and #{ ... } == 0,
			"LPH_NO_UPVALUES only accepts a single constant function as an argument."
		)
		return f
	end

	LPH_CRASH = function(...)
		warn("LPH_CRASH INVOKED")
		assert(#{ ... } == 0, "LPH_CRASH does not accept any arguments.")
	end

	getgenv().Key = "yom123"
end

--#region Localizing globals
local type = type
local typeof = typeof
local pairs = pairs
local ipairs = ipairs
local table = table
local next = next
local string = string
local math = math
local math_max = math.max
local math_min = math.min
local math_sin = math.sin
local math_floor = math.floor
local os = os
local coroutine = coroutine
local coroutine_create = coroutine.create
local coroutine_resume = coroutine.resume
local coroutine_yield = coroutine.yield
local _coroutine_close = coroutine.close
local task = task
local task_wait = task.wait
local task_spawn = task.spawn
local task_defer = task.defer

--#endregion

local Storage = {
	Originals = {},
	OldHipHeight = 0,
	RayCastGuides = {},
	Panic = false,
	MoveDirection = Vector3.zero,
	ItemAuraConnections = {},
	MovementSpoof = false,
	SupressNotifications = false,
	Gun_Attributes = {
		{
			Name = "Disable Scopes",
			Attribute = "SniperScope",
			Type = "function",
			Function = function(Value: boolean, Self: Instance, Attribute: string)
				if game.HasTag(Self, "Gun") and Attribute == "SniperScope" then
					return true, not Value
				end
				return false, nil
			end,
		},
		-- { Name = "Accuracy", Type = "number", Max = 1, Min = 0.2 },
		-- { Name = "Automatic", Type = "boolean" },
		-- { Name = "FireRate", Type = "number", Max = 5000, Min = 100 },
		-- { Name = "Range", Type = "number", Max = 2000, Min = 50 },
		{ Name = "Recoil", Type = "number", Max = 5, Min = 0, Default = 0.1 },
		{ Name = "Zoom", Type = "number", Max = 5, Min = 0, Default = 1 },
	},
	Vehicle_Attributes = {
		{ Name = "acceleration", Type = "number", Min = 5, Max = 100, DisplayName = "Acceleration" },
		-- { Name = "forwardMaxSpeed", Type = "number", Min = 5, Max = 120, DisplayName = "Max Speed" },
		-- { Name = "maxSpeedTorque", Type = "number", Min = 1000, Max = 100000, DisplayName = "Max Speed Torque" },
		-- { Name = "minSpeedTorque", Type = "number", Min = 1000, Max = 100000, DisplayName = "Min. Speed Torque" },
		{ Name = "slipThreshold", Type = "number", Min = 10, Max = 100, DisplayName = "Slip Threshold" },
		{ Name = "staticFriction", Type = "number", Min = 1, Max = 10, DisplayName = "Static Friction" },
	},
	Blacklisted_Network_Calls = {
		["replicate_billboard_gui"] = true,
		["replicate_stamina_bar"] = true,
		["invalid_entry"] = true,
	},
	Teleport_Positions = {
		["Bike Shop"] = Vector3.new(256, 261, -206),
		["Burger Place"] = Vector3.new(113, 260, -212),
		["Gun Shop"] = Vector3.new(-140, 259, -221),
		["House"] = Vector3.new(124, 261, -393),
		["Hospital"] = Vector3.new(-133, 261, -555),
		["Dealer"] = Vector3.new(-222, 255, 388),
		["Car Dealership"] = Vector3.new(118, 260, 431),
		["Gas Station"] = Vector3.new(125, 258, 137),
		["Pawn Shop"] = Vector3.new(1177, 258, -535),
		["Spin Club"] = Vector3.new(1253, 260, -418),
	},
	Anti_Aim_Animation = nil,
	LastHackedATM = os.clock(),
	Initialized = false,
	CharacterConnections = {},
	UpdateGunStatsCallback = Instance.new("BindableEvent"),
	UpdateMeleeStatsCallback = Instance.new("BindableEvent"),
	GunModReferences = {
		["accuracy"] = "GunMods_S_Accuracy",
		["automatic"] = "GunMods_S_Automatic",
		["fire_rate"] = "GunMods_S_FireRate",
	},
	MeleeModReferences = {
		["cone_angle"] = "MeleeMods_S_ConeAngle",
		["range"] = "MeleeMods_S_Range",
		["speed"] = "MeleeMods_S_Speed",
	},
	FlyJumpConnection = nil,
	ServerStaminaGui = game:GetService("Players").LocalPlayer
		:WaitForChild("PlayerGui")
		:WaitForChild("TopRightHud")
		:WaitForChild("Holder")
		:WaitForChild("StaminaBar")
		:Clone(),
	LastKilledBy = nil,
	Connections = {},
	Routines = {},
	RarityColors = {
		["Common"] = Color3.fromRGB(255, 255, 255),
		["Uncommon"] = Color3.fromRGB(99, 255, 52),
		["Rare"] = Color3.fromRGB(51, 170, 255),
		["Epic"] = Color3.fromRGB(237, 44, 255),
		["Legendary"] = Color3.fromRGB(255, 150, 0),
		["Omega"] = Color3.fromRGB(255, 20, 51),
	},
}

-- Expose Storage globally for auxiliary modules/utilities
getgenv().BS_Storage = Storage

-- Name generator and helpers will be defined once below (single implementation in file)

local CurrentDate = os.date("*t")
local ExpirationDate = { year = 2026, month = 2, day = 15 }
local ExpirationTime = os.time(ExpirationDate)
local CurrentTime = os.time(CurrentDate)
local Executor = identifyexecutor()

-- Unique name generator for Storage registries
Storage.Connections.__counters = Storage.Connections.__counters or {}
Storage.Routines.__counters = Storage.Routines.__counters or {}
local function _nextKey(tbl: { [any]: any }, base: string): string
	local counters = rawget(tbl, "__counters")
	local n = (counters[base] or 0) + 1
	local key = base
	if rawget(tbl, base) ~= nil then
		key = (`%s#%d`):format(base, n)
	end
	while rawget(tbl, key) ~= nil do
		n += 1
		key = (`%s#%d`):format(base, n)
	end
	counters[base] = n
	return key
end

Storage.Routines[_nextKey(Storage.Routines, "ClockIntegrityCheck")] = task_spawn(function()
	-- To ensure os.clock hasn't been tampered with, we run it and wait to see if it's changed by the time we return.
	local StartTime = os.clock()
	task_wait(10)
	local EndTime = os.clock()

	if EndTime - StartTime < 5 then
		LPH_CRASH()
	end
end)

-- if CurrentTime >= ExpirationTime then
-- 	print("This script has expired. Please contact the developer for a new version.")
-- 	error("Script expired.")
-- 	return
-- end

local InitializedSignal = Instance.new("BindableEvent")
local START_TIME = os.clock()
local TELEPORT_SPEED_VEHICLE = 60
local TELEPORT_SPEED = 32
local PANIC_HEIGHT_THRESHOLD = 266
local PANIC_CONST_OFY = 255
local PANIC_DURATION = 25
local AUTO_HOP_INTERVAL = 60 * 5
local TELEPORT_SPEEDUP_TIME = 1
local TP_HEIGHT_OFFSET = 3
local SUPPORTED_VERSIONS = { "1.3.30", "1.3.31", "1.3.32", "1.3.33", "1.3.34", "1.3.35", "1.3.36", "1.3.37", "1.3.38", "1.3.40", "1.3.41" }
local Translator = require("./modules/Translation.luau")
local T = Translator.translate

local Version = "8.6.0"
local SubVersion = (not FREE_BUILD) and "Release [Paid]" or "Release [Free]"
local ORCHESTRATOR_MENU_ENABLED = false

shared.HOOKING_ENABLED = true

type MarkerObject = {
	Object: Part,
	Destroy: (self: MarkerObject) -> (),
	SetColor: (self: MarkerObject, Color: Color3) -> (),
	SetPosition: (self: MarkerObject, Position: Vector3) -> (),
}

-- Define a generic state type used by the ATM system.
type State<T> = {
	set: (self: State<T>, value: T) -> (),
	get: () -> T,
	-- Optional hook callback for state changes.
	hook: ((self: State<T>, newValue: T) -> ())?,
}

-- The internal state table for each ATM “class” object.
type ATM_ClassState = {
	fake_hacker_state_1: State<any>,
	fake_disabled_state_1: State<boolean>,
	fake_hack_tool_1: State<string>,
	start_hack: State<number>,
	disabled: State<boolean>,
	hacker: State<any>,
	active_hack_tool: State<string>,
	fake_hacker_state_2: State<Instance>,
	fake_disabled_state_2: State<boolean>,
	fake_hack_tool_2: State<string>,
}

-- The structure representing an individual ATM object.
type ATM_ClassObject = {
	instance: Model, -- The ATM's instance in the world.
	states: ATM_ClassState, -- Its state table.
}

--#region Initializing core functionality

if not rconsoleprint then
	rconsoleprint = function(...) end
end

if not rconsolewarn then
	rconsolewarn = function(...) end
end

if not rconsoledestroy then
	rconsoledestroy = function(...) end
end

local function G_Toggle(ToggleName: string): boolean
	if not getgenv().Library then
		repeat
			wait()
		until getgenv().Library
	end

	if not getgenv().Library.Toggles then
		repeat
			wait()
		until getgenv().Library.Toggles
	end

	if not getgenv().Library.Toggles[ToggleName] then
		return false
	end

	return getgenv().Library.Toggles[ToggleName].Value
end

local function G_Option(OptionName: string): any
	if not getgenv().Library then
		repeat
			wait()
		until getgenv().Library
	end

	if not getgenv().Library.Options then
		repeat
			wait()
		until getgenv().Library.Options
	end

	if not getgenv().Library.Options[OptionName] then
		repeat
			wait()
		until getgenv().Library.Options[OptionName]
	end

	return getgenv().Library.Options[OptionName].Value
end

local function G_Option_NYield(OptionName: string): any
	return getgenv().Library.Options[OptionName].Value
end

local function G_Toggle_NYield(ToggleName: string): any
	return getgenv().Library.Toggles[ToggleName].Value
end

local function UpdateStatus(Text)
	local statusLabel = rawget(shared, "StatusText")
	if statusLabel and statusLabel.Parent then
		statusLabel.Text = Text
	end
	task_wait(0.05)
end

local function SafeRequire(...)
	local OldThreadContext = getthreadcontext()
	setthreadcontext(2)
	local Result = require(...)
	setthreadcontext(OldThreadContext)
	return Result
end

local function GetBoundingBox(model, orientation): (CFrame, Vector3)
	if typeof(model) == "Instance" then
		model = model:GetDescendants()
	end
	if not orientation then
		orientation = CFrame.new()
	end
	local abs = math.abs
	local inf = math.huge

	local minx, miny, minz = inf, inf, inf
	local maxx, maxy, maxz = -inf, -inf, -inf

	for _, obj in pairs(model) do
		if obj:IsA("BasePart") then
			local cf = obj.CFrame
			cf = orientation:toObjectSpace(cf)
			local size = obj.Size
			local sx, sy, sz = size.X, size.Y, size.Z
		
