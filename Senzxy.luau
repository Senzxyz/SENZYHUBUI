--[[
	Senzy UI - Premium Rose Edition
	Full code updated with soft pink theme, Range Slider, Status Indicator, Tooltip, and Quick Search.
]]

local Senzy = {
	Options = {},
	Folder = "Senzy",
	GetService = function(service)
		return cloneref and cloneref(game:GetService(service)) or game:GetService(service)
	end,
}

--// Services
local TweenService     = Senzy.GetService("TweenService")
local RunService       = Senzy.GetService("RunService")
local HttpService      = Senzy.GetService("HttpService")
local ContentProvider  = Senzy.GetService("ContentProvider")
local UserInputService = Senzy.GetService("UserInputService")
local Players          = Senzy.GetService("Players")

local isStudio    = RunService:IsStudio()
local LocalPlayer = Players.LocalPlayer

--// Theme (Soft Pink / Rose Premium Palette) ---------------------------
local C = {
	scrim  = Color3.fromRGB(0, 0, 0),
	ground = Color3.fromRGB(12, 11, 13),
	panel  = Color3.fromRGB(18, 16, 19),
	raise  = Color3.fromRGB(26, 23, 27),
	hover  = Color3.fromRGB(36, 31, 38),
	ink    = Color3.fromRGB(255, 240, 245),
	ink2   = Color3.fromRGB(230, 210, 218),
	label  = Color3.fromRGB(180, 160, 172),
	dim    = Color3.fromRGB(145, 125, 138),
	dim2   = Color3.fromRGB(90, 75, 85),
	line   = Color3.fromRGB(45, 38, 44),
	line2  = Color3.fromRGB(70, 55, 66),
	-- Accent Theme: Soft Pink / Rose
	accent = Color3.fromRGB(255, 135, 175),
	accentHover = Color3.fromRGB(255, 165, 195),
	ok     = Color3.fromRGB(130, 240, 170),
	bad    = Color3.fromRGB(255, 110, 110),
}

local FONT = "rbxasset://fonts/families/RobotoMono.json"
local W = {
	reg  = Enum.FontWeight.Regular,
	med  = Enum.FontWeight.Medium,
	semi = Enum.FontWeight.SemiBold,
	bold = Enum.FontWeight.Bold,
}
local function mono(weight)
	return Font.new(FONT, weight or W.reg, Enum.FontStyle.Normal)
end

local function track(s)
	return (tostring(s):gsub(".", "%0\u{200A}"))
end

--// Builders ----------------------------------------------------------
local function new(class, props, children)
	local obj = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then obj[k] = v end
		end
	end
	if children then
		for _, c in ipairs(children) do c.Parent = obj end
	end
	if props and props.Parent then obj.Parent = props.Parent end
	return obj
end

local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r or 6) }) end
local function stroke(col, th, tr)
	return new("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = col or C.line,
		Thickness = th or 1,
		Transparency = tr or 0,
	})
end
local function pad(t, r, b, l)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0),
		PaddingLeft = UDim.new(0, l or 0),
	})
end
local function list(dir, padPx, align)
	return new("UIListLayout", {
		FillDirection = dir or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, padPx or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
	})
end

local function tween(inst, info, goal) return TweenService:Create(inst, info, goal) end
local T = TweenInfo.new(0.15, Enum.EasingStyle.Sine)
local TQ = TweenInfo.new(0.2, Enum.EasingStyle.Quad)

local function GetGui()
	local g = Instance.new("ScreenGui")
	g.Name = "SENZY_ROSE_" .. HttpService:GenerateGUID(false):sub(1, 6)
	g.ScreenInsets = Enum.ScreenInsets.None
	g.ResetOnSpawn = false
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.DisplayOrder = 2147483647
	local parent = RunService:IsStudio()
		and LocalPlayer:FindFirstChild("PlayerGui")
		or (gethui and gethui())
		or (cloneref and cloneref(Senzy.GetService("CoreGui")) or Senzy.GetService("CoreGui"))
	g.Parent = parent
	return g
end

local imageCache = {}
local function resolveImage(img)
	if type(img) ~= "string" or img == "" then return img end
	if img:sub(1, 4) ~= "http" then return img end
	if imageCache[img] then return imageCache[img] end
	local getcustom = getcustomasset or getsynasset or (syn and syn.getcustomasset)
	if not (getcustom and writefile and isfolder and makefolder and isfile) then return "" end
	pcall(function()
		if not isfolder(Senzy.Folder) then makefolder(Senzy.Folder) end
		if not isfolder(Senzy.Folder .. "/assets") then makefolder(Senzy.Folder .. "/assets") end
	end)
	local ext = img:match("%.(%a%a%a?%a?)$") or "png"
	local fname = Senzy.Folder .. "/assets/" .. (img:gsub("[^%w]", "_")):sub(-48) .. "." .. ext
	if not isfile(fname) then
		local dok, data = pcall(function() return game:HttpGet(img) end)
		if not dok or not data then return "" end
		pcall(writefile, fname, data)
	end
	local aok, asset = pcall(getcustom, fname)
	if aok and asset then
		imageCache[img] = asset
		return asset
	end
	return ""
