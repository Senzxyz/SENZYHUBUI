local SENZYHUB = {
	Options = {},
	Folder = "SENZYHUB",
	GetService = function(service)
		return cloneref and cloneref(game:GetService(service)) or game:GetService(service)
	end,
}

--// Services
local TweenService     = SENZYHUB.GetService("TweenService")
local RunService       = SENZYHUB.GetService("RunService")
local HttpService      = SENZYHUB.GetService("HttpService")
local ContentProvider  = SENZYHUB.GetService("ContentProvider")
local UserInputService  = SENZYHUB.GetService("UserInputService")
local Players          = SENZYHUB.GetService("Players")

local isStudio    = RunService:IsStudio()
local LocalPlayer = Players.LocalPlayer

--// Theme -------------------------------------------------------------
local C = {
	scrim  = Color3.fromRGB(0, 0, 0),
	ground = Color3.fromRGB(10, 10, 10),
	panel  = Color3.fromRGB(15, 15, 15),
	raise  = Color3.fromRGB(24, 24, 24),
	hover  = Color3.fromRGB(32, 32, 32),
	ink    = Color3.fromRGB(255, 255, 255),
	ink2   = Color3.fromRGB(225, 225, 225),
	label  = Color3.fromRGB(190, 190, 190),
	dim    = Color3.fromRGB(152, 152, 152),
	dim2   = Color3.fromRGB(96, 96, 96),
	line   = Color3.fromRGB(40, 40, 40),
	line2  = Color3.fromRGB(65, 65, 65),
	ok     = Color3.fromRGB(120, 230, 150),
	bad    = Color3.fromRGB(240, 120, 120),
}

-- เปลี่ยนฟอนต์ให้ดูโมเดิร์นและอ่านง่ายขึ้น (ใช้ Montserrat แบบหนา)
local FONT = "rbxasset://fonts/families/Montserrat.json"
local W = {
	reg  = Enum.FontWeight.Medium,
	med  = Enum.FontWeight.SemiBold,
	semi = Enum.FontWeight.Bold,
	bold = Enum.FontWeight.Heavy,
}
local function getFont(weight)
	return Font.new(FONT, weight or W.reg, Enum.FontStyle.Normal)
end

local function track(s)
	return tostring(s)
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

local function corner(r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 6) })
end

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

local function tween(inst, info, goal)
	return TweenService:Create(inst, info, goal)
end
local T = TweenInfo.new(0.12, Enum.EasingStyle.Sine)
local TQ = TweenInfo.new(0.18, Enum.EasingStyle.Quad)

local function GetGui()
	local g = Instance.new("ScreenGui")
	g.Name = "SENZYHUB_" .. HttpService:GenerateGUID(false):sub(1, 6)
	g.ScreenInsets = Enum.ScreenInsets.None
	g.ResetOnSpawn = false
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.DisplayOrder = 2147483647
	local parent = RunService:IsStudio()
		and LocalPlayer:FindFirstChild("PlayerGui")
		or (gethui and gethui())
		or (cloneref and cloneref(SENZYHUB.GetService("CoreGui")) or SENZYHUB.GetService("CoreGui"))
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
	local ok = pcall(function()
		if not isfolder(SENZYHUB.Folder) then makefolder(SENZYHUB.Folder) end
		if not isfolder(SENZYHUB.Folder .. "/assets") then makefolder(SENZYHUB.Folder .. "/assets") end
	end)
	if not ok then return "" end
	local ext = img:match("%.(%a%a%a?%a?)$") or "png"
	local fname = SENZYHUB.Folder .. "/assets/" .. (img:gsub("[^%w]", "_")):sub(-48) .. "." .. ext
	if not isfile(fname) then
		local dok, data = pcall(function() return game:HttpGet(img) end)
		if not dok or not data then return "" end
		if not pcall(writefile, fname, data) then return "" end
	end
	local aok, asset = pcall(getcustom, fname)
	if aok and asset then
		imageCache[img] = asset
		return asset
	end
	return ""
end

