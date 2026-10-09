-- | UI by XeHigh Developer | x

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local win = {}

local Presets = {
	Dark = {
		Window = Color3.fromRGB(30, 33, 40), Sidebar = Color3.fromRGB(37, 41, 50),
		Card = Color3.fromRGB(41, 45, 54), Field = Color3.fromRGB(52, 57, 68),
		Stroke = Color3.fromRGB(60, 66, 78), Text = Color3.fromRGB(236, 239, 246),
		SubText = Color3.fromRGB(150, 157, 171), Off = Color3.fromRGB(72, 78, 92),
	},
	Midnight = {
		Window = Color3.fromRGB(14, 17, 26), Sidebar = Color3.fromRGB(19, 23, 35),
		Card = Color3.fromRGB(24, 29, 43), Field = Color3.fromRGB(33, 39, 57),
		Stroke = Color3.fromRGB(40, 47, 68), Text = Color3.fromRGB(230, 235, 248),
		SubText = Color3.fromRGB(134, 144, 170), Off = Color3.fromRGB(52, 60, 84),
	},
	Mocha = {
		Window = Color3.fromRGB(36, 31, 31), Sidebar = Color3.fromRGB(43, 37, 37),
		Card = Color3.fromRGB(50, 43, 43), Field = Color3.fromRGB(63, 54, 54),
		Stroke = Color3.fromRGB(72, 62, 62), Text = Color3.fromRGB(242, 235, 230),
		SubText = Color3.fromRGB(170, 158, 150), Off = Color3.fromRGB(88, 76, 76),
	},
	Light = {
		Window = Color3.fromRGB(244, 245, 248), Sidebar = Color3.fromRGB(231, 234, 240),
		Card = Color3.fromRGB(255, 255, 255), Field = Color3.fromRGB(236, 239, 244),
		Stroke = Color3.fromRGB(210, 215, 224), Text = Color3.fromRGB(28, 32, 40),
		SubText = Color3.fromRGB(110, 118, 132), Off = Color3.fromRGB(198, 204, 214),
	},
}
local PresetNames = { "Dark", "Midnight", "Mocha", "Light" }

local Accents = {
	Blue = Color3.fromRGB(41, 148, 255), Purple = Color3.fromRGB(150, 98, 255),
	Pink = Color3.fromRGB(255, 92, 160), Red = Color3.fromRGB(255, 82, 82),
	Orange = Color3.fromRGB(255, 150, 50), Green = Color3.fromRGB(52, 199, 100),
	Teal = Color3.fromRGB(40, 200, 200),
}
local AccentNames = { "Blue", "Purple", "Pink", "Red", "Orange", "Green", "Teal" }
local FONT_NAMES = { "Kanit", "Prompt" }
local DEFAULT_FONT_ASSETS = {
	Kanit = 12187373592,
	Prompt = 12187607287,
}
local FontFaceCache, FontWarnings = {}, {}

local function normalizeFontName(name)
	if type(name) ~= "string" then
		return nil
	end
	for _, fontName in ipairs(FONT_NAMES) do
		if string.lower(name) == string.lower(fontName) then
			return fontName
		end
	end
	return nil
end

local function normalizeFontAssetId(value)
	if type(value) == "number" then
		return value > 0 and math.floor(value) or nil
	end
	if type(value) == "string" then
		local id = string.match(value, "^%s*(%d+)%s*$") or string.match(value, "^rbxassetid://(%d+)$")
		return id and tonumber(id) or nil
	end
	return nil
end

local function resolveFontFace(name, weight, fallback, assetId)
	if not assetId then
		if not FontWarnings[name] then
			FontWarnings[name] = true
			warn("[MacUI] Font '" .. name .. "' needs a Roblox Font asset ID in FontAssets; falling back to Gotham.")
		end
		return Font.fromEnum(fallback)
	end
	local key = name .. ":" .. tostring(assetId) .. ":" .. weight.Name
	local face = FontFaceCache[key]
	if face == nil then
		local ok, result = pcall(function()
			return Font.fromId(assetId, weight, Enum.FontStyle.Normal)
		end)
		if ok and result then
			face = result
			FontFaceCache[key] = face
		else
			FontFaceCache[key] = false
			if not FontWarnings[key] then
				FontWarnings[key] = true
				warn("[MacUI] Could not load Font asset for '" .. name .. "'; falling back to Gotham. " .. tostring(result))
			end
			face = false
		end
	end
	if face then
		return face
	end
	return Font.fromEnum(fallback)
end

local function tween(inst, props, t)
	TweenService:Create(inst, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function New(className, props, children)
	local inst = Instance.new(className)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function Round(r)
	return New("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

-- fires on the very first press (no need to click twice)
local function onPress(btn, fn)
	btn.InputBegan:Connect(function(input)
		if isPress(input) then
			fn()
		end
	end)
end

local function animateButton(button, getAccent)
	local scale = New("UIScale", { Scale = 1, Parent = button })
	local hovered = false
	local pressId = 0

	local function setScale(value, duration, style)
		TweenService:Create(scale, TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = value,
		}):Play()
	end

	local function ripple(input)
		local width, height = button.AbsoluteSize.X, button.AbsoluteSize.Y
		if width <= 0 or height <= 0 then
			return
		end
		local x = math.clamp(input.Position.X - button.AbsolutePosition.X, 0, width)
		local y = math.clamp(input.Position.Y - button.AbsolutePosition.Y, 0, height)
		local radius = math.sqrt(math.max(x, width - x) ^ 2 + math.max(y, height - y) ^ 2)
		local diameter = radius * 2
		local color = getAccent and getAccent() or Color3.new(1, 1, 1)
		local layer = New("Frame", {
			Name = "RippleMask",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Size = UDim2.fromScale(1, 1),
			ZIndex = button.ZIndex + 1,
			Parent = button,
		})
		local corner = button:FindFirstChildOfClass("UICorner")
		if corner then
			corner:Clone().Parent = layer
		end
		local circle = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.62,
			BorderSizePixel = 0,
			ZIndex = layer.ZIndex,
			Parent = layer,
		}, { Round(100) })
		local expand = TweenService:Create(circle, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(diameter, diameter),
			BackgroundTransparency = 1,
		})
		expand:Play()
		task.delay(0.36, function()
			if layer.Parent then
				layer:Destroy()
			end
		end)
	end

	button.MouseEnter:Connect(function()
		hovered = true
		setScale(1.045, 0.16, Enum.EasingStyle.Back)
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		setScale(1, 0.14)
	end)
	button.InputBegan:Connect(function(input)
		if isPress(input) then
			pressId += 1
			setScale(0.94, 0.07)
			ripple(input)
		end
	end)
	button.InputEnded:Connect(function(input)
		if isPress(input) then
			local id = pressId
			setScale(hovered and 1.06 or 1.035, 0.11, Enum.EasingStyle.Back)
			task.delay(0.12, function()
				if button.Parent and id == pressId then
					setScale(hovered and 1.045 or 1, 0.13)
				end
			end)
		end
	end)
end

local function normalizeAsset(id)
	if id == nil or id == "" then
		return nil
	end
	id = tostring(id)
	if string.match(id, "^%d+$") then
		return "rbxassetid://" .. id
	end
	return id
end

----------------------------------------------------------------------
-- Local 16x16 drawings remain as a fallback when no Fluent asset is available.
----------------------------------------------------------------------
local IconDefs = {
	home = function(a)
		a.line(2.4, 7.1, 8, 2.5, 1.2); a.line(8, 2.5, 13.6, 7.1, 1.2)
		a.line(3.5, 6.4, 3.5, 13.6, 1.2); a.line(12.5, 6.4, 12.5, 13.6, 1.2)
		a.line(3.5, 13.6, 12.5, 13.6, 1.2); a.line(6.4, 13.6, 6.4, 9.5, 1.2); a.line(6.4, 9.5, 9.6, 9.5, 1.2); a.line(9.6, 9.5, 9.6, 13.6, 1.2)
	end,

	house = function(a)
		local stroke = 4 / 3
		a.line(2, 6.7, 8, 2, stroke); a.line(8, 2, 14, 6.7, stroke)
		a.line(2, 6.7, 2, 12.7, stroke); a.line(14, 6.7, 14, 12.7, stroke)
		a.line(2, 12.7, 2.4, 13.4, stroke); a.line(2.4, 13.4, 3.3, 14, stroke)
		a.line(3.3, 14, 6, 14, stroke); a.line(10, 14, 12.7, 14, stroke)
		a.line(12.7, 14, 13.6, 13.4, stroke); a.line(13.6, 13.4, 14, 12.7, stroke)
		a.line(6, 14, 6, 9.5, stroke); a.line(6, 9.5, 6.4, 8.9, stroke)
		a.line(6.4, 8.9, 7, 8.7, stroke); a.line(7, 8.7, 9, 8.7, stroke)
		a.line(9, 8.7, 9.6, 8.9, stroke); a.line(9.6, 8.9, 10, 9.5, stroke)
		a.line(10, 9.5, 10, 14, stroke)
	end,

	sprout = function(a)
		a.fill(2.2, 9.8, 2.2, 3.6, 0.7)
		a.fill(5.4, 7.2, 2.2, 6.2, 0.7)
		a.fill(8.6, 4.6, 2.2, 8.8, 0.7)
		a.line(11.2, 13.4, 13.6, 11.0, 1.15)
	end,

	bag = function(a)
		a.outline(3.0, 5.0, 10.0, 9.0, 2.0, 1.2)
		a.line(5.3, 5.0, 5.3, 3.7, 1.15); a.line(10.7, 5.0, 10.7, 3.7, 1.15); a.line(5.3, 3.7, 10.7, 3.7, 1.15)
		a.line(3.2, 8.0, 12.8, 8.0, 1.0)
	end,

	arrow = function(a)
		a.ring(8.8, 2.2, 3.0, 3.0, 1.5, 1.15)
		a.line(8.0, 6.0, 6.0, 9.0, 1.25)
		a.line(6.0, 9.0, 9.0, 10.2, 1.25)
		a.line(6.0, 8.8, 3.6, 11.8, 1.2)
		a.line(9.0, 10.2, 12.5, 12.8, 1.2)
		a.line(7.0, 7.1, 11.6, 6.2, 1.15)
	end,

	shield = function(a)
		a.line(8, 1.9, 12.5, 4.0, 1.2); a.line(12.5, 4.0, 11.7, 10.2, 1.2); a.line(11.7, 10.2, 8, 14.0, 1.2)
		a.line(8, 14.0, 4.3, 10.2, 1.2); a.line(4.3, 10.2, 3.5, 4.0, 1.2); a.line(3.5, 4.0, 8, 1.9, 1.2)
		a.line(6.0, 8.0, 7.3, 9.3, 1.1); a.line(7.3, 9.3, 10.2, 6.4, 1.1)
	end,

	dumbbell = function(a)
		a.ring(4.5, 4.0, 4.2, 7.0, 2.1, 1.15); a.ring(7.3, 4.0, 4.2, 7.0, 2.1, 1.15)
		a.line(8.0, 6.0, 8.0, 9.0, 1.15)
		a.line(2.4, 5.0, 2.4, 10.0, 1.15); a.line(13.6, 5.0, 13.6, 10.0, 1.15)
	end,

	pin = function(a)
		a.ring(3.2, 1.8, 9.6, 9.6, 4.8, 1.2)
		a.line(5.0, 9.5, 8.0, 14.0, 1.2); a.line(11.0, 9.5, 8.0, 14.0, 1.2)
		a.ring(6.6, 5.2, 2.8, 2.8, 1.4, 1.05)
	end,

	gear = function(a)
		a.ring(3.0, 3.0, 10.0, 10.0, 5.0, 1.2); a.ring(6.0, 6.0, 4.0, 4.0, 2.0, 1.1)
		a.line(8, 0.9, 8, 2.7, 1.15); a.line(8, 13.3, 8, 15.1, 1.15); a.line(0.9, 8, 2.7, 8, 1.15); a.line(13.3, 8, 15.1, 8, 1.15)
	end,

	user = function(a)
		a.ring(5.0, 1.8, 6.0, 6.0, 3.0, 1.2); a.ring(2.4, 9.0, 11.2, 6.0, 5.0, 1.2)
	end,

	sword = function(a)
		a.line(3.0, 13.0, 12.8, 3.2, 1.2); a.line(2.6, 10.1, 5.9, 13.4, 1.1); a.line(10.6, 5.4, 13.2, 2.8, 1.1)
	end,

	search = function(a)
		a.ring(1.9, 1.9, 8.6, 8.6, 4.3, 1.2); a.line(9.5, 9.5, 13.9, 13.9, 1.2)
	end,

	chevron = function(a)
		a.line(4.0, 5.8, 8.0, 9.9, 1.15); a.line(8.0, 9.9, 12.0, 5.8, 1.15)
	end,

	close = function(a)
		a.line(4.2, 4.2, 11.8, 11.8, 1.2); a.line(11.8, 4.2, 4.2, 11.8, 1.2)
	end,

	sidebar = function(a)
		a.outline(1.8, 3.0, 12.4, 10.0, 2.4, 1.2)
		a.line(6.2, 3.6, 6.2, 12.4, 1.1)
	end,

	left = function(a)
		a.line(10.2, 3.4, 5.4, 8.0, 1.6); a.line(5.4, 8.0, 10.2, 12.6, 1.6)
	end,

	right = function(a)
		a.line(5.8, 3.4, 10.6, 8.0, 1.6); a.line(10.6, 8.0, 5.8, 12.6, 1.6)
	end,

	updown = function(a)
		a.line(5.0, 6.4, 8.0, 3.6, 1.2); a.line(8.0, 3.6, 11.0, 6.4, 1.2)
		a.line(5.0, 9.6, 8.0, 12.4, 1.2); a.line(8.0, 12.4, 11.0, 9.6, 1.2)
	end,

	lock = function(a)
		a.outline(3.4, 7.0, 9.2, 6.8, 2.0, 1.2)
		a.line(5.6, 7.0, 5.6, 4.8, 1.2); a.line(10.4, 7.0, 10.4, 4.8, 1.2)
		a.line(5.6, 4.8, 6.6, 3.2, 1.2); a.line(6.6, 3.2, 9.4, 3.2, 1.2); a.line(9.4, 3.2, 10.4, 4.8, 1.2)
		a.fill(7.3, 9.2, 1.4, 2.2, 0.7)
	end,

	star = function(a)
		a.line(8, 1.8, 10, 6, 1.1); a.line(10, 6, 14.4, 6.5, 1.1); a.line(14.4, 6.5, 11.2, 9.5, 1.1)
		a.line(11.2, 9.5, 12, 14, 1.1); a.line(12, 14, 8, 11.8, 1.1); a.line(8, 11.8, 4, 14, 1.1)
		a.line(4, 14, 4.8, 9.5, 1.1); a.line(4.8, 9.5, 1.6, 6.5, 1.1); a.line(1.6, 6.5, 6, 6, 1.1); a.line(6, 6, 8, 1.8, 1.1)
	end,

	bolt = function(a)
		a.line(9.2, 1.8, 4.4, 9.0, 1.15); a.line(4.4, 9.0, 8.0, 9.0, 1.15); a.line(8.0, 9.0, 6.8, 14.2, 1.15)
		a.line(6.8, 14.2, 11.6, 7.0, 1.15); a.line(11.6, 7.0, 8.0, 7.0, 1.15); a.line(8.0, 7.0, 9.2, 1.8, 1.15)
	end,

	eye = function(a)
		a.ring(1.4, 4.4, 13.2, 7.2, 3.6, 1.2); a.ring(6.0, 6.2, 4.0, 4.0, 2.0, 1.1)
	end,

	folder = function(a)
		a.outline(2.0, 4.6, 12.0, 8.6, 2.0, 1.2)
		a.line(3.0, 4.6, 3.0, 3.6, 1.1); a.line(3.0, 3.6, 6.2, 3.6, 1.1); a.line(6.2, 3.6, 7.4, 4.6, 1.1)
	end,

	list = function(a)
		a.fill(2.0, 3.0, 2.0, 2.0, 0.8); a.fill(2.0, 7.0, 2.0, 2.0, 0.8); a.fill(2.0, 11.0, 2.0, 2.0, 0.8)
		a.line(6.0, 4.0, 13.5, 4.0, 1.1); a.line(6.0, 8.0, 13.5, 8.0, 1.1); a.line(6.0, 12.0, 13.5, 12.0, 1.1)
	end,
}

local IconAlias = {
	farming = "sprout", loadout = "bag", backpack = "bag", movement = "arrow", run = "arrow",
	equip = "shield", training = "dumbbell", travel = "pin", map = "pin", settings = "gear",
	character = "user", combat = "sword", swords = "sword",
	locked = "lock", favorite = "star", power = "bolt", visual = "eye", esp = "eye", files = "folder",
	cog = "gear", settings2 = "gear", player = "user", users = "user", person = "user", target = "pin",
	["map-pin"] = "pin", zap = "bolt", ["folder-open"] = "folder", unlock = "lock", key = "lock", flame = "bolt",
	sparkles = "star", ["sliders-horizontal"] = "gear", wrench = "gear", tool = "gear",
}

-- Lucide icon names are rendered with the closest built-in line drawing.
-- Use names such as "lucide:house" or "lucide-house"; no image asset is required.
local LucideIconAlias = {
	["arrow-left"] = "left", ["arrow-right"] = "right", ["arrow-down-up"] = "updown",
	["arrow-up-down"] = "updown", ["panel-left"] = "sidebar", ["panel-left-close"] = "sidebar",
	["chevron-down"] = "chevron", ["chevrons-up-down"] = "updown", x = "close",
	["circle-user-round"] = "user", ["user-round"] = "user", ["user-round-check"] = "user",
	["map-pinned"] = "pin", ["map-pin"] = "pin", locate = "pin",
	package = "bag", ["package-open"] = "bag", backpack = "bag",
	["shield-check"] = "shield", ["shield-plus"] = "shield",
	["settings-2"] = "gear", ["sliders-horizontal"] = "gear", ["sliders-vertical"] = "gear",
	["badge-check"] = "shield", check = "shield",
	["eye-off"] = "eye", ["folder-open"] = "folder", files = "folder",
	zap = "bolt", activity = "bolt", sparkles = "star", award = "star",
	leaf = "sprout", ["house-plus"] = "house", ["house-plug"] = "house",
	swords = "sword", crosshair = "pin", target = "pin",
	["list-checks"] = "list", ["list-plus"] = "list", ["clipboard-list"] = "list",
	["lock-keyhole"] = "lock", ["key-round"] = "lock", ["unlock-keyhole"] = "lock",
}