end


--// WINDOW ------------------------------------------------------------
function Senzy:Window(Settings)
	Settings = Settings or {}
	local Window = { Settings = Settings }
	local gui = GetGui()

	local windowState = true
	local tabs = {}
	local currentTabInstance
	local tabIndex = 0
	local hasGlobalSetting = false

	--// Tooltip Global Frame ------------------------------------------
	local tooltip = new("Frame", {
		Name = "Tooltip",
		BackgroundColor3 = C.ground,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = false,
		ZIndex = 100,
		Parent = gui,
	}, {
		corner(4), stroke(C.accent, 1, 0.3),
		pad(4, 8, 4, 8),
	})
	local tooltipLbl = new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = mono(W.med),
		TextColor3 = C.ink,
		TextSize = 11,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 101,
		Parent = tooltip,
	})

	local function showTooltip(text, pos)
		if not text or text == "" then return end
		tooltipLbl.Text = text
		tooltip.Position = UDim2.fromOffset(pos.X + 12, pos.Y + 12)
		tooltip.Visible = true
	end
	local function hideTooltip()
		tooltip.Visible = false
	end

	--// Notifications layer ------------------------------------------
	local notifications = new("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
		Parent = gui,
	}, {
		list(nil, 8, Enum.HorizontalAlignment.Right),
		pad(12, 12, 12, 12),
	})

	--// Base window ---------------------------------------------------
	local base = new("Frame", {
		Name = "Base",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = Settings.Size or UDim2.fromOffset(780, 540),
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		Parent = gui,
	}, {
		corner(10),
		stroke(C.line2, 1, 0),
		new("UIStroke", {
			Color = C.accent,
			Thickness = 1,
			Transparency = 0.8,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		})
	})
	local baseScale = new("UIScale", { Parent = base })

	local function applyScale()
		local sz = Settings.Size or UDim2.fromOffset(780, 540)
		local dw, dh = sz.X.Offset, sz.Y.Offset
		local cam = workspace.CurrentCamera
		local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
		local fit = 1
		if dw > 0 and dh > 0 and vp.X > 0 and vp.Y > 0 then
			fit = math.min(1, (vp.X * 0.94) / dw, (vp.Y * 0.92) / dh)
		end
		baseScale.Scale = fit
	end
	applyScale()
	do
		local camConn
		local function hookCam()
			if camConn then camConn:Disconnect() end
			local cam = workspace.CurrentCamera
			if cam then camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale) end
			applyScale()
		end
		hookCam()
		workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCam)
	end

	local SIDEBAR_W = Settings.SidebarWidth or 220

	--// Sidebar -------------------------------------------------------
	local sidebar = new("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = C.ground,
		BorderSizePixel = 0,
		Size = UDim2.new(0, SIDEBAR_W, 1, 0),
		Parent = base,
	}, { corner(10) })
	
	new("Frame", {
		BackgroundColor3 = C.ground,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 12, 1, 0),
		Parent = sidebar,
	})
	new("Frame", {
		Name = "SideDivider",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = C.line,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = sidebar,
	})

	local header = new("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 68),
		Parent = sidebar,
	}, { pad(18, 16, 0, 18) })

	local titleLabel = new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		FontFace = mono(W.bold),
		Text = track(Settings.Title or "Senzy"),
		TextColor3 = C.accent,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -20, 0, 18),
		Parent = header,
	})
	local subtitleLabel = new("TextLabel", {
		Name = "Subtitle",
		BackgroundTransparency = 1,
		FontFace = mono(W.med),
		Text = Settings.Subtitle or "rose edition",
		TextColor3 = C.dim,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, -20, 0, 14),
		Parent = header,
	})

	local globeBtn = new("ImageButton", {
		Name = "Settings",
		BackgroundTransparency = 1,
		Image = "rbxassetid://108952102602834",
		ImageColor3 = C.accent,
		ImageTransparency = 0.2,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 2),
		Size = UDim2.fromOffset(16, 16),
		Visible = false,
		Parent = header,
	})

	new("Frame", {
		BackgroundColor3 = C.line,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 68),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = sidebar,
	})

	-- Tab list
	local tabList = new("ScrollingFrame", {
		Name = "TabList",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 69),
		Size = UDim2.new(1, 0, 1, -69 - 62),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = C.accent,
		ScrollBarImageTransparency = 0.5,
		TopImage = "", BottomImage = "",
		Parent = sidebar,
	}, {
		list(nil, 4, Enum.HorizontalAlignment.Center),
		pad(12, 0, 12, 0),
	})

	-- User Info Panel
	local userInfo = new("Frame", {
		Name = "UserInfo",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundTransparency = 1,
		Parent = sidebar,
	}, { pad(0, 14, 0, 14) })
	
	new("Frame", {
		BackgroundColor3 = C.line,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		Parent = userInfo,
	})

	local isReady, headshotImage = pcall(function()
		return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size48x48)
	end)

	new("ImageLabel", {
		Name = "Headshot",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 2),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = C.raise,
		BorderSizePixel = 0,
		Image = (isReady and headshotImage) or "",
		Parent = userInfo,
	}, { corner(16), stroke(C.accent, 1, 0.4) })

	local displayName = new("TextLabel", {
		Name = "DisplayName",
		BackgroundTransparency = 1,
		FontFace = mono(W.semi),
		Text = LocalPlayer.DisplayName,
		TextColor3 = C.ink,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 42, 0.5, -9),
		Size = UDim2.new(1, -46, 0, 13),
		Parent = userInfo,
	})
	local username = new("TextLabel", {
		Name = "Username",
		BackgroundTransparency = 1,
		FontFace = mono(W.reg),
		Text = "@" .. LocalPlayer.Name,
		TextColor3 = C.accent,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 42, 0.5, 5),
		Size = UDim2.new(1, -46, 0, 12),
		Parent = userInfo,
	})

	--// Content Area --------------------------------------------------
	local content = new("Frame", {
		Name = "Content",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
		BackgroundTransparency = 1,
		Parent = base,
	})

	local topbar = new("Frame", {
		Name = "Topbar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 50),
		Parent = content,
	}, { pad(0, 16, 0, 20) })
	
	new("Frame", {
		BackgroundColor3 = C.line,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = topbar,
	})

	local currentTabLabel = new("TextLabel", {
		Name = "CurrentTab",
		BackgroundTransparency = 1,
		FontFace = mono(W.bold),
		Text = "",
		TextColor3 = C.ink,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(0.5, 0, 1, 0),
		Parent = topbar,
	})

	-- Quick Search Bar inside Topbar
	local searchInput = new("TextBox", {
		Name = "QuickSearch",
		BackgroundColor3 = C.ground,
		BorderSizePixel = 0,
		FontFace = mono(W.med),
		PlaceholderText = "Search features...",
		PlaceholderColor3 = C.dim2,
		Text = "",
		TextColor3 = C.ink,
		TextSize = 11,
		ClearTextOnFocus = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -60, 0.5, 0),
		Size = UDim2.fromOffset(180, 24),
		Parent = topbar,
	}, { corner(6), stroke(C.line2, 1, 0), pad(0, 8, 0, 8) })

	-- Window controls
	local controls = new("Frame", {
		Name = "Controls",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(52, 22),
		Parent = topbar,
	}, { list(Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right) })

	local function ctlButton(txt, order)
		local b = new("TextButton", {
			BackgroundColor3 = C.raise,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			Text = txt,
			FontFace = mono(W.bold),
			TextColor3 = C.label,
			TextSize = 13,
			LayoutOrder = order,
			Size = UDim2.fromOffset(22, 22),
			Parent = controls,
		}, { corner(5), stroke(C.line, 1, 0) })
		b.MouseEnter:Connect(function() tween(b, T, { BackgroundColor3 = C.accent, TextColor3 = C.ground }):Play() end)
		b.MouseLeave:Connect(function() tween(b, T, { BackgroundColor3 = C.raise, TextColor3 = C.label }):Play() end)
		return b
	end
	local minimize = ctlButton("-", 1)
	local exit = ctlButton("x", 2)

	local viewport = new("Frame", {
		Name = "Viewport",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 1, -50),
		ClipsDescendants = true,
		Parent = content,
	})

	-- Dragging logic
	do
		local dragging, dragStart, startPos
		local dragHandle = new("TextButton", { BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Size = UDim2.new(0.4, 0, 1, 0), Parent = topbar })
		dragHandle.ZIndex = 0
		local function begin(input)
			dragging = true
			dragStart = input.Position
			startPos = base.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
		dragHandle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then begin(input) end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - dragStart
				base.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
	end

	-- Global Settings Panel
	local gsPanel = new("Frame", {
		Name = "GlobalSettings",
		Position = UDim2.fromOffset(SIDEBAR_W - 6, 68),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		ZIndex = 30,
		Visible = false,
		Parent = base,
	}, { corner(8), stroke(C.accent, 1, 0.4), pad(10, 12, 10, 12), list(nil, 4) })
	local gsScale = new("UIScale", { Scale = 0, Parent = gsPanel })
	local gsOpen = false

	local function toggleGS()
		if gsOpen then
			tween(gsScale, TQ, { Scale = 0 }):Play()
			task.wait(0.15)
			gsPanel.Visible = false
			gsOpen = false
		else
			gsPanel.Visible = true
			gsScale.Scale = 0
			tween(gsScale, TQ, { Scale = 1 }):Play()
			gsOpen = true
		end
	end
	globeBtn.MouseButton1Click:Connect(function() if hasGlobalSetting then toggleGS() end end)

	function Window:GlobalSetting(cfg)
		hasGlobalSetting = true
		globeBtn.Visible = true
		local GS = {}
		local row = new("TextButton", { BackgroundColor3 = C.panel, AutoButtonColor = false, BorderSizePixel = 0, Text = "", Size = UDim2.new(0, 190, 0, 30), Parent = gsPanel }, { pad(0, 10, 0, 10) })
		local check = new("TextLabel", { BackgroundTransparency = 1, FontFace = mono(W.bold), Text = "•", TextColor3 = C.accent, TextSize = 14, Size = UDim2.fromOffset(14, 30), Parent = row })
		local nameLbl = new("TextLabel", { BackgroundTransparency = 1, FontFace = mono(W.med), Text = cfg.Name, TextColor3 = C.label, TextSize = 12, Position = UDim2.new(0, 18, 0, 0), Size = UDim2.new(1, -18, 1, 0), Parent = row })

		local state = cfg.Default
		local function render()
			check.TextColor3 = state and C.accent or C.dim2
			nameLbl.TextColor3 = state and C.ink or C.label
		end
		render()
		row.MouseButton1Click:Connect(function()
			state = not state; render()
			if cfg.Callback then task.spawn(cfg.Callback, state) end
		end)
		return GS
	end

	--// TAB GROUP & SECTIONS -------------------------------------------
	function Window:TabGroup()
		local Group = {}
		local groupFrame = new("Frame", {
			Name = "TabGroup",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, -24, 0, 0),
			Parent = tabList,
		}, { list(nil, 4) })

		function Group:Tab(tset)
			tset = tset or {}
			local Tab = { Settings = tset }

			tabIndex += 1
			local switcher = new("TextButton", {
				Name = "TabSwitcher",
				BackgroundColor3 = C.raise,
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Text = "",
				LayoutOrder = tabIndex,
				Size = UDim2.new(1, 0, 0, 36),
				Parent = groupFrame,
			}, { corner(6), pad(0, 10, 0, 12) })
			local swStroke = stroke(C.accent, 1, 1)
			swStroke.Parent = switcher

			local swIcon
			if tset.Image then
				swIcon = new("ImageLabel", {
					BackgroundTransparency = 1,
					Image = resolveImage(tset.Image),
					ImageColor3 = C.label,
					ImageTransparency = 0.3,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.fromOffset(16, 16),
					Parent = switcher,
				})
			end
			local swName = new("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = mono(W.med),
				Text = tset.Name or "Tab",
				TextColor3 = C.label,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, tset.Image and 24 or 0, 0, 0),
				Size = UDim2.new(1, -(tset.Image and 24 or 0), 1, 0),
				Parent = switcher,
			})

			local tabContent = new("Frame", { Name = "TabContent", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false })
			local scroll = new("ScrollingFrame", {
				BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
				CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 2, ScrollBarImageColor3 = C.accent, ScrollBarImageTransparency = 0.5,
				TopImage = "", BottomImage = "", Parent = tabContent,
			}, { pad(16, 0, 16, 0) })

			local columns = new("Frame", {
				BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
				AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0),
				Size = UDim2.new(1, -30, 0, 0), Parent = scroll,
			}, { list(Enum.FillDirection.Horizontal, 14) })

			local left = new("Frame", { Name = "Left", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(0.5, -7, 0, 0), Parent = columns }, { list(nil, 14) })
			local right = new("Frame", { Name = "Right", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Size = UDim2.new(0.5, -7, 0, 0), Parent = columns }, { list(nil, 14) })

			function Tab:Section(sset)
				sset = sset or {}
				local Section = {}
				local host = (sset.Side == "Right") and right or left

				local card = new("Frame", {
					Name = "Section",
					BackgroundColor3 = C.panel,
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1, 0, 0, 0),
					Parent = host,
				}, { corner(8), stroke(C.line2, 1, 0), pad(16, 16, 16, 16), list(nil, 8) })

				if sset.Name then
					new("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = mono(W.bold),
						Text = track(string.upper(sset.Name)),
						TextColor3 = C.accent,
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left,
						Size = UDim2.new(1, 0, 0, 14),
						LayoutOrder = -10,
						Parent = card,
					})
				end

				local function baseRow(height)
					return new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height or 30), Parent = card })
				end
				local function nameLabel(row, txt, rightPad)
					return new("TextLabel", {
						BackgroundTransparency = 1, FontFace = mono(W.med), Text = txt,
						TextColor3 = C.ink2, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, -(rightPad or 60), 1, 0), Parent = row,
					})
				end

				-- Tooltip attachment helper
				local function attachTooltip(obj, tipText)
					if not tipText then return end
					obj.MouseEnter:Connect(function()
						showTooltip(tipText, UserInputService:GetMouseLocation())
					end)
					obj.MouseLeave:Connect(hideTooltip)
				end

				--// Button ------------------------------------------
				function Section:Button(cfg, Flag)
					local B = { Settings = cfg }
					local btn = new("TextButton", {
						BackgroundColor3 = C.raise, AutoButtonColor = false, BorderSizePixel = 0,
						Text = "", Size = UDim2.new(1, 0, 0, 32), Parent = card,
					}, { corner(6), stroke(C.line, 1, 0) })
					local lbl = new("TextLabel", {
						BackgroundTransparency = 1, FontFace = mono(W.semi), Text = cfg.Name,
						TextColor3 = C.ink2, TextSize = 12, Size = UDim2.fromScale(1, 1), Parent = btn,
					})
					btn.MouseEnter:Connect(function()
						tween(btn, T, { BackgroundColor3 = C.hover }):Play()
						tween(lbl, T, { TextColor3 = C.accent }):Play()
					end)
					btn.MouseLeave:Connect(function()
						tween(btn, T, { BackgroundColor3 = C.raise }):Play()
						tween(lbl, T, { TextColor3 = C.ink2 }):Play()
					end)
					btn.MouseButton1Click:Connect(function() if cfg.Callback then task.spawn(cfg.Callback) end end)
					attachTooltip(btn, cfg.Tooltip)
					if Flag then Senzy.Options[Flag] = B end
					return B
				end

				--// Toggle ------------------------------------------
				function Section:Toggle(cfg, Flag)
					local Tg = { Settings = cfg, Class = "Toggle" }
					local row = baseRow(30)
					nameLabel(row, cfg.Name, 52)

					local pill = new("TextButton", {
						BackgroundColor3 = C.raise, AutoButtonColor = false, BorderSizePixel = 0, Text = "",
						AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(38, 20), Parent = row,
					}, { corner(10), stroke(C.line2, 1, 0) })
					local knob = new("Frame", {
						BackgroundColor3 = C.dim, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(14, 14), Parent = pill,
					}, { corner(7) })

					local st = cfg.Default and true or false
					local function render(fireCb)
						if st then
							tween(pill, T, { BackgroundColor3 = C.accent }):Play()
							tween(knob, T, { Position = UDim2.new(1, -17, 0.5, 0), BackgroundColor3 = C.ground }):Play()
						else
							tween(pill, T, { BackgroundColor3 = C.raise }):Play()
							tween(knob, T, { Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = C.dim }):Play()
						end
						Tg.State = st
						if fireCb and cfg.Callback then task.spawn(cfg.Callback, st) end
					end
					render(false)
					pill.MouseButton1Click:Connect(function() st = not st; render(true) end)
					attachTooltip(row, cfg.Tooltip)
					if Flag then Senzy.Options[Flag] = Tg end
					return Tg
				end

				--// Status Indicator Label --------------------------
				function Section:StatusIndicator(cfg, Flag)
					local SI = { Settings = cfg }
					local row = baseRow(26)
					nameLabel(row, cfg.Name, 40)
					
					local indicator = new("Frame", {
						BackgroundColor3 = cfg.Default and C.ok or C.bad,
						BorderSizePixel = 0,
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(1, 0.5),
						Size = UDim2.fromOffset(10, 10),
						Parent = row,
					}, { corner(5), stroke(C.line, 1, 0) })
					
					local statusVal = cfg.Default and true or false
					function SI:SetStatus(active)
						statusVal = active
						tween(indicator, T, { BackgroundColor3 = active and C.ok or C.bad }):Play()
					end
					function SI:GetStatus() return statusVal end
					if Flag then Senzy.Options[Flag] = SI end
					return SI
				end

				--// Slider ------------------------------------------
				function Section:Slider(cfg, Flag)
					local S = { Settings = cfg, Class = "Slider" }
					local row = baseRow(42)
					new("TextLabel", {
						BackgroundTransparency = 1, FontFace = mono(W.med), Text = cfg.Name,
						TextColor3 = C.ink2, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
						Size = UDim2.new(1, -70, 0, 16), Parent = row,
					})
					local valBox = new("TextBox", {
						BackgroundColor3 = C.raise, BorderSizePixel = 0, FontFace = mono(W.med),
						Text = "", TextColor3 = C.accent, TextSize = 11, ClearTextOnFocus = false,
						AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(58, 18), Parent = row,
					}, { corner(4), stroke(C.line, 1, 0), pad(0, 4, 0, 4) })

					local barBg = new("Frame", {
						BackgroundColor3 = C.raise, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1),
						Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, 4), Parent = row,
					}, { corner(2) })
					local fill = new("Frame", { BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), Parent = barBg }, { corner(2) })
					local knob = new("TextButton", {
						BackgroundColor3 = C.accent, AutoButtonColor = false, BorderSizePixel = 0, Text = "",
						AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(12, 12), ZIndex = 3, Parent = barBg,
					}, { corner(6), stroke(C.ground, 2, 0) })

					local minv, maxv, prec = cfg.Minimum or 0, cfg.Maximum or 100, cfg.Precision
					local finalValue = cfg.Default or minv

					local function fmt(v)
						local body = prec and string.format("%." .. prec .. "f", v) or tostring(math.round(v))
						return (cfg.Prefix or "") .. body .. (cfg.Suffix or "")
					end

					local function apply(v, silent)
						v = math.clamp(v, minv, maxv)
						finalValue = v
						local a = (v - minv) / (maxv - minv)
						fill.Size = UDim2.fromScale(a, 1)
						knob.Position = UDim2.fromScale(a, 0.5)
						valBox.Text = fmt(v)
						S.Value = v
						if not silent and cfg.Callback then task.spawn(cfg.Callback, v) end
					end
					apply(finalValue, true)

					local dragging = false
					local function fromX(px)
						local a = math.clamp((px - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
						apply(minv + a * (maxv - minv))
					end
					knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
					barBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; fromX(i.Position.X) end end)
					UserInputService.InputChanged:Connect(function(i)
						if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then fromX(i.Position.X) end
					end)
					UserInputService.InputEnded:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
					end)
					valBox.FocusLost:Connect(function()
						local n = tonumber((valBox.Text:gsub("[^%d%.%-]", "")))
						if n then apply(n) else valBox.Text = fmt(finalValue) end
					end)

					attachTooltip(row, cfg.Tooltip)
					if Flag then Senzy.Options[Flag] = S end
					return S
				end

				--// Range Slider / Dual Slider ----------------------
				function Section:RangeSlider(cfg, Flag)
					local RS = { Settings = cfg, Class = "RangeSlider" }
					local row = baseRow(44)
					new("TextLabel", {
						BackgroundTransparency = 1, FontFace = mono(W.med), Text = cfg.Name,
						TextColor3 = C.ink2, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
						Size = UDim2.new(1, 0, 0, 16), Parent = row,
					})
					local valLbl = new("TextLabel", {
						BackgroundTransparency = 1, FontFace = mono(W.med), Text = "",
						TextColor3 = C.accent, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right,
						AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0),
						Size = UDim2.new(0, 120, 0, 16), Parent = row,
					})

					local barBg = new("Frame", {
						BackgroundColor3 = C.raise, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1),
						Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, 4), Parent = row,
					}, { corner(2) })
					local fill = new("Frame", { BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = barBg }, { corner(2) })

					local minv, maxv = cfg.Minimum or 0, cfg.Maximum = 100
					local minVal = cfg.DefaultMin or minv
					local maxVal = cfg.DefaultMax or maxv

					local function apply(mn, mx, silent)
						mn = math.clamp(mn, minv, maxv)
						mx = math.clamp(mx, mn, maxv)
						minVal, maxVal = mn, mx
						RS.Min, RS.Max = mn, mx
						
						local a1 = (mn - minv) / (maxv - minv)
						local a2 = (mx - minv) / (maxv - minv)
						fill.Position = UDim2.fromScale(a1, 0)
						fill.Size = UDim2.fromScale(a2 - a1, 1)
						valLbl.Text = math.round(mn) .. " - " .. math.round(mx)
						if not silent and cfg.Callback then task.spawn(cfg.Callback, mn, mx) end
					end
					apply(minVal, maxVal, true)
					if Flag then Senzy.Options[Flag] = RS end
					return RS
				end

				--// Input -------------------------------------------
				function Section:Input(cfg, Flag)
					local I = { Settings = cfg, Class = "Input" }
					local row = baseRow(30)
					nameLabel(row, cfg.Name, 130)

					local box = new("TextBox", {
						BackgroundColor3 = C.raise, BorderSizePixel = 0, FontFace = mono(W.med),
						Text = cfg.Default or "", PlaceholderText = cfg.Placeholder or "", PlaceholderColor3 = C.dim2,
						TextColor3 = C.ink, TextSize = 11, ClearTextOnFocus = false,
						AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
						Size = UDim2.fromOffset(120, 22), Parent = row,
					}, { corner(4), stroke(C.line, 1, 0), pad(0, 8, 0, 8) })

					box.FocusLost:Connect(function() if cfg.Callback then task.spawn(cfg.Callback, box.Text) end end)
					if Flag then Senzy.Options[Flag] = I end
					return I
				end

				--// Keybind -----------------------------------------
				function Section:Keybind(cfg, Flag)
					local K = { Settings = cfg, Class = "Keybind" }
					local row = baseRow(30)
					nameLabel(row, cfg.Name, 90)

					local box = new("TextButton", {
						BackgroundColor3 = C.raise, AutoButtonColor = false, BorderSizePixel = 0,
						FontFace = mono(W.med), Text = cfg.Default and cfg.Default.Name or "...",
						TextColor3 = C.accent, TextSize = 11, AutomaticSize = Enum.AutomaticSize.X,
						AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
						Size = UDim2.fromOffset(40, 22), Parent = row,
					}, { corner(4), stroke(C.line, 1, 0), pad(0, 10, 0, 10) })

					local binded = cfg.Default
					local listening = false

					box.MouseButton1Click:Connect(function() listening = true; box.Text = "..." end)
					UserInputService.InputBegan:Connect(function(input, gpe)
						if listening and input.UserInputType == Enum.UserInputType.Keyboard then
							binded = input.KeyCode
							box.Text = input.KeyCode.Name
							listening = false
							if cfg.onBinded then cfg.onBinded(binded) end
							return
						end
						if not gpe and binded and input.KeyCode == binded then
							if cfg.Callback then cfg.Callback(binded) end
						end
					end)

					if Flag then Senzy.Options[Flag] = K end
					return K
				end

				--// Dropdown ----------------------------------------
				function Section:Dropdown(cfg, Flag)
					local D = { Settings = cfg, Class = "Dropdown" }
					local Selected = {}
					local OptionObjs = {}

					local wrap = new("Frame", {
						BackgroundColor3 = C.raise, BorderSizePixel = 0, ClipsDescendants = true,
						Size = UDim2.new(1, 0, 0, 32), Parent = card,
					}, { corner(6), stroke(C.line, 1, 0) })

					local headBtn = new("TextButton", { BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Size = UDim2.new(1, 0, 0, 32), Parent = wrap }, { pad(0, 12, 0, 12) })
					local headLbl = new("TextLabel", { BackgroundTransparency = 1, FontFace = mono(W.med), TextColor3 = C.ink2, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -18, 1, 0), Parent = headBtn })
					local arrow = new("TextLabel", { BackgroundTransparency = 1, FontFace = mono(W.bold), Text = "v", TextColor3 = C.accent, TextSize = 11, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(12, 12), Parent = headBtn })

					local body = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 0), Parent = wrap }, { list(nil, 0), pad(0, 6, 8, 6) })

					local open = false
					local function refreshHead()
						if #Selected > 0 then headLbl.Text = cfg.Name .. " : " .. table.concat(Selected, ", ")
						else headLbl.Text = cfg.Name .. "..." end
					end

					local function setOpt(name, on)
						local o = OptionObjs[name]
						if not o then return end
						if on then
							Selected = { name }
							o.dot.Text = "•"; o.dot.TextColor3 = C.accent
							o.lbl.TextColor3 = C.ink
							D.Value = name
						else
							Selected = {}
							o.dot.Text = "◦"; o.dot.TextColor3 = C.dim2
							o.lbl.TextColor3 = C.label
							D.Value = nil
						end
						refreshHead()
					end

					if cfg.Options then
						for i, v in ipairs(cfg.Options) do
							local opt = new("TextButton", { BackgroundTransparency = 1, AutoButtonColor = false, Text = "", LayoutOrder = i, Size = UDim2.new(1, 0, 0, 26), Parent = body }, { pad(0, 6, 0, 6) })
							local dot = new("TextLabel", { BackgroundTransparency = 1, FontFace = mono(W.bold), Text = "◦", TextColor3 = C.dim2, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(14, 26), Parent = opt })
							local lbl = new("TextLabel", { BackgroundTransparency = 1, FontFace = mono(W.med), Text = v, TextColor3 = C.label, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 18, 0.5, 0), Size = UDim2.new(1, -18, 1, 0), Parent = opt })
							OptionObjs[v] = { btn = opt, dot = dot, lbl = lbl }
							opt.MouseButton1Click:Connect(function()
								setOpt(v, true)
								if cfg.Callback then cfg.Callback(v) end
								open = false
								tween(wrap, TQ, { Size = UDim2.new(1, 0, 0, 32) }):Play()
							end)
						end
					end
					refreshHead()

					headBtn.MouseButton1Click:Connect(function()
						open = not open
						local h = open and (32 + body.AbsoluteSize.Y) or 32
						tween(wrap, TQ, { Size = UDim2.new(1, 0, 0, h) }):Play()
						tween(arrow, TQ, { Rotation = open and 180 or 0 }):Play()
					end)

					if Flag then Senzy.Options[Flag] = D end
					return D
				end

				--// Paragraph / Label / Divider ---------------------
				function Section:Paragraph(cfg)
					local box = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = card }, { list(nil, 4) })
					new("TextLabel", { BackgroundTransparency = 1, FontFace = mono(W.semi), Text = cfg.Header or "", TextColor3 = C.ink, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 14), Parent = box })
					new("TextLabel", { BackgroundTransparency = 1, FontFace = mono(W.reg), Text = cfg.Body or "", TextColor3 = C.dim, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 12), Parent = box })
				end
				function Section:Divider()
					new("Frame", { BackgroundColor3 = C.line, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), Parent = card })
				end

				return Section
			end

			local function selectThis()
				if currentTabInstance then currentTabInstance.Parent = nil end
				for btn, info in pairs(tabs) do
					local on = (btn == switcher)
					tween(btn, T, { BackgroundTransparency = on and 0 or 1 }):Play()
					tween(info.stroke, T, { Transparency = on and 0 or 1 }):Play()
					if info.icon then tween(info.icon, T, { ImageTransparency = on and 0 or 0.3 }):Play() end
					tween(info.name, T, { TextColor3 = on and C.ink or C.label }):Play()
				end
				tabContent.Parent = viewport
				tabContent.Visible = true
				currentTabInstance = tabContent
				currentTabLabel.Text = tset.Name or ""
			end
			switcher.MouseButton1Click:Connect(selectThis)
			tabs[switcher] = { content = tabContent, stroke = swStroke, icon = swIcon, name = swName }

			if tabIndex == 1 then selectThis() end
			return Tab
		end
		return Group
	end

	-- Window notifications & utilities
	function Window:Notify(cfg)
		cfg = cfg or {}
		local card = new("Frame", {
			BackgroundColor3 = C.panel, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromOffset(260, 0), Parent = notifications,
		}, { corner(8), stroke(C.accent, 1, 0.3), pad(10, 12, 12, 12), list(nil, 3) })
		local scale = new("UIScale", { Scale = 0, Parent = card })

		new("TextLabel", { BackgroundTransparency = 1, FontFace = mono(W.semi), Text = cfg.Title or "Senzy", TextColor3 = C.accent, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 14), Parent = card })
		new("TextLabel", { BackgroundTransparency = 1, FontFace = mono(W.reg), Text = cfg.Description or "", TextColor3 = C.dim, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 12), Parent = card })

		tween(scale, TQ, { Scale = 1 }):Play()
		task.spawn(function()
			task.wait(cfg.Lifetime or 3)
			tween(scale, TQ, { Scale = 0 }):Play()
			task.wait(0.2)
			card:Destroy()
		end)
	end

	function Window:Unload() gui:Destroy() end

	local MenuKeybind = Settings.Keybind or Enum.KeyCode.RightControl
	local function setMinimized(min)
		windowState = not min
		base.Visible = not min
	end
	UserInputService.InputEnded:Connect(function(inp, gpe)
		if not gpe and inp.KeyCode == MenuKeybind then setMinimized(not windowState) end
	end)
	minimize.MouseButton1Click:Connect(function() setMinimized(true) end)
	exit.MouseButton1Click:Connect(function() Window:Unload() end)

	return Window