--  WINDOW
function SENZYHUB:Window(Settings)
	Settings = Settings or {}
	local Window = { Settings = Settings }
	local gui = GetGui()

	local windowState = true
	local tabs = {}
	local currentTabInstance
	local tabIndex = 0
	local hasGlobalSetting = false

	local notifications = new("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
		Parent = gui,
	}, {
		new("UIListLayout", {
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		pad(12, 12, 12, 12),
	})

	local base = new("Frame", {
		Name = "Base",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = Settings.Size or UDim2.fromOffset(780, 530),
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		Parent = gui,
	}, {
		corner(10),
		stroke(C.line2, 1.5, 0),
	})
	local baseScale = new("UIScale", { Parent = base })

	local userScale = 1
	local function applyScale()
		local sz = Settings.Size or UDim2.fromOffset(780, 530)
		local dw, dh = sz.X.Offset, sz.Y.Offset
		local cam = workspace.CurrentCamera
		local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
		local fit = 1
		if dw > 0 and dh > 0 and vp.X > 0 and vp.Y > 0 then
			fit = math.min(1, (vp.X * 0.94) / dw, (vp.Y * 0.92) / dh)
		end
		baseScale.Scale = userScale * fit
	end
	applyScale()

	local SIDEBAR_W = Settings.SidebarWidth or 220

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
		Size = UDim2.new(1, 0, 0, 70),
		Parent = sidebar,
	}, { pad(18, 16, 0, 18) })

	local titleLabel = new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		FontFace = getFont(W.bold),
		Text = track(Settings.Title or "SENZY HUB"),
		TextColor3 = C.ink,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -20, 0, 20),
		Parent = header,
	})
	local subtitleLabel = new("TextLabel", {
		Name = "Subtitle",
		BackgroundTransparency = 1,
		FontFace = getFont(W.med),
		Text = Settings.Subtitle or "Ultimate Script UI",
		TextColor3 = C.label,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, -20, 0, 14),
		Parent = header,
	})

	local globeBtn = new("ImageButton", {
		Name = "Settings",
		BackgroundTransparency = 1,
		Image = "rbxassetid://108952102602834",
		ImageColor3 = C.ink,
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
		Position = UDim2.fromOffset(0, 70),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = sidebar,
	})

	local tabList = new("ScrollingFrame", {
		Name = "TabList",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 71),
		Size = UDim2.new(1, 0, 1, -71 - 65),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = C.line2,
		Parent = sidebar,
	}, {
		list(nil, 4, Enum.HorizontalAlignment.Center),
		pad(12, 0, 12, 0),
	})

	local userInfo = new("Frame", {
		Name = "UserInfo",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 65),
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
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = C.raise,
		BorderSizePixel = 0,
		Image = (isReady and headshotImage) or "",
		Parent = userInfo,
	}, { corner(17), stroke(C.line2, 1, 0) })

	new("TextLabel", {
		Name = "DisplayName",
		BackgroundTransparency = 1,
		FontFace = getFont(W.semi),
		Text = LocalPlayer.DisplayName,
		TextColor3 = C.ink,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 44, 0.5, -10),
		Size = UDim2.new(1, -44, 0, 14),
		Parent = userInfo,
	})
	
	new("TextLabel", {
		Name = "Username",
		BackgroundTransparency = 1,
		FontFace = getFont(W.reg),
		Text = "@" .. LocalPlayer.Name,
		TextColor3 = C.dim,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 44, 0.5, 6),
		Size = UDim2.new(1, -44, 0, 12),
		Parent = userInfo,
	})

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
		Size = UDim2.new(1, 0, 0, 48),
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
		FontFace = getFont(W.semi),
		Text = "",
		TextColor3 = C.ink,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, -90, 1, 0),
		Parent = topbar,
	})

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
			FontFace = getFont(W.bold),
			TextColor3 = C.ink,
			TextSize = 13,
			LayoutOrder = order,
			Size = UDim2.fromOffset(22, 22),
			Parent = controls,
		}, { corner(5), stroke(C.line, 1, 0) })
		b.MouseEnter:Connect(function() tween(b, T, { BackgroundColor3 = C.hover }):Play() end)
		b.MouseLeave:Connect(function() tween(b, T, { BackgroundColor3 = C.raise }):Play() end)
		return b
	end
	local minimize = ctlButton("-", 1)
	local exit = ctlButton("x", 2)

	local viewport = new("Frame", {
		Name = "Viewport",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 1, -48),
		ClipsDescendants = true,
		Parent = content,
	})

	-- Dragging System
	do
		local dragging, dragStart, startPos
		local dragHandle = new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, -90, 1, 0), Parent = topbar, ZIndex = 0 })
		dragHandle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true; dragStart = input.Position; startPos = base.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - dragStart
				base.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end

	-- Global Settings Panel
	local gsPanel = new("Frame", {
		Name = "GlobalSettings",
		Position = UDim2.fromOffset(SIDEBAR_W - 6, 70),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		ZIndex = 30,
		Visible = false,
		Parent = base,
	}, { corner(8), stroke(C.line2, 1, 0), pad(10, 12, 10, 12), list(nil, 4) })
	local gsScale = new("UIScale", { Scale = 0, Parent = gsPanel })
	local gsOpen = false

	globeBtn.MouseButton1Click:Connect(function()
		gsOpen = not gsOpen
		gsPanel.Visible = true
		tween(gsScale, TQ, { Scale = gsOpen and 1 or 0 }):Play()
		if not gsOpen then task.wait(0.2); if not gsOpen then gsPanel.Visible = false end end
	end)

	function Window:GlobalSetting(cfg)
		hasGlobalSetting = true; globeBtn.Visible = true
		local GS = {}
		local row = new("TextButton", { BackgroundColor3 = C.panel, AutoButtonColor = false, BorderSizePixel = 0, Text = "", Size = UDim2.new(0, 190, 0, 30), Parent = gsPanel }, { pad(0, 10, 0, 10) })
		local check = new("TextLabel", { BackgroundTransparency = 1, FontFace = getFont(W.bold), Text = "•", TextColor3 = C.ink, TextSize = 14, Size = UDim2.fromOffset(14, 30), Parent = row })
		local nameLbl = new("TextLabel", { BackgroundTransparency = 1, FontFace = getFont(W.med), Text = cfg.Name, TextColor3 = C.label, TextSize = 12, Position = UDim2.new(0, 18, 0, 0), Size = UDim2.new(1, -18, 1, 0), Parent = row })

		local state = cfg.Default
		local function render()
			check.TextColor3 = state and C.ok or C.dim2
			nameLbl.TextColor3 = state and C.ink or C.label
		end
		render()
		row.MouseButton1Click:Connect(function()
			state = not state; render()
			if cfg.Callback then task.spawn(cfg.Callback, state) end
		end)
		return GS
	end

	-- Tab Group & Tab System
	function Window:TabGroup()
		local Group = {}
		local groupFrame = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, -24, 0, 0), Parent = tabList }, { list(nil, 4) })

		function Group:Tab(tset)
			tset = tset or {}
			local Tab = { Settings = tset }
			tabIndex += 1

			local switcher = new("TextButton", {
				BackgroundColor3 = C.raise,
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Text = "",
				LayoutOrder = tabIndex,
				Size = UDim2.new(1, 0, 0, 36),
				Parent = groupFrame,
			}, { corner(6), pad(0, 10, 0, 12) })
			local swStroke = stroke(C.line2, 1, 1)
			swStroke.Parent = switcher

			local swIcon
			if tset.Image then
				swIcon = new("ImageLabel", {
					BackgroundTransparency = 1,
					Image = resolveImage(tset.Image),
					ImageColor3 = C.label,
					ImageTransparency = 0.3,
					Size = UDim2.fromOffset(16, 16),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					Parent = switcher,
				})
			end
			local swName = new("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = getFont(W.med),
				Text = tset.Name or "Tab",
				TextColor3 = C.label,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, tset.Image and 24 or 0, 0, 0),
				Size = UDim2.new(1, -(tset.Image and 24 or 0), 1, 0),
				Parent = switcher,
			})

			local tabContent = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false })
			local scroll = new("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = C.line2,
				TopImage = "", BottomImage = "",
				Parent = tabContent,
			}, { pad(16, 0, 16, 0) })

			local columns = new("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0),
				Size = UDim2.new(1, -30, 0, 0),
				Parent = scroll,
			}, { list(Enum.FillDirection.Horizontal, 14) })

			local left = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(0.5, -7, 0, 0), Parent = columns }, { list(nil, 14) })
			local right = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Size = UDim2.new(0.5, -7, 0, 0), Parent = columns }, { list(nil, 14) })

			function Tab:Section(sset)
				sset = sset or {}
				local Section = {}
				local host = (sset.Side == "Right") and right or left

				local card = new("Frame", {
					BackgroundColor3 = C.panel,
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1, 0, 0, 0),
					Parent = host,
				}, { corner(8), stroke(C.line2, 1, 0), pad(16, 16, 16, 16), list(nil, 10) })

				if sset.Name then
					new("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = getFont(W.bold),
						Text = string.upper(sset.Name),
						TextColor3 = C.ink,
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left,
						Size = UDim2.new(1, 0, 0, 14),
						LayoutOrder = -10,
						Parent = card,
					})
				end

				local function baseRow(height)
					return new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height or 32), Parent = card })
				end
				local function nameLabel(row, txt, rightPad)
					return new("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = getFont(W.med),
						Text = txt,
						TextColor3 = C.ink2,
						TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.fromScale(0, 0.5),
						Size = UDim2.new(1, -(rightPad or 60), 1, 0),
						Parent = row,
					})
				end

				-- ฟีเจอร์: Button เพิ่มลูกเล่น Hover / Active
				function Section:Button(cfg, Flag)
					local B = { Settings = cfg }
					local btn = new("TextButton", { BackgroundColor3 = C.raise, AutoButtonColor = false, BorderSizePixel = 0, Text = "", Size = UDim2.new(1, 0, 0, 34), Parent = card }, { corner(6), stroke(C.line, 1, 0) })
					local lbl = new("TextLabel", { BackgroundTransparency = 1, FontFace = getFont(W.semi), Text = cfg.Name, TextColor3 = C.ink2, TextSize = 12, Size = UDim2.fromScale(1, 1), Parent = btn })
					
					btn.MouseEnter:Connect(function() tween(btn, T, { BackgroundColor3 = C.hover }):Play(); tween(lbl, T, { TextColor3 = C.ink }):Play() end)
					btn.MouseLeave:Connect(function() tween(btn, T, { BackgroundColor3 = C.raise }):Play(); tween(lbl, T, { TextColor3 = C.ink2 }):Play() end)
					btn.MouseButton1Click:Connect(function() if cfg.Callback then task.spawn(cfg.Callback) end end)
					if Flag then SENZYHUB.Options[Flag] = B end
					return B
				end

				-- ฟีเจอร์: Toggle แบบพรีเมียม
				function Section:Toggle(cfg, Flag)
					local Tg = { Settings = cfg, Class = "Toggle" }
					local row = baseRow(32)
					nameLabel(row, cfg.Name, 52)

					local pill = new("TextButton", { BackgroundColor3 = C.raise, AutoButtonColor = false, BorderSizePixel = 0, Text = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(40, 22), Parent = row }, { corner(11), stroke(C.line2, 1, 0) })
					local knob = new("Frame", { BackgroundColor3 = C.dim, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(16, 16), Parent = pill }, { corner(8) })

					local st = cfg.Default and true or false
					local function render(fireCb)
						if st then
							tween(pill, T, { BackgroundColor3 = C.ok }):Play()
							tween(knob, T, { Position = UDim2.new(1, -19, 0.5, 0), BackgroundColor3 = C.panel }):Play()
						else
							tween(pill, T, { BackgroundColor3 = C.raise }):Play()
							tween(knob, T, { Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = C.dim }):Play()
						end
						Tg.State = st
						if fireCb and cfg.Callback then task.spawn(cfg.Callback, st) end
					end
					render(false)
					pill.MouseButton1Click:Connect(function() st = not st; render(true) end)
					if Flag then SENZYHUB.Options[Flag] = Tg end
					return Tg
				end

				-- ฟีเจอร์: Slider ปรับแต่งความลื่นไหล
				function Section:Slider(cfg, Flag)
					local S = { Settings = cfg, Class = "Slider" }
					local row = baseRow(45)
					new("TextLabel", { BackgroundTransparency = 1, FontFace = getFont(W.med), Text = cfg.Name, TextColor3 = C.ink2, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -70, 0, 16), Parent = row })
					
					local valBox = new("TextBox", { BackgroundColor3 = C.raise, BorderSizePixel = 0, FontFace = getFont(W.med), Text = "", TextColor3 = C.ink, TextSize = 11, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(60, 20), Parent = row }, { corner(4), stroke(C.line, 1, 0) })
					local barBg = new("Frame", { BackgroundColor3 = C.raise, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, 6), Parent = row }, { corner(3) })
					local fill = new("Frame", { BackgroundColor3 = C.ok, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), Parent = barBg }, { corner(3) })

					local minv, maxv, finalValue = cfg.Minimum or 0, cfg.Maximum or 100, cfg.Default or 0
					local function apply(v, silent)
						v = math.clamp(v, minv, maxv); finalValue = v
						local a = (v - minv) / (maxv - minv)
						fill.Size = UDim2.fromScale(a, 1)
						valBox.Text = tostring(math.round(v))
						S.Value = v
						if not silent and cfg.Callback then task.spawn(cfg.Callback, v) end
					end
					apply(finalValue, true)

					local dragging = false
					barBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
					UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
					UserInputService.InputChanged:Connect(function(i)
						if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
							local a = math.clamp((i.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
							apply(minv + a * (maxv - minv))
						end
					end)
					if Flag then SENZYHUB.Options[Flag] = S end
					return S
				end

				-- ฟีเจอร์: Dropdown เมนูเลือกข้อมูล
				function Section:Dropdown(cfg, Flag)
					local D = { Settings = cfg, Class = "Dropdown" }
					local wrap = new("Frame", { BackgroundColor3 = C.raise, BorderSizePixel = 0, ClipsDescendants = true, Size = UDim2.new(1, 0, 0, 34), Parent = card }, { corner(6), stroke(C.line, 1, 0) })
					local headBtn = new("TextButton", { BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Size = UDim2.new(1, 0, 0, 34), Parent = wrap }, { pad(0, 12, 0, 12) })
					local headLbl = new("TextLabel", { BackgroundTransparency = 1, FontFace = getFont(W.med), Text = cfg.Name, TextColor3 = C.ink2, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 1, 0), Parent = headBtn })
					
					function D:SetVisibility(s) wrap.Visible = s end
					if Flag then SENZYHUB.Options[Flag] = D end
					return D
				end

				-- ฟีเจอร์: Label / Paragraph สำหรับแสดงข้อความแนะนำ
				function Section:Paragraph(cfg)
					local box = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Parent = card }, { list(nil, 4) })
					new("TextLabel", { BackgroundTransparency = 1, FontFace = getFont(W.semi), Text = cfg.Header or "", TextColor3 = C.ink, TextSize = 12, TextWrapped = true, Size = UDim2.new(1, 0, 0, 14), Parent = box })
					new("TextLabel", { BackgroundTransparency = 1, FontFace = getFont(W.reg), Text = cfg.Body or "", TextColor3 = C.dim, TextSize = 11, TextWrapped = true, Size = UDim2.new(1, 0, 0, 12), Parent = box })
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
					tween(info.name, T, { TextColor3 = on and C.ink or C.label }):Play()
				end
				tabContent.Parent = viewport; tabContent.Visible = true; currentTabInstance = tabContent
				currentTabLabel.Text = tset.Name or ""
			end
			switcher.MouseButton1Click:Connect(selectThis)
			tabs[switcher] = { content = tabContent, stroke = swStroke, name = swName }
			return Tab
		end
		return Group
	end

	function Window:Notify(cfg)
		local card = new("Frame", { BackgroundColor3 = C.panel, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.fromOffset(260, 0), Parent = notifications }, { corner(8), stroke(C.line2, 1, 0), pad(12, 14, 12, 14), list(nil, 4) })
		new("TextLabel", { BackgroundTransparency = 1, FontFace = getFont(W.semi), Text = cfg.Title or "SENZY HUB", TextColor3 = C.ink, TextSize = 12, Size = UDim2.new(1, 0, 0, 14), Parent = card })
		new("TextLabel", { BackgroundTransparency = 1, FontFace = getFont(W.reg), Text = cfg.Description or "", TextColor3 = C.dim, TextSize = 11, TextWrapped = true, Size = UDim2.new(1, 0, 0, 12), Parent = card })
		task.delay(cfg.Lifetime or 3, function() card:Destroy() end)
	end

	return Window
end

return SENZYHUB