local FluentIconAssets = {
	["lucide-accessibility"] = "rbxassetid://10709751939",
	["lucide-activity"] = "rbxassetid://10709752035",
	["lucide-air-vent"] = "rbxassetid://10709752131",
	["lucide-airplay"] = "rbxassetid://10709752254",
	["lucide-alarm-check"] = "rbxassetid://10709752405",
	["lucide-alarm-clock"] = "rbxassetid://10709752630",
	["lucide-alarm-clock-off"] = "rbxassetid://10709752508",
	["lucide-alarm-minus"] = "rbxassetid://10709752732",
	["lucide-alarm-plus"] = "rbxassetid://10709752825",
	["lucide-album"] = "rbxassetid://10709752906",
	["lucide-alert-circle"] = "rbxassetid://10709752996",
	["lucide-alert-octagon"] = "rbxassetid://10709753064",
	["lucide-alert-triangle"] = "rbxassetid://10709753149",
	["lucide-align-center"] = "rbxassetid://10709753570",
	["lucide-align-center-horizontal"] = "rbxassetid://10709753272",
	["lucide-align-center-vertical"] = "rbxassetid://10709753421",
	["lucide-align-end-horizontal"] = "rbxassetid://10709753692",
	["lucide-align-end-vertical"] = "rbxassetid://10709753808",
	["lucide-align-horizontal-distribute-center"] = "rbxassetid://10747779791",
	["lucide-align-horizontal-distribute-end"] = "rbxassetid://10747784534",
	["lucide-align-horizontal-distribute-start"] = "rbxassetid://10709754118",
	["lucide-align-horizontal-justify-center"] = "rbxassetid://10709754204",
	["lucide-align-horizontal-justify-end"] = "rbxassetid://10709754317",
	["lucide-align-horizontal-justify-start"] = "rbxassetid://10709754436",
	["lucide-align-horizontal-space-around"] = "rbxassetid://10709754590",
	["lucide-align-horizontal-space-between"] = "rbxassetid://10709754749",
	["lucide-align-justify"] = "rbxassetid://10709759610",
	["lucide-align-left"] = "rbxassetid://10709759764",
	["lucide-align-right"] = "rbxassetid://10709759895",
	["lucide-align-start-horizontal"] = "rbxassetid://10709760051",
	["lucide-align-start-vertical"] = "rbxassetid://10709760244",
	["lucide-align-vertical-distribute-center"] = "rbxassetid://10709760351",
	["lucide-align-vertical-distribute-end"] = "rbxassetid://10709760434",
	["lucide-align-vertical-distribute-start"] = "rbxassetid://10709760612",
	["lucide-align-vertical-justify-center"] = "rbxassetid://10709760814",
	["lucide-align-vertical-justify-end"] = "rbxassetid://10709761003",
	["lucide-align-vertical-justify-start"] = "rbxassetid://10709761176",
	["lucide-align-vertical-space-around"] = "rbxassetid://10709761324",
	["lucide-align-vertical-space-between"] = "rbxassetid://10709761434",
	["lucide-anchor"] = "rbxassetid://10709761530",
	["lucide-angry"] = "rbxassetid://10709761629",
	["lucide-annoyed"] = "rbxassetid://10709761722",
	["lucide-aperture"] = "rbxassetid://10709761813",
	["lucide-apple"] = "rbxassetid://10709761889",
	["lucide-archive"] = "rbxassetid://10709762233",
	["lucide-archive-restore"] = "rbxassetid://10709762058",
	["lucide-armchair"] = "rbxassetid://10709762327",
	["lucide-arrow-big-down"] = "rbxassetid://10747796644",
	["lucide-arrow-big-left"] = "rbxassetid://10709762574",
	["lucide-arrow-big-right"] = "rbxassetid://10709762727",
	["lucide-arrow-big-up"] = "rbxassetid://10709762879",
	["lucide-arrow-down"] = "rbxassetid://10709767827",
	["lucide-arrow-down-circle"] = "rbxassetid://10709763034",
	["lucide-arrow-down-left"] = "rbxassetid://10709767656",
	["lucide-arrow-down-right"] = "rbxassetid://10709767750",
	["lucide-arrow-left"] = "rbxassetid://10709768114",
	["lucide-arrow-left-circle"] = "rbxassetid://10709767936",
	["lucide-arrow-left-right"] = "rbxassetid://10709768019",
	["lucide-arrow-right"] = "rbxassetid://10709768347",
	["lucide-arrow-right-circle"] = "rbxassetid://10709768226",
	["lucide-arrow-up"] = "rbxassetid://10709768939",
	["lucide-arrow-up-circle"] = "rbxassetid://10709768432",
	["lucide-arrow-up-down"] = "rbxassetid://10709768538",
	["lucide-arrow-up-left"] = "rbxassetid://10709768661",
	["lucide-arrow-up-right"] = "rbxassetid://10709768787",
	["lucide-asterisk"] = "rbxassetid://10709769095",
	["lucide-at-sign"] = "rbxassetid://10709769286",
	["lucide-award"] = "rbxassetid://10709769406",
	["lucide-axe"] = "rbxassetid://10709769508",
	["lucide-axis-3d"] = "rbxassetid://10709769598",
	["lucide-baby"] = "rbxassetid://10709769732",
	["lucide-backpack"] = "rbxassetid://10709769841",
	["lucide-baggage-claim"] = "rbxassetid://10709769935",
	["lucide-banana"] = "rbxassetid://10709770005",
	["lucide-banknote"] = "rbxassetid://10709770178",
	["lucide-bar-chart"] = "rbxassetid://10709773755",
	["lucide-bar-chart-2"] = "rbxassetid://10709770317",
	["lucide-bar-chart-3"] = "rbxassetid://10709770431",
	["lucide-bar-chart-4"] = "rbxassetid://10709770560",
	["lucide-bar-chart-horizontal"] = "rbxassetid://10709773669",
	["lucide-barcode"] = "rbxassetid://10747360675",
	["lucide-baseline"] = "rbxassetid://10709773863",
	["lucide-bath"] = "rbxassetid://10709773963",
	["lucide-battery"] = "rbxassetid://10709774640",
	["lucide-battery-charging"] = "rbxassetid://10709774068",
	["lucide-battery-full"] = "rbxassetid://10709774206",
	["lucide-battery-low"] = "rbxassetid://10709774370",
	["lucide-battery-medium"] = "rbxassetid://10709774513",
	["lucide-beaker"] = "rbxassetid://10709774756",
	["lucide-bed"] = "rbxassetid://10709775036",
	["lucide-bed-double"] = "rbxassetid://10709774864",
	["lucide-bed-single"] = "rbxassetid://10709774968",
	["lucide-beer"] = "rbxassetid://10709775167",
	["lucide-bell"] = "rbxassetid://10709775704",
	["lucide-bell-minus"] = "rbxassetid://10709775241",
	["lucide-bell-off"] = "rbxassetid://10709775320",
	["lucide-bell-plus"] = "rbxassetid://10709775448",
	["lucide-bell-ring"] = "rbxassetid://10709775560",
	["lucide-bike"] = "rbxassetid://10709775894",
	["lucide-binary"] = "rbxassetid://10709776050",
	["lucide-bitcoin"] = "rbxassetid://10709776126",
	["lucide-bluetooth"] = "rbxassetid://10709776655",
	["lucide-bluetooth-connected"] = "rbxassetid://10709776240",
	["lucide-bluetooth-off"] = "rbxassetid://10709776344",
	["lucide-bluetooth-searching"] = "rbxassetid://10709776501",
	["lucide-bold"] = "rbxassetid://10747813908",
	["lucide-bomb"] = "rbxassetid://10709781460",
	["lucide-bone"] = "rbxassetid://10709781605",
	["lucide-book"] = "rbxassetid://10709781824",
	["lucide-book-open"] = "rbxassetid://10709781717",
	["lucide-bookmark"] = "rbxassetid://10709782154",
	["lucide-bookmark-minus"] = "rbxassetid://10709781919",
	["lucide-bookmark-plus"] = "rbxassetid://10709782044",
	["lucide-bot"] = "rbxassetid://10709782230",
	["lucide-box"] = "rbxassetid://10709782497",
	["lucide-box-select"] = "rbxassetid://10709782342",
	["lucide-boxes"] = "rbxassetid://10709782582",
	["lucide-briefcase"] = "rbxassetid://10709782662",
	["lucide-brush"] = "rbxassetid://10709782758",
	["lucide-bug"] = "rbxassetid://10709782845",
	["lucide-building"] = "rbxassetid://10709783051",
	["lucide-building-2"] = "rbxassetid://10709782939",
	["lucide-bus"] = "rbxassetid://10709783137",
	["lucide-cake"] = "rbxassetid://10709783217",
	["lucide-calculator"] = "rbxassetid://10709783311",
	["lucide-calendar"] = "rbxassetid://10709789505",
	["lucide-calendar-check"] = "rbxassetid://10709783474",
	["lucide-calendar-check-2"] = "rbxassetid://10709783392",
	["lucide-calendar-clock"] = "rbxassetid://10709783577",
	["lucide-calendar-days"] = "rbxassetid://10709783673",
	["lucide-calendar-heart"] = "rbxassetid://10709783835",
	["lucide-calendar-minus"] = "rbxassetid://10709783959",
	["lucide-calendar-off"] = "rbxassetid://10709788784",
	["lucide-calendar-plus"] = "rbxassetid://10709788937",
	["lucide-calendar-range"] = "rbxassetid://10709789053",
	["lucide-calendar-search"] = "rbxassetid://10709789200",
	["lucide-calendar-x"] = "rbxassetid://10709789407",
	["lucide-calendar-x-2"] = "rbxassetid://10709789329",
	["lucide-camera"] = "rbxassetid://10709789686",
	["lucide-camera-off"] = "rbxassetid://10747822677",
	["lucide-car"] = "rbxassetid://10709789810",
	["lucide-carrot"] = "rbxassetid://10709789960",
	["lucide-cast"] = "rbxassetid://10709790097",
	["lucide-charge"] = "rbxassetid://10709790202",
	["lucide-check"] = "rbxassetid://10709790644",
	["lucide-check-circle"] = "rbxassetid://10709790387",
	["lucide-check-circle-2"] = "rbxassetid://10709790298",
	["lucide-check-square"] = "rbxassetid://10709790537",
	["lucide-chef-hat"] = "rbxassetid://10709790757",
	["lucide-cherry"] = "rbxassetid://10709790875",
	["lucide-chevron-down"] = "rbxassetid://10709790948",
	["lucide-chevron-first"] = "rbxassetid://10709791015",
	["lucide-chevron-last"] = "rbxassetid://10709791130",
	["lucide-chevron-left"] = "rbxassetid://10709791281",
	["lucide-chevron-right"] = "rbxassetid://10709791437",
	["lucide-chevron-up"] = "rbxassetid://10709791523",
	["lucide-chevrons-down"] = "rbxassetid://10709796864",
	["lucide-chevrons-down-up"] = "rbxassetid://10709791632",
	["lucide-chevrons-left"] = "rbxassetid://10709797151",
	["lucide-chevrons-left-right"] = "rbxassetid://10709797006",
	["lucide-chevrons-right"] = "rbxassetid://10709797382",
	["lucide-chevrons-right-left"] = "rbxassetid://10709797274",
	["lucide-chevrons-up"] = "rbxassetid://10709797622",
	["lucide-chevrons-up-down"] = "rbxassetid://10709797508",
	["lucide-chrome"] = "rbxassetid://10709797725",
	["lucide-circle"] = "rbxassetid://10709798174",
	["lucide-circle-dot"] = "rbxassetid://10709797837",
	["lucide-circle-ellipsis"] = "rbxassetid://10709797985",
	["lucide-circle-slashed"] = "rbxassetid://10709798100",
	["lucide-citrus"] = "rbxassetid://10709798276",
	["lucide-clapperboard"] = "rbxassetid://10709798350",
	["lucide-clipboard"] = "rbxassetid://10709799288",
	["lucide-clipboard-check"] = "rbxassetid://10709798443",
	["lucide-clipboard-copy"] = "rbxassetid://10709798574",
	["lucide-clipboard-edit"] = "rbxassetid://10709798682",
	["lucide-clipboard-list"] = "rbxassetid://10709798792",
	["lucide-clipboard-signature"] = "rbxassetid://10709798890",
	["lucide-clipboard-type"] = "rbxassetid://10709798999",
	["lucide-clipboard-x"] = "rbxassetid://10709799124",
	["lucide-clock"] = "rbxassetid://10709805144",
	["lucide-clock-1"] = "rbxassetid://10709799535",
	["lucide-clock-10"] = "rbxassetid://10709799718",
	["lucide-clock-11"] = "rbxassetid://10709799818",
	["lucide-clock-12"] = "rbxassetid://10709799962",
	["lucide-clock-2"] = "rbxassetid://10709803876",
	["lucide-clock-3"] = "rbxassetid://10709803989",
	["lucide-clock-4"] = "rbxassetid://10709804164",
	["lucide-clock-5"] = "rbxassetid://10709804291",
	["lucide-clock-6"] = "rbxassetid://10709804435",
	["lucide-clock-7"] = "rbxassetid://10709804599",
	["lucide-clock-8"] = "rbxassetid://10709804784",
	["lucide-clock-9"] = "rbxassetid://10709804996",
	["lucide-cloud"] = "rbxassetid://10709806740",
	["lucide-cloud-cog"] = "rbxassetid://10709805262",
	["lucide-cloud-drizzle"] = "rbxassetid://10709805371",
	["lucide-cloud-fog"] = "rbxassetid://10709805477",
	["lucide-cloud-hail"] = "rbxassetid://10709805596",
	["lucide-cloud-lightning"] = "rbxassetid://10709805727",
	["lucide-cloud-moon"] = "rbxassetid://10709805942",
	["lucide-cloud-moon-rain"] = "rbxassetid://10709805838",
	["lucide-cloud-off"] = "rbxassetid://10709806060",
	["lucide-cloud-rain"] = "rbxassetid://10709806277",
	["lucide-cloud-rain-wind"] = "rbxassetid://10709806166",
	["lucide-cloud-snow"] = "rbxassetid://10709806374",
	["lucide-cloud-sun"] = "rbxassetid://10709806631",
	["lucide-cloud-sun-rain"] = "rbxassetid://10709806475",
	["lucide-cloudy"] = "rbxassetid://10709806859",
	["lucide-clover"] = "rbxassetid://10709806995",
	["lucide-code"] = "rbxassetid://10709810463",
	["lucide-code-2"] = "rbxassetid://10709807111",
	["lucide-codepen"] = "rbxassetid://10709810534",
	["lucide-codesandbox"] = "rbxassetid://10709810676",
	["lucide-coffee"] = "rbxassetid://10709810814",
	["lucide-cog"] = "rbxassetid://10709810948",
	["lucide-coins"] = "rbxassetid://10709811110",
	["lucide-columns"] = "rbxassetid://10709811261",
	["lucide-command"] = "rbxassetid://10709811365",
	["lucide-compass"] = "rbxassetid://10709811445",
	["lucide-component"] = "rbxassetid://10709811595",
	["lucide-concierge-bell"] = "rbxassetid://10709811706",
	["lucide-connection"] = "rbxassetid://10747361219",
	["lucide-contact"] = "rbxassetid://10709811834",
	["lucide-contrast"] = "rbxassetid://10709811939",
	["lucide-cookie"] = "rbxassetid://10709812067",
	["lucide-copy"] = "rbxassetid://10709812159",
	["lucide-copyleft"] = "rbxassetid://10709812251",
	["lucide-copyright"] = "rbxassetid://10709812311",
	["lucide-corner-down-left"] = "rbxassetid://10709812396",
	["lucide-corner-down-right"] = "rbxassetid://10709812485",
	["lucide-corner-left-down"] = "rbxassetid://10709812632",
	["lucide-corner-left-up"] = "rbxassetid://10709812784",
	["lucide-corner-right-down"] = "rbxassetid://10709812939",
	["lucide-corner-right-up"] = "rbxassetid://10709813094",
	["lucide-corner-up-left"] = "rbxassetid://10709813185",
	["lucide-corner-up-right"] = "rbxassetid://10709813281",
	["lucide-cpu"] = "rbxassetid://10709813383",
	["lucide-croissant"] = "rbxassetid://10709818125",
	["lucide-crop"] = "rbxassetid://10709818245",
	["lucide-cross"] = "rbxassetid://10709818399",
	["lucide-crosshair"] = "rbxassetid://10709818534",
	["lucide-crown"] = "rbxassetid://10709818626",
	["lucide-cup-soda"] = "rbxassetid://10709818763",
	["lucide-curly-braces"] = "rbxassetid://10709818847",
	["lucide-currency"] = "rbxassetid://10709818931",
	["lucide-database"] = "rbxassetid://10709818996",
	["lucide-delete"] = "rbxassetid://10709819059",
	["lucide-diamond"] = "rbxassetid://10709819149",
	["lucide-dice-1"] = "rbxassetid://10709819266",
	["lucide-dice-2"] = "rbxassetid://10709819361",
	["lucide-dice-3"] = "rbxassetid://10709819508",
	["lucide-dice-4"] = "rbxassetid://10709819670",
	["lucide-dice-5"] = "rbxassetid://10709819801",
	["lucide-dice-6"] = "rbxassetid://10709819896",
	["lucide-dices"] = "rbxassetid://10723343321",
	["lucide-diff"] = "rbxassetid://10723343416",
	["lucide-disc"] = "rbxassetid://10723343537",
	["lucide-divide"] = "rbxassetid://10723343805",
	["lucide-divide-circle"] = "rbxassetid://10723343636",
	["lucide-divide-square"] = "rbxassetid://10723343737",
	["lucide-dollar-sign"] = "rbxassetid://10723343958",
	["lucide-download"] = "rbxassetid://10723344270",
	["lucide-download-cloud"] = "rbxassetid://10723344088",
	["lucide-droplet"] = "rbxassetid://10723344432",
	["lucide-droplets"] = "rbxassetid://10734883356",
	["lucide-drumstick"] = "rbxassetid://10723344737",
	["lucide-edit"] = "rbxassetid://10734883598",
	["lucide-edit-2"] = "rbxassetid://10723344885",
	["lucide-edit-3"] = "rbxassetid://10723345088",
	["lucide-egg"] = "rbxassetid://10723345518",
	["lucide-egg-fried"] = "rbxassetid://10723345347",
	["lucide-electricity"] = "rbxassetid://10723345749",
	["lucide-electricity-off"] = "rbxassetid://10723345643",
	["lucide-equal"] = "rbxassetid://10723345990",
	["lucide-equal-not"] = "rbxassetid://10723345866",
	["lucide-eraser"] = "rbxassetid://10723346158",
	["lucide-euro"] = "rbxassetid://10723346372",
	["lucide-expand"] = "rbxassetid://10723346553",
	["lucide-external-link"] = "rbxassetid://10723346684",
	["lucide-eye"] = "rbxassetid://10723346959",
	["lucide-eye-off"] = "rbxassetid://10723346871",
	["lucide-factory"] = "rbxassetid://10723347051",
	["lucide-fan"] = "rbxassetid://10723354359",
	["lucide-fast-forward"] = "rbxassetid://10723354521",
	["lucide-feather"] = "rbxassetid://10723354671",
	["lucide-figma"] = "rbxassetid://10723354801",
	["lucide-file"] = "rbxassetid://10723374641",
	["lucide-file-archive"] = "rbxassetid://10723354921",
	["lucide-file-audio"] = "rbxassetid://10723355148",
	["lucide-file-audio-2"] = "rbxassetid://10723355026",
	["lucide-file-axis-3d"] = "rbxassetid://10723355272",
	["lucide-file-badge"] = "rbxassetid://10723355622",
	["lucide-file-badge-2"] = "rbxassetid://10723355451",
	["lucide-file-bar-chart"] = "rbxassetid://10723355887",
	["lucide-file-bar-chart-2"] = "rbxassetid://10723355746",
	["lucide-file-box"] = "rbxassetid://10723355989",
	["lucide-file-check"] = "rbxassetid://10723356210",
	["lucide-file-check-2"] = "rbxassetid://10723356100",
	["lucide-file-clock"] = "rbxassetid://10723356329",
	["lucide-file-code"] = "rbxassetid://10723356507",
	["lucide-file-cog"] = "rbxassetid://10723356830",
	["lucide-file-cog-2"] = "rbxassetid://10723356676",
	["lucide-file-diff"] = "rbxassetid://10723357039",
	["lucide-file-digit"] = "rbxassetid://10723357151",
	["lucide-file-down"] = "rbxassetid://10723357322",
	["lucide-file-edit"] = "rbxassetid://10723357495",
	["lucide-file-heart"] = "rbxassetid://10723357637",
	["lucide-file-image"] = "rbxassetid://10723357790",
	["lucide-file-input"] = "rbxassetid://10723357933",
	["lucide-file-json"] = "rbxassetid://10723364435",
	["lucide-file-json-2"] = "rbxassetid://10723364361",
	["lucide-file-key"] = "rbxassetid://10723364605",
	["lucide-file-key-2"] = "rbxassetid://10723364515",
	["lucide-file-line-chart"] = "rbxassetid://10723364725",
	["lucide-file-lock"] = "rbxassetid://10723364957",
	["lucide-file-lock-2"] = "rbxassetid://10723364861",
	["lucide-file-minus"] = "rbxassetid://10723365254",
	["lucide-file-minus-2"] = "rbxassetid://10723365086",
	["lucide-file-output"] = "rbxassetid://10723365457",
	["lucide-file-pie-chart"] = "rbxassetid://10723365598",
	["lucide-file-plus"] = "rbxassetid://10723365877",
	["lucide-file-plus-2"] = "rbxassetid://10723365766",
	["lucide-file-question"] = "rbxassetid://10723365987",
	["lucide-file-scan"] = "rbxassetid://10723366167",
	["lucide-file-search"] = "rbxassetid://10723366550",
	["lucide-file-search-2"] = "rbxassetid://10723366340",
	["lucide-file-signature"] = "rbxassetid://10723366741",
	["lucide-file-spreadsheet"] = "rbxassetid://10723366962",
	["lucide-file-symlink"] = "rbxassetid://10723367098",
	["lucide-file-terminal"] = "rbxassetid://10723367244",
	["lucide-file-text"] = "rbxassetid://10723367380",
	["lucide-file-type"] = "rbxassetid://10723367606",
	["lucide-file-type-2"] = "rbxassetid://10723367509",
	["lucide-file-up"] = "rbxassetid://10723367734",
	["lucide-file-video"] = "rbxassetid://10723373884",
	["lucide-file-video-2"] = "rbxassetid://10723367834",
	["lucide-file-volume"] = "rbxassetid://10723374172",
	["lucide-file-volume-2"] = "rbxassetid://10723374030",
	["lucide-file-warning"] = "rbxassetid://10723374276",
	["lucide-file-x"] = "rbxassetid://10723374544",
	["lucide-file-x-2"] = "rbxassetid://10723374378",
	["lucide-files"] = "rbxassetid://10723374759",
	["lucide-film"] = "rbxassetid://10723374981",
	["lucide-filter"] = "rbxassetid://10723375128",
	["lucide-fingerprint"] = "rbxassetid://10723375250",
	["lucide-flag"] = "rbxassetid://10723375890",
	["lucide-flag-off"] = "rbxassetid://10723375443",
	["lucide-flag-triangle-left"] = "rbxassetid://10723375608",
	["lucide-flag-triangle-right"] = "rbxassetid://10723375727",
	["lucide-flame"] = "rbxassetid://10723376114",
	["lucide-flashlight"] = "rbxassetid://10723376471",
	["lucide-flashlight-off"] = "rbxassetid://10723376365",
	["lucide-flask-conical"] = "rbxassetid://10734883986",
	["lucide-flask-round"] = "rbxassetid://10723376614",
	["lucide-flip-horizontal"] = "rbxassetid://10723376884",
	["lucide-flip-horizontal-2"] = "rbxassetid://10723376745",
	["lucide-flip-vertical"] = "rbxassetid://10723377138",
	["lucide-flip-vertical-2"] = "rbxassetid://10723377026",
	["lucide-flower"] = "rbxassetid://10747830374",
	["lucide-flower-2"] = "rbxassetid://10723377305",
	["lucide-focus"] = "rbxassetid://10723377537",
	["lucide-folder"] = "rbxassetid://10723387563",
	["lucide-folder-archive"] = "rbxassetid://10723384478",
	["lucide-folder-check"] = "rbxassetid://10723384605",
	["lucide-folder-clock"] = "rbxassetid://10723384731",
	["lucide-folder-closed"] = "rbxassetid://10723384893",
	["lucide-folder-cog"] = "rbxassetid://10723385213",
	["lucide-folder-cog-2"] = "rbxassetid://10723385036",
	["lucide-folder-down"] = "rbxassetid://10723385338",
	["lucide-folder-edit"] = "rbxassetid://10723385445",
	["lucide-folder-heart"] = "rbxassetid://10723385545",
	["lucide-folder-input"] = "rbxassetid://10723385721",
	["lucide-folder-key"] = "rbxassetid://10723385848",
	["lucide-folder-lock"] = "rbxassetid://10723386005",
	["lucide-folder-minus"] = "rbxassetid://10723386127",
	["lucide-folder-open"] = "rbxassetid://10723386277",
	["lucide-folder-output"] = "rbxassetid://10723386386",
	["lucide-folder-plus"] = "rbxassetid://10723386531",
	["lucide-folder-search"] = "rbxassetid://10723386787",
	["lucide-folder-search-2"] = "rbxassetid://10723386674",
	["lucide-folder-symlink"] = "rbxassetid://10723386930",
	["lucide-folder-tree"] = "rbxassetid://10723387085",
	["lucide-folder-up"] = "rbxassetid://10723387265",
	["lucide-folder-x"] = "rbxassetid://10723387448",
	["lucide-folders"] = "rbxassetid://10723387721",
	["lucide-form-input"] = "rbxassetid://10723387841",
	["lucide-forward"] = "rbxassetid://10723388016",
	["lucide-frame"] = "rbxassetid://10723394389",
	["lucide-framer"] = "rbxassetid://10723394565",
	["lucide-frown"] = "rbxassetid://10723394681",
	["lucide-fuel"] = "rbxassetid://10723394846",
	["lucide-function-square"] = "rbxassetid://10723395041",
	["lucide-gamepad"] = "rbxassetid://10723395457",
	["lucide-gamepad-2"] = "rbxassetid://10723395215",
	["lucide-gauge"] = "rbxassetid://10723395708",
	["lucide-gavel"] = "rbxassetid://10723395896",
	["lucide-gem"] = "rbxassetid://10723396000",
	["lucide-ghost"] = "rbxassetid://10723396107",
	["lucide-gift"] = "rbxassetid://10723396402",
	["lucide-gift-card"] = "rbxassetid://10723396225",
	["lucide-git-branch"] = "rbxassetid://10723396676",
	["lucide-git-branch-plus"] = "rbxassetid://10723396542",
	["lucide-git-commit"] = "rbxassetid://10723396812",
	["lucide-git-compare"] = "rbxassetid://10723396954",
	["lucide-git-fork"] = "rbxassetid://10723397049",
	["lucide-git-merge"] = "rbxassetid://10723397165",
	["lucide-git-pull-request"] = "rbxassetid://10723397431",
	["lucide-git-pull-request-closed"] = "rbxassetid://10723397268",
	["lucide-git-pull-request-draft"] = "rbxassetid://10734884302",
	["lucide-glass"] = "rbxassetid://10723397788",
	["lucide-glass-2"] = "rbxassetid://10723397529",
	["lucide-glass-water"] = "rbxassetid://10723397678",
	["lucide-glasses"] = "rbxassetid://10723397895",
	["lucide-globe"] = "rbxassetid://10723404337",
	["lucide-globe-2"] = "rbxassetid://10723398002",
	["lucide-grab"] = "rbxassetid://10723404472",
	["lucide-graduation-cap"] = "rbxassetid://10723404691",
	["lucide-grape"] = "rbxassetid://10723404822",
	["lucide-grid"] = "rbxassetid://10723404936",
	["lucide-grip-horizontal"] = "rbxassetid://10723405089",
	["lucide-grip-vertical"] = "rbxassetid://10723405236",
	["lucide-hammer"] = "rbxassetid://10723405360",
	["lucide-hand"] = "rbxassetid://10723405649",
	["lucide-hand-metal"] = "rbxassetid://10723405508",
	["lucide-hard-drive"] = "rbxassetid://10723405749",
	["lucide-hard-hat"] = "rbxassetid://10723405859",
	["lucide-hash"] = "rbxassetid://10723405975",
	["lucide-haze"] = "rbxassetid://10723406078",
	["lucide-headphones"] = "rbxassetid://10723406165",
	["lucide-heart"] = "rbxassetid://10723406885",
	["lucide-heart-crack"] = "rbxassetid://10723406299",
	["lucide-heart-handshake"] = "rbxassetid://10723406480",
	["lucide-heart-off"] = "rbxassetid://10723406662",
	["lucide-heart-pulse"] = "rbxassetid://10723406795",
	["lucide-help-circle"] = "rbxassetid://10723406988",
	["lucide-hexagon"] = "rbxassetid://10723407092",
	["lucide-highlighter"] = "rbxassetid://10723407192",
	["lucide-history"] = "rbxassetid://10723407335",
	["lucide-home"] = "rbxassetid://10723407389",
	["lucide-hourglass"] = "rbxassetid://10723407498",
	["lucide-ice-cream"] = "rbxassetid://10723414308",
	["lucide-image"] = "rbxassetid://10723415040",
	["lucide-image-minus"] = "rbxassetid://10723414487",
	["lucide-image-off"] = "rbxassetid://10723414677",
	["lucide-image-plus"] = "rbxassetid://10723414827",
	["lucide-import"] = "rbxassetid://10723415205",
	["lucide-inbox"] = "rbxassetid://10723415335",
	["lucide-indent"] = "rbxassetid://10723415494",
	["lucide-indian-rupee"] = "rbxassetid://10723415642",
	["lucide-infinity"] = "rbxassetid://10723415766",
	["lucide-info"] = "rbxassetid://10723415903",
	["lucide-inspect"] = "rbxassetid://10723416057",
	["lucide-italic"] = "rbxassetid://10723416195",
	["lucide-japanese-yen"] = "rbxassetid://10723416363",
	["lucide-joystick"] = "rbxassetid://10723416527",
	["lucide-key"] = "rbxassetid://10723416652",
	["lucide-keyboard"] = "rbxassetid://10723416765",
	["lucide-lamp"] = "rbxassetid://10723417513",
	["lucide-lamp-ceiling"] = "rbxassetid://10723416922",
	["lucide-lamp-desk"] = "rbxassetid://10723417016",
	["lucide-lamp-floor"] = "rbxassetid://10723417131",
	["lucide-lamp-wall-down"] = "rbxassetid://10723417240",
	["lucide-lamp-wall-up"] = "rbxassetid://10723417356",
	["lucide-landmark"] = "rbxassetid://10723417608",
	["lucide-languages"] = "rbxassetid://10723417703",
	["lucide-laptop"] = "rbxassetid://10723423881",
	["lucide-laptop-2"] = "rbxassetid://10723417797",
	["lucide-lasso"] = "rbxassetid://10723424235",
	["lucide-lasso-select"] = "rbxassetid://10723424058",
	["lucide-laugh"] = "rbxassetid://10723424372",
	["lucide-layers"] = "rbxassetid://10723424505",
	["lucide-layout"] = "rbxassetid://10723425376",
	["lucide-layout-dashboard"] = "rbxassetid://10723424646",
	["lucide-layout-grid"] = "rbxassetid://10723424838",
	["lucide-layout-list"] = "rbxassetid://10723424963",
	["lucide-layout-template"] = "rbxassetid://10723425187",
	["lucide-leaf"] = "rbxassetid://10723425539",
	["lucide-library"] = "rbxassetid://10723425615",
	["lucide-life-buoy"] = "rbxassetid://10723425685",
	["lucide-lightbulb"] = "rbxassetid://10723425852",
	["lucide-lightbulb-off"] = "rbxassetid://10723425762",
	["lucide-line-chart"] = "rbxassetid://10723426393",
	["lucide-link"] = "rbxassetid://10723426722",
	["lucide-link-2"] = "rbxassetid://10723426595",
	["lucide-link-2-off"] = "rbxassetid://10723426513",
	["lucide-list"] = "rbxassetid://10723433811",
	["lucide-list-checks"] = "rbxassetid://10734884548",
	["lucide-list-end"] = "rbxassetid://10723426886",
	["lucide-list-minus"] = "rbxassetid://10723426986",
	["lucide-list-music"] = "rbxassetid://10723427081",
	["lucide-list-ordered"] = "rbxassetid://10723427199",
	["lucide-list-plus"] = "rbxassetid://10723427334",
	["lucide-list-start"] = "rbxassetid://10723427494",
	["lucide-list-video"] = "rbxassetid://10723427619",
	["lucide-list-x"] = "rbxassetid://10723433655",
	["lucide-loader"] = "rbxassetid://10723434070",
	["lucide-loader-2"] = "rbxassetid://10723433935",
	["lucide-locate"] = "rbxassetid://10723434557",
	["lucide-locate-fixed"] = "rbxassetid://10723434236",
	["lucide-locate-off"] = "rbxassetid://10723434379",
	["lucide-lock"] = "rbxassetid://10723434711",
	["lucide-log-in"] = "rbxassetid://10723434830",
	["lucide-log-out"] = "rbxassetid://10723434906",
	["lucide-luggage"] = "rbxassetid://10723434993",
	["lucide-magnet"] = "rbxassetid://10723435069",
	["lucide-mail"] = "rbxassetid://10734885430",
	["lucide-mail-check"] = "rbxassetid://10723435182",
	["lucide-mail-minus"] = "rbxassetid://10723435261",
	["lucide-mail-open"] = "rbxassetid://10723435342",
	["lucide-mail-plus"] = "rbxassetid://10723435443",
	["lucide-mail-question"] = "rbxassetid://10723435515",
	["lucide-mail-search"] = "rbxassetid://10734884739",
	["lucide-mail-warning"] = "rbxassetid://10734885015",
	["lucide-mail-x"] = "rbxassetid://10734885247",
	["lucide-mails"] = "rbxassetid://10734885614",
	["lucide-map"] = "rbxassetid://10734886202",
	["lucide-map-pin"] = "rbxassetid://10734886004",
	["lucide-map-pin-off"] = "rbxassetid://10734885803",
	["lucide-maximize"] = "rbxassetid://10734886735",
	["lucide-maximize-2"] = "rbxassetid://10734886496",
	["lucide-medal"] = "rbxassetid://10734887072",
	["lucide-megaphone"] = "rbxassetid://10734887454",
	["lucide-megaphone-off"] = "rbxassetid://10734887311",
	["lucide-meh"] = "rbxassetid://10734887603",
	["lucide-menu"] = "rbxassetid://10734887784",
	["lucide-message-circle"] = "rbxassetid://10734888000",
	["lucide-message-square"] = "rbxassetid://10734888228",
	["lucide-mic"] = "rbxassetid://10734888864",
	["lucide-mic-2"] = "rbxassetid://10734888430",
	["lucide-mic-off"] = "rbxassetid://10734888646",
	["lucide-microscope"] = "rbxassetid://10734889106",
	["lucide-microwave"] = "rbxassetid://10734895076",
	["lucide-milestone"] = "rbxassetid://10734895310",
	["lucide-minimize"] = "rbxassetid://10734895698",
	["lucide-minimize-2"] = "rbxassetid://10734895530",
	["lucide-minus"] = "rbxassetid://10734896206",
	["lucide-minus-circle"] = "rbxassetid://10734895856",
	["lucide-minus-square"] = "rbxassetid://10734896029",
	["lucide-monitor"] = "rbxassetid://10734896881",
	["lucide-monitor-off"] = "rbxassetid://10734896360",
	["lucide-monitor-speaker"] = "rbxassetid://10734896512",
	["lucide-moon"] = "rbxassetid://10734897102",
	["lucide-more-horizontal"] = "rbxassetid://10734897250",
	["lucide-more-vertical"] = "rbxassetid://10734897387",
	["lucide-mountain"] = "rbxassetid://10734897956",
	["lucide-mountain-snow"] = "rbxassetid://10734897665",
	["lucide-mouse"] = "rbxassetid://10734898592",
	["lucide-mouse-pointer"] = "rbxassetid://10734898476",
	["lucide-mouse-pointer-2"] = "rbxassetid://10734898194",
	["lucide-mouse-pointer-click"] = "rbxassetid://10734898355",
	["lucide-move"] = "rbxassetid://10734900011",
	["lucide-move-3d"] = "rbxassetid://10734898756",
	["lucide-move-diagonal"] = "rbxassetid://10734899164",
	["lucide-move-diagonal-2"] = "rbxassetid://10734898934",
	["lucide-move-horizontal"] = "rbxassetid://10734899414",
	["lucide-move-vertical"] = "rbxassetid://10734899821",
	["lucide-music"] = "rbxassetid://10734905958",
	["lucide-music-2"] = "rbxassetid://10734900215",
	["lucide-music-3"] = "rbxassetid://10734905665",
	["lucide-music-4"] = "rbxassetid://10734905823",
	["lucide-navigation"] = "rbxassetid://10734906744",
	["lucide-navigation-2"] = "rbxassetid://10734906332",
	["lucide-navigation-2-off"] = "rbxassetid://10734906144",
	["lucide-navigation-off"] = "rbxassetid://10734906580",
	["lucide-network"] = "rbxassetid://10734906975",
	["lucide-newspaper"] = "rbxassetid://10734907168",
	["lucide-octagon"] = "rbxassetid://10734907361",
	["lucide-option"] = "rbxassetid://10734907649",
	["lucide-outdent"] = "rbxassetid://10734907933",
	["lucide-package"] = "rbxassetid://10734909540",
	["lucide-package-2"] = "rbxassetid://10734908151",
	["lucide-package-check"] = "rbxassetid://10734908384",
	["lucide-package-minus"] = "rbxassetid://10734908626",
	["lucide-package-open"] = "rbxassetid://10734908793",
	["lucide-package-plus"] = "rbxassetid://10734909016",
	["lucide-package-search"] = "rbxassetid://10734909196",
	["lucide-package-x"] = "rbxassetid://10734909375",
	["lucide-paint-bucket"] = "rbxassetid://10734909847",
	["lucide-paintbrush"] = "rbxassetid://10734910187",
	["lucide-paintbrush-2"] = "rbxassetid://10734910030",
	["lucide-palette"] = "rbxassetid://10734910430",
	["lucide-palmtree"] = "rbxassetid://10734910680",
	["lucide-paperclip"] = "rbxassetid://10734910927",
	["lucide-party-popper"] = "rbxassetid://10734918735",
	["lucide-pause"] = "rbxassetid://10734919336",
	["lucide-pause-circle"] = "rbxassetid://10735024209",
	["lucide-pause-octagon"] = "rbxassetid://10734919143",
	["lucide-pen-tool"] = "rbxassetid://10734919503",
	["lucide-pencil"] = "rbxassetid://10734919691",
	["lucide-percent"] = "rbxassetid://10734919919",
	["lucide-person-standing"] = "rbxassetid://10734920149",
	["lucide-phone"] = "rbxassetid://10734921524",
	["lucide-phone-call"] = "rbxassetid://10734920305",
	["lucide-phone-forwarded"] = "rbxassetid://10734920508",
	["lucide-phone-incoming"] = "rbxassetid://10734920694",
	["lucide-phone-missed"] = "rbxassetid://10734920845",
	["lucide-phone-off"] = "rbxassetid://10734921077",
	["lucide-phone-outgoing"] = "rbxassetid://10734921288",
	["lucide-pie-chart"] = "rbxassetid://10734921727",
	["lucide-piggy-bank"] = "rbxassetid://10734921935",
	["lucide-pin"] = "rbxassetid://10734922324",
	["lucide-pin-off"] = "rbxassetid://10734922180",
	["lucide-pipette"] = "rbxassetid://10734922497",
	["lucide-pizza"] = "rbxassetid://10734922774",
	["lucide-plane"] = "rbxassetid://10734922971",
	["lucide-play"] = "rbxassetid://10734923549",
	["lucide-play-circle"] = "rbxassetid://10734923214",
	["lucide-plus"] = "rbxassetid://10734924532",
	["lucide-plus-circle"] = "rbxassetid://10734923868",
	["lucide-plus-square"] = "rbxassetid://10734924219",
	["lucide-podcast"] = "rbxassetid://10734929553",
	["lucide-pointer"] = "rbxassetid://10734929723",
	["lucide-pound-sterling"] = "rbxassetid://10734929981",
	["lucide-power"] = "rbxassetid://10734930466",
	["lucide-power-off"] = "rbxassetid://10734930257",
	["lucide-printer"] = "rbxassetid://10734930632",
	["lucide-puzzle"] = "rbxassetid://10734930886",
	["lucide-quote"] = "rbxassetid://10734931234",
	["lucide-radio"] = "rbxassetid://10734931596",
	["lucide-radio-receiver"] = "rbxassetid://10734931402",
	["lucide-rectangle-horizontal"] = "rbxassetid://10734931777",
	["lucide-rectangle-vertical"] = "rbxassetid://10734932081",
	["lucide-recycle"] = "rbxassetid://10734932295",
	["lucide-redo"] = "rbxassetid://10734932822",
	["lucide-redo-2"] = "rbxassetid://10734932586",
	["lucide-refresh-ccw"] = "rbxassetid://10734933056",
	["lucide-refresh-cw"] = "rbxassetid://10734933222",
	["lucide-refrigerator"] = "rbxassetid://10734933465",
	["lucide-regex"] = "rbxassetid://10734933655",
	["lucide-repeat"] = "rbxassetid://10734933966",
	["lucide-repeat-1"] = "rbxassetid://10734933826",
	["lucide-reply"] = "rbxassetid://10734934252",
	["lucide-reply-all"] = "rbxassetid://10734934132",
	["lucide-rewind"] = "rbxassetid://10734934347",
	["lucide-rocket"] = "rbxassetid://10734934585",
	["lucide-rocking-chair"] = "rbxassetid://10734939942",
	["lucide-rotate-3d"] = "rbxassetid://10734940107",
	["lucide-rotate-ccw"] = "rbxassetid://10734940376",
	["lucide-rotate-cw"] = "rbxassetid://10734940654",
	["lucide-rss"] = "rbxassetid://10734940825",
	["lucide-ruler"] = "rbxassetid://10734941018",
	["lucide-russian-ruble"] = "rbxassetid://10734941199",
	["lucide-sailboat"] = "rbxassetid://10734941354",
	["lucide-save"] = "rbxassetid://10734941499",
	["lucide-scale"] = "rbxassetid://10734941912",
	["lucide-scale-3d"] = "rbxassetid://10734941739",
	["lucide-scaling"] = "rbxassetid://10734942072",
	["lucide-scan"] = "rbxassetid://10734942565",
	["lucide-scan-face"] = "rbxassetid://10734942198",
	["lucide-scan-line"] = "rbxassetid://10734942351",
	["lucide-scissors"] = "rbxassetid://10734942778",
	["lucide-screen-share"] = "rbxassetid://10734943193",
	["lucide-screen-share-off"] = "rbxassetid://10734942967",
	["lucide-scroll"] = "rbxassetid://10734943448",
	["lucide-search"] = "rbxassetid://10734943674",
	["lucide-send"] = "rbxassetid://10734943902",
	["lucide-separator-horizontal"] = "rbxassetid://10734944115",
	["lucide-separator-vertical"] = "rbxassetid://10734944326",
	["lucide-server"] = "rbxassetid://10734949856",
	["lucide-server-cog"] = "rbxassetid://10734944444",
	["lucide-server-crash"] = "rbxassetid://10734944554",
	["lucide-server-off"] = "rbxassetid://10734944668",
	["lucide-settings"] = "rbxassetid://10734950309",
	["lucide-settings-2"] = "rbxassetid://10734950020",
	["lucide-share"] = "rbxassetid://10734950813",
	["lucide-share-2"] = "rbxassetid://10734950553",
	["lucide-sheet"] = "rbxassetid://10734951038",
	["lucide-shield"] = "rbxassetid://10734951847",
	["lucide-shield-alert"] = "rbxassetid://10734951173",
	["lucide-shield-check"] = "rbxassetid://10734951367",
	["lucide-shield-close"] = "rbxassetid://10734951535",
	["lucide-shield-off"] = "rbxassetid://10734951684",
	["lucide-shirt"] = "rbxassetid://10734952036",
	["lucide-shopping-bag"] = "rbxassetid://10734952273",
	["lucide-shopping-cart"] = "rbxassetid://10734952479",
	["lucide-shovel"] = "rbxassetid://10734952773",
	["lucide-shower-head"] = "rbxassetid://10734952942",
	["lucide-shrink"] = "rbxassetid://10734953073",
	["lucide-shrub"] = "rbxassetid://10734953241",
	["lucide-shuffle"] = "rbxassetid://10734953451",
	["lucide-sidebar"] = "rbxassetid://10734954301",
	["lucide-sidebar-close"] = "rbxassetid://10734953715",
	["lucide-sidebar-open"] = "rbxassetid://10734954000",
	["lucide-sigma"] = "rbxassetid://10734954538",
	["lucide-signal"] = "rbxassetid://10734961133",
	["lucide-signal-high"] = "rbxassetid://10734954807",
	["lucide-signal-low"] = "rbxassetid://10734955080",
	["lucide-signal-medium"] = "rbxassetid://10734955336",
	["lucide-signal-zero"] = "rbxassetid://10734960878",
	["lucide-siren"] = "rbxassetid://10734961284",
	["lucide-skip-back"] = "rbxassetid://10734961526",
	["lucide-skip-forward"] = "rbxassetid://10734961809",
	["lucide-skull"] = "rbxassetid://10734962068",
	["lucide-slack"] = "rbxassetid://10734962339",
	["lucide-slash"] = "rbxassetid://10734962600",
	["lucide-slice"] = "rbxassetid://10734963024",
	["lucide-sliders"] = "rbxassetid://10734963400",
	["lucide-sliders-horizontal"] = "rbxassetid://10734963191",
	["lucide-smartphone"] = "rbxassetid://10734963940",
	["lucide-smartphone-charging"] = "rbxassetid://10734963671",
	["lucide-smile"] = "rbxassetid://10734964441",
	["lucide-smile-plus"] = "rbxassetid://10734964188",
	["lucide-snowflake"] = "rbxassetid://10734964600",
	["lucide-sofa"] = "rbxassetid://10734964852",
	["lucide-sort-asc"] = "rbxassetid://10734965115",
	["lucide-sort-desc"] = "rbxassetid://10734965287",
	["lucide-speaker"] = "rbxassetid://10734965419",
	["lucide-sprout"] = "rbxassetid://10734965572",
	["lucide-square"] = "rbxassetid://10734965702",
	["lucide-star"] = "rbxassetid://10734966248",
	["lucide-star-half"] = "rbxassetid://10734965897",
	["lucide-star-off"] = "rbxassetid://10734966097",
	["lucide-stethoscope"] = "rbxassetid://10734966384",
	["lucide-sticker"] = "rbxassetid://10734972234",
	["lucide-sticky-note"] = "rbxassetid://10734972463",
	["lucide-stop-circle"] = "rbxassetid://10734972621",
	["lucide-stretch-horizontal"] = "rbxassetid://10734972862",
	["lucide-stretch-vertical"] = "rbxassetid://10734973130",
	["lucide-strikethrough"] = "rbxassetid://10734973290",
	["lucide-subscript"] = "rbxassetid://10734973457",
	["lucide-sun"] = "rbxassetid://10734974297",
	["lucide-sun-dim"] = "rbxassetid://10734973645",
	["lucide-sun-medium"] = "rbxassetid://10734973778",
	["lucide-sun-moon"] = "rbxassetid://10734973999",
	["lucide-sun-snow"] = "rbxassetid://10734974130",
	["lucide-sunrise"] = "rbxassetid://10734974522",
	["lucide-sunset"] = "rbxassetid://10734974689",
	["lucide-superscript"] = "rbxassetid://10734974850",
	["lucide-swiss-franc"] = "rbxassetid://10734975024",
	["lucide-switch-camera"] = "rbxassetid://10734975214",
	["lucide-sword"] = "rbxassetid://10734975486",
	["lucide-swords"] = "rbxassetid://10734975692",
	["lucide-syringe"] = "rbxassetid://10734975932",
	["lucide-table"] = "rbxassetid://10734976230",
	["lucide-table-2"] = "rbxassetid://10734976097",
	["lucide-tablet"] = "rbxassetid://10734976394",
	["lucide-tag"] = "rbxassetid://10734976528",
	["lucide-tags"] = "rbxassetid://10734976739",
	["lucide-target"] = "rbxassetid://10734977012",
	["lucide-tent"] = "rbxassetid://10734981750",
	["lucide-terminal"] = "rbxassetid://10734982144",
	["lucide-terminal-square"] = "rbxassetid://10734981995",
	["lucide-text-cursor"] = "rbxassetid://10734982395",
	["lucide-text-cursor-input"] = "rbxassetid://10734982297",
	["lucide-thermometer"] = "rbxassetid://10734983134",
	["lucide-thermometer-snowflake"] = "rbxassetid://10734982571",
	["lucide-thermometer-sun"] = "rbxassetid://10734982771",
	["lucide-thumbs-down"] = "rbxassetid://10734983359",
	["lucide-thumbs-up"] = "rbxassetid://10734983629",
	["lucide-ticket"] = "rbxassetid://10734983868",
	["lucide-timer"] = "rbxassetid://10734984606",
	["lucide-timer-off"] = "rbxassetid://10734984138",
	["lucide-timer-reset"] = "rbxassetid://10734984355",
	["lucide-toggle-left"] = "rbxassetid://10734984834",
	["lucide-toggle-right"] = "rbxassetid://10734985040",
	["lucide-tornado"] = "rbxassetid://10734985247",
	["lucide-toy-brick"] = "rbxassetid://10747361919",
	["lucide-train"] = "rbxassetid://10747362105",
	["lucide-trash"] = "rbxassetid://10747362393",
	["lucide-trash-2"] = "rbxassetid://10747362241",
	["lucide-tree-deciduous"] = "rbxassetid://10747362534",
	["lucide-tree-pine"] = "rbxassetid://10747362748",
	["lucide-trees"] = "rbxassetid://10747363016",
	["lucide-trending-down"] = "rbxassetid://10747363205",
	["lucide-trending-up"] = "rbxassetid://10747363465",
	["lucide-triangle"] = "rbxassetid://10747363621",
	["lucide-trophy"] = "rbxassetid://10747363809",
	["lucide-truck"] = "rbxassetid://10747364031",
	["lucide-tv"] = "rbxassetid://10747364593",
	["lucide-tv-2"] = "rbxassetid://10747364302",
	["lucide-type"] = "rbxassetid://10747364761",
	["lucide-umbrella"] = "rbxassetid://10747364971",
	["lucide-underline"] = "rbxassetid://10747365191",
	["lucide-undo"] = "rbxassetid://10747365484",
	["lucide-undo-2"] = "rbxassetid://10747365359",
	["lucide-unlink"] = "rbxassetid://10747365771",
	["lucide-unlink-2"] = "rbxassetid://10747397871",
	["lucide-unlock"] = "rbxassetid://10747366027",
	["lucide-upload"] = "rbxassetid://10747366434",
	["lucide-upload-cloud"] = "rbxassetid://10747366266",
	["lucide-usb"] = "rbxassetid://10747366606",
	["lucide-user"] = "rbxassetid://10747373176",
	["lucide-user-check"] = "rbxassetid://10747371901",
	["lucide-user-cog"] = "rbxassetid://10747372167",
	["lucide-user-minus"] = "rbxassetid://10747372346",
	["lucide-user-plus"] = "rbxassetid://10747372702",
	["lucide-user-x"] = "rbxassetid://10747372992",
	["lucide-users"] = "rbxassetid://10747373426",
	["lucide-utensils"] = "rbxassetid://10747373821",
	["lucide-utensils-crossed"] = "rbxassetid://10747373629",
	["lucide-venetian-mask"] = "rbxassetid://10747374003",
	["lucide-verified"] = "rbxassetid://10747374131",
	["lucide-vibrate"] = "rbxassetid://10747374489",
	["lucide-vibrate-off"] = "rbxassetid://10747374269",
	["lucide-video"] = "rbxassetid://10747374938",
	["lucide-video-off"] = "rbxassetid://10747374721",
	["lucide-view"] = "rbxassetid://10747375132",
	["lucide-voicemail"] = "rbxassetid://10747375281",
	["lucide-volume"] = "rbxassetid://10747376008",
	["lucide-volume-1"] = "rbxassetid://10747375450",
	["lucide-volume-2"] = "rbxassetid://10747375679",
	["lucide-volume-x"] = "rbxassetid://10747375880",
	["lucide-wallet"] = "rbxassetid://10747376205",
	["lucide-wand"] = "rbxassetid://10747376565",
	["lucide-wand-2"] = "rbxassetid://10747376349",
	["lucide-watch"] = "rbxassetid://10747376722",
	["lucide-waves"] = "rbxassetid://10747376931",
	["lucide-webcam"] = "rbxassetid://10747381992",
	["lucide-wifi"] = "rbxassetid://10747382504",
	["lucide-wifi-off"] = "rbxassetid://10747382268",
	["lucide-wind"] = "rbxassetid://10747382750",
	["lucide-wrap-text"] = "rbxassetid://10747383065",
	["lucide-wrench"] = "rbxassetid://10747383470",
	["lucide-x"] = "rbxassetid://10747384394",
	["lucide-x-circle"] = "rbxassetid://10747383819",
	["lucide-x-octagon"] = "rbxassetid://10747384037",
	["lucide-x-square"] = "rbxassetid://10747384217",
	["lucide-zoom-in"] = "rbxassetid://10747384552",
	["lucide-zoom-out"] = "rbxassetid://10747384679",
}