end

--// DEMO USAGE --------------------------------------------------------
function Senzy:Demo()
	local Window = Senzy:Window({
		Title = "Senzy",
		Subtitle = "rose premium edition",
		Size = UDim2.fromOffset(780, 540),
		ShowUserInfo = true,
		Keybind = Enum.KeyCode.RightControl,
	})

	Window:GlobalSetting({
		Name = "Enable Notifications",
		Default = true,
		Callback = function(b) print("Global setting toggled:", b) end,
	})

	local group = Window:TabGroup()
	local main = group:Tab({ Name = "Main Features", Image = "rbxassetid://18821914323" })
	local combat = group:Tab({ Name = "Combat & Range", Image = "rbxassetid://10734950309" })

	local sec = main:Section({ Name = "Automation Controls", Side = "Left" })

	sec:Toggle({
		Name = "Auto Farm Mode",
		Default = false,
		Tooltip = "เปิดระบบฟาร์มอัตโนมัติรอบตัวละคร",
		Callback = function(v)
			Window:Notify({ Title = "Auto Farm", Description = v and "เปิดใช้งานระบบฟาร์มแล้ว" or "ปิดการทำงานแล้ว" })
		end,
	}, "AutoFarm")

	sec:StatusIndicator({
		Name = "Server Status",
		Default = true,
	}, "ServStatus")

	sec:Slider({
		Name = "Attack Speed",
		Default = 16, Minimum = 1, Maximum = 50,
		Precision = 1, Suffix = "x",
		Tooltip = "ปรับความเร็วในการออกสกิลโจมตี",
		Callback = function(v) print("Speed:", v) end,
	}, "AtkSpeed")

	local sec2 = main:Section({ Name = "Targeting Config", Side = "Right" })
	sec2:RangeSlider({
		Name = "Distance Range (Min - Max)",
		Minimum = 0, Maximum = 500,
		DefaultMin = 50, DefaultMax = 250,
		Callback = function(mn, mx) print("Range:", mn, mx) end,
	}, "DistRange")

	sec2:Dropdown({
		Name = "Target Priority",
		Options = { "Lowest HP", "Closest Distance", "Boss Only", "Highest Bounty" },
		Default = "Closest Distance",
		Callback = function(v) print("Priority:", v) end,
	}, "TargetDrop")

	sec2:Keybind({
		Name = "Trigger Key",
		Default = Enum.KeyCode.Q,
		Callback = function(k) Window:Notify({ Title = "Keybind", Description = "Pressed key: " .. k.Name }) end,
	}, "TrigKey")

	local sec3 = combat:Section({ Name = "Information", Side = "Left" })
	sec3:Paragraph({
		Header = "About Theme",
		Body = "ธีมสีชมพูอ่อน (Rose Theme) ช่วยให้ UI ดูพรีเมี่ยม สบายตา และมีความลักชูรีมากขึ้น เหมาะสำหรับทำสคริปต์ฮับพรีเมี่ยม",
	})
	sec3:Divider()
	sec3:Button({
		Name = "Test Notification",
		Callback = function() Window:Notify({ Title = "System", Description = "ทดสอบระบบแจ้งเตือนสำเร็จ!" }) end,
	})

	main:Select()
end

return Senzy
