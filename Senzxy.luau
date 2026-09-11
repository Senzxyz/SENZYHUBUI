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
			if k ~= "Parent" then
				obj[k] = v
			end
		end
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = obj
		end
	end
	if props and props.Parent then
		obj.Parent = props.Parent
	end
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
	if not (getcustom and writefile and isfolder and makefolder and isfile) then
		return ""
	end
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
	local unloaded = false
	local tabs = {}
	local currentTabInstance
	local tabIndex = 0
	local hasGlobalSetting = false

	--// Notifications layer ------------------------------------------
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

	--// Base window ---------------------------------------------------
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
		if dw <= 0 then dw = base.AbsoluteSize.X end
		if dh <= 0 then dh = base.AbsoluteSize.Y end
		local cam = workspace.CurrentCamera
		local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
		local fit = 1
		if dw > 0 and dh > 0 and vp.X > 0 and vp.Y > 0 then
			fit = math.min(1, (vp.X * 0.94) / dw, (vp.Y * 0.92) / dh)
		end
		baseScale.Scale = userScale * fit
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
	}, {
		corner(10),
	})
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
	}, {
		pad(18, 16, 0, 18),
	})

	local titleLabel = new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		FontFace = getFont(W.bold),
		Text = track(Settings.Title or "SENZY HUB"),
		TextColor3 = C.ink,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, -20, 0, 20),
		Parent = header,
	})
	local subtitleLabel = new("TextLabel", {
		Name = "Subtitle",
		BackgroundTransparency = 1,
		FontFace = getFont(W.med),
		Text = Settings.Subtitle or "",
		TextColor3 = C.label,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
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

	-- Tab list
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
		TopImage = "", BottomImage = "",
		Parent = sidebar,
	}, {
		list(nil, 4, Enum.HorizontalAlignment.Center),
		pad(12, 0, 12, 0),
	})

	-- User info (bottom)
	local userInfo = new("Frame", {
		Name = "UserInfo",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 65),
		BackgroundTransparency = 1,
		Parent = sidebar,
	}, {
		pad(0, 14, 0, 14),
	})
	new("Frame", {
		BackgroundColor3 = C.line,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		Parent = userInfo,
	})

	local isReady, headshotImage = pcall(function()
		return Players:GetUserThumbnailAsync(LocalPlayer.UserId,
			Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size48x48)
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
	}, {
		corner(17),
		stroke(C.line2, 1, 0),
	})

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

	--// Content -------------------------------------------------------
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
	}, {
		pad(0, 16, 0, 20),
	})
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
	}, {
		list(Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right),
	})

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
		b.MouseEnter:Connect(function()
			tween(b, T, { BackgroundColor3 = C.hover }):Play()
		end)
		b.MouseLeave:Connect(function()
			tween(b, T, { BackgroundColor3 = C.raise }):Play()
		end)
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

	--// Dragging -----------------------------------------------------
	do
		local dragging, dragStart, startPos
		local dragHandle = new("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(1, -90, 1, 0),
			Parent = topbar,
		})
		dragHandle.ZIndex = 0
		local function begin(input)
			dragging = true
			dragStart = input.Position
			startPos = base.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
		dragHandle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				begin(input)
			end
		end)
		local headerDrag = new("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Parent = header,
		})
		headerDrag.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				begin(input)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - dragStart
				base.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
	end


	--  GLOBAL SETTINGS PANEL
	local gsPanel = new("Frame", {
		Name = "GlobalSettings",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(SIDEBAR_W - 6, 70),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		ZIndex = 30,
		Visible = false,
		Parent = base,
	}, {
		corner(8), stroke(C.line2, 1, 0),
		pad(10, 12, 10, 12),
		list(nil, 4),
	})
	local gsScale = new("UIScale", { Scale = 0, Parent = gsPanel })
	local gsOpen = false
	local gsHover = false

	local function toggleGS()
		if gsOpen then
			gsPanel.Visible = true
			local tw = tween(gsScale, TQ, { Scale = 0 })
			tw:Play(); tw.Completed:Wait()
			gsPanel.Visible = false
			gsOpen = false
		else
			gsPanel.Visible = true
			gsScale.Scale = 0
			tween(gsScale, TQ, { Scale = 1 }):Play()
			gsOpen = true
		end
	end
	globeBtn.MouseButton1Click:Connect(function()
		if hasGlobalSetting then toggleGS() end
	end)
	gsPanel.MouseEnter:Connect(function() gsHover = true end)
	gsPanel.MouseLeave:Connect(function() gsHover = false end)
	UserInputService.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 and gsOpen and not gsHover then
			task.wait()
			if not gsHover then toggleGS() end
		end
	end)

	function Window:GlobalSetting(cfg)
		hasGlobalSetting = true
		globeBtn.Visible = true
		local GS = {}
		local row = new("TextButton", {
			BackgroundColor3 = C.panel,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			Text = "",
			Size = UDim2.new(0, 190, 0, 30),
			Parent = gsPanel,
		}, { pad(0, 10, 0, 10) })

		local check = new("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = getFont(W.bold),
			Text = "•",
			TextColor3 = C.ink,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(14, 30),
			Parent = row,
		})
		local nameLbl = new("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = getFont(W.med),
			Text = cfg.Name,
			TextColor3 = C.label,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 18, 0.5, 0),
			Size = UDim2.new(1, -18, 1, 0),
			Parent = row,
		})

		local state = cfg.Default
		local function render()
			check.TextColor3 = state and C.ok or C.dim2
			check.Text = state and "•" or "◦"
			nameLbl.TextColor3 = state and C.ink or C.label
		end
		render()
		row.MouseButton1Click:Connect(function()
			state = not state
			render()
			task.spawn(function()
				if cfg.Callback then cfg.Callback(state) end
			end)
		end)
		function GS:UpdateName(n) nameLbl.Text = n end
		function GS:UpdateState(s) state = s; render() end
		return GS
	end


	--  TAB GROUP  /  TAB
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
			local swStroke = stroke(C.line2, 1, 1)
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
				FontFace = getFont(W.med),
				Text = tset.Name or "Tab",
				TextColor3 = C.label,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, tset.Image and 24 or 0, 0, 0),
				Size = UDim2.new(1, -(tset.Image and 24 or 0), 1, 0),
				Parent = switcher,
			})

			local tabContent = new("Frame", {
				Name = "TabContent",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Visible = false,
			})
			local scroll = new("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = C.line2,
				TopImage = "", BottomImage = "",
				Parent = tabContent,
			}, {
				pad(16, 0, 16, 0),
			})
			local columns = new("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0),
				Size = UDim2.new(1, -30, 0, 0),
				Parent = scroll,
			}, {
				list(Enum.FillDirection.Horizontal, 14),
			})
			local left = new("Frame", {
				Name = "Left",
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(0.5, -7, 0, 0),
				Parent = columns,
			}, { list(nil, 14) })
			local right = new("Frame", {
				Name = "Right",
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				Size = UDim2.new(0.5, -7, 0, 0),
				Parent = columns,
			}, { list(nil, 14) })

			--// Section --------------------------------------------
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
				}, {
					corner(8), stroke(C.line2, 1, 0),
					pad(16, 16, 16, 16),
					list(nil, 10),
				})

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
					local row = new("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, height or 32),
						Parent = card,
					})
					return row
				end
				local function nameLabel(row, txt, rightPad)
					return new("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = getFont(W.med),
						Text = txt,
						TextColor3 = C.ink2,
						TextSize = 12,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.fromScale(0, 0.5),
						Size = UDim2.new(1, -(rightPad or 60), 1, 0),
						Parent = row,
					})
				end

				--// Button ------------------------------------------
				function Section:Button(cfg, Flag)
					local B = { Settings = cfg }
					local btn = new("TextButton", {
						BackgroundColor3 = C.raise,
						AutoButtonColor = false,
						BorderSizePixel = 0,
						Text = "",
						Size = UDim2.new(1, 0, 0, 34),
						Parent = card,
					}, { corner(6), stroke(C.line, 1, 0) })
					local lbl = new("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = getFont(W.semi),
						Text = cfg.Name,
						TextColor3 = C.ink2,
						TextSize = 12,
						Size = UDim2.fromScale(1, 1),
						Parent = btn,
					})
					btn.MouseEnter:Connect(function()
						tween(btn, T, { BackgroundColor3 = C.hover }):Play()
						tween(lbl, T, { TextColor3 = C.ink }):Play()
					end)
					btn.MouseLeave:Connect(function()
						tween(btn, T, { BackgroundColor3 = C.raise }):Play()
						tween(lbl, T, { TextColor3 = C.ink2 }):Play()
					end)
					btn.MouseButton1Click:Connect(function()
						if cfg.Callback then task.spawn(cfg.Callback) end
					end)
					function B:UpdateName(n) lbl.Text = n end
					function B:SetVisibility(s) btn.Visible = s end
					if Flag then SENZYHUB.Options[Flag] = B end
					return B
				end

				--// Toggle ------------------------------------------
				function Section:Toggle(cfg, Flag)
					local Tg = { Settings = cfg, Class = "Toggle" }
					local row = baseRow(32)
					nameLabel(row, cfg.Name, 52)

					local pill = new("TextButton", {
						BackgroundColor3 = C.raise,
						AutoButtonColor = false,
						BorderSizePixel = 0,
						Text = "",
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(1, 0.5),
						Size = UDim2.fromOffset(40, 22),
						Parent = row,
					}, { corner(11), stroke(C.line2, 1, 0) })
					local knob = new("Frame", {
						BackgroundColor3 = C.dim,
						BorderSizePixel = 0,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 3, 0.5, 0),
						Size = UDim2.fromOffset(16, 16),
						Parent = pill,
					}, { corner(8) })

					local st = cfg.Default and true or false
					local function render(fireCb)
						if st then
							tween(pill, T, { BackgroundColor3 = C.ok }):Play()
							tween(knob, T, {
								Position = UDim2.new(1, -19, 0.5, 0),
								BackgroundColor3 = C.panel,
							}):Play()
						else
							tween(pill, T, { BackgroundColor3 = C.raise }):Play()
							tween(knob, T, {
								Position = UDim2.new(0, 3, 0.5, 0),
								BackgroundColor3 = C.dim,
							}):Play()
						end
						Tg.State = st
						if fireCb and cfg.Callback then task.spawn(cfg.Callback, st) end
					end
					render(false)
					pill.MouseButton1Click:Connect(function()
						st = not st; render(true)
					end)

					function Tg:Toggle() st = not st; render(true) end
					function Tg:UpdateState(s) st = s; render(true) end
					function Tg:GetState() return st end
					function Tg:UpdateName(n) row.TextLabel.Text = n end
					function Tg:SetVisibility(s) row.Visible = s end
					if Flag then SENZYHUB.Options[Flag] = Tg end
					return Tg
				end

				--// Slider ------------------------------------------
				function Section:Slider(cfg, Flag)
					local S = { Settings = cfg, Class = "Slider" }
					local row = baseRow(45)
					new("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = getFont(W.med),
						Text = cfg.Name,
						TextColor3 = C.ink2,
						TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						ClipsDescendants = true,
						Position = UDim2.fromScale(0, 0),
						Size = UDim2.new(1, -70, 0, 16),
						Parent = row,
					})
					local valBox = new("TextBox", {
						BackgroundColor3 = C.raise,
						BorderSizePixel = 0,
						FontFace = getFont(W.med),
						Text = "",
						TextColor3 = C.ink,
						TextSize = 11,
						ClearTextOnFocus = false,
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.fromScale(1, 0),
						Size = UDim2.fromOffset(60, 20),
						Parent = row,
					}, { corner(4), stroke(C.line, 1, 0) })

					local barBg = new("Frame", {
						BackgroundColor3 = C.raise,
						BorderSizePixel = 0,
						AnchorPoint = Vector2.new(0, 1),
						Position = UDim2.new(0, 0, 1, -4),
						Size = UDim2.new(1, 0, 0, 6),
						Parent = row,
					}, { corner(3) })
					
					-- แถบเลื่อน (Fill) เป็นสีขาวปกติ (C.ink) ตามที่มึงขอ
					local fill = new("Frame", {
						BackgroundColor3 = C.ink,
						BorderSizePixel = 0,
						Size = UDim2.fromScale(0, 1),
						Parent = barBg,
					}, { corner(3) })

					local minv = cfg.Minimum or 0
					local maxv = cfg.Maximum or 100
					local prec = cfg.Precision
					local finalValue = cfg.Default or minv

					local function fmt(v)
						local method = cfg.DisplayMethod
						local body
						if method == "Percent" then
							local p = (v - minv) / (maxv - minv) * 100
							body = (prec and string.format("%." .. prec .. "f", p) or tostring(math.round(p))) .. "%"
						elseif method == "Degrees" then
							body = (prec and string.format("%." .. prec .. "f", v) or tostring(math.round(v))) .. "°"
						elseif prec then
							body = string.format("%." .. prec .. "f", v)
						else
							body = tostring(math.round(v))
						end
						return (cfg.Prefix or "") .. body .. (cfg.Suffix or "")
					end

					local function apply(v, silent)
						v = math.clamp(v, minv, maxv)
						finalValue = v
						local a = (v - minv) / (maxv - minv)
						fill.Size = UDim2.fromScale(a, 1)
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
					barBg.InputBegan:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1
							or i.UserInputType == Enum.UserInputType.Touch then
							dragging = true; fromX(i.Position.X)
						end
					end)
					UserInputService.InputChanged:Connect(function(i)
						if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
							or i.UserInputType == Enum.UserInputType.Touch) then
							fromX(i.Position.X)
						end
					end)
					UserInputService.InputEnded:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1
							or i.UserInputType == Enum.UserInputType.Touch then
							if dragging and cfg.onInputComplete then cfg.onInputComplete(finalValue) end
							dragging = false
						end
					end)
					valBox.FocusLost:Connect(function()
						local n = tonumber((valBox.Text:gsub("[^%d%.%-]", "")))
						if n then apply(n) else valBox.Text = fmt(finalValue) end
					end)

					function S:UpdateValue(v) apply(tonumber(v), false) end
					function S:GetValue() return finalValue end
					function S:SetVisibility(s) row.Visible = s end
					if Flag then SENZYHUB.Options[Flag] = S end
					return S
				end

				--// Input -------------------------------------------
				function Section:Input(cfg, Flag)
					local I = { Settings = cfg, Class = "Input" }
					local row = baseRow(32)
					nameLabel(row, cfg.Name, 130)

					local box = new("TextBox", {
						BackgroundColor3 = C.raise,
						BorderSizePixel = 0,
						FontFace = getFont(W.med),
						Text = cfg.Default or "",
						PlaceholderText = cfg.Placeholder or "",
						PlaceholderColor3 = C.dim2,
						TextColor3 = C.ink,
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left,
						ClearTextOnFocus = false,
						ClipsDescendants = true,
						TextTruncate = Enum.TextTruncate.AtEnd,
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(1, 0.5),
						Size = UDim2.fromOffset(120, 24),
						Parent = row,
					}, { corner(4), stroke(C.line, 1, 0), pad(0, 8, 0, 8) })

					local function limit(v)
						if cfg.CharacterLimit then return v:sub(1, cfg.CharacterLimit) end
						return v
					end
					local subs = {
						All = function(v) return limit(v) end,
						Numeric = function(v) return limit((v:gsub("[^%d%.%-]", ""))) end,
						Alphabetic = function(v) return limit((v:gsub("[^%a ]", ""))) end,
						AlphaNumeric = function(v) return limit((v:gsub("[^%w]", ""))) end,
					}
					local accept = type(cfg.AcceptedCharacters) == "function"
						and cfg.AcceptedCharacters or (subs[cfg.AcceptedCharacters] or subs.All)

					box:GetPropertyChangedSignal("Text"):Connect(function()
						box.Text = accept(box.Text)
						I.Text = box.Text
						if cfg.onChanged then cfg.onChanged(box.Text) end
					end)
					box.FocusLost:Connect(function()
						if cfg.Callback then task.spawn(cfg.Callback, box.Text) end
					end)

					function I:GetInput() return box.Text end
					function I:UpdateText(t)
						box.Text = accept(t)
						if cfg.Callback then task.spawn(cfg.Callback, box.Text) end
					end
					function I:UpdatePlaceholder(p) box.PlaceholderText = p end
					function I:SetVisibility(s) row.Visible = s end
					if Flag then SENZYHUB.Options[Flag] = I end
					return I
				end

				--// Keybind -----------------------------------------
				function Section:Keybind(cfg, Flag)
					local K = { Settings = cfg, Class = "Keybind" }
					local row = baseRow(32)
					nameLabel(row, cfg.Name, 90)

					local box = new("TextButton", {
						BackgroundColor3 = C.raise,
						AutoButtonColor = false,
						BorderSizePixel = 0,
						FontFace = getFont(W.med),
						Text = cfg.Default and cfg.Default.Name or "...",
						TextColor3 = C.ink,
						TextSize = 11,
						AutomaticSize = Enum.AutomaticSize.X,
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(1, 0.5),
						Size = UDim2.fromOffset(40, 24),
						Parent = row,
					}, { corner(4), stroke(C.line, 1, 0), pad(0, 10, 0, 10) })

					local binded = cfg.Default
					local listening = false

					box.MouseButton1Click:Connect(function()
						listening = true
						box.Text = "..."
						box.TextColor3 = C.ok
					end)
					UserInputService.InputBegan:Connect(function(input, gpe)
						if listening then
							if input.UserInputType == Enum.UserInputType.Keyboard then
								binded = input.KeyCode
								box.Text = input.KeyCode.Name
							elseif input.UserInputType == Enum.UserInputType.MouseButton1
								or input.UserInputType == Enum.UserInputType.MouseButton2 then
								binded = input.UserInputType
								box.Text = input.UserInputType.Name
							else return end
							box.TextColor3 = C.ink
							listening = false
							if cfg.onBinded then cfg.onBinded(binded) end
							return
						end
						if gpe then return end
						if binded and (input.KeyCode == binded or input.UserInputType == binded) then
							if cfg.Callback then cfg.Callback(binded) end
							if cfg.onBindHeld then cfg.onBindHeld(true, binded) end
						end
					end)
					UserInputService.InputEnded:Connect(function(input)
						if not listening and binded and (input.KeyCode == binded or input.UserInputType == binded) then
							if cfg.onBindHeld then cfg.onBindHeld(false, binded) end
						end
					end)

					function K:Bind(key) binded = key; box.Text = key.Name end
					function K:Unbind() binded = nil; box.Text = "..." end
					function K:GetBind() return binded end
					function K:SetVisibility(s) row.Visible = s end
					if Flag then SENZYHUB.Options[Flag] = K end
					return K
				end

				--// Dropdown ----------------------------------------
				function Section:Dropdown(cfg, Flag)
					local D = { Settings = cfg, Class = "Dropdown" }
					local Selected = {}
					local OptionObjs = {}

					local wrap = new("Frame", {
						BackgroundColor3 = C.raise,
						BorderSizePixel = 0,
						ClipsDescendants = true,
						Size = UDim2.new(1, 0, 0, 34),
						Parent = card,
					}, { corner(6), stroke(C.line, 1, 0) })

					local headBtn = new("TextButton", {
						BackgroundTransparency = 1,
						AutoButtonColor = false,
						Text = "",
						Size = UDim2.new(1, 0, 0, 34),
						Parent = wrap,
					}, { pad(0, 12, 0, 12) })
					local headLbl = new("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = getFont(W.med),
						TextColor3 = C.ink2,
						TextSize = 12,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left,
						Size = UDim2.new(1, -18, 1, 0),
						Parent = headBtn,
					})
					local arrow = new("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = getFont(W.bold),
						Text = "v",
						TextColor3 = C.dim,
						TextSize = 11,
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(1, 0.5),
						Size = UDim2.fromOffset(12, 12),
						Parent = headBtn,
					})

					local body = new("Frame", {
						BackgroundTransparency = 1,
						AutomaticSize = Enum.AutomaticSize.Y,
						Position = UDim2.fromOffset(0, 34),
						Size = UDim2.new(1, 0, 0, 0),
						Parent = wrap,
					}, { list(nil, 0), pad(0, 6, 8, 6) })

					local open = false
					local searchQuery = ""

					local searchWrap = new("Frame", {
						BackgroundColor3 = C.ground,
						BorderSizePixel = 0,
						LayoutOrder = -1,
						Size = UDim2.new(1, 0, 0, 26),
						Parent = body,
					}, { corner(5), stroke(C.line, 1, 0), pad(0, 8, 0, 8) })
					local searchBox = new("TextBox", {
						BackgroundTransparency = 1,
						FontFace = getFont(W.med),
						PlaceholderText = "Search...",
						PlaceholderColor3 = C.dim2,
						Text = "",
						TextColor3 = C.ink2,
						TextSize = 12,
						ClipsDescendants = true,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left,
						ClearTextOnFocus = false,
						Size = UDim2.new(1, 0, 1, 0),
						Parent = searchWrap,
					})

					local function applyFilter()
						local q = searchQuery:lower()
						for name, o in pairs(OptionObjs) do
							o.btn.Visible = (q == "") or (tostring(name):lower():find(q, 1, true) ~= nil)
						end
					end

					local function updateSearchVis()
						local n = 0
						for _ in pairs(OptionObjs) do n = n + 1 end
						searchWrap.Visible = (cfg.Search ~= false) and (n > 6)
						if not searchWrap.Visible and searchQuery ~= "" then
							searchQuery = ""; searchBox.Text = ""; applyFilter()
						end
					end

					searchBox:GetPropertyChangedSignal("Text"):Connect(function()
						searchQuery = searchBox.Text or ""
						applyFilter()
					end)
					
					local function bodyLocalH()
						local s = baseScale.Scale
						if s <= 0 then s = 1 end
						return body.AbsoluteSize.Y / s
					end
					body:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
						if open then wrap.Size = UDim2.new(1, 0, 0, 34 + bodyLocalH()) end
					end)

					local function refreshHead()
						if #Selected > 0 then
							headLbl.Text = cfg.Name .. " : " .. table.concat(Selected, ", ")
						else
							headLbl.Text = cfg.Name .. "..."
						end
					end

					local function setOpt(name, on)
						local o = OptionObjs[name]
						if not o then return end
						if on then
							if cfg.Multi then
								if not table.find(Selected, name) then table.insert(Selected, name) end
							else
								for n2, o2 in pairs(OptionObjs) do
									if n2 ~= name then
										o2.dot.Text = "◦"; o2.dot.TextColor3 = C.dim2
										o2.lbl.TextColor3 = C.label
									end
								end
								Selected = { name }
							end
							o.dot.Text = "•"; o.dot.TextColor3 = C.ok
							o.lbl.TextColor3 = C.ink
							D.Value = cfg.Multi and Selected or name
						else
							if cfg.Multi then
								local idx = table.find(Selected, name)
								if idx then table.remove(Selected, idx) end
							else
								Selected = {}
							end
							o.dot.Text = "◦"; o.dot.TextColor3 = C.dim2
							o.lbl.TextColor3 = C.label
							D.Value = cfg.Multi and Selected or nil
						end
						refreshHead()
					end

					local function addOption(i, v)
						local opt = new("TextButton", {
							BackgroundTransparency = 1,
							AutoButtonColor = false,
							Text = "",
							LayoutOrder = i,
							Size = UDim2.new(1, 0, 0, 26),
							Parent = body,
						}, { pad(0, 6, 0, 6) })
						local dot = new("TextLabel", {
							BackgroundTransparency = 1,
							FontFace = getFont(W.bold),
							Text = "◦",
							TextColor3 = C.dim2,
							TextSize = 13,
							TextXAlignment = Enum.TextXAlignment.Left,
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.fromScale(0, 0.5),
							Size = UDim2.fromOffset(14, 26),
							Parent = opt,
						})
						local lbl = new("TextLabel", {
							BackgroundTransparency = 1,
							FontFace = getFont(W.med),
							Text = v,
							TextColor3 = C.label,
							TextSize = 12,
							TextXAlignment = Enum.TextXAlignment.Left,
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(0, 18, 0.5, 0),
							Size = UDim2.new(1, -18, 1, 0),
							Parent = opt,
						})
						OptionObjs[v] = { btn = opt, dot = dot, lbl = lbl, Index = i }
						opt.MouseButton1Click:Connect(function()
							local on = not (table.find(Selected, v) and true or false)
							if cfg.Required and not on and #Selected <= 1 then return end
							setOpt(v, on)
							task.spawn(function()
								if cfg.Multi then
									local ret = {}
									for _, s in ipairs(Selected) do ret[s] = true end
									if cfg.Callback then cfg.Callback(ret) end
								elseif cfg.Callback then
									cfg.Callback(Selected[1])
								end
							end)
						end)
						if cfg.Default then
							if cfg.Multi and type(cfg.Default) == "table" then
								if table.find(cfg.Default, v) then setOpt(v, true) end
							elseif cfg.Default == i or cfg.Default == v then
								setOpt(v, true)
							end
						end
					end

					if cfg.Options then
						for i, v in ipairs(cfg.Options) do addOption(i, v) end
					end
					updateSearchVis()
					applyFilter()
					refreshHead()

					headBtn.MouseButton1Click:Connect(function()
						open = not open
						local h = open and (34 + bodyLocalH()) or 34
						tween(wrap, TQ, { Size = UDim2.new(1, 0, 0, h) }):Play()
						tween(arrow, TQ, { Rotation = open and 180 or 0 }):Play()
					end)

					function D:UpdateSelection(sel)
						for n in pairs(OptionObjs) do setOpt(n, false) end
						local picks = {}
						if type(sel) == "table" then
							for n in pairs(OptionObjs) do
								if table.find(sel, n) then setOpt(n, true); table.insert(picks, n) end
							end
						else
							for n, o in pairs(OptionObjs) do
								if n == sel or o.Index == sel then setOpt(n, true); table.insert(picks, n) end
							end
						end
						if cfg.Callback then
							if cfg.Multi then
								local ret = {}; for _, p in ipairs(picks) do ret[p] = true end
								cfg.Callback(ret)
							else
								cfg.Callback(picks[1])
							end
						end
					end
					function D:ClearOptions()
						for _, o in pairs(OptionObjs) do o.btn:Destroy() end
						OptionObjs = {}; Selected = {}; refreshHead()
						updateSearchVis()
					end
					function D:InsertOptions(opts)
						cfg.Options = opts
						for i, v in ipairs(opts) do addOption(i, v) end
						updateSearchVis(); applyFilter()
					end
					function D:GetOptions()
						local out = {}
						for n in pairs(OptionObjs) do out[n] = table.find(Selected, n) and true or false end
						return out
					end
					function D:SetVisibility(s) wrap.Visible = s end
					if Flag then SENZYHUB.Options[Flag] = D end
					return D
				end

				--// Header / Label / SubLabel / Paragraph -----------
				function Section:Header(cfg, Flag)
					local H = { Settings = cfg }
					local lbl = new("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = getFont(W.bold),
						Text = string.upper(cfg.Text or cfg.Name or ""),
						TextColor3 = C.ink2,
						TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.new(1, 0, 0, 16),
						Parent = card,
					})
					function H:UpdateName(n) lbl.Text = string.upper(n) end
					function H:SetVisibility(s) lbl.Visible = s end
					if Flag then SENZYHUB.Options[Flag] = H end
					return H
				end
				function Section:Label(cfg, Flag)
					local L = { Settings = cfg }
					local lbl = new("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = getFont(W.reg),
						RichText = true,
						Text = cfg.Text or cfg.Name or "",
						TextColor3 = C.label,
						TextSize = 12,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.new(1, 0, 0, 14),
						Parent = card,
					})
					function L:UpdateName(n) lbl.Text = n end
					function L:SetVisibility(s) lbl.Visible = s end
					if Flag then SENZYHUB.Options[Flag] = L end
					return L
				end
				function Section:SubLabel(cfg, Flag)
					local L = { Settings = cfg }
					local lbl = new("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = getFont(W.reg),
						RichText = true,
						Text = cfg.Text or cfg.Name or "",
						TextColor3 = C.dim,
						TextSize = 11,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.new(1, 0, 0, 13),
						Parent = card,
					})
					function L:UpdateName(n) lbl.Text = n end
					function L:SetVisibility(s) lbl.Visible = s end
					if Flag then SENZYHUB.Options[Flag] = L end
					return L
				end
				function Section:Paragraph(cfg, Flag)
					local P = { Settings = cfg }
					local collapsible = cfg.Collapsible == true
					local open = (not collapsible) or (cfg.DefaultOpen == true)
					local rawHeader = cfg.Header or ""
					local box = new("Frame", {
						BackgroundTransparency = 1,
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.new(1, 0, 0, 0),
						Parent = card,
					}, { list(nil, 5) })
					local hdrProps = {
						BackgroundTransparency = 1,
						FontFace = getFont(W.semi),
						Text = rawHeader,
						TextColor3 = C.ink2,
						TextSize = 12,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.new(1, 0, 0, 14),
						Parent = box,
					}
					if collapsible then hdrProps.AutoButtonColor = false end
					local hdr = new(collapsible and "TextButton" or "TextLabel", hdrProps)
					local bdy = new("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = getFont(W.reg),
						RichText = cfg.BodyRichText == true,
						Text = cfg.Body or "",
						TextColor3 = C.dim,
						TextSize = 11,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutomaticSize = Enum.AutomaticSize.Y,
						LayoutOrder = 1,
						Size = UDim2.new(1, 0, 0, 12),
						Parent = box,
					})
					local function refresh()
						hdr.Text = (collapsible and (open and "- " or "+ ") or "") .. rawHeader
						if collapsible then bdy.Visible = open end
					end
					if collapsible then
						hdr.MouseButton1Click:Connect(function() open = not open; refresh() end)
					end
					refresh()
					function P:UpdateHeader(n) rawHeader = n; refresh() end
					function P:UpdateBody(n) bdy.Text = n end
					function P:SetVisibility(s) box.Visible = s end
					function P:SetOpen(s) if collapsible then open = s; refresh() end end
					if Flag then SENZYHUB.Options[Flag] = P end
					return P
				end
				function Section:Divider()
					local Dv = {}
					local d = new("Frame", {
						BackgroundColor3 = C.line,
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 0, 1),
						Parent = card,
					})
					function Dv:Remove() d:Destroy() end
					function Dv:SetVisibility(s) d.Visible = s end
					return Dv
				end
				function Section:Spacer(px)
					local Sp = {}
					local s = new("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, px or 4),
						Parent = card,
					})
					function Sp:Remove() s:Destroy() end
					function Sp:SetVisibility(v) s.Visible = v end
					return Sp
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
			switcher.MouseEnter:Connect(function()
				if switcher.BackgroundTransparency > 0 then
					tween(swName, T, { TextColor3 = C.ink2 }):Play()
				end
			end)
			switcher.MouseLeave:Connect(function()
				if switcher.BackgroundTransparency > 0 then
					tween(swName, T, { TextColor3 = C.label }):Play()
				end
			end)

			tabs[switcher] = { content = tabContent, stroke = swStroke, icon = swIcon, name = swName }
			function Tab:Select() selectThis() end

			--// Config section -------------------------------------
			function Tab:InsertConfigSection(side)
				local cs = Tab:Section({ Name = "Configuration", Side = side or "Left" })
				if isStudio then
					cs:Label({ Text = "Config system unavailable (isStudio)." })
					return
				end
				local inputPath
				cs:Input({
					Name = "Config Name", Placeholder = "name", AcceptedCharacters = "All",
					Callback = function(v) inputPath = v end,
				})
				local sel = cs:Dropdown({
					Name = "Select Config", Multi = false, Required = false,
					Options = SENZYHUB:RefreshConfigList(),
					Callback = function() end,
				})
				cs:Button({ Name = "Create", Callback = function()
					if not inputPath or inputPath:gsub(" ", "") == "" then
						Window:Notify({ Title = "Config", Description = "Name cannot be empty." }); return
					end
					local ok, err = SENZYHUB:SaveConfig(inputPath)
					Window:Notify({ Title = "Config", Description = ok and ("Created " .. inputPath) or tostring(err) })
					sel:ClearOptions(); sel:InsertOptions(SENZYHUB:RefreshConfigList())
				end })
				cs:Button({ Name = "Load", Callback = function()
					local ok, err = SENZYHUB:LoadConfig(sel.Value)
					Window:Notify({ Title = "Config", Description = ok and ("Loaded " .. tostring(sel.Value)) or tostring(err) })
				end })
				cs:Button({ Name = "Overwrite", Callback = function()
					local ok, err = SENZYHUB:SaveConfig(sel.Value)
					Window:Notify({ Title = "Config", Description = ok and ("Overwrote " .. tostring(sel.Value)) or tostring(err) })
				end })
				cs:Button({ Name = "Refresh List", Callback = function()
					sel:ClearOptions(); sel:InsertOptions(SENZYHUB:RefreshConfigList())
				end })
				local autoLbl
				cs:Button({ Name = "Set Autoload", Callback = function()
					if not sel.Value then return end
					writefile(SENZYHUB.Folder .. "/settings/autoload.txt", sel.Value)
					autoLbl:UpdateName("Autoload: " .. sel.Value)
					Window:Notify({ Title = "Config", Description = "Autoload set to " .. sel.Value })
				end })
				autoLbl = cs:Label({ Text = "Autoload: None" })
				if isfile and isfile(SENZYHUB.Folder .. "/settings/autoload.txt") then
					autoLbl:UpdateName("Autoload: " .. readfile(SENZYHUB.Folder .. "/settings/autoload.txt"))
				end
			end

			return Tab
		end

		return Group
	end

	--  NOTIFY
	function Window:Notify(cfg)
		cfg = cfg or {}
		local N = {}
		local card = new("Frame", {
			Name = "Notification",
			BackgroundColor3 = C.panel,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromOffset(cfg.SizeX or 260, 0),
			Parent = notifications,
		}, {
			corner(8), stroke(C.line2, 1, 0),
			pad(12, 14, 12, 14), list(nil, 4),
		})
		local scale = new("UIScale", { Scale = 0, Parent = card })

		new("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = getFont(W.semi),
			Text = cfg.Title or "SENZY HUB",
			TextColor3 = C.ink,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 14),
			Parent = card,
		})
		new("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = getFont(W.reg),
			Text = cfg.Description or "",
			TextColor3 = C.dim,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 12),
			Parent = card,
		})

		local alive = true
		local function dismiss()
			if not alive then return end
			alive = false
			local tw = tween(scale, TQ, { Scale = 0 })
			tw:Play(); tw.Completed:Wait()
			card:Destroy()
		end

		tween(scale, TQ, { Scale = 1 }):Play()
		task.spawn(function()
			local life = cfg.Lifetime or 3
			if life > 0 then
				task.wait(life)
				dismiss()
			end
		end)

		function N:Cancel() dismiss() end
		function N:UpdateTitle(t) card.TextLabel.Text = t end
		return N
	end

	--  DIALOG
	function Window:Dialog(cfg)
		cfg = cfg or {}
		local Dg = {}
		local canvas = new("CanvasGroup", {
			Name = "Dialog",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			GroupTransparency = 1,
			ZIndex = 50,
			Parent = base,
		}, { corner(8) })
		new("Frame", {
			BackgroundColor3 = C.scrim,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Parent = canvas,
		}, { corner(8) })
		local pnl = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(300, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = C.panel,
			BorderSizePixel = 0,
			ZIndex = 51,
			Parent = canvas,
		}, {
			corner(8), stroke(C.line2, 1, 0),
			pad(18, 18, 18, 18), list(nil, 10),
		})

		new("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = getFont(W.bold),
			Text = cfg.Title or "SENZY HUB",
			TextColor3 = C.ink,
			TextSize = 15,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 18),
			ZIndex = 51,
			Parent = pnl,
		})
		new("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = getFont(W.reg),
			Text = cfg.Description or "",
			TextColor3 = C.dim,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 14),
			ZIndex = 51,
			Parent = pnl,
		})
		local btnHost = new("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			ZIndex = 51,
			Parent = pnl,
		}, { list(nil, 8) })

		local DINFO = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local closing = false
		local function close()
			if closing then return end
			closing = true
			local tw = tween(canvas, DINFO, { GroupTransparency = 1 })
			tw:Play(); tw.Completed:Wait()
			canvas:Destroy()
		end

		for i, b in ipairs(cfg.Buttons or {}) do
			local btn = new("TextButton", {
				BackgroundColor3 = C.raise,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				FontFace = getFont(W.semi),
				Text = b.Name,
				TextColor3 = C.ink2,
				TextSize = 12,
				LayoutOrder = i,
				Size = UDim2.new(1, 0, 0, 34),
				ZIndex = 51,
				Parent = btnHost,
			}, { corner(6), stroke(C.line, 1, 0) })
			btn.MouseEnter:Connect(function()
				tween(btn, T, { BackgroundColor3 = C.hover, TextColor3 = C.ink }):Play()
			end)
			btn.MouseLeave:Connect(function()
				tween(btn, T, { BackgroundColor3 = C.raise, TextColor3 = C.ink2 }):Play()
			end)
			btn.MouseButton1Click:Connect(function()
				if b.Callback then task.spawn(b.Callback) end
				close()
			end)
		end

		task.wait()
		canvas.GroupTransparency = 1
		tween(canvas, DINFO, { GroupTransparency = 0 }):Play()

		function Dg:Cancel() close() end
		return Dg
	end

	--  WINDOW STATE / CONTROLS & FUNCTIONAL BUTTONS
	function Window:UpdateTitle(t) titleLabel.Text = track(t) end
	function Window:UpdateSubtitle(t) subtitleLabel.Text = t end
	function Window:SetState(s) windowState = s; base.Visible = s end
	function Window:GetState() return windowState end
	function Window:SetSize(sz) base.Size = sz end
	function Window:GetSize() return base.Size end
	function Window:SetScale(s) userScale = s or 1; applyScale() end
	function Window:GetScale() return userScale end
	function Window:SetNotificationsState(s) notifications.Visible = s end
	function Window:GetNotificationsState() return notifications.Visible end

	local onUnload
	function Window:Unload()
		if onUnload then pcall(onUnload) end
		unloaded = true
		gui:Destroy()
	end
	function Window.onUnloaded(cb) onUnload = cb end

	-- Restore Button when minimized (ทำให้ใช้งานได้จริง)
	local restoreBtn = new("TextButton", {
		Name = "Restore",
		BackgroundColor3 = C.panel,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Text = "OPEN",
		FontFace = getFont(W.bold),
		TextColor3 = C.ink,
		TextSize = 10,
		Position = UDim2.fromOffset(24, 24),
		Size = UDim2.fromOffset(50, 30),
		Visible = false,
		ZIndex = 25,
		Parent = gui,
	}, { corner(6), stroke(C.line2, 1, 0) })

	restoreBtn.MouseEnter:Connect(function()
		tween(restoreBtn, T, { BackgroundColor3 = C.raise }):Play()
	end)
	restoreBtn.MouseLeave:Connect(function()
		tween(restoreBtn, T, { BackgroundColor3 = C.panel }):Play()
	end)

	local function setMinimized(min)
		windowState = not min
		base.Visible = not min
		restoreBtn.Visible = min
	end

	minimize.MouseButton1Click:Connect(function()
		setMinimized(true)
	end)

	restoreBtn.MouseButton1Click:Connect(function()
		setMinimized(false)
	end)

	exit.MouseButton1Click:Connect(function()
		Window:Dialog({
			Title = Settings.Title or "SENZY HUB",
			Description = "Close the menu? Unsaved configuration will be lost.",
			Buttons = {
				{ Name = "Confirm", Callback = function() Window:Unload() end },
				{ Name = "Cancel" },
			},
		})
	end)

	--  CONFIG SYSTEM
	local ClassParser = {
		Toggle = {
			Save = function(f, d) return { type = "Toggle", flag = f, state = d.State or false } end,
			Load = function(f, d) if SENZYHUB.Options[f] and d.state ~= nil then SENZYHUB.Options[f]:UpdateState(d.state) end end,
		},
		Slider = {
			Save = function(f, d) return { type = "Slider", flag = f, value = d.Value and tostring(d.Value) or false } end,
			Load = function(f, d) if SENZYHUB.Options[f] and d.value then SENZYHUB.Options[f]:UpdateValue(d.value) end end,
		},
		Input = {
			Save = function(f, d) return { type = "Input", flag = f, text = d.Text } end,
			Load = function(f, d) if SENZYHUB.Options[f] and type(d.text) == "string" then SENZYHUB.Options[f]:UpdateText(d.text) end end,
		},
		Keybind = {
			Save = function(f, d) return { type = "Keybind", flag = f, bind = typeof(d.Bind) == "EnumItem" and d.Bind.Name or nil } end,
			Load = function(f, d) if SENZYHUB.Options[f] and d.bind then SENZYHUB.Options[f]:Bind(Enum.KeyCode[d.bind]) end end,
		},
		Dropdown = {
			Save = function(f, d) return { type = "Dropdown", flag = f, value = d.Value } end,
			Load = function(f, d) if SENZYHUB.Options[f] and d.value then SENZYHUB.Options[f]:UpdateSelection(d.value) end end,
		},
		Colorpicker = {
			Save = function(f, d)
				local c = d.Color
				return {
					type = "Colorpicker", flag = f,
					color = string.format("#%02X%02X%02X",
						math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)),
					alpha = d.Alpha,
				}
			end,
			Load = function(f, d)
				if SENZYHUB.Options[f] and d.color then
					local h = d.color:gsub("#", "")
					SENZYHUB.Options[f]:SetColor(Color3.fromRGB(
						tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)))
					if d.alpha then SENZYHUB.Options[f]:SetAlpha(d.alpha) end
				end
			end,
		},
	}

	local function buildTree()
		if isStudio or not (isfolder and makefolder) then return end
		for _, p in ipairs({ SENZYHUB.Folder, SENZYHUB.Folder .. "/settings" }) do
			if not isfolder(p) then makefolder(p) end
		end
	end

	function SENZYHUB:SetFolder(folder)
		if isStudio then return "Config system unavailable." end
		SENZYHUB.Folder = folder
		buildTree()
	end

	function SENZYHUB:SaveConfig(path)
		if isStudio or not writefile then return false, "Config unavailable." end
		if not path then return false, "Please select a config file." end
		local data = { objects = {} }
		for flag, opt in pairs(SENZYHUB.Options) do
			if ClassParser[opt.Class] and not opt.IgnoreConfig then
				table.insert(data.objects, ClassParser[opt.Class].Save(flag, opt))
			end
		end
		local ok, enc = pcall(HttpService.JSONEncode, HttpService, data)
		if not ok then return false, "JSON encode failed." end
		writefile(SENZYHUB.Folder .. "/settings/" .. path .. ".json", enc)
		return true
	end

	function SENZYHUB:LoadConfig(path)
		if isStudio or not (isfile and readfile) then return false, "Config unavailable." end
		if not path then return false, "Please select a config file." end
		local file = SENZYHUB.Folder .. "/settings/" .. path .. ".json"
		if not isfile(file) then return false, "Invalid file." end
		local ok, dec = pcall(HttpService.JSONDecode, HttpService, readfile(file))
		if not ok then return false, "JSON decode failed." end
		for _, opt in ipairs(dec.objects) do
			if ClassParser[opt.type] then
				task.spawn(ClassParser[opt.type].Load, opt.flag, opt)
			end
		end
		return true
	end

	function SENZYHUB:RefreshConfigList()
		if isStudio or not (isfolder and listfiles) then return {} end
		if not (isfolder(SENZYHUB.Folder) and isfolder(SENZYHUB.Folder .. "/settings")) then return {} end
		local out = {}
		for _, file in ipairs(listfiles(SENZYHUB.Folder .. "/settings")) do
			if file:sub(-5) == ".json" then
				local name = file:match("([^/\\]+)%.json$")
				if name and name ~= "options" then table.insert(out, name) end
			end
		end
		return out
	end

	function SENZYHUB:LoadAutoLoadConfig()
		if isStudio or not (isfile and readfile) then return end
		local f = SENZYHUB.Folder .. "/settings/autoload.txt"
		if isfile(f) then
			local name = readfile(f)
			local ok, err = SENZYHUB:LoadConfig(name)
			Window:Notify({
				Title = "Config",
				Description = ok and ("Autoloaded " .. name) or ("Autoload error: " .. tostring(err)),
			})
		end
	end

	buildTree()

	pcall(function()
		local preload = { globeBtn, "rbxassetid://2849458409", "rbxassetid://73265255323268" }
		ContentProvider:PreloadAsync(preload)
	end)

	return Window