local IconAssetNameAliases = {
	home = "home", house = "home", sprout = "sprout", bag = "package-open",
	arrow = "move", shield = "shield", pin = "map-pin", gear = "cog",
	user = "user", sword = "sword", search = "search", chevron = "chevron-down",
	close = "x", sidebar = "sidebar", left = "arrow-left", right = "arrow-right",
	updown = "arrow-up-down", lock = "lock", star = "star", bolt = "activity",
	eye = "eye", folder = "folder", list = "list",
}

local function resolveIconName(s)
	s = string.lower(s)
	local lucideName = string.match(s, "^lucide:(.+)$") or string.match(s, "^lucide%-(.+)$")
	if lucideName then
		s = LucideIconAlias[lucideName] or lucideName
	end
	if IconDefs[s] then
		return s
	end
	return LucideIconAlias[s] or IconAlias[s] or (FluentIconAssets["lucide-" .. s] and s or nil)
end

local function buildIcon(name, parent, size)
	local s = size or 16
	local k = s / 16
	local root = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(s, s),
		ClipsDescendants = false,
		Parent = parent,
	})
	local parts = {}
	local api = {}

	function api.fill(x, y, w, h, radius, rot)
		local f = New("Frame", {
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(x * k, y * k),
			Size = UDim2.fromOffset(w * k, h * k),
			Rotation = rot or 0,
			Parent = root,
		}, { Round((radius or 0) * k) })
		table.insert(parts, { Inst = f, Kind = "fill" })
	end
	function api.ring(x, y, w, h, radius, thick)
		local f = New("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(x * k, y * k),
			Size = UDim2.fromOffset(w * k, h * k),
			Parent = root,
		}, { Round(radius * k) })
		local st = New("UIStroke", {
			Thickness = thick * k,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = f,
		})
		table.insert(parts, { Inst = st, Kind = "stroke" })
	end
	api.outline = api.ring
	function api.line(x1, y1, x2, y2, t)
		local dx, dy = x2 - x1, y2 - y1
		local len = math.sqrt(dx * dx + dy * dy)
		local f = New("Frame", {
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset((x1 + x2) / 2 * k, (y1 + y2) / 2 * k),
			Size = UDim2.fromOffset(len * k, t * k),
			Rotation = math.deg(math.atan2(dy, dx)),
			Parent = root,
		}, { Round(t * k / 2) })
		table.insert(parts, { Inst = f, Kind = "fill" })
	end

	IconDefs[name](api)
	return { Root = root, Parts = parts, Kind = "drawn" }
end

local function makeIcon(parent, icon, size)
	size = size or 16

	local assetId
	local tint = true
	if type(icon) == "table" then
		assetId = normalizeAsset(icon.Id)
		if icon.Tint ~= nil then
			tint = icon.Tint
		end
	elseif type(icon) == "number" then
		assetId = normalizeAsset(icon)
	elseif type(icon) == "string" then
		if string.match(icon, "^%s*%d+%s*$") or string.match(icon, "^rbxassetid://%d+$") then
			assetId = normalizeAsset(string.match(icon, "^%s*(%d+)%s*$") or icon)
		else
			local name = resolveIconName(icon)
			if name then
				local assetName = IconAssetNameAliases[name] or name
				assetId = FluentIconAssets["lucide-" .. assetName]
			end
		end
	end

	if assetId then
		return {
			Kind = "image",
			Tint = tint,
			Root = New("ImageLabel", {
				Name = "Icon",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = assetId,
				ImageColor3 = Color3.new(1, 1, 1),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(size, size),
				Parent = parent,
			}),
		}
	end

	if type(icon) ~= "string" then
		icon = "list"
	end
	local name = resolveIconName(icon)
	if name and IconDefs[name] then
		return buildIcon(name, parent, size)
	end
	if #icon > 1 and string.match(icon, "^[%w_%-%.:/]+$") then
		return buildIcon("list", parent, size) -- an icon name this library does not draw (not an emoji)
	end

	return {
		Kind = "text",
		Root = New("TextLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			Text = icon,
			Font = Enum.Font.Gotham,
			TextSize = size - 2,
			Size = UDim2.fromOffset(size, size),
			Parent = parent,
		}),
	}
end

local function tintIcon(ic, color)
	if not ic then
		return
	end
	if ic.Kind == "drawn" then
		for _, p in ipairs(ic.Parts) do
			if p.Kind == "fill" then
				p.Inst.BackgroundColor3 = color
			else
				p.Inst.Color = color
			end
		end
	elseif ic.Kind == "image" then
		if ic.Tint ~= false then
			ic.Root.ImageColor3 = color
		end
	else
		ic.Root.TextColor3 = color
	end
end

----------------------------------------------------------------------
-- ============================================================================
-- COMPATIBILITY LAYER: other naming styles, notifications, library-level destroy
-- ============================================================================
local function firstNonNil(...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if v ~= nil then
			return v
		end
	end
	return nil
end

local function copyTable(t)
	local c = {}
	for k, v in pairs(t) do
		c[k] = v
	end
	return c
end

-- Enum.KeyCode.F  /  "F"  /  "RightShift"  ->  Enum.KeyCode item (nil when it is not a key)
local ENUM_ITEM = "EnumItem"
local function toKeyCode(k)
	if typeof(k) == ENUM_ITEM and k.EnumType == Enum.KeyCode then
		return k
	end
	if type(k) == "string" then
		local ok, v = pcall(function()
			return Enum.KeyCode[k]
		end)
		if ok and v then
			return v
		end
	end
	return nil
end

-- control kinds and every method name (from other UI libraries) that maps to them
local KIND_NAMES = {
	Button = { "Button", "CreateButton", "NewButton", "addButton", "MakeButton" },
	Toggle = { "Toggle", "CreateToggle", "NewToggle", "addToggle", "MakeToggle", "AddCheckbox", "Checkbox", "CreateCheckbox" },
	Slider = { "Slider", "CreateSlider", "NewSlider", "addSlider", "MakeSlider" },
	Dropdown = { "Dropdown", "CreateDropdown", "NewDropdown", "addDropdown", "MakeDropdown" },
	Label = {
		"Label", "CreateLabel", "NewLabel", "addLabel", "MakeLabel",
		"Paragraph", "AddParagraph", "CreateParagraph", "NewParagraph", "addParagraph",
	},
	Textbox = {
		"Textbox", "TextBox", "CreateTextbox", "CreateTextBox", "AddTextBox", "NewTextbox", "NewTextBox",
		"addTextbox", "addTextBox", "Input", "AddInput", "CreateInput", "Box", "CreateBox", "AddBox",
	},
	Bind = {
		"Bind", "Keybind", "KeyBind", "CreateBind", "CreateKeybind", "AddKeybind", "AddKeyBind", "NewBind",
		"NewKeybind", "addKeybind", "AddKeyPicker", "KeyPicker", "CreateKeyPicker",
	},
	ColorPicker = {
		"ColorPicker", "Colorpicker", "CreateColorPicker", "CreateColorpicker", "AddColorpicker", "NewColorPicker",
		"addColorPicker", "ColourPicker", "AddColourPicker",
	},
}
local DIVIDER_NAMES = {
	"AddDivider", "CreateDivider", "Divider", "AddSeparator", "CreateSeparator", "Separator", "NewDivider",
}
local BLANK_NAMES = { "AddBlank", "Blank", "AddSpace", "CreateSpace", "AddSpacer", "CreateSpacer", "Spacer" }
local SECTION_NAMES = {
	"AddSection", "CreateSection", "NewSection", "Section", "addSection", "MakeSection", "CreateGroup", "AddGroup",
	"AddGroupbox", "AddLeftGroupbox", "AddRightGroupbox", "CreateFolder", "AddFolder",
}
local TAB_NAMES = {
	"AddTab", "CreateTab", "MakeTab", "NewTab", "Tab", "addPage", "AddPage", "CreatePage", "NewPage", "MakePage", "Page",
}

local COLOR3, ENUMITEM = "Color3", "EnumItem"

local function hexOf(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

-- accepts the option names other UI libraries use (Title/Text, CurrentValue, Values, Content, flag, list, ...)
local LOWER_KEYS = {
	flag = "Flag", default = "Default", min = "Min", max = "Max", list = "Options", location = "Location",
	precise = "Precise", name = "Name", text = "Name", callback = "Callback", value = "Value", type = "Type",
}
local function normControl(kind, o)
	if type(o) == "string" then
		o = { Name = o }
	end
	o = o or {}
	local n = copyTable(o)
	for k, v in pairs(o) do
		local c = type(k) == "string" and LOWER_KEYS[k]
		if c and n[c] == nil then
			n[c] = v
		end
	end
	n.Name = firstNonNil(n.Name, n.Title, n.Text, n.Label)
	n.Desc = firstNonNil(n.Desc, n.Description, n.Info, n.SubContent)
	n.Callback = firstNonNil(n.Callback, n.Function, n.Action, n.Func)
	if kind == "Toggle" then
		n.Default = firstNonNil(n.Default, n.CurrentValue, n.Value, n.State, n.Enabled, false)
	elseif kind == "Slider" then
		if type(n.Range) == "table" then
			n.Min = firstNonNil(n.Min, n.Range[1], n.Range.Min)
			n.Max = firstNonNil(n.Max, n.Range[2], n.Range.Max)
		end
		n.Min = firstNonNil(n.Min, n.Minimum)
		n.Max = firstNonNil(n.Max, n.Maximum)
		n.Default = firstNonNil(n.Default, n.CurrentValue, n.Value, n.Min)
		n.Increment = firstNonNil(n.Increment, n.Step)
		if n.Increment == nil and type(n.Rounding) == "number" then
			n.Increment = 10 ^ -n.Rounding
		end
		if n.Increment == nil and n.Precise then
			n.Increment = 0.01
		end
		n.Suffix = firstNonNil(n.Suffix, n.ValueName)
	elseif kind == "Dropdown" then
		n._rayfield = (o.CurrentOption ~= nil) or (o.MultipleOptions ~= nil)
		n.Options = firstNonNil(n.Options, n.Values, n.List, n.Items, n.Choices)
		n.Default = firstNonNil(n.Default, n.CurrentOption, n.Value)
		n.Multi = (firstNonNil(n.Multi, n.MultipleOptions, n.Multiple) == true)
	elseif kind == "Label" then
		n.Value = firstNonNil(n.Value, n.Content, n.Description)
		if n.Value == nil and n.Name ~= nil then
			n.Value = n.Name -- Section:Label("just text")
			n.Name = ""
		end
	elseif kind == "Textbox" then
		n.Default = firstNonNil(n.Default, n.CurrentValue, n.Value, "")
		n.Placeholder = firstNonNil(n.Placeholder, n.PlaceholderText)
		n.EnterOnly = firstNonNil(n.EnterOnly, n.Finished)
		n.ClearOnFocus = firstNonNil(n.ClearOnFocus, n.ClearTextOnFocus)
		n.ClearAfter = firstNonNil(n.ClearAfter, n.TextDisappear, n.RemoveTextAfterFocusLost)
		if n.Numeric == nil and n.Type == "number" then
			n.Numeric = true
		end
	elseif kind == "Bind" then
		n.Default = firstNonNil(n.Default, n.CurrentKeybind, n.CurrentBind, n.Key, n.Keybind, n.Value)
		n.OnChange = firstNonNil(n.OnChange, n.Changed, n.ChangedCallback, n.changedCallback)
		n.Hold = firstNonNil(n.Hold, n.HoldToInteract)
	elseif kind == "ColorPicker" then
		n.Default = firstNonNil(n.Default, n.Color, n.CurrentValue, n.CurrentColor, n.Value)
	end
	return n
end

-- Turns the arguments of any control call into one option table, whatever the library style:
--   table      Toggle({ Name = .. })                      Rayfield / Orion / Fluent
--   idx+table  AddToggle("Idx", { Text = .. })            Linoria / Fluent
--   Kavo       NewButton(name, tip, callback)  NewSlider(name, tip, max, min, callback) ...
--   Venyx      addToggle(title, default, callback)  addSlider(title, default, min, max, callback) ...
--   positional Toggle("name", { flag = .. }, callback)    Wally and similar
local IDX_KINDS = { Toggle = true, Slider = true, Dropdown = true, Textbox = true, Bind = true, ColorPicker = true }
local function parseControl(kind, nameUsed, ...)
	local a1, a2, a3, a4, a5 = ...
	local meta = {}
	if type(a1) == "table" then
		meta.native = (nameUsed == "Add" .. kind)
		return normControl(kind, a1), meta
	end
	if type(a1) ~= "string" then
		return normControl(kind, {}), meta
	end

	if string.match(nameUsed, "^New%u") then -- Kavo
		local n = { Name = a1 }
		if kind == "Button" or kind == "Toggle" or kind == "Textbox" then
			n.Callback = a3
		elseif kind == "Slider" then
			n.Max, n.Min, n.Callback, n.Default = a3, a4, a5, a4
		elseif kind == "Dropdown" then
			n.Options, n.Callback = a3, a4
		elseif kind == "Bind" or kind == "ColorPicker" then
			n.Default, n.Callback = a3, a4
		elseif kind == "Label" then
			n.Name, n.Value = "", a1
		end
		return normControl(kind, n), meta
	end

	if string.match(nameUsed, "^add%u") then -- Venyx
		local n = { Name = a1 }
		if kind == "Button" then
			n.Callback = a2
		elseif kind == "Toggle" or kind == "Textbox" or kind == "ColorPicker" then
			n.Default, n.Callback = a2, a3
		elseif kind == "Bind" then
			n.Default, n.Callback, n.OnChange = a2, a3, a4
		elseif kind == "Slider" then
			n.Default, n.Min, n.Max, n.Callback = a2, a3, a4, a5
		elseif kind == "Dropdown" then
			n.Options, n.Callback = a2, a3
		elseif kind == "Label" then
			n.Name, n.Value = "", a1
		end
		return normControl(kind, n), meta
	end

	if type(a2) == "table" and IDX_KINDS[kind] and string.match(nameUsed, "^Add") then -- Linoria / Fluent
		local n = normControl(kind, a2)
		meta.idx = a1
		n.Name = firstNonNil(n.Name, a1)
		return n, meta
	end

	-- generic positional: name first, then callback / options table / strings / booleans / numbers in any order
	local n = { Name = a1 }
	local strs, bools, nums = {}, {}, {}
	for i = 2, select("#", ...) do
		local v = select(i, ...)
		local tv = type(v)
		if tv == "function" then
			n.Callback = n.Callback or v
		elseif tv == "table" then
			if kind == "Dropdown" and v[1] ~= nil and n.Options == nil then
				n.Options = v
			else
				for k, x in pairs(v) do
					n[k] = x
				end
			end
		elseif tv == "string" then
			table.insert(strs, v)
		elseif tv == "boolean" then
			table.insert(bools, v)
		elseif tv == "number" then
			table.insert(nums, v)
		elseif typeof(v) == COLOR3 then
			n.Default = v
		elseif typeof(v) == ENUMITEM then
			n.Default = v
		end
	end
	if kind == "Label" then
		n.Value = strs[1]
	elseif kind == "Button" then
		n.Desc = strs[1]
	elseif kind == "Toggle" then
		n.Default = bools[1]
		n.Desc = strs[1]
	elseif kind == "Slider" then
		if #nums >= 3 then
			n.Min, n.Max, n.Default = nums[1], nums[2], nums[3]
		elseif #nums == 2 then
			n.Min, n.Max = nums[1], nums[2]
		elseif #nums == 1 then
			n.Max = nums[1]
		end
	elseif kind == "Textbox" then
		n.Default = strs[1]
	elseif kind == "Bind" and n.Default == nil then
		n.Default = strs[1]
	end
	return normControl(kind, n), meta
end

-- theme names of other libraries -> our preset + accent
local ThemeMap = {
	darktheme = { "Dark" }, lighttheme = { "Light" }, midnight = { "Midnight" }, mocha = { "Mocha" },
	bloodtheme = { "Dark", "Red" }, grapetheme = { "Dark", "Purple" }, ocean = { "Midnight", "Teal" },
	sentinel = { "Dark", "Blue" }, synapse = { "Dark", "Orange" },
	default = { "Dark" }, amberglow = { "Mocha", "Orange" }, amethyst = { "Midnight", "Purple" },
	bloom = { "Dark", "Pink" }, darkblue = { "Midnight", "Blue" }, green = { "Dark", "Green" },
	light = { "Light" }, serenity = { "Light", "Teal" },
	dark = { "Dark" }, darker = { "Midnight" }, aqua = { "Dark", "Teal" }, rose = { "Mocha", "Pink" },
}

local function unself(a, ...)
	if a == win then
		return ...
	end
	return a, ...
end

-- ============================================================================
-- FUZZY METHOD NAMES: any method name that looks like "add / create / new / make + a control word" is understood
-- (AddFancySwitch, createcheckbox, NewRangeBar, MakeGroup ...). Unknown "AddSomething" names do nothing
-- instead of raising an error, so scripts written for other libraries keep running.
-- ============================================================================
local VERBS = { "add", "create", "new", "make", "build", "insert", "append", "register", "draw", "render", "spawn" }
local BARE = {
	toggle = 1, switch = 1, checkbox = 1, button = 1, btn = 1, slider = 1, dropdown = 1, textbox = 1, input = 1,
	keybind = 1, bind = 1, colorpicker = 1, label = 1, paragraph = 1, divider = 1, separator = 1, section = 1,
	tab = 1, page = 1, notify = 1, notification = 1, dialog = 1, window = 1,
}
-- { keyword, category, kind } - the first keyword contained in the name wins, so order matters
local KEYWORDS = {
	{ "tabbox", "tabbox" },
	{ "groupbox", "section" }, { "section", "section" }, { "group", "section" }, { "folder", "section" },
	{ "category", "section" }, { "panel", "section" }, { "card", "section" }, { "container", "section" },
	{ "colorpicker", "control", "ColorPicker" }, { "colourpicker", "control", "ColorPicker" },
	{ "color", "control", "ColorPicker" }, { "colour", "control", "ColorPicker" }, { "palette", "control", "ColorPicker" },
	{ "keybind", "control", "Bind" }, { "keypicker", "control", "Bind" }, { "hotkey", "control", "Bind" },
	{ "shortcut", "control", "Bind" }, { "bind", "control", "Bind" }, { "key", "control", "Bind" },
	{ "checkbox", "control", "Toggle" }, { "tickbox", "control", "Toggle" }, { "toggle", "control", "Toggle" },
	{ "switch", "control", "Toggle" }, { "check", "control", "Toggle" }, { "onoff", "control", "Toggle" },
	{ "enable", "control", "Toggle" },
	{ "textbox", "control", "Textbox" }, { "textinput", "control", "Textbox" }, { "input", "control", "Textbox" },
	{ "field", "control", "Textbox" }, { "entry", "control", "Textbox" }, { "editbox", "control", "Textbox" },
	{ "box", "control", "Textbox" },
	{ "slider", "control", "Slider" }, { "range", "control", "Slider" },
	{ "dropdown", "control", "Dropdown" }, { "combo", "control", "Dropdown" }, { "select", "control", "Dropdown" },
	{ "choose", "control", "Dropdown" }, { "listbox", "control", "Dropdown" }, { "menu", "control", "Dropdown" },
	{ "option", "control", "Dropdown" }, { "list", "control", "Dropdown" }, { "picker", "control", "Dropdown" },
	{ "button", "control", "Button" }, { "btn", "control", "Button" }, { "click", "control", "Button" },
	{ "action", "control", "Button" },
	{ "divider", "divider" }, { "separator", "divider" }, { "seperator", "divider" }, { "hr", "divider" },
	{ "line", "divider" }, { "rule", "divider" },
	{ "blank", "blank" }, { "spacer", "blank" }, { "space", "blank" }, { "gap", "blank" }, { "padding", "blank" },
	{ "notif", "notify" }, { "toast", "notify" }, { "alert", "notify" }, { "popup", "notify" },
	{ "dialog", "dialog" }, { "prompt", "dialog" }, { "confirm", "dialog" }, { "modal", "dialog" },
	{ "window", "window" }, { "tab", "tab" }, { "page", "tab" },
	{ "label", "control", "Label" }, { "paragraph", "control", "Label" }, { "text", "control", "Label" },
	{ "title", "control", "Label" }, { "heading", "control", "Label" }, { "info", "control", "Label" },
	{ "note", "control", "Label" }, { "status", "control", "Label" }, { "message", "control", "Label" },
	{ "content", "control", "Label" }, { "description", "control", "Label" }, { "display", "control", "Label" },
}

-- returns category, kind  (category = control / section / tabbox / divider / blank / notify / dialog / window / tab /
-- unknown) or nil when the name does not look like a builder call
local function classifyName(key)
	if type(key) ~= "string" or key == "" or string.sub(key, 1, 1) == "_" then
		return nil
	end
	local low = string.lower(key)
	local rest, hasVerb = low, false
	for _, v in ipairs(VERBS) do
		if #low > #v and string.sub(low, 1, #v) == v then
			rest, hasVerb = string.sub(low, #v + 1), true
			break
		end
	end
	rest = string.gsub(rest, "[^a-z]", "")
	if rest == "" then
		return nil
	end
	if not hasVerb and not BARE[rest] then
		return nil
	end
	for _, k in ipairs(KEYWORDS) do
		if string.find(rest, k[1], 1, true) then
			return k[2], k[3]
		end
	end
	return hasVerb and "unknown" or nil
end

-- an object that accepts any call and any field and always answers with itself (used for unknown builder names)
local Dummy
Dummy = setmetatable({}, {
	__index = function()
		return function()
			return Dummy
		end
	end,
	__call = function()
		return Dummy
	end,
})
local warnedNames = {}
local function unknownBuilder(key)
	if not warnedNames[key] then
		warnedNames[key] = true
		warn("[MacUI] '" .. tostring(key) .. "' is not supported by this library and was ignored")
	end
	return function()
		return Dummy
	end
end

-- first argument may be the object (colon call) or already the real first argument (dot call)
local function shift(self, scope, ...)
	if self == scope then
		return ...
	end
	return self, ...
end

-- makes `scope` answer unknown builder names: handlers[category](kind, key) must return the function to call
local function installFuzzy(scope, handlers)
	setmetatable(scope, {
		__index = function(t, key)
			local cat, kind = classifyName(key)
			if not cat then
				return nil
			end
			local h = handlers[cat]
			local fn = h and h(kind, key)
			if fn == nil then
				fn = unknownBuilder(key)
			end
			rawset(t, key, fn)
			return fn
		end,
	})
end

win.Flags, win.Options, win.Toggles = {}, {}, {}
for _, t in ipairs({ win.Flags, win.Options, win.Toggles }) do
	setmetatable(t, { __macui = true })
end
pcall(function() -- Linoria-style globals: Toggles.X / Options.X (replaced when they are left over from an older MacUI)
	local env = (getgenv and getgenv()) or _G
	for name, tbl in pairs({ Toggles = win.Toggles, Options = win.Options }) do
		local cur = env[name]
		local mt = type(cur) == "table" and getmetatable(cur)
		if cur == nil or (mt and mt.__macui) then
			env[name] = tbl
		end
	end
end)

win._windows = {} -- every live window, so win.Destroy() can remove them all
win._onUnload = {}

-- notifications (bottom-right corner, stack upwards)
local notifyGui, notifyHolder
local notifyCounter = 0
local NotifyDefault = {
	Card = Color3.fromRGB(41, 45, 54), Stroke = Color3.fromRGB(60, 66, 78),
	Text = Color3.fromRGB(236, 239, 246), SubText = Color3.fromRGB(150, 157, 171),
	Accent = Color3.fromRGB(41, 148, 255),
}
local NotifyTypes = {
	success = Color3.fromRGB(52, 199, 100),
	warning = Color3.fromRGB(255, 177, 66), warn = Color3.fromRGB(255, 177, 66),
	error = Color3.fromRGB(255, 82, 82), danger = Color3.fromRGB(255, 82, 82),
}

local function ensureNotifyGui()
	if notifyGui and notifyGui.Parent then
		return
	end
	notifyGui = New("ScreenGui", {
		Name = "MacUI_Notify",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 1000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local ok = pcall(function()
		notifyGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not ok or not notifyGui.Parent then
		notifyGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	notifyHolder = New("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 290, 1, -32),
		Parent = notifyGui,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
		}),
	})
end

-- win.Notify({ Title = "..", Content = "..", Duration = 3, Type = "success" | "warning" | "error" })
-- also works as Library:Notify(...) and Window:Notify(...); a plain string is the content
function win.Notify(...)
	local o, b = unself(...)
	if type(o) == "string" then
		if type(b) == "string" then
			o = { Title = o, Content = b } -- Notify("title", "text")
		elseif type(b) == "number" then
			o = { Content = o, Duration = b } -- Notify("text", seconds)
		else
			o = { Content = o }
		end
	end
	o = o or {}
	local title = tostring(firstNonNil(o.Title, o.Name, "Notification"))
	local content = tostring(firstNonNil(o.Content, o.Text, o.Description, o.Desc, ""))
	if o.SubContent then
		content = content .. "\n" .. tostring(o.SubContent)
	end
	local duration = tonumber(firstNonNil(o.Duration, o.Time, 3)) or 3
	local C = win._theme or NotifyDefault
	local accent = NotifyTypes[string.lower(tostring(o.Type or ""))] or C.Accent

	ensureNotifyGui()
	notifyCounter += 1
	local wrap = New("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = notifyCounter,
		Parent = notifyHolder,
	})
	local card = New("Frame", {
		BackgroundColor3 = C.Card,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 320, 0, 0),
		Parent = wrap,
	}, {
		Round(10),
		New("UIStroke", { Color = C.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})
	New("Frame", {
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, 0),
		Parent = card,
	})
	local inner = New("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = card,
	}, {
		New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
		}),
	})
	New("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 1,
		Parent = inner,
	})
	if content ~= "" then
		New("TextLabel", {
			BackgroundTransparency = 1,
			Text = content,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = C.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 2,
			Parent = inner,
		})
	end
	local hit = New("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = card,
	})
	animateButton(hit, function()
		return accent
	end)

	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
	}):Play()

	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		local tw = TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position = UDim2.new(0, 320, 0, 0),
		})
		tw:Play()
		task.delay(0.3, function()
			wrap:Destroy()
		end)
	end
	hit.Activated:Connect(close)
	if duration > 0 and duration < math.huge then
		task.delay(duration, close)
	end
	return { Close = close }
end

-- removes every window (and notifications) created by this library
function win.Destroy()
	for _, fn in ipairs(win._onUnload) do
		task.spawn(fn)
	end
	win._onUnload = {}
	for _, t in ipairs({ win.Flags, win.Options, win.Toggles }) do
		for k in pairs(t) do
			t[k] = nil
		end
	end
	for _, w in ipairs(table.clone(win._windows)) do
		pcall(function()
			w:Destroy()
		end)
	end
	if notifyGui then
		notifyGui:Destroy()
		notifyGui = nil
	end
end

local function getGuiParent()
	local lp = Players.LocalPlayer
	-- Executor/CoreGui first, then PlayerGui as the normal Roblox fallback.
	local ok, hui = pcall(function()
		if type(gethui) == "function" then
			return gethui()
		end
		return nil
	end)
	if ok and hui then
		return hui
	end
	local okCore, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if okCore and core then
		return core
	end
	if lp then
		return lp:WaitForChild("PlayerGui")
	end
	return nil
end

local function attachGui(gui)
	local parent = getGuiParent()
	if not parent then
		return false
	end
	local ok = pcall(function()
		gui.Parent = parent
	end)
	if ok and gui.Parent then
		return true
	end
	local lp = Players.LocalPlayer
	if lp then
		local ok2 = pcall(function()
			gui.Parent = lp:WaitForChild("PlayerGui")
		end)
		return ok2 and gui.Parent ~= nil
	end
	return false
end