end


--  DEMO
function SENZYHUB:Demo()
	local Window = SENZYHUB:Window({
		Title = "SENZY HUB",
		Subtitle = "ultimate ui demo",
		Size = UDim2.fromOffset(780, 530),
		ShowUserInfo = true,
		Keybind = Enum.KeyCode.RightControl,
	})

	Window:GlobalSetting({
		Name = "Notifications",
		Default = Window:GetNotificationsState(),
		Callback = function(b) Window:SetNotificationsState(b) end,
	})

	local group = Window:TabGroup()
	local main = group:Tab({ Name = "Demo", Image = "rbxassetid://18821914323" })
	local settings = group:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" })

	local sec = main:Section({ Name = "Controls", Side = "Left" })

	sec:Button({
		Name = "Open Dialog",
		Callback = function()
			Window:Dialog({
				Title = "SENZY HUB",
				Description = "This is a confirmation dialog.",
				Buttons = {
					{ Name = "Confirm", Callback = function() print("confirmed") end },
					{ Name = "Cancel" },
				},
			})
		end,
	})

	sec:Toggle({
		Name = "Example Toggle",
		Default = false,
		Callback = function(v)
			Window:Notify({ Title = "Toggle", Description = (v and "Enabled" or "Disabled") .. " example." })
		end,
	}, "ExampleToggle")

	sec:Slider({
		Name = "Slider",
		Default = 50, Minimum = 0, Maximum = 100,
		DisplayMethod = "Percent", Precision = 0,
		Callback = function(v) print("slider", v) end,
	}, "ExampleSlider")

	sec:Input({
		Name = "Input",
		Placeholder = "type here",
		AcceptedCharacters = "All",
		Callback = function(t) print("input", t) end,
	}, "ExampleInput")

	sec:Keybind({
		Name = "Keybind",
		Callback = function(k) print("pressed", k.Name) end,
		onBinded = function(k) print("bound", k.Name) end,
	}, "ExampleKeybind")

	local sec2 = main:Section({ Name = "Selection", Side = "Right" })
	sec2:Dropdown({
		Name = "Fruit",
		Multi = false, Required = true,
		Options = { "Apple", "Banana", "Orange", "Grape", "Mango" },
		Default = 1,
		Callback = function(v) print("dropdown", v) end,
	}, "ExampleDropdown")

	local sec3 = main:Section({ Name = "Info", Side = "Right" })
	sec3:Header({ Text = "Section Header" })
	sec3:Paragraph({
		Header = "Paragraph",
		Body = "SENZY HUB keeps the clean modern look: flat dark grey, Montserrat type, and functional controls.",
	})
	sec3:Divider()

	SENZYHUB:SetFolder("SENZYHUB")
	settings:InsertConfigSection("Left")

	main:Select()
	SENZYHUB:LoadAutoLoadConfig()
end

return SENZYHUB