local function buildWindow(opts)
	local library = win
	if type(opts) == "string" then
		opts = { Title = opts }
	end
	do -- accept other option names without touching the caller's table
		local c = copyTable(opts or {})
		c.Title = firstNonNil(c.Title, c.Name, c.Text)
		c.Subtitle = firstNonNil(c.Subtitle, c.SubTitle, c.Description)
		if c.ToggleKey == nil then
			c.ToggleKey = c.MinimizeKey -- Fluent
		end
		local th = c.Theme
		if type(th) == "table" then -- Kavo / Venyx custom theme tables
			c.Accent = c.Accent or th.SchemeColor or th.Accent or th.Glow
			c.Theme = nil
		elseif type(th) == "string" and not Presets[th] then
			local m = ThemeMap[string.lower(th)]
			if m then
				c.Theme = m[1]
				if m[2] and not c.Accent then
					c.Accent = Accents[m[2]]
				end
			else
				c.Theme = nil
			end
		end
		opts = c
	end
	-- CreateWindow supports Font = "Kanit" | "Prompt", FontScale = 0.7 to 1.4,
	-- and FontAssets = { Kanit = 123, Prompt = 456 }.
	local fontFamily = normalizeFontName(opts.Font or opts.FontFamily) or "Kanit"
	if opts.Font ~= nil or opts.FontFamily ~= nil then
		if not normalizeFontName(opts.Font or opts.FontFamily) then
			warn("[MacUI] Unsupported font; use 'Kanit' or 'Prompt'. Using Kanit.")
		end
	end
	local fontScale = math.clamp(tonumber(opts.FontScale) or 1, 0.7, 1.4)
	local fontAssets = opts.FontAssets or opts.FontAssetIds
	if type(fontAssets) ~= "table" then
		if fontAssets ~= nil then
			warn("[MacUI] FontAssets must be a table with Kanit and/or Prompt asset IDs.")
		end
		fontAssets = {}
	end
	local fontAssetIds = {}
	for _, name in ipairs(FONT_NAMES) do
		local value = fontAssets[name]
		if value == nil then
			value = DEFAULT_FONT_ASSETS[name]
		end
		if value ~= nil then
			fontAssetIds[name] = normalizeFontAssetId(value)
			if not fontAssetIds[name] then
				warn("[MacUI] Invalid FontAssets." .. name .. "; expected a numeric Roblox Font asset ID.")
			end
		end
	end
	local WIDTH, HEIGHT, SIDE = 560, 370, 150
	local UDIM2 = "UDim2"
	if typeof(opts.Size) == UDIM2 and opts.Size.X.Offset > 0 and opts.Size.Y.Offset > 0 then
		WIDTH = math.max(430, opts.Size.X.Offset)
		HEIGHT = math.max(300, opts.Size.Y.Offset)
	end
	local PROFILE_H = (opts.ShowUser ~= false) and 54 or 0
	local conns = {}

	-- theme system
	local Theme = {}
	local hooks = {}

	-- glass: 0 = solid window, higher = more see-through
	local glassAmount = (opts.Glass ~= nil) and opts.Glass or 0.18
	local glassOn = glassAmount > 0
	if not glassOn then
		glassAmount = 0.18
	end

	local function derive()
		Theme.Selected = Theme.Accent:Lerp(Color3.new(1, 1, 1), 0.45)
		Theme.SelectedText = Color3.fromRGB(18, 24, 36)
		local g = Theme.Glass or 0
		Theme.GlassMain = g
		Theme.GlassSide = g * 0.6
		Theme.GlassCard = g * 0.7
		Theme.GlassField = g * 0.35
	end
	local function loadPreset(name)
		for k, v in pairs(Presets[name]) do
			Theme[k] = v
		end
	end
	loadPreset((opts.Theme and Presets[opts.Theme]) and opts.Theme or "Dark")
	Theme.Accent = opts.Accent or Accents.Blue
	Theme.Glass = glassOn and glassAmount or 0
	derive()

	local function applyTheme()
		for _, h in ipairs(hooks) do
			h()
		end
	end
	local function refreshGlass()
		Theme.Glass = glassOn and glassAmount or 0
		derive()
		applyTheme()
	end
	local function themed(inst, map)
		local function h()
			for prop, key in pairs(map) do
				inst[prop] = Theme[key]
			end
		end
		h()
		table.insert(hooks, h)
		return inst
	end
	local function themedIcon(ic, key)
		local function h()
			tintIcon(ic, Theme[key])
		end
		h()
		table.insert(hooks, h)
	end
	local function Stroke(key)
		return themed(New("UIStroke", {
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}), { Color = key or "Stroke" })
	end
	local function Label(props, key)
		local base = {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
		}
		for k, v in pairs(props) do
			base[k] = v
		end
		return themed(New("TextLabel", base), { TextColor3 = key or "Text" })
	end

	local logoId = normalizeAsset(opts.Logo)
	local function addLogo(parent, size, position, radius)
		local fallback = themed(New("TextLabel", {
			Text = string.upper(string.sub(opts.Title or "M", 1, 1)),
			Font = Enum.Font.GothamBold,
			TextSize = math.floor(size * 0.52),
			TextColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Position = position,
			Size = UDim2.fromOffset(size, size),
			Visible = logoId == nil,
			Parent = parent,
		}, { Round(radius) }), { BackgroundColor3 = "Accent" })
		if logoId then
			local image = New("ImageLabel", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = logoId,
				ScaleType = Enum.ScaleType.Fit,
				Position = position,
				Size = UDim2.fromOffset(size, size),
				Parent = parent,
			}, { Round(radius) })
			image:GetPropertyChangedSignal("IsLoaded"):Connect(function()
				if image.IsLoaded then
					fallback.Visible = false
				end
			end)
			task.delay(5, function()
				if image.Parent and not image.IsLoaded then
					fallback.Visible = true
					warn("[MacUI] Logo did not load, check the image id: " .. tostring(opts.Logo))
				end
			end)
		end
	end

	-- Small UI icons (search / chevron / close) use built-in drawings.
	local function uiIcon(parent, iconName, size)
		return makeIcon(parent, iconName, size)
	end

	-- gui root
	local gui = New("ScreenGui", {
		Name = "MacUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	if not attachGui(gui) then
		warn("[MacUI] Could not parent ScreenGui")
		return nil
	end
	local fontBindings = setmetatable({}, { __mode = "k" })
	local function applyFontTo(instance)
		if not (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")) then
			return
		end
		local binding = fontBindings[instance]
		if not binding then
			local legacyFont = instance.Font
			local fontName = legacyFont.Name
			local weight = Enum.FontWeight.Regular
			if string.find(fontName, "Bold", 1, true) or string.find(fontName, "Black", 1, true) then
				weight = Enum.FontWeight.Bold
			elseif string.find(fontName, "Medium", 1, true) or string.find(fontName, "Semibold", 1, true) then
				weight = Enum.FontWeight.Medium
			end
			binding = { BaseSize = instance.TextSize, Weight = weight, Fallback = legacyFont }
			fontBindings[instance] = binding
		end
		instance.FontFace = resolveFontFace(fontFamily, binding.Weight, binding.Fallback, fontAssetIds[fontFamily])
		instance.TextSize = math.max(1, math.floor(binding.BaseSize * fontScale + 0.5))
	end
	table.insert(conns, gui.DescendantAdded:Connect(applyFontTo))
	for _, descendant in ipairs(gui:GetDescendants()) do
		applyFontTo(descendant)
	end

	local main = themed(New("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WIDTH, HEIGHT),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = gui,
	}, { Round(12), Stroke("Stroke") }), { BackgroundColor3 = "Window", BackgroundTransparency = "GlassMain" })
	main.Visible = true
	main.Active = true

	-- two sizes (yellow button), always limited to what fits on screen
	local scaleObj = New("UIScale", { Scale = 1, Parent = main })
	local openAnimScale = New("UIScale", { Scale = 1, Parent = main })
	local currentScale = 1
	local scaleSlider
	local fitMax = 1.5
	do
		local cam = workspace.CurrentCamera
		if cam then
			local vp = cam.ViewportSize
			fitMax = math.min(vp.X / (WIDTH + 30), vp.Y / (HEIGHT + 30))
		end
		if fitMax < 1 then
			currentScale = math.max(fitMax, 0.5)
		end
		scaleObj.Scale = currentScale
	end
	local SIZE_SMALL = math.max(0.5, math.min(0.85, fitMax))
	local SIZE_LARGE = math.max(0.5, math.min(1.15, fitMax))
	local function setScale(v)
		v = math.clamp(v, 0.5, 1.5)
		currentScale = v
		tween(scaleObj, { Scale = v }, 0.15)
		if scaleSlider then
			scaleSlider:Set(v)
		end
	end

	-- sidebar: clipped container, so only the left corners are round and nothing overlaps
	local sideClip = New("Frame", {
		Size = UDim2.new(0, SIDE, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = main,
	})
	themed(New("Frame", {
		Size = UDim2.new(0, SIDE + 12, 1, 0),
		BorderSizePixel = 0,
		Parent = sideClip,
	}, { Round(12) }), { BackgroundColor3 = "Sidebar", BackgroundTransparency = "GlassSide" })
	themed(New("Frame", {
		Position = UDim2.new(1, -1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BorderSizePixel = 0,
		Parent = sideClip,
	}), { BackgroundColor3 = "Stroke" })

	local sideList = New("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 45),
		Size = UDim2.new(0, SIDE - 1, 1, -45 - PROFILE_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sideClip,
	}, {
		New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
	})

	-- profile: avatar + name at the bottom of the sidebar
	local applyUser = function() end
	local userInfo = {
		Name = opts.UserName, UserId = opts.UserId, Image = opts.UserImage, Mask = opts.MaskName,
		Note = opts.UserNote, NoteColor = opts.UserNoteColor,
	}
	if PROFILE_H > 0 then
		themed(New("Frame", {
			Name = "ProfileLine",
			Position = UDim2.new(0, 8, 1, -PROFILE_H),
			Size = UDim2.new(0, SIDE - 17, 0, 1),
			BorderSizePixel = 0,
			Parent = sideClip,
		}), { BackgroundColor3 = "Stroke" })
		local avatar = themed(New("Frame", {
			Name = "Avatar",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 1, -PROFILE_H / 2),
			Size = UDim2.fromOffset(32, 32),
			BorderSizePixel = 0,
			Parent = sideClip,
		}, { Round(16) }), { BackgroundColor3 = "Field" })
		local letter = Label({
			Text = "?",
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			Parent = avatar,
		}, "SubText")
		local avatarImg = New("ImageLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScaleType = Enum.ScaleType.Crop,
			Size = UDim2.fromScale(1, 1),
			Parent = avatar,
		}, { Round(16) })
		local nameLabel = Label({
			Text = "",
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 48, 1, -PROFILE_H / 2),
			Size = UDim2.fromOffset(SIDE - 48 - 6, 18),
			Parent = sideClip,
		}, "Text")
		-- second line under the name (key time left, status, ...): Window:SetUserNote("text")
		local noteLabel = Label({
			Text = "",
			TextSize = 11,
			RichText = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 48, 1, -PROFILE_H / 2 + 9),
			Size = UDim2.fromOffset(SIDE - 48 - 6, 14),
			Visible = false,
			Parent = sideClip,
		}, "SubText")
		avatarImg:GetPropertyChangedSignal("IsLoaded"):Connect(function()
			if avatarImg.IsLoaded and avatarImg.Image ~= "" then
				letter.Visible = false
			end
		end)
		applyUser = function()
			local lp = Players.LocalPlayer
			local shown = userInfo.Name
			if (shown == nil or shown == "" or shown == false) and lp then
				shown = (lp.DisplayName ~= "" and lp.DisplayName) or lp.Name
			end
			shown = tostring(shown or "Player")
			nameLabel.Text = userInfo.Mask and (string.sub(shown, 1, 2) .. "*****") or shown
			letter.Text = string.upper(string.sub(shown, 1, 1))
			local img = userInfo.Image and normalizeAsset(userInfo.Image)
			if not img then
				local uid = tonumber(userInfo.UserId) or (lp and lp.UserId)
				if uid and uid > 0 then
					img = "rbxthumb://type=AvatarHeadShot&id=" .. uid .. "&w=150&h=150"
				end
			end
			-- note line: with a note the name moves up, without one the name stays centred
			local note = userInfo.Note
			note = (note ~= nil and note ~= false) and tostring(note) or ""
			if note ~= "" and typeof(userInfo.NoteColor) == COLOR3 then
				note = '<font color="' .. hexOf(userInfo.NoteColor) .. '">' .. note .. "</font>"
			end
			noteLabel.Text = note
			noteLabel.Visible = note ~= ""
			nameLabel.Position = UDim2.new(0, 48, 1, -PROFILE_H / 2 - (note ~= "" and 8 or 0))
			letter.Visible = true
			avatarImg.Image = img or ""
			if img and avatarImg.IsLoaded then
				letter.Visible = false
			end
		end
		applyUser()
	end

	-- drag strip next to the traffic lights (the lights themselves never start a drag)
	local dragStrip = New("Frame", {
		Position = UDim2.fromOffset(84, 0),
		Size = UDim2.new(1, -85, 0, 44),
		BackgroundTransparency = 1,
		Parent = sideClip,
	})

	-- traffic lights: large invisible hit area, action on the first press
	local lights = {}
	local function light(dotX, color, glyph)
		local hit = New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(dotX - 4, 9),
			Size = UDim2.fromOffset(21, 26),
			ZIndex = 10,
			Parent = main,
		})
		animateButton(hit, function()
			return color
		end)
		local dot = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(13, 13),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = hit,
		}, { Round(7) })
		local g = New("TextLabel", {
			BackgroundTransparency = 1,
			Text = "",
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = Color3.fromRGB(60, 24, 20),
			Size = UDim2.fromScale(1, 1),
			Parent = dot,
		})
		table.insert(lights, { Glyph = glyph, Label = g })
		hit.MouseEnter:Connect(function()
			for _, o in ipairs(lights) do
				o.Label.Text = o.Glyph
			end
		end)
		hit.MouseLeave:Connect(function()
			for _, o in ipairs(lights) do
				o.Label.Text = ""
			end
		end)
		return hit
	end
	local red = light(14, Color3.fromRGB(255, 95, 87), "×")
	local yellow = light(35, Color3.fromRGB(254, 188, 46), "+")
	local green = light(56, Color3.fromRGB(40, 200, 64), "–")

	-- top bar
	local topbar = New("Frame", {
		Position = UDim2.new(0, SIDE, 0, 0),
		Size = UDim2.new(1, -SIDE, 0, 44),
		BackgroundTransparency = 1,
		Parent = main,
	})
	local noDrag = {} -- header controls that must not start a window drag
	local onToggleSidebar, navStep, updateNav -- assigned further down
	local headLeft = New("Frame", {
		Name = "HeadLeft",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, -170, 1, 0),
		Parent = topbar,
	})
	local function navButton(x, iconName, onClick)
		local hit = New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(x, 8),
			Size = UDim2.fromOffset(22, 28),
			Parent = headLeft,
		})
		animateButton(hit, function()
			return Theme.Accent
		end)
		local ic = uiIcon(hit, iconName, 18)
		ic.Root.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Root.Position = UDim2.fromScale(0.5, 0.5)
		local enabled, hover = true, false
		local function paint()
			local c = (not enabled) and Theme.Off:Lerp(Theme.SubText, 0.5) or (hover and Theme.Accent or Theme.Text)
			tintIcon(ic, c)
		end
		table.insert(hooks, paint)
		paint()
		hit.MouseEnter:Connect(function()
			hover = true
			paint()
		end)
		hit.MouseLeave:Connect(function()
			hover = false
			paint()
		end)
		onPress(hit, function()
			if enabled then
				onClick()
			end
		end)
		table.insert(noDrag, hit)
		return {
			SetEnabled = function(v)
				enabled = v
				paint()
			end,
			SetVisible = function(v)
				hit.Visible = v
				if not v then
					hover = false
					paint()
				end
			end,
		}
	end
	local backBtn, fwdBtn
	navButton(14, "sidebar", function()
		if onToggleSidebar then
			onToggleSidebar()
		end
	end)
	backBtn = navButton(36, "left", function()
		if navStep then
			navStep(-1)
		end
	end)
	fwdBtn = navButton(57, "right", function()
		if navStep then
			navStep(1)
		end
	end)
	backBtn.SetVisible(false)
	fwdBtn.SetVisible(false)

	addLogo(headLeft, 28, UDim2.fromOffset(86, 8), 14)
	Label({
		Text = opts.Title or "My Script",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		Position = UDim2.fromOffset(120, 6),
		Size = UDim2.new(1, -120, 0, 18),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = headLeft,
	}, "Text")
	Label({
		Text = opts.Subtitle or "Primary",
		TextSize = 11,
		Position = UDim2.fromOffset(120, 23),
		Size = UDim2.new(1, -120, 0, 14),
		Parent = headLeft,
	}, "SubText")

	-- divider between the header (title / subtitle / search) and the content
	themed(New("Frame", {
		Name = "HeaderLine",
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = main,
	}), { BackgroundColor3 = "Stroke" })

	-- search: frame holds icon + text box + clear button; the text is clipped inside the frame
	local searchFrame = themed(New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(150, 28),
		BorderSizePixel = 0,
		Parent = topbar,
	}, { Round(7) }), { BackgroundColor3 = "Field", BackgroundTransparency = "GlassField" })
	table.insert(noDrag, searchFrame)
	do
		local si = uiIcon(searchFrame, "search", 14)
		si.Root.AnchorPoint = Vector2.new(0, 0.5)
		si.Root.Position = UDim2.fromOffset(9, 14)
		themedIcon(si, "SubText")
	end
	local searchBox = themed(New("TextBox", {
		Text = "",
		PlaceholderText = "Search",
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = false,
		ClipsDescendants = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(30, 0),
		Size = UDim2.new(1, -54, 1, 0),
		Parent = searchFrame,
	}), { TextColor3 = "Text", PlaceholderColor3 = "SubText" })
	local clearBtn = New("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -4, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		Visible = false,
		Parent = searchFrame,
	})
	animateButton(clearBtn, function()
		return Theme.Accent
	end)
	do
		local ci = uiIcon(clearBtn, "close", 12)
		ci.Root.AnchorPoint = Vector2.new(0.5, 0.5)
		ci.Root.Position = UDim2.fromScale(0.5, 0.5)
		themedIcon(ci, "SubText")
	end
	onPress(clearBtn, function()
		searchBox.Text = ""
	end)
	onPress(searchFrame, function()
		searchBox:CaptureFocus()
	end)

	local pages = New("Frame", {
		Position = UDim2.new(0, SIDE, 0, 45),
		Size = UDim2.new(1, -SIDE, 1, -45),
		BackgroundTransparency = 1,
		Parent = main,
	})
	local sideOpen = true
	local LIGHTS_W = 74 -- room for the traffic lights when the sidebar is collapsed
	onToggleSidebar = function()
		sideOpen = not sideOpen
		local w = sideOpen and SIDE or 0
		local lx = sideOpen and 0 or LIGHTS_W
		tween(sideClip, { Size = UDim2.new(0, w, 1, 0) }, 0.2)
		tween(topbar, { Position = UDim2.new(0, w, 0, 0), Size = UDim2.new(1, -w, 0, 44) }, 0.2)
		tween(pages, { Position = UDim2.new(0, w, 0, 45), Size = UDim2.new(1, -w, 1, -45) }, 0.2)
		tween(headLeft, { Position = UDim2.fromOffset(lx, 0), Size = UDim2.new(1, -170 - lx, 1, 0) }, 0.2)
	end

	local noResults = Label({
		Text = "No results",
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = pages,
	}, "SubText")

	-- Dynamic Island-style menu toggle
	local openBtn = New("TextButton", {
		Name = "OpenButton",
		Text = opts.Title or "My Script",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(230, 48),
		ZIndex = 20,
		Parent = gui,
	}, {
		Round(24),
		Stroke("Stroke"),
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 48),
			PaddingRight = UDim.new(0, 12),
		}),
	})
	addLogo(openBtn, 30, UDim2.fromOffset(9, 9), 15)

	-- toggle-UI keybind state
	local NONE_KEY = Enum.KeyCode.Unknown
	local toggleKey = NONE_KEY
	do
		local k = opts.ToggleKey
		if k == false or k == "None" then
			toggleKey = NONE_KEY -- keyboard toggle disabled (the Dynamic Island button still works)
		else
			toggleKey = toKeyCode(k) or Enum.KeyCode.RightShift
		end
	end
	local bindBusy = false -- true while any Bind control is waiting for a key press
	local consumedInput -- the key press a Bind control just captured (never also toggles the UI)
	local activeBindCancel -- cancels the Bind control that is currently listening
	local toggleBindCtl -- the "Toggle UI" row in the settings tab (kept in sync)

	local refreshCurrent -- assigned after selectTab exists
	local openAnimTween
	local function setMainVisible(visible)
		if main.Visible == visible then
			return
		end
		main.Visible = visible
		if visible then
			if refreshCurrent then
				refreshCurrent()
			end
			if openAnimTween then
				openAnimTween:Cancel()
			end
			openAnimScale.Scale = 0.94
			openAnimTween = TweenService:Create(
				openAnimScale,
				TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Scale = 1 }
			)
			openAnimTween:Play()
		else
			if openAnimTween then
				openAnimTween:Cancel()
				openAnimTween = nil
			end
			openAnimScale.Scale = 1
		end
	end
	local function toggleMain()
		setMainVisible(not main.Visible)
	end

	-- dragging (window and sliders)
	local dragging, dragStart, startPos = false, nil, nil
	local activeSlider = nil

	local function overSearch(pos)
		for _, f in ipairs(noDrag) do
			local a, sz = f.AbsolutePosition, f.AbsoluteSize
			if f.Visible and pos.X >= a.X and pos.X <= a.X + sz.X and pos.Y >= a.Y and pos.Y <= a.Y + sz.Y then
				return true
			end
		end
		return false
	end
	local function makeDraggable(handle)
		handle.InputBegan:Connect(function(input)
			if isPress(input) and not overSearch(input.Position) then
				dragging, dragStart, startPos = true, input.Position, main.Position
			end
		end)
	end
	makeDraggable(topbar)
	makeDraggable(dragStrip)

	onPress(openBtn, toggleMain)

	table.insert(conns, UIS.InputChanged:Connect(function(input)
		if not isMove(input) then
			return
		end
		if dragging then
			local d = (input.Position - dragStart) / currentScale
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		elseif activeSlider then
			activeSlider(input.Position.X, input.Position.Y)
		end
	end))
	table.insert(conns, UIS.InputEnded:Connect(function(input)
		if isPress(input) then
			dragging = false
			activeSlider = nil
		end
	end))

	-- close confirmation dialog
	local confirm = New("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 100,
		Parent = main,
	}, { Round(12) })
	local dlg = themed(New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(280, 150),
		BorderSizePixel = 0,
		Parent = confirm,
	}, { Round(12), Stroke("Stroke") }), { BackgroundColor3 = "Card" })
	Label({
		Text = "Close script?",
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		Position = UDim2.fromOffset(20, 16),
		Size = UDim2.new(1, -40, 0, 20),
		Parent = dlg,
	}, "Text")
	Label({
		Text = "This turns off everything and removes the UI. You will need to run the script again to use it.",
		TextSize = 12,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(20, 42),
		Size = UDim2.new(1, -40, 0, 50),
		Parent = dlg,
	}, "SubText")
	local cancelBtn = themed(New("TextButton", {
		Text = "Cancel",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		AutoButtonColor = false,
		Position = UDim2.fromOffset(20, 104),
		Size = UDim2.fromOffset(115, 30),
		BorderSizePixel = 0,
		Parent = dlg,
	}, { Round(7), Stroke("Stroke") }), { BackgroundColor3 = "Field", TextColor3 = "Text" })
	animateButton(cancelBtn, function()
		return Theme.Accent
	end)
	local closeBtn = New("TextButton", {
		Text = "Close",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(255, 95, 87),
		Position = UDim2.fromOffset(145, 104),
		Size = UDim2.fromOffset(115, 30),
		BorderSizePixel = 0,
		Parent = dlg,
	}, { Round(7) })
	animateButton(closeBtn, function()
		return Theme.Accent
	end)

	----------------------------------------------------------------
	-- tabs, groups, search
	----------------------------------------------------------------
	local win = {}
	local currentTab
	local order = 0
	local tabsList = {}
	local groups, groupList = {}, {}

	local function applyFilter()
		local q = string.lower(searchBox.Text)
		q = string.gsub(q, "^%s+", "")
		q = string.gsub(q, "%s+$", "")
		clearBtn.Visible = (searchBox.Text ~= "")
		local firstMatch
		for _, tab in ipairs(tabsList) do
			local any = false
			for _, sec in ipairs(tab._sections) do
				local secAny = false
				for _, r in ipairs(sec.Rows) do
					local m = (q == "") or (string.find(r.Key, q, 1, true) ~= nil)
					r.Frame.Visible = m
					if m then
						if r.Div then
							r.Div.Visible = secAny
						end
						secAny = true
					end
				end
				sec.Holder.Visible = (q == "") or secAny
				if secAny then
					any = true
				end
			end
			tab.HasMatch = any
			tab.Btn.Visible = (q == "") or any
			if any and not firstMatch then
				firstMatch = tab
			end
		end

		local seenShown = false
		for _, g in ipairs(groupList) do
			local shown = false
			for _, t in ipairs(g.Tabs) do
				if t.Btn.Visible then
					shown = true
				end
			end
			g.Label.Visible = shown
			if g.Divider then
				g.Divider.Visible = shown and seenShown
			end
			if shown then
				seenShown = true
			end
		end

		updateNav()
		if q ~= "" and not firstMatch then
			noResults.Visible = true
			if currentTab then
				currentTab.Page.Visible = false
			end
			return
		end
		noResults.Visible = false
		if q ~= "" and currentTab and not currentTab.HasMatch and firstMatch then
			win._select(firstMatch, true)
		elseif currentTab then
			currentTab.Page.Visible = true
		end
	end
	searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)

	local function styleTab(tab)
		local selected = (currentTab == tab)
		tab.Btn.BackgroundColor3 = Theme.Selected
		local c = selected and Theme.SelectedText or Theme.SubText
		tab.Text.TextColor3 = c
		tab.Bar.Visible = selected
		if tab.Icon then
			tintIcon(tab.Icon, selected and c or Theme.SubText:Lerp(Theme.Text, 0.4))
		end
	end

	local function selectTab(tab, skipFilter)
		local old = currentTab
		local entering = old ~= nil and old ~= tab
		currentTab = tab
		if entering then
			old.Page.Visible = false
			tween(old.Btn, { BackgroundTransparency = 1 })
			styleTab(old)
		end
		tab.Page.Position = UDim2.fromOffset(entering and 16 or 0, 0)
		tab.Page.Visible = true
		if entering then
			tween(tab.Page, { Position = UDim2.fromOffset(0, 0) }, 0.22)
		end
		tween(tab.Btn, { BackgroundTransparency = 0 })
		styleTab(tab)
		if not skipFilter then
			applyFilter()
		end
		updateNav()
	end
	win._select = selectTab

	-- < / > : previous / next visible tab, one step per press.
	-- Middle tabs show both arrows; the first tab shows only > and the last tab shows only <.
	local function navList()
		local list = {}
		for _, t in ipairs(tabsList) do
			if t.Btn.Visible then
				table.insert(list, t)
			end
		end
		return list
	end
	local function navIndex(list)
		for i, t in ipairs(list) do
			if t == currentTab then
				return i
			end
		end
		return nil
	end
	updateNav = function()
		local list = navList()
		local i = navIndex(list)
		backBtn.SetVisible(i ~= nil and i > 1)
		fwdBtn.SetVisible(i ~= nil and i < #list)
	end
	navStep = function(dir)
		local list = navList()
		local i = navIndex(list)
		if i and list[i + dir] then
			selectTab(list[i + dir])
		end
	end

	-- Re-applies the current tab once the layout has settled (same effect as clicking another tab and
	-- coming back), so the first tab is usable right when the window opens. Calls are batched.
	local refreshToken = 0
	refreshCurrent = function()
		refreshToken += 1
		local my = refreshToken
		task.defer(function()
			if my ~= refreshToken or not gui.Parent or not currentTab then
				return
			end
			currentTab.Page.Visible = false
			task.wait()
			if my ~= refreshToken or not gui.Parent or not currentTab then
				return
			end
			selectTab(currentTab, false)
			task.wait(0.25)
			if my == refreshToken and gui.Parent and currentTab then
				selectTab(currentTab, false)
			end
		end)
	end

	-- ---------------------------------------------------------------- compat: value tracking, flags, config
	local flagged = {} -- { name, obj, kind } of every control that has a flag / idx
	local saveSoon = function() end -- replaced when config saving is enabled

	local function toMap(list)
		local m = {}
		for _, v in ipairs(list or {}) do
			m[v] = true
		end
		return m
	end
	local function mapToList(m, order)
		local list = {}
		if order then
			for _, v in ipairs(order) do
				if m[v] then
					table.insert(list, v)
				end
			end
		else
			for k, on in pairs(m) do
				if on then
					table.insert(list, k)
				end
			end
		end
		return list
	end

	-- wraps a raw control: other callback styles, .Value / :OnChanged / :SetValue, Flags / Options / Toggles,
	-- location[flag] writes (Wally), config saving and the helper methods other libraries give their objects
	local function wrapControl(Section, kind, n, meta, raw)
		local userCb = n.Callback
		local flag = firstNonNil(meta.idx, n.Flag)
		local location = n.Location
		local listeners = {}
		local obj
		local multi = (kind == "Dropdown" and n.Multi == true)
		local ddMode = "native" -- native: string / array, array: Rayfield, map: Linoria + Fluent
		local mode = n.Mode and string.lower(tostring(n.Mode)) or nil
		local state = (mode == "always")

		if kind == "Dropdown" then
			if n._rayfield then
				ddMode = "array"
			elseif meta.idx then
				ddMode = "map"
			end
			local list = n.Options or {}
			n.Options = list
			local d = n.Default
			local function byIndex(x)
				if type(x) == "number" and list[x] ~= nil and type(list[x]) ~= "number" then
					return list[x]
				end
				return x
			end
			if multi then
				local arr = {}
				if type(d) == "table" then
					if #d > 0 then
						for _, v in ipairs(d) do
							table.insert(arr, v)
						end
					else
						for _, v in ipairs(list) do
							if d[v] then
								table.insert(arr, v)
							end
						end
					end
				elseif d ~= nil then
					arr = { byIndex(d) }
				end
				n.Default = arr
			else
				if type(d) == "table" then
					if d[1] ~= nil then
						d = d[1]
					else
						local found
						for _, v in ipairs(list) do
							if d[v] then
								found = v
								break
							end
						end
						d = found
					end
				end
				n.Default = byIndex(d)
			end
		end

		local function ext(v) -- raw value -> what the script sees
			if kind == "Dropdown" then
				if ddMode == "array" then
					return multi and v or { v }
				elseif ddMode == "map" and multi then
					return toMap(v)
				end
			end
			return v
		end
		local function toRaw(v) -- what the script passes in -> raw value
			if kind == "Dropdown" then
				if type(v) == "table" then
					local list = (#v > 0) and v or mapToList(v, obj and obj.Values or n.Options)
					if multi then
						return list
					end
					return list[1]
				end
				return v
			elseif kind == "Bind" then
				if v == false or v == "None" then
					return false
				end
				return toKeyCode(v) or v
			end
			return v
		end
		local function setFields(v)
			if not obj then
				return
			end
			if kind == "Bind" then
				local nm = (v == nil or v == Enum.KeyCode.Unknown) and "None" or v.Name
				obj.Value, obj.CurrentKeybind = nm, nm
			elseif kind == "Dropdown" then
				local e = ext(v)
				obj.Value = e
				obj.CurrentOption = (ddMode == "array") and e or (multi and v or { v })
				if location and flag then
					location[flag] = e
				end
			elseif kind == "ColorPicker" then
				obj.Value, obj.Color, obj.CurrentValue = v, v, v
				if location and flag then
					location[flag] = v
				end
			else
				obj.Value, obj.CurrentValue = v, v
				if location and flag then
					location[flag] = v
				end
			end
		end
		local function changed(e)
			for _, fn in ipairs(listeners) do
				task.spawn(fn, e)
			end
			saveSoon()
		end

		-- callbacks the raw control will call
		if kind == "Button" then
			n.Callback = function()
				if userCb then
					task.spawn(userCb)
				end
			end
		elseif kind == "Bind" then
			local hold = (n.Hold == true)
			n.Callback = function(key)
				if mode == "always" then
					return
				end
				if mode == "toggle" then
					state = not state
				elseif mode == "hold" then
					state = true
				end
				if not userCb then
					return
				end
				if mode == "toggle" or mode == "hold" then
					task.spawn(userCb, state)
				elseif hold then
					task.spawn(userCb, true)
				else
					task.spawn(userCb, key)
				end
			end
			if hold or mode == "hold" then
				local userRel = n.Released
				n.Released = function(key)
					if mode == "hold" then
						state = false
					end
					if userCb then
						task.spawn(userCb, false)
					end
					if userRel then
						task.spawn(userRel, key)
					end
				end
			end
			local userChange = n.OnChange
			n.OnChange = function(key)
				setFields(key)
				changed(key.Name)
				if userChange then
					task.spawn(userChange, key)
				end
			end
		elseif kind ~= "Label" then
			n.Callback = function(v)
				setFields(v)
				local e = ext(v)
				for _, fn in ipairs(listeners) do
					task.spawn(fn, e)
				end
				saveSoon()
				if userCb then
					task.spawn(userCb, e)
				end
			end
		end

		obj = raw(Section, n)
		if type(obj) ~= "table" then
			return obj
		end
		obj.Type = kind
		obj.Flag = flag
		local row, titleLabel, descLabel = Section._lastRow, Section._lastTitle, Section._lastDesc
		obj.Row = row

		-- helpers every object gets
		function obj:SetName(text)
			if titleLabel then
				titleLabel.Text = tostring(text)
			end
		end
		function obj:SetDesc(text)
			text = tostring(text or "")
			if not (descLabel and row) then
				return
			end
			descLabel.Text = text
			if kind ~= "Label" then
				local has = text ~= ""
				descLabel.Visible = has
				row.Size = UDim2.new(1, 0, 0, has and 52 or 40)
				titleLabel.Position = UDim2.new(0, 14, 0, has and 9 or 0)
				titleLabel.Size = has and UDim2.new(1, -200, 0, 18) or UDim2.new(1, -200, 1, 0)
			end
		end
		function obj:SetVisible(v)
			if row then
				row.Visible = v ~= false
			end
		end
		function obj:Destroy()
			if row then
				row:Destroy()
			end
			if flag ~= nil then
				if library.Flags[flag] == obj then
					library.Flags[flag] = nil
				end
				if library.Options[flag] == obj then
					library.Options[flag] = nil
				end
				if library.Toggles[flag] == obj then
					library.Toggles[flag] = nil
				end
				for i, f in ipairs(flagged) do
					if f.obj == obj then
						table.remove(flagged, i)
						break
					end
				end
			end
		end
		obj.Remove = obj.Destroy
		-- Kavo-style updaters
		function obj:UpdateButton(t)
			obj:SetName(t)
		end
		function obj:UpdateToggle(t, st)
			if t ~= nil and t ~= "" then
				obj:SetName(t)
			end
			if st ~= nil and obj.SetSilent then
				obj:SetSilent(st)
			end
		end
		function obj:UpdateSlider(t, v)
			if t ~= nil and t ~= "" then
				obj:SetName(t)
			end
			if v ~= nil and obj.SetSilent then
				obj:SetSilent(v)
			end
		end
		function obj:UpdateDropdown(t)
			obj:SetName(t)
		end
		obj.UpdateTextBox, obj.UpdateKeybind, obj.UpdateColorPicker = obj.UpdateDropdown, obj.UpdateDropdown, obj.UpdateDropdown
		function obj:UpdateLabel(t)
			if kind == "Label" then
				obj:Set(t)
			else
				obj:SetName(t)
			end
		end
		-- Linoria: Toggle:AddColorPicker / AddKeyPicker, Button:AddButton (each becomes its own row)
		function obj:AddColorPicker(...)
			return Section:AddColorPicker(...)
		end
		function obj:AddKeyPicker(...)
			return Section:AddKeyPicker(...)
		end
		if kind == "Button" then
			function obj:AddButton(...)
				return Section:AddButton(...)
			end
			function obj:Set(text) -- Rayfield: ButtonObject:Set("new name")
				obj:SetName(text)
			end
			return obj
		elseif kind == "Label" then
			local rawLabelSet = obj.Set
			function obj:Set(v)
				if type(v) == "table" then
					if v.Title then
						obj:SetName(v.Title)
					end
					v = firstNonNil(v.Content, v.Text, "")
				end
				rawLabelSet(obj, tostring(v))
			end
			obj.SetText, obj.SetValue = obj.Set, obj.Set
			return obj
		end

		-- value controls
		local rawSet, rawGet = obj.Set, obj.Get
		local fires = not meta.native -- native Set is silent; the other libraries' Set runs the callback
		local function applyValue(v, fire)
			if kind == "Bind" and type(v) == "table" and typeof(v) ~= ENUMITEM then
				if v[2] then
					mode = string.lower(tostring(v[2]))
				end
				v = v[1]
			end
			rawSet(obj, toRaw(v))
			local cur = rawGet(obj)
			setFields(cur)
			if fire then
				if kind == "Bind" then
					changed(cur and cur.Name or "None")
				else
					local e = ext(cur)
					changed(e)
					if userCb then
						task.spawn(userCb, e)
					end
				end
			end
		end
		function obj:Set(v)
			applyValue(v, fires)
		end
		function obj:SetValue(v)
			applyValue(v, true)
		end
		function obj:SetSilent(v)
			applyValue(v, false)
		end
		obj.Fire = obj.SetValue
		obj.GetValue = rawGet
		function obj:OnChanged(fn)
			table.insert(listeners, fn)
			return {
				Disconnect = function()
					local i = table.find(listeners, fn)
					if i then
						table.remove(listeners, i)
					end
				end,
			}
		end
		if kind == "Dropdown" then
			local rawRefresh = obj.Refresh
			obj.Values = n.Options
			function obj:Refresh(list, keep)
				obj.Values = list or {}
				rawRefresh(obj, list, keep)
				setFields(rawGet(obj))
			end
			obj.SetOptions, obj.SetValues = obj.Refresh, obj.Refresh
		elseif kind == "Bind" then
			obj.Mode = mode
			function obj:GetState()
				return mode == "always" or state
			end
		end
		if kind == "Toggle" or kind == "Slider" or kind == "Dropdown" then
			obj.SetText = obj.SetName
		end

		setFields(rawGet(obj))
		if flag ~= nil then
			library.Flags[flag] = obj
			library.Options[flag] = obj
			if kind == "Toggle" then
				library.Toggles[flag] = obj
			end
			table.insert(flagged, { name = tostring(flag), obj = obj, kind = kind })
		end
		return obj
	end

	local function makeSection(tab, o)
		o = o or {}
		local Section = { _count = 0, _rowLog = {} }
		tab._order += 1

		local holder = New("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = tab._order,
			Parent = tab.Page,
		}, { New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
		local secEntry = { Holder = holder, Rows = {} }
		table.insert(tab._sections, secEntry)

		if o.Title and o.Icon then
			local head = New("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 18),
				LayoutOrder = 1,
				Parent = holder,
			})
			local sic = makeIcon(head, o.Icon, 16)
			sic.Root.AnchorPoint = Vector2.new(0, 0.5)
			sic.Root.Position = UDim2.fromOffset(0, 9)
			if o.IconColor then
				tintIcon(sic, o.IconColor)
			else
				themedIcon(sic, "Accent")
			end
			Section._titleLabel = Label({
				Text = o.Title,
				Font = Enum.Font.GothamBold,
				AutomaticSize = Enum.AutomaticSize.Y,
				Position = UDim2.fromOffset(24, 0),
				Size = UDim2.new(1, -24, 0, 18),
				TextWrapped = true,
				Parent = head,
			}, "Text")
		elseif o.Title then
			Section._titleLabel = Label({
				Text = o.Title,
				Font = Enum.Font.GothamBold,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				TextWrapped = true,
				LayoutOrder = 1,
				Parent = holder,
			}, "Text")
		end
		if o.Desc then
			Label({
				Text = o.Desc,
				TextSize = 12,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				TextWrapped = true,
				LayoutOrder = 2,
				Parent = holder,
			}, "SubText")
		end

		local card = themed(New("Frame", {
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 3,
			Parent = holder,
		}, { Round(8), Stroke("Stroke"), New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) }), {
			BackgroundColor3 = "Card", BackgroundTransparency = "GlassCard",
		})

		local function newRow(title, desc)
			Section._count += 1
			refreshCurrent()
			local hasDesc = desc ~= nil and desc ~= ""
			local row = New("Frame", {
				Name = title or "Row",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, hasDesc and 52 or 40),
				LayoutOrder = Section._count,
				Parent = card,
			})
			local div
			if Section._count > 1 then
				div = themed(New("Frame", {
					Position = UDim2.fromOffset(14, 0),
					Size = UDim2.new(1, -28, 0, 1),
					BorderSizePixel = 0,
					Parent = row,
				}), { BackgroundColor3 = "Stroke" })
			end
			local titleLabel = Label({
				Text = title or "",
				Font = Enum.Font.GothamMedium,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.new(0, 14, 0, hasDesc and 9 or 0),
				Size = hasDesc and UDim2.new(1, -200, 0, 18) or UDim2.new(1, -200, 1, 0),
				Parent = row,
			}, "Text")
			local descLabel = Label({
				Text = desc or "",
				TextSize = 12,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Visible = hasDesc,
				Position = UDim2.new(0, 14, 0, 28),
				Size = UDim2.new(1, -200, 0, 16),
				Parent = row,
			}, "SubText")
			table.insert(secEntry.Rows, {
				Frame = row,
				Div = div,
				Key = string.lower(table.concat({
					tab.Name or "", o.Title or "", o.Desc or "", title or "", desc or "",
				}, " ")),
			})
			Section._lastRow, Section._lastTitle, Section._lastDesc = row, titleLabel, descLabel
			table.insert(Section._rowLog, row)
			return row, descLabel
		end

		function Section:AddToggle(t)
			local row = newRow(t.Name, t.Desc)
			local state = t.Default == true
			local track = New("TextButton", {
				Text = "",
				AutoButtonColor = false,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(40, 22),
				BackgroundColor3 = state and Theme.Accent or Theme.Off,
				BorderSizePixel = 0,
				Parent = row,
			}, { Round(11) })
			animateButton(track, function()
				return Theme.Accent
			end)
			local knob = New("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Parent = track,
			}, { Round(8) })
			table.insert(hooks, function()
				track.BackgroundColor3 = state and Theme.Accent or Theme.Off
			end)

			local obj = {}
			local function set(v, silent)
				state = v
				tween(track, { BackgroundColor3 = v and Theme.Accent or Theme.Off })
				tween(knob, { Position = v and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
				if not silent and t.Callback then
					task.spawn(t.Callback, v)
				end
			end
			track.Activated:Connect(function()
				set(not state)
			end)
			function obj:Set(v)
				set(v, true)
			end
			function obj:Get()
				return state
			end
			return obj
		end

		function Section:AddDropdown(d)
			local row = newRow(d.Name, d.Desc)
			local options = d.Options or {}
			local multi = d.Multi == true
			local value -- a string, or an array of strings when Multi = true
			if multi then
				value = {}
				if type(d.Default) == "table" then
					for _, v in ipairs(d.Default) do
						table.insert(value, v)
					end
				elseif d.Default ~= nil then
					value = { d.Default }
				end
			else
				value = d.Default or options[1]
			end
			local function display(v)
				if multi then
					return (#v == 0) and "None" or table.concat(v, ", ")
				end
				return tostring(v)
			end
			local function isSel(opt)
				if multi then
					return table.find(value, opt) ~= nil
				end
				return opt == value
			end

			local btn = themed(New("TextButton", {
				Text = "",
				AutoButtonColor = false,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(150, 26),
				BorderSizePixel = 0,
				Parent = row,
			}, { Round(6), Stroke("Stroke") }), { BackgroundColor3 = "Field", BackgroundTransparency = "GlassField" })
			animateButton(btn, function()
				return Theme.Accent
			end)
			local valueLabel = Label({
				Text = display(value),
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -30, 1, 0),
				Parent = btn,
			}, "Text")
			local chev = uiIcon(btn, "updown", 14)
			chev.Root.AnchorPoint = Vector2.new(1, 0.5)
			chev.Root.Position = UDim2.new(1, -6, 0.5, 0)
			themedIcon(chev, "SubText")

			local obj = {}
			local dropdownOpen = false
			local function set(v, silent)
				if multi then
					local copy = {}
					for _, x in ipairs(v or {}) do
						table.insert(copy, x)
					end
					v = copy
				end
				value = v
				valueLabel.Text = display(v)
				if not silent and d.Callback then
					task.spawn(d.Callback, v)
				end
			end

			btn.Activated:Connect(function()
				if dropdownOpen then
					return
				end
				dropdownOpen = true
				local catcher = New("TextButton", {
					Text = "",
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 50,
					Parent = gui,
				})
				local popW = 170
				local popH = math.min(#options * 26 + 8, 170)
				local abs, size = btn.AbsolutePosition, btn.AbsoluteSize
				local screen = gui.AbsoluteSize
				local x = math.clamp(abs.X + size.X - popW, 4, math.max(4, screen.X - popW - 4))
				local y = abs.Y + size.Y + 4
				if y + popH > screen.Y - 4 then
					y = math.max(4, abs.Y - popH - 4)
				end
				local opensUp = y < abs.Y
				local pop = New("ScrollingFrame", {
					Position = UDim2.fromOffset(x, opensUp and y + popH or y),
					Size = UDim2.fromOffset(popW, 0),
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					ScrollBarThickness = 3,
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ZIndex = 51,
					Parent = gui,
				}, {
					Round(8),
					New("UIStroke", { Color = Theme.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
					New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
					New("UIPadding", {
						PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
						PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
					}),
				})
				tween(pop, {
					Position = UDim2.fromOffset(x, y),
					Size = UDim2.fromOffset(popW, popH),
				}, 0.2)
				local function close()
					if not dropdownOpen then
						return
					end
					dropdownOpen = false
					catcher:Destroy()
					tween(pop, {
						Position = UDim2.fromOffset(x, opensUp and y + popH or y),
						Size = UDim2.fromOffset(popW, 0),
					}, 0.16)
					task.delay(0.18, function()
						if pop.Parent then
							pop:Destroy()
						end
					end)
				end
				catcher.Activated:Connect(close)
				for i, opt in ipairs(options) do
					local item = New("TextButton", {
						Text = tostring(opt),
						Font = Enum.Font.Gotham,
						TextSize = 13,
						TextColor3 = isSel(opt) and Theme.Accent or Theme.Text,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutoButtonColor = false,
						BackgroundColor3 = Theme.Selected,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 0, 26),
						LayoutOrder = i,
						ZIndex = 52,
						Parent = pop,
					}, { Round(5), New("UIPadding", { PaddingLeft = UDim.new(0, 8) }) })
					animateButton(item, function()
						return Theme.Accent
					end)
					item.MouseEnter:Connect(function()
						tween(item, { BackgroundTransparency = 0.75 })
					end)
					item.MouseLeave:Connect(function()
						tween(item, { BackgroundTransparency = 1 })
					end)
					item.Activated:Connect(function()
						if multi then
							local on = table.find(value, opt) ~= nil
							local cur = {}
							for _, o2 in ipairs(options) do
								local keep
								if o2 == opt then
									keep = not on
								else
									keep = table.find(value, o2) ~= nil
								end
								if keep then
									table.insert(cur, o2)
								end
							end
							set(cur)
							item.TextColor3 = isSel(opt) and Theme.Accent or Theme.Text
						else
							set(opt)
							close()
						end
					end)
				end
			end)

			function obj:Set(v)
				if multi and type(v) ~= "table" then
					v = { v }
				end
				set(v, true)
			end
			function obj:Get()
				if multi then
					return table.clone(value)
				end
				return value
			end
			-- replace the option list (value is kept when it is still in the list)
			function obj:Refresh(list, keepValue)
				options = list or {}
				if multi then
					local keep = {}
					for _, v in ipairs(value) do
						if table.find(options, v) then
							table.insert(keep, v)
						end
					end
					set(keep, true)
				elseif not keepValue and not table.find(options, value) then
					set(options[1], true)
				end
			end
			obj.SetOptions = obj.Refresh
			obj.SetValues = obj.Refresh
			return obj
		end

		function Section:AddSlider(s)
			local row = newRow(s.Name, s.Desc)
			local min, max, inc = s.Min or 0, s.Max or 100, s.Increment or 1
			local value = math.clamp(s.Default or min, min, max)

			local valueLabel = Label({
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(46, 20),
				Parent = row,
			}, "SubText")
			local hit = New("TextButton", {
				Text = "",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -66, 0.5, 0),
				Size = UDim2.fromOffset(110, 22),
				Parent = row,
			})
			local bar = themed(New("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0, 6),
				BorderSizePixel = 0,
				Parent = hit,
			}, { Round(3) }), { BackgroundColor3 = "Off" })
			local fill = themed(New("Frame", {
				Size = UDim2.fromScale(0, 1),
				BorderSizePixel = 0,
				Parent = bar,
			}, { Round(3) }), { BackgroundColor3 = "Accent" })

			local function render()
				local span = max - min
				fill.Size = UDim2.fromScale(span > 0 and (value - min) / span or 0, 1)
				valueLabel.Text = tostring(value) .. (s.Suffix or "")
			end
			render()

			local function fromX(x)
				local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
				local v = min + (max - min) * a
				v = math.floor(v / inc + 0.5) * inc
				v = math.clamp(tonumber(string.format("%.4f", v)), min, max)
				if v ~= value then
					value = v
					render()
					if s.Callback then
						task.spawn(s.Callback, v)
					end
				end
			end

			hit.InputBegan:Connect(function(input)
				if isPress(input) then
					activeSlider = fromX
					fromX(input.Position.X)
				end
			end)

			local obj = {}
			function obj:Set(v)
				value = math.clamp(tonumber(string.format("%.4f", v)), min, max)
				render()
			end
			function obj:Get()
				return value
			end
			return obj
		end

		function Section:AddButton(b)
			local row = newRow(b.Name, b.Desc)
			local btn = themed(New("TextButton", {
				Text = b.ButtonText or "Run",
				Font = Enum.Font.GothamMedium,
				TextSize = 13,
				AutoButtonColor = false,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(80, 26),
				BorderSizePixel = 0,
				Parent = row,
			}, { Round(6), Stroke("Stroke") }), {
				BackgroundColor3 = "Field", BackgroundTransparency = "GlassField", TextColor3 = "Text",
			})
			btn.MouseEnter:Connect(function()
				tween(btn, { BackgroundColor3 = Theme.Off })
			end)
			btn.MouseLeave:Connect(function()
				tween(btn, { BackgroundColor3 = Theme.Field })
			end)
			animateButton(btn, function()
				return Theme.Accent
			end)
			btn.Activated:Connect(function()
				if b.Callback then
					task.spawn(b.Callback)
				end
			end)
			local obj = { Instance = btn }
			function obj:SetText(text)
				btn.Text = tostring(text)
			end
			return obj
		end

		function Section:AddLabel(l)
			local row, descLabel = newRow(l.Name, l.Value or " ")
			row.AutomaticSize = Enum.AutomaticSize.Y
			descLabel.TextTruncate = Enum.TextTruncate.None
			descLabel.TextWrapped = true
			descLabel.TextYAlignment = Enum.TextYAlignment.Top
			descLabel.AutomaticSize = Enum.AutomaticSize.Y
			descLabel.Size = UDim2.new(1, -28, 0, 16)
			New("UIPadding", { PaddingBottom = UDim.new(0, 10), Parent = descLabel })
			if l.Name == nil or l.Name == "" then
				row.Size = UDim2.new(1, 0, 0, 40)
				descLabel.Position = UDim2.new(0, 14, 0, 10)
			end
			local obj = {}
			function obj:Set(text)
				descLabel.Text = tostring(text)
			end
			return obj
		end

		function Section:AddTextbox(t)
			local row = newRow(t.Name, t.Desc)
			local box = themed(New("TextBox", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(math.clamp(tonumber(t.Width) or 150, 60, 170), 26),
				Text = tostring(t.Default or ""),
				PlaceholderText = tostring(t.Placeholder or ""),
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = t.ClearOnFocus == true,
				ClipsDescendants = true,
				BorderSizePixel = 0,
				Parent = row,
			}, {
				Round(6),
				Stroke("Stroke"),
				New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
			}), {
				BackgroundColor3 = "Field", BackgroundTransparency = "GlassField",
				TextColor3 = "Text", PlaceholderColor3 = "SubText",
			})
			local stroke = box:FindFirstChildOfClass("UIStroke")
			box.Focused:Connect(function()
				if stroke then
					stroke.Color = Theme.Accent
				end
			end)
			if t.Numeric then
				box:GetPropertyChangedSignal("Text"):Connect(function()
					local f = string.gsub(box.Text, "[^%d%.%-]", "")
					if f ~= box.Text then
						box.Text = f
					end
				end)
			end
			-- fires when the user presses Enter or clicks away (EnterOnly = true -> only on Enter)
			box.FocusLost:Connect(function(enterPressed)
				if stroke then
					stroke.Color = Theme.Stroke
				end
				if t.EnterOnly and not enterPressed then
					return
				end
				if t.Callback then
					task.spawn(t.Callback, box.Text)
				end
				if t.ClearAfter then
					box.Text = ""
				end
			end)
			local obj = { Instance = box }
			function obj:Set(v)
				box.Text = tostring(v)
			end
			function obj:Get()
				return box.Text
			end
			return obj
		end

		function Section:AddBind(b)
			local row = newRow(b.Name, b.Desc)
			local NONE = Enum.KeyCode.Unknown
			local toKey = toKeyCode
			local key
			if b.Default == false or b.Default == "None" then
				key = NONE
			else
				key = toKey(b.Default) or Enum.KeyCode.RightControl
			end
			local listening = false

			local btn = themed(New("TextButton", {
				Text = "",
				Font = Enum.Font.GothamMedium,
				TextSize = 13,
				AutoButtonColor = false,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(96, 26),
				BorderSizePixel = 0,
				Parent = row,
			}, { Round(6), Stroke("Stroke") }), {
				BackgroundColor3 = "Field", BackgroundTransparency = "GlassField", TextColor3 = "Text",
			})
			animateButton(btn, function()
				return Theme.Accent
			end)
			local function paint()
				btn.Text = listening and "..." or (key == NONE and "None" or key.Name)
				btn.TextColor3 = listening and Theme.Accent or Theme.Text
			end
			paint()
			local cancelListen
			local function stopListening()
				listening = false
				paint()
				if activeBindCancel == cancelListen then
					activeBindCancel = nil
					task.defer(function() -- after this input event, so the key just captured never toggles the UI
						if not activeBindCancel then
							bindBusy = false
						end
					end)
				end
			end
			cancelListen = stopListening
			btn.Activated:Connect(function()
				if listening then
					stopListening()
				else
					if activeBindCancel then
						activeBindCancel()
					end
					listening = true
					activeBindCancel = cancelListen
					bindBusy = true
					paint()
				end
			end)

			-- click the box, then press a key (Esc cancels, Backspace clears)
			table.insert(conns, UIS.InputBegan:Connect(function(input, processed)
				if input.UserInputType ~= Enum.UserInputType.Keyboard then
					return
				end
				if listening then
					consumedInput = input
					if input.KeyCode ~= Enum.KeyCode.Escape then
						key = (input.KeyCode == Enum.KeyCode.Backspace) and NONE or input.KeyCode
						if b.OnChange then
							task.spawn(b.OnChange, key)
						end
					end
					stopListening()
					return
				end
				if processed or key == NONE then
					return
				end
				if input.KeyCode == key and b.Callback then
					task.spawn(b.Callback, key)
				end
			end))
			if b.Released then
				table.insert(conns, UIS.InputEnded:Connect(function(input)
					if not listening and key ~= NONE and input.KeyCode == key then
						task.spawn(b.Released, key)
					end
				end))
			end

			local obj = {}
			function obj:Set(k)
				if k == false then
					key = NONE
				else
					key = toKey(k) or key
				end
				paint()
			end
			function obj:Get()
				return key
			end
			return obj
		end

		function Section:AddColorPicker(c)
			local row = newRow(c.Name, c.Desc)
			local value = c.Default
			if typeof(value) ~= COLOR3 then
				value = Color3.new(1, 1, 1)
			end
			local swatch = New("TextButton", {
				Text = "",
				AutoButtonColor = false,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(46, 22),
				BackgroundColor3 = value,
				BorderSizePixel = 0,
				Parent = row,
			}, { Round(6), Stroke("Stroke") })
			animateButton(swatch, function()
				return Theme.Accent
			end)
			local function set(v, silent)
				value = v
				swatch.BackgroundColor3 = v
				if not silent and c.Callback then
					task.spawn(c.Callback, v)
				end
			end

			swatch.Activated:Connect(function()
				local catcher = New("TextButton", {
					Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 50, Parent = gui,
				})
				local popW, popH = 190, 176
				local abs, size = swatch.AbsolutePosition, swatch.AbsoluteSize
				local screen = gui.AbsoluteSize
				local x = math.clamp(abs.X + size.X - popW, 4, math.max(4, screen.X - popW - 4))
				local y = abs.Y + size.Y + 4
				if y + popH > screen.Y - 4 then
					y = math.max(4, abs.Y - popH - 4)
				end
				local pop = New("Frame", {
					Position = UDim2.fromOffset(x, y),
					Size = UDim2.fromOffset(popW, popH),
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					ZIndex = 51,
					Parent = gui,
				}, {
					Round(8),
					New("UIStroke", { Color = Theme.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
				})
				local h, sat, val = value:ToHSV()
				local sv = New("TextButton", {
					Text = "", AutoButtonColor = false,
					Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(170, 100),
					BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, ZIndex = 52, Parent = pop,
				}, { Round(4) })
				New("Frame", {
					Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
					ZIndex = 53, Parent = sv,
				}, { Round(4), New("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
				New("Frame", {
					Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0,
					ZIndex = 54, Parent = sv,
				}, { Round(4), New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
				local svCur = New("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10),
					BackgroundTransparency = 1, ZIndex = 55, Parent = sv,
				}, { Round(5), New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }) })

				local stops = {}
				for i = 0, 6 do
					table.insert(stops, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(math.min(i / 6, 0.999), 1, 1)))
				end
				local hue = New("TextButton", {
					Text = "", AutoButtonColor = false,
					Position = UDim2.fromOffset(10, 118), Size = UDim2.fromOffset(170, 12),
					BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 52, Parent = pop,
				}, { Round(6), New("UIGradient", { Color = ColorSequence.new(stops) }) })
				local hueCur = New("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, 16),
					BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 53, Parent = hue,
				}, { Round(2), New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 }) })

				local hex = New("TextBox", {
					Position = UDim2.fromOffset(10, 140), Size = UDim2.fromOffset(170, 26),
					Text = hexOf(value), Font = Enum.Font.GothamMedium, TextSize = 13,
					TextColor3 = Theme.Text, BackgroundColor3 = Theme.Card, ClearTextOnFocus = false,
					BorderSizePixel = 0, ZIndex = 52, Parent = pop,
				}, { Round(6) })

				local function place()
					sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
					svCur.Position = UDim2.fromScale(sat, 1 - val)
					hueCur.Position = UDim2.fromScale(h, 0.5)
				end
				local function refresh()
					place()
					local col = Color3.fromHSV(h, sat, val)
					hex.Text = hexOf(col)
					set(col)
				end
				place()
				local function fromSV(px, py)
					local a, sz = sv.AbsolutePosition, sv.AbsoluteSize
					sat = math.clamp((px - a.X) / math.max(sz.X, 1), 0, 1)
					val = 1 - math.clamp((py - a.Y) / math.max(sz.Y, 1), 0, 1)
					refresh()
				end
				local function fromHue(px)
					local a, sz = hue.AbsolutePosition, hue.AbsoluteSize
					h = math.clamp((px - a.X) / math.max(sz.X, 1), 0, 0.999)
					refresh()
				end
				sv.InputBegan:Connect(function(input)
					if isPress(input) then
						activeSlider = fromSV
						fromSV(input.Position.X, input.Position.Y)
					end
				end)
				hue.InputBegan:Connect(function(input)
					if isPress(input) then
						activeSlider = fromHue
						fromHue(input.Position.X)
					end
				end)
				hex.FocusLost:Connect(function()
					local r, g, b = string.match(hex.Text, "^#?(%x%x)(%x%x)(%x%x)$")
					if r then
						local col = Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
						h, sat, val = col:ToHSV()
						refresh()
					else
						hex.Text = hexOf(value)
					end
				end)
				catcher.Activated:Connect(function()
					activeSlider = nil
					catcher:Destroy()
					pop:Destroy()
				end)
			end)

			local obj = {}
			function obj:Set(v)
				if typeof(v) == COLOR3 then
					set(v, true)
				elseif type(v) == "table" and v.R then
					set(Color3.fromRGB(v.R, v.G or 0, v.B or 0), true)
				end
			end
			function obj:Get()
				return value
			end
			return obj
		end

		local function addDivider()
			Section._count += 1
			local row = New("Frame", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), LayoutOrder = Section._count, Parent = card,
			})
			themed(New("Frame", {
				AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0),
				Size = UDim2.new(1, -28, 0, 1), BorderSizePixel = 0, Parent = row,
			}), { BackgroundColor3 = "Stroke" })
			table.insert(Section._rowLog, row)
			return { Row = row, Destroy = function() row:Destroy() end }
		end
		local function addBlank(_, h)
			Section._count += 1
			local row = New("Frame", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, tonumber(h) or 8),
				LayoutOrder = Section._count, Parent = card,
			})
			table.insert(Section._rowLog, row)
			return { Row = row, Destroy = function() row:Destroy() end }
		end
		for _, nm in ipairs(DIVIDER_NAMES) do
			Section[nm] = addDivider
		end
		for _, nm in ipairs(BLANK_NAMES) do
			Section[nm] = addBlank
		end
		-- Rayfield: SectionObject:Set("new name")
		function Section:Set(text)
			if Section._titleLabel then
				Section._titleLabel.Text = tostring(text)
			end
		end

		-- every control answers to every naming / argument style (see KIND_NAMES and parseControl)
		local rawControls = {}
		for kind in pairs(KIND_NAMES) do
			rawControls[kind] = Section["Add" .. kind]
		end
		local function dispatch(kind, nameUsed, ...)
			local n, meta = parseControl(kind, nameUsed, ...)
			return wrapControl(Section, kind, n, meta, rawControls[kind])
		end
		for kind, names in pairs(KIND_NAMES) do
			local function install(nm)
				Section[nm] = function(self, ...)
					return dispatch(kind, nm, shift(self, Section, ...))
				end
			end
			install("Add" .. kind)
			for _, nm in ipairs(names) do
				install(nm)
			end
		end

		-- Venyx updaters: section:updateToggle(control, title, value) ...
		local function rename(ctl, title)
			if type(ctl) == "table" and title ~= nil and ctl.SetName then
				ctl:SetName(title)
			end
		end
		function Section:updateButton(ctl, title)
			rename(ctl, title)
		end
		function Section:updateToggle(ctl, title, value)
			rename(ctl, title)
			if value ~= nil and ctl and ctl.SetSilent then
				ctl:SetSilent(value)
			end
		end
		function Section:updateSlider(ctl, title, value)
			rename(ctl, title)
			if value ~= nil and ctl and ctl.SetSilent then
				ctl:SetSilent(value)
			end
		end
		function Section:updateDropdown(ctl, title, list)
			rename(ctl, title)
			if list and ctl and ctl.Refresh then
				ctl:Refresh(list)
			end
		end
		function Section:updateKeybind(ctl, title, key)
			rename(ctl, title)
			if key ~= nil and ctl and ctl.SetSilent then
				ctl:SetSilent(key)
			end
		end
		function Section:updateColorPicker(ctl, title, color)
			rename(ctl, title)
			if color ~= nil and ctl and ctl.SetSilent then
				ctl:SetSilent(color)
			end
		end

		-- Linoria / Obsidian: groupbox:AddDependencyBox() + box:SetupDependencies({ { Toggles.X, true } })
		function Section:AddDependencyBox()
			local rows = {}
			local box = {}
			setmetatable(box, {
				__index = function(_, k)
					local f = Section[k]
					if type(f) ~= "function" then
						return nil
					end
					return function(_, ...)
						local before = #Section._rowLog
						local r = f(Section, ...)
						for i = before + 1, #Section._rowLog do
							table.insert(rows, Section._rowLog[i])
						end
						return r
					end
				end,
			})
			function box:SetupDependencies(deps)
				local function eval()
					local show = true
					for _, d in ipairs(deps or {}) do
						if d[1] and d[1].Value ~= d[2] then
							show = false
						end
					end
					for _, r in ipairs(rows) do
						r.Visible = show
					end
				end
				for _, d in ipairs(deps or {}) do
					if d[1] and d[1].OnChanged then
						d[1]:OnChanged(eval)
					end
				end
				eval()
			end
			return box
		end
		-- media rows have no equivalent here: accepted and ignored
		function Section:AddImage()
			return {}
		end
		Section.AddVideo = Section.AddImage

		installFuzzy(Section, {
			control = function(kind)
				return function(self, ...)
					return Section["Add" .. kind](Section, shift(self, Section, ...))
				end
			end,
			divider = function()
				return function()
					return Section.AddDivider(Section)
				end
			end,
			blank = function()
				return function(self, ...)
					return Section.AddBlank(Section, shift(self, Section, ...))
				end
			end,
			section = function() -- nested groups are not supported: the call returns this section
				return function()
					return Section
				end
			end,
			notify = function()
				return function(self, ...)
					return library.Notify(shift(self, Section, ...))
				end
			end,
		})
		return Section
	end

	function win:AddTab(o, icon2)
		if type(o) == "string" then
			o = { Name = o }
			if icon2 ~= nil and type(icon2) ~= "table" then
				o.Icon = icon2
			end
		end
		o = copyTable(o or {})
		if type(o.Icon) == "number" then
			o.Icon = tostring(o.Icon)
		end
		o.Name = tostring(firstNonNil(o.Name, o.Title, o.Text, "Tab"))
		local group
		if o.Section then
			group = groups[o.Section]
			if not group then
				group = { Tabs = {} }
				groups[o.Section] = group
				if #groupList > 0 then
					order += 1
					group.Divider = themed(New("Frame", {
						Size = UDim2.new(1, 0, 0, 1),
						BorderSizePixel = 0,
						LayoutOrder = order,
						Parent = sideList,
					}), { BackgroundColor3 = "Stroke" })
				end
				order += 1
				group.Label = Label({
					Text = o.Section,
					TextSize = 11,
					Size = UDim2.new(1, 0, 0, 26),
					LayoutOrder = order,
					Parent = sideList,
				}, "SubText")
				New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), Parent = group.Label })
				table.insert(groupList, group)
			end
		end

		order += 1
		local btn = New("TextButton", {
			Name = o.Name,
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Theme.Selected,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = order,
			Parent = sideList,
		}, { Round(6) })
		local bar = themed(New("Frame", {
			Position = UDim2.new(0, 3, 0.5, -7),
			Size = UDim2.fromOffset(3, 14),
			BorderSizePixel = 0,
			Visible = false,
			Parent = btn,
		}, { Round(2) }), { BackgroundColor3 = "Accent" })

		local icon
		if o.Icon then
			icon = makeIcon(btn, o.Icon, 17)
			icon.Root.AnchorPoint = Vector2.new(0, 0.5)
			icon.Root.Position = UDim2.new(0, 11, 0.5, 0)
		end
		local text = New("TextLabel", {
			BackgroundTransparency = 1,
			Text = o.Name,
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, icon and 36 or 14, 0, 0),
			Size = UDim2.new(1, -42, 1, 0),
			Parent = btn,
		})

		local page = New("ScrollingFrame", {
			Name = o.Name,
			Visible = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromScale(1, 1),
			ScrollBarThickness = 3,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = pages,
		}, {
			New("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }),
			New("UIPadding", {
				PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14),
				PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
			}),
		})
		themed(page, { ScrollBarImageColor3 = "Off" })

		local Tab = {
			Name = o.Name, Btn = btn, Text = text, Icon = icon, Bar = bar,
			Page = page, _sections = {}, _order = 0, HasMatch = true,
		}
		function Tab:AddSection(so, icon2)
			if type(so) == "string" then
				so = { Title = so }
				if type(icon2) == "string" then
					so.Icon = icon2
				end
			end
			local c = copyTable(so or {})
			c.Title = firstNonNil(c.Title, c.Name, c.Text)
			c.Desc = firstNonNil(c.Desc, c.Description)
			local sec = makeSection(Tab, c)
			Tab._current = sec
			return sec
		end
		do
			local rawAddSection = Tab.AddSection
			Tab.AddSection = function(self, ...)
				return rawAddSection(Tab, shift(self, Tab, ...))
			end
		end
		for _, nm in ipairs(SECTION_NAMES) do
			Tab[nm] = Tab.AddSection
		end

		-- Linoria: Tab:AddTabbox() / tabbox:AddTab("name") -> one section per tab
		local function newTabbox()
			local tb = { Tabs = {} }
			function tb:AddTab(name)
				local sec = Tab:AddSection({ Title = tostring(name) })
				tb.Tabs[name] = sec
				return sec
			end
			return tb
		end
		Tab.AddTabbox, Tab.AddLeftTabbox, Tab.AddRightTabbox = newTabbox, newTabbox, newTabbox

		-- controls called on the tab itself go into the newest section (Rayfield: CreateSection then CreateButton ...)
		local function current()
			if not Tab._current then
				Tab._current = makeSection(Tab, {})
			end
			return Tab._current
		end
		local function route(nm)
			Tab[nm] = function(self, ...)
				local sec = current()
				return sec[nm](sec, shift(self, Tab, ...))
			end
		end
		for kind, names in pairs(KIND_NAMES) do
			route("Add" .. kind)
			for _, nm in ipairs(names) do
				route(nm)
			end
		end
		for _, nm in ipairs(DIVIDER_NAMES) do
			route(nm)
		end
		for _, nm in ipairs(BLANK_NAMES) do
			route(nm)
		end
		installFuzzy(Tab, {
			control = function(kind)
				return function(self, ...)
					local sec = current()
					return sec["Add" .. kind](sec, shift(self, Tab, ...))
				end
			end,
			divider = function()
				return function()
					return current():AddDivider()
				end
			end,
			blank = function()
				return function(self, ...)
					return current():AddBlank(shift(self, Tab, ...))
				end
			end,
			section = function()
				return function(self, ...)
					return Tab.AddSection(Tab, shift(self, Tab, ...))
				end
			end,
			tabbox = function()
				return newTabbox
			end,
			notify = function()
				return function(self, ...)
					return library.Notify(shift(self, Tab, ...))
				end
			end,
		})
		table.insert(tabsList, Tab)
		if group then
			table.insert(group.Tabs, Tab)
		end
		table.insert(hooks, function()
			styleTab(Tab)
		end)

		btn.Activated:Connect(function()
			selectTab(Tab)
		end)
		animateButton(btn, function()
			return Theme.Accent
		end)
		if not currentTab then
			selectTab(Tab)
		else
			styleTab(Tab)
		end
		updateNav()
		refreshCurrent()
		return Tab
	end
	do
		local rawAddTab = win.AddTab
		win.AddTab = function(self, ...)
			return rawAddTab(win, shift(self, win, ...))
		end
	end
	for _, nm in ipairs(TAB_NAMES) do
		win[nm] = win.AddTab
	end

	-- Window:Section(...) without a tab: goes into an automatic "Main" tab
	local defaultTab
	local function defTab()
		if not defaultTab then
			defaultTab = win:AddTab({ Name = opts.DefaultTabName or "Main", Icon = "home" })
		end
		return defaultTab
	end
	for _, nm in ipairs(SECTION_NAMES) do
		win[nm] = function(self, ...)
			local so, icon2 = shift(self, win, ...)
			return defTab():AddSection(so, icon2)
		end
	end
	-- controls called on the window itself (Wally style: window:Toggle(...), window:Button(...)) go into the
	-- automatic tab, under the newest section
	local function routeWin(nm)
		if win[nm] ~= nil or nm == "Toggle" then
			return
		end
		win[nm] = function(self, ...)
			local t = defTab()
			return t[nm](t, shift(self, win, ...))
		end
	end
	for kind, names in pairs(KIND_NAMES) do
		routeWin("Add" .. kind)
		for _, nm in ipairs(names) do
			routeWin(nm)
		end
	end
	for _, nm in ipairs(DIVIDER_NAMES) do
		routeWin(nm)
	end
	for _, nm in ipairs(BLANK_NAMES) do
		routeWin(nm)
	end

	-- settings tab (theme, glass, accent, typography, size)
	local ui: any = {} -- settings-tab controls, kept in sync with the win:Set* functions
	local function applyFontSettings()
		for instance in pairs(fontBindings) do
			if instance.Parent then
				applyFontTo(instance)
			else
				fontBindings[instance] = nil
			end
		end
	end
	function win:SetFont(name)
		local normalized = normalizeFontName(name)
		if not normalized then
			warn("[MacUI] Unsupported font '" .. tostring(name) .. "'; use 'Kanit' or 'Prompt'.")
			return false
		end
		fontFamily = normalized
		applyFontSettings()
		if ui.font then
			ui.font:Set(fontFamily)
		end
		return true
	end
	function win:GetFont()
		return fontFamily
	end
	function win:SetFontScale(scale)
		scale = tonumber(scale)
		if not scale then
			warn("[MacUI] Font scale must be a number between 0.7 and 1.4.")
			return false
		end
		fontScale = math.clamp(scale, 0.7, 1.4)
		applyFontSettings()
		if ui.fontScale then
			ui.fontScale:Set(math.floor(fontScale * 100 + 0.5))
		end
		return true
	end
	function win:GetFontScale()
		return fontScale
	end
	function win:SetTheme(name)
		if Presets[name] then
			loadPreset(name)
			derive()
			applyTheme()
			if ui.theme then
				ui.theme:Set(name)
			end
		end
	end
	function win:SetAccent(color)
		Theme.Accent = color
		derive()
		applyTheme()
		if ui.accent then
			local nm = "Custom"
			for n, c in pairs(Accents) do
				if c == color then
					nm = n
				end
			end
			ui.accent:Set(nm)
			ui.r:Set(math.floor(color.R * 255 + 0.5))
			ui.g:Set(math.floor(color.G * 255 + 0.5))
			ui.b:Set(math.floor(color.B * 255 + 0.5))
		end
	end
	function win:SetScale(v)
		setScale(v)
	end
	function win:SetGlass(amount)
		amount = math.clamp(amount or 0, 0, 0.6)
		glassOn = amount > 0
		if glassOn then
			glassAmount = amount
		end
		refreshGlass()
		if ui.glassToggle then
			ui.glassToggle:Set(glassOn)
			ui.glassSlider:Set(glassOn and math.floor(glassAmount * 100 + 0.5) or 0)
		end
	end

	function win:AddSettingsTab(o)
		o = o or {}
		local tab = win:AddTab({
			Section = o.Section or "Settings",
			Name = o.Name or "Settings",
			Icon = o.Icon or "gear",
		})

		local look = tab:AddSection({ Title = "Appearance", Desc = "Change the UI color tone." })
		ui.theme = look:AddDropdown({
			Name = "Theme",
			Desc = "Base colors of the window.",
			Options = PresetNames,
			Default = (opts.Theme and Presets[opts.Theme]) and opts.Theme or "Dark",
			Callback = function(v)
				win:SetTheme(v)
			end,
		})
		ui.glassToggle = look:AddToggle({
			Name = "Glass background",
			Desc = "See-through window.",
			Default = glassOn,
			Callback = function(v)
				glassOn = v
				refreshGlass()
				ui.glassSlider:Set(v and math.floor(glassAmount * 100 + 0.5) or 0)
			end,
		})
		ui.glassSlider = look:AddSlider({
			Name = "Glass amount",
			Desc = "How see-through the window is.",
			Min = 0, Max = 60, Increment = 5, Suffix = "%",
			Default = glassOn and math.floor(glassAmount * 100 + 0.5) or 0,
			Callback = function(v)
				if v <= 0 then
					glassOn = false
				else
					glassOn = true
					glassAmount = v / 100
				end
				refreshGlass()
				ui.glassToggle:Set(glassOn)
			end,
		})

		local r, g, b
		local function fromSliders()
			win:SetAccent(Color3.fromRGB(r:Get(), g:Get(), b:Get()))
		end

		local startC = Theme.Accent
		local startAccent = "Custom"
		for n, c in pairs(Accents) do
			if c == startC then
				startAccent = n
			end
		end
		ui.accent = look:AddDropdown({
			Name = "Accent color",
			Desc = "Switches, sliders and highlights.",
			Options = AccentNames,
			Default = startAccent,
			Callback = function(v)
				win:SetAccent(Accents[v])
			end,
		})
		r = look:AddSlider({ Name = "Accent red", Min = 0, Max = 255, Default = math.floor(startC.R * 255 + 0.5), Callback = fromSliders })
		g = look:AddSlider({ Name = "Accent green", Min = 0, Max = 255, Default = math.floor(startC.G * 255 + 0.5), Callback = fromSliders })
		b = look:AddSlider({ Name = "Accent blue", Min = 0, Max = 255, Default = math.floor(startC.B * 255 + 0.5), Callback = fromSliders })
		ui.r, ui.g, ui.b = r, g, b

		local typography = tab:AddSection({ Title = "Typography", Desc = "Choose the font and text size." })
		ui.font = typography:AddDropdown({
			Name = "Font",
			Desc = "Choose a font. Set its asset ID in CreateWindow FontAssets first.",
			Options = FONT_NAMES,
			Default = fontFamily,
			Callback = function(value)
				win:SetFont(value)
			end,
		})
		ui.fontScale = typography:AddSlider({
			Name = "Text size",
			Desc = "Adjust all UI text from 70% to 140%.",
			Min = 70, Max = 140, Increment = 5, Suffix = "%",
			Default = math.floor(fontScale * 100 + 0.5),
			Callback = function(value)
				win:SetFontScale(value / 100)
			end,
		})

		local section = tab:AddSection({ Title = "Window", Desc = "Size and controls." })
		scaleSlider = section:AddSlider({
			Name = "UI size",
			Desc = "The yellow button switches 2 sizes.",
			Min = 0.5, Max = 1.5, Default = currentScale, Increment = 0.05, Suffix = "x",
			Callback = function(v)
				currentScale = v
				tween(scaleObj, { Scale = v }, 0.1)
			end,
		})
		toggleBindCtl = section:AddBind({
			Name = "Toggle UI",
			Desc = "Click, then press a key. Backspace = none.",
			Default = (toggleKey ~= NONE_KEY) and toggleKey or false,
			OnChange = function(k)
				toggleKey = k
			end,
		})
		section:AddButton({
			Name = "Unload script",
			Desc = "Same as the red button.",
			ButtonText = "Unload",
			Callback = function()
				win:ConfirmClose()
			end,
		})
		return tab
	end

	-- window controls
	local destroyed = false
	function win:Destroy()
		if destroyed then
			return
		end
		destroyed = true
		for i, w in ipairs(library._windows) do
			if w == win then
				table.remove(library._windows, i)
				break
			end
		end
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		gui:Destroy()
		if opts.OnDestroy then
			task.spawn(opts.OnDestroy)
		end
	end
	function win:ConfirmClose()
		if opts.ConfirmClose == false then
			win:Destroy()
		else
			setMainVisible(true)
			confirm.Visible = true
		end
	end
	function win:Toggle(...)
		if select("#", ...) > 0 then -- Window:Toggle("name", ...) is a switch control (Wally style)
			local t = defTab()
			return t:Toggle(...)
		end
		toggleMain()
		return nil
	end
	function win:SetVisible(v)
		if main.Visible ~= (v == true) then
			toggleMain()
		end
	end
	function win:Show()
		win:SetVisible(true)
	end
	function win:Hide()
		win:SetVisible(false)
	end
	function win:IsVisible()
		return main.Visible
	end
	-- Window:SetToggleKey(Enum.KeyCode.F1) / ("F1") / (false = no keyboard shortcut)
	function win:SetToggleKey(k)
		if k == false or k == "None" then
			toggleKey = NONE_KEY
		else
			toggleKey = toKeyCode(k) or toggleKey
		end
		if toggleBindCtl then
			toggleBindCtl:Set((toggleKey ~= NONE_KEY) and toggleKey or false)
		end
	end
	function win:GetToggleKey()
		return toggleKey
	end

	-- Window:SelectTab(2) / ("name") / (tab)   (also SelectPage)
	function win:SelectTab(x)
		local tab
		if type(x) == "number" then
			tab = tabsList[x]
		elseif type(x) == "string" then
			for _, t in ipairs(tabsList) do
				if t.Name == x then
					tab = t
				end
			end
		elseif type(x) == "table" then
			tab = x
		end
		if tab and tab.Page then
			selectTab(tab)
		end
	end
	win.SelectPage = win.SelectTab
	function win:Minimize()
		toggleMain()
	end

	-- Fluent: Window:Dialog({ Title, Content, Buttons = { { Title, Callback }, ... } })
	function win:Dialog(o)
		o = o or {}
		local overlay = New("TextButton", {
			Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5,
			BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 200, Parent = gui,
		})
		local card = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(300, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.Card, BorderSizePixel = 0, ZIndex = 201, Parent = overlay,
		}, {
			Round(10),
			New("UIStroke", { Color = Theme.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
			New("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
				PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16),
			}),
		})
		local function text(str, size, color, font, order)
			New("TextLabel", {
				BackgroundTransparency = 1, Text = tostring(str), Font = font, TextSize = size, TextColor3 = color,
				TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0), LayoutOrder = order, ZIndex = 202, Parent = card,
			})
		end
		text(firstNonNil(o.Title, o.Name, "Dialog"), 15, Theme.Text, Enum.Font.GothamBold, 1)
		local body = firstNonNil(o.Content, o.Text, o.Description)
		if body then
			text(body, 13, Theme.SubText, Enum.Font.Gotham, 2)
		end
		local buttons = o.Buttons or { { Title = "OK" } }
		local rowFrame = New("Frame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 3, ZIndex = 202, Parent = card,
		}, {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})
		local w = math.floor((268 - 8 * (#buttons - 1)) / math.max(#buttons, 1))
		for i, b in ipairs(buttons) do
			local btn = New("TextButton", {
				Text = tostring(firstNonNil(b.Title, b.Name, b.Text, "OK")), Font = Enum.Font.GothamMedium, TextSize = 13,
				TextColor3 = (i == 1) and Color3.new(1, 1, 1) or Theme.Text,
				BackgroundColor3 = (i == 1) and Theme.Accent or Theme.Field, AutoButtonColor = false,
				BorderSizePixel = 0, Size = UDim2.fromOffset(w, 30), LayoutOrder = i, ZIndex = 203, Parent = rowFrame,
			}, { Round(6) })
			animateButton(btn, function()
				return Theme.Accent
			end)
			btn.Activated:Connect(function()
				overlay:Destroy()
				local cb = firstNonNil(b.Callback, b.Function, b.Func)
				if cb then
					task.spawn(cb)
				end
			end)
		end
		return { Close = function() overlay:Destroy() end }
	end

	-- config files (Rayfield ConfigurationSaving / Orion SaveConfig): every control with a flag / idx is saved
	local cfg = opts.ConfigurationSaving
	local cfgOn = (type(cfg) == "table" and cfg.Enabled == true) or opts.SaveConfig == true
	win._cfgOn = cfgOn
	local function configFile(name)
		local folder = tostring(firstNonNil(type(cfg) == "table" and cfg.FolderName or nil, opts.ConfigFolder, "MacUI"))
		local file = tostring(name or firstNonNil(type(cfg) == "table" and cfg.FileName or nil, opts.Title, "config"))
		file = string.gsub(file, "[^%w%-_ ]", "_")
		return folder, folder .. "/" .. file .. ".json"
	end
	local function encodeValue(kind, v)
		if kind == "ColorPicker" and v then
			return { R = math.floor(v.R * 255 + 0.5), G = math.floor(v.G * 255 + 0.5), B = math.floor(v.B * 255 + 0.5) }
		elseif kind == "Bind" then
			return (not v or v == Enum.KeyCode.Unknown) and "None" or v.Name
		end
		return v
	end
	local function decodeValue(kind, v)
		if kind == "ColorPicker" and type(v) == "table" then
			return Color3.fromRGB(v.R or 255, v.G or 255, v.B or 255)
		elseif kind == "Bind" then
			return (v ~= "None") and toKeyCode(v) or false
		end
		return v
	end
	function win:SaveConfig(name)
		if not writefile then
			return false
		end
		local data = {}
		for _, f in ipairs(flagged) do
			data[f.name] = encodeValue(f.kind, f.obj:Get())
		end
		return (pcall(function()
			local folder, path = configFile(name)
			if makefolder and isfolder and not isfolder(folder) then
				makefolder(folder)
			end
			writefile(path, game:GetService("HttpService"):JSONEncode(data))
		end))
	end
	function win:LoadConfig(name)
		if not (readfile and isfile) then
			return false
		end
		local ok, data = pcall(function()
			local _, path = configFile(name)
			if not isfile(path) then
				return nil
			end
			return game:GetService("HttpService"):JSONDecode(readfile(path))
		end)
		if not ok or type(data) ~= "table" then
			return false
		end
		for _, f in ipairs(flagged) do
			local v = data[f.name]
			if v ~= nil then
				pcall(function()
					f.obj:SetValue(decodeValue(f.kind, v))
				end)
			end
		end
		return true
	end
	if cfgOn then
		local token = 0
		saveSoon = function()
			token += 1
			local my = token
			task.delay(0.4, function()
				if my == token and not destroyed then
					win:SaveConfig()
				end
			end)
		end
	end

	function win:SetUser(t)
		for k, v in pairs(t or {}) do
			userInfo[k] = v
		end
		applyUser()
	end
	-- text under the name at the bottom of the sidebar. Window:SetUserNote("Expires: 23h 53m")
	-- colour for the whole line: SetUserNote(text, Color3); part of it: RichText such as <font color="#FF8A3D">23h</font>
	-- SetUserNote("") or SetUserNote(nil) removes the line again
	function win:SetUserNote(text, color)
		userInfo.Note = text
		userInfo.NoteColor = color
		applyUser()
	end
	function win:GetUserNote()
		return userInfo.Note
	end
	function win:ToggleSidebar()
		onToggleSidebar()
	end
	function win.Notify(a, ...)
		if a == win then
			return library.Notify(...)
		end
		return library.Notify(a, ...)
	end

	onPress(red, function()
		win:ConfirmClose()
	end)
	onPress(yellow, function()
		local mid = (SIZE_SMALL + SIZE_LARGE) / 2
		if currentScale >= mid then
			setScale(SIZE_SMALL)
		else
			setScale(SIZE_LARGE)
		end
	end)
	onPress(green, function()
		confirm.Visible = false
		setMainVisible(false)
	end)
	onPress(cancelBtn, function()
		confirm.Visible = false
	end)
	onPress(closeBtn, function()
		win:Destroy()
	end)

	-- toggle-UI shortcut: ignored while typing in a text box or while a Bind control is waiting for a key
	table.insert(conns, UIS.InputBegan:Connect(function(input, processed)
		if processed or bindBusy or input == consumedInput or toggleKey == NONE_KEY then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
			toggleMain()
		end
	end))

	installFuzzy(win, {
		tab = function()
			return function(self, ...)
				return win.AddTab(win, shift(self, win, ...))
			end
		end,
		section = function()
			return function(self, ...)
				local so, icon2 = shift(self, win, ...)
				return defTab():AddSection(so, icon2)
			end
		end,
		tabbox = function()
			return function()
				return defTab():AddTabbox()
			end
		end,
		control = function(kind)
			return function(self, ...)
				local t = defTab()
				return t["Add" .. kind](t, shift(self, win, ...))
			end
		end,
		divider = function()
			return function()
				return defTab():AddDivider()
			end
		end,
		blank = function()
			return function(self, ...)
				return defTab():AddBlank(shift(self, win, ...))
			end
		end,
		notify = function()
			return function(self, ...)
				return library.Notify(shift(self, win, ...))
			end
		end,
		dialog = function()
			return function(self, ...)
				return win.Dialog(win, shift(self, win, ...))
			end
		end,
	})
	table.insert(library._windows, win)
	library._theme = Theme -- live table, used by notifications
	return win
end

-- Library.CreateWindow(opts) / Library:CreateWindow(opts) / Library:Window(opts) all work
function win.CreateWindow(...)
	local a, b = unself(...)
	local o
	if type(a) == "table" then
		o = a
	elseif type(a) == "string" then -- CreateLib("Title", "Theme") / new("Title", themeTable) / CreateWindow("Title")
		o = { Title = a }
		if b ~= nil and type(b) ~= "function" then
			o.Theme = b
		end
	else
		o = {}
	end
	return buildWindow(o)
end
for _, n in ipairs({ "Window", "MakeWindow", "NewWindow", "Create", "CreateLib", "new", "New" }) do
	win[n] = win.CreateWindow
end

local function lastWindow()
	return win._windows[#win._windows]
end
-- config: Orion Init(), Rayfield LoadConfiguration(), SaveConfiguration()
function win.LoadConfiguration()
	for _, w in ipairs(win._windows) do
		if w._cfgOn then
			w:LoadConfig()
		end
	end
end
function win.SaveConfiguration()
	for _, w in ipairs(win._windows) do
		if w._cfgOn then
			w:SaveConfig()
		end
	end
end
function win.Init()
	win.LoadConfiguration()
end
win.MakeNotification = win.Notify
function win.Unload()
	win.Destroy()
end
function win.OnUnload(...)
	local fn = unself(...)
	if type(fn) == "function" then
		table.insert(win._onUnload, fn)
	end
end
function win.Toggle()
	local w = lastWindow()
	if w then
		w:Toggle()
	end
end
function win.SetVisibility(...)
	local v = unself(...)
	local w = lastWindow()
	if w then
		w:SetVisible(v ~= false)
	end
end
function win.IsVisible()
	local w = lastWindow()
	return w ~= nil and w:IsVisible()
end
function win.SetTheme(...)
	local name = unself(...)
	local w = lastWindow()
	if w and type(name) == "string" then
		local m = ThemeMap[string.lower(name)]
		w:SetTheme((m and m[1]) or name)
		if m and m[2] then
			w:SetAccent(Accents[m[2]])
		end
	end
end
-- cosmetic features of other libraries that have no equivalent here: accepted and ignored
for _, n in ipairs({
	"SetWatermark", "SetWatermarkVisibility", "SetFont", "SetLoadingText", "UpdateColorsUsingRegistry",
	"RefreshConfigList", "SetKeybindFrame", "ToggleKeybindFrame",
}) do
	win[n] = function() end
end
win.KeybindFrame = { Visible = false }
win.Watermark = { Visible = false }
win.Unloaded = false

installFuzzy(win, {
	window = function()
		return win.CreateWindow
	end,
	notify = function()
		return win.Notify
	end,
})

-- lets other scripts (e.g. a key-timer) find the windows of the script that loaded this library without editing it:
-- getgenv().MacUI_Library._windows
pcall(function()
	local g = (getgenv and getgenv()) or _G
	g.MacUI_Library = win
end)


--========================================================--
-- NYX KEY SYSTEM (integrated; original UI code is unchanged)
--========================================================--
local function installNyxKeySystem()
    local ok, err = pcall(function()
        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")
        local player = Players.LocalPlayer
        local env = (getgenv and getgenv()) or _G

        env.NyxLibraryKeyRun = (env.NyxLibraryKeyRun or 0) + 1
        local runId = env.NyxLibraryKeyRun
        local CFG = {
            URL = "https://zerzy.xyz/api/verify.php",
            MATCH = "verify.php",
            FALLBACK_WAIT = 6,
            KICK_ON_EXPIRE = true,
            COLOR = "#FF8A3D",
            ERROR_COLOR = "#FF5252",
        }

        local resolved, failed, kicked = false, false, false
        local endAt = nil

        local function note(value)
            if env.NyxLibraryKeyRun ~= runId then return end
            for _, window in ipairs(win._windows) do
                if type(window) == "table" and type(window.SetUserNote) == "function" then
                    pcall(function() window:SetUserNote(value) end)
                end
            end
        end

        local function unix(y, m, d, h, mi, s)
            y = (m <= 2) and y - 1 or y
            local era = math.floor(y / 400)
            local yoe = y - era * 400
            local doy = math.floor((153 * ((m + 9) % 12) + 2) / 5) + d - 1
            local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
            return (era * 146097 + doe - 719468) * 86400 + h * 3600 + mi * 60 + s
        end

        local months = {Jan=1,Feb=2,Mar=3,Apr=4,May=5,Jun=6,Jul=7,Aug=8,Sep=9,Oct=10,Nov=11,Dec=12}
        local function serverNow(headers)
            if type(headers) == "table" then
                for k, v in pairs(headers) do
                    if tostring(k):lower() == "date" then
                        local d, mon, y, h, mi, s = tostring(v):match("(%d+) (%a+) (%d+) (%d+):(%d+):(%d+)")
                        if d and months[mon] then return unix(tonumber(y), months[mon], tonumber(d), tonumber(h), tonumber(mi), tonumber(s)) end
                    end
                end
            end
            return os.time()
        end

        local function parseDate(v)
            if type(v) ~= "string" then return nil end
            local y, mo, d, rest = v:match("^(%d%d%d%d)-(%d%d)-(%d%d)(.*)$")
            if not y then return nil end
            local h, mi, s, tail = rest:match("^[T ](%d%d):(%d%d):?(%d*)(.*)$")
            h, mi, s = tonumber(h) or 23, tonumber(mi) or 59, tonumber(s) or 59
            local tz = 7 * 3600
            if tail then
                local sign, th, tm = tail:match("([%+%-])(%d%d):?(%d%d)$")
                if sign then tz = (tonumber(th) * 3600 + tonumber(tm) * 60) * (sign == "-" and -1 or 1)
                elseif tail:match("Z$") then tz = 0 end
            end
            return unix(tonumber(y), tonumber(mo), tonumber(d), h, mi, s) - tz
        end

        local fields = {
            "expires_in","expire_in","expires_after","expires_at","expire_at","expires",
            "expiry","expire","expiration","expired_at","expire_time","valid_until",
            "end_time","ends_at","timeleft","time_left","remaining","seconds_left","ttl","duration"
        }

        local function remaining(name, value, now)
            if type(value) == "string" then
                local low = value:lower()
                if low == "never" or low == "lifetime" or low == "permanent" or low == "unlimited" then return "lifetime" end
                local n = tonumber(value)
                if n then value = n else
                    local stamp = parseDate(value)
                    if stamp then return stamp - now end
                    return nil
                end
            end
            if type(value) ~= "number" then return nil end
            if value > 1e12 then value = value / 1000 end
            if value <= 0 then return nil end
            if name:find("left",1,true) or name:find("remain",1,true) or name:find("ttl",1,true)
                or name:find("duration",1,true) or name:find("_in",1,true) or name:find("_after",1,true)
                or value < 1e9 then return value end
            return value - now
        end

        local function findExpiry(tbl, now)
            if type(tbl) ~= "table" then return nil end
            for _, field in ipairs(fields) do
                if tbl[field] ~= nil then
                    local result = remaining(field, tbl[field], now)
                    if result ~= nil then return result end
                end
            end
        end

        local function accept(data, headers)
            if resolved or type(data) ~= "table" then return end
            if data.success ~= true then
                failed, resolved = true, true
                note('<font color="' .. CFG.ERROR_COLOR .. '">คีย์ไม่ถูกต้อง</font>')
                return
            end
            local now = serverNow(headers)
            local left = findExpiry(data, now)
            if left == nil then left = findExpiry(data.data, now) end
            if left == nil then left = findExpiry(data.key, now) end
            resolved = true
            if left == "lifetime" then
                endAt = "lifetime"
            elseif type(left) == "number" and left > 0 then
                endAt = os.time() + math.floor(left)
            elseif type(left) == "number" then
                failed = true
            else
                endAt = "unknown"
            end
        end

        local function inspect(opts, response)
            if type(opts) ~= "table" or type(response) ~= "table" then return end
            local url = tostring(opts.Url or opts.url or "")
            if not url:find(CFG.MATCH, 1, true) then return end
            local okJson, data = pcall(function()
                return HttpService:JSONDecode(response.Body or response.body or "")
            end)
            if okJson then accept(data, response.Headers or response.headers) end
        end

        local function wrap(container, name)
            if type(container) ~= "table" then return end
            local original = rawget(container, name)
            if typeof(original) ~= "function" then return end
            container[name] = function(...)
                local args = table.pack(...)
                local response = original(table.unpack(args, 1, args.n))
                pcall(inspect, args[1], response)
                return response
            end
        end
        wrap(env, "request")
        wrap(env, "http_request")
        if type(env.syn) == "table" then wrap(env.syn, "request") end

        task.spawn(function()
            task.wait(CFG.FALLBACK_WAIT)
            if resolved or env.NyxLibraryKeyRun ~= runId then return end
            local key = env.Key
            local requestFn = rawget(env, "request") or rawget(env, "http_request")
                or (type(env.syn) == "table" and rawget(env.syn, "request"))
            local hwid
            local funcs = { gethwid, get_hwid, type(env.syn) == "table" and env.syn.get_hwid or nil }
            for _, fn in ipairs(funcs) do
                if typeof(fn) == "function" then
                    local okH, value = pcall(fn)
                    if okH and value then hwid = tostring(value); break end
                end
            end
            if not (key and tostring(key) ~= "" and hwid and typeof(requestFn) == "function") then return end
            local okReq, response = pcall(function()
                return requestFn({
                    Url = CFG.URL, Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode({key = tostring(key), hwid = hwid})
                })
            end)
            if okReq and type(response) == "table" then
                local okJson, data = pcall(function() return HttpService:JSONDecode(response.Body or response.body or "") end)
                if okJson then accept(data, response.Headers or response.headers) end
            end
        end)

        local function formatTime(seconds)
            seconds = math.max(0, math.floor(seconds))
            if seconds <= 0 then return '<font color="' .. CFG.ERROR_COLOR .. '">คีย์หมดอายุ</font>' end
            return string.format('<font color="%s">คีย์เหลือ %d วัน %02d:%02d:%02d</font>',
                CFG.COLOR, math.floor(seconds/86400), math.floor((seconds%86400)/3600),
                math.floor((seconds%3600)/60), seconds%60)
        end

        task.spawn(function()
            while env.NyxLibraryKeyRun == runId do
                if endAt == "lifetime" then
                    note('<font color="' .. CFG.COLOR .. '">คีย์ถาวร (Lifetime)</font>')
                elseif endAt == "unknown" then
                    note('<font color="' .. CFG.COLOR .. '">คีย์ใช้งานได้</font>')
                elseif type(endAt) == "number" then
                    local left = endAt - os.time()
                    note(formatTime(left))
                    if left <= 0 and CFG.KICK_ON_EXPIRE and not kicked then
                        kicked = true
                        note('<font color="' .. CFG.ERROR_COLOR .. '">คีย์หมดอายุ กำลังออกจากเกม...</font>')
                        task.wait(0.2)
                        pcall(function() player:Kick("Your key has expired") end)
                        break
                    end
                elseif failed then
                    note('<font color="' .. CFG.ERROR_COLOR .. '">คีย์ไม่ถูกต้อง</font>')
                elseif resolved then
                    note('<font color="' .. CFG.COLOR .. '">ตรวจสอบคีย์แล้ว</font>')
                else
                    note('<font color="' .. CFG.COLOR .. '">กำลังตรวจสอบคีย์...</font>')
                end
                task.wait(1)
            end
        end)
    end)
    if not ok then warn("[MacUI Key System] " .. tostring(err)) end
end

installNyxKeySystem()

return win
