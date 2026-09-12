--[[
    SenzyHub Key System Library (SUI / Symbios Style)
    Usage:
    local KeyLib = loadstring(game:HttpGet("ลิงก์ไฟล์นี้"))()
    KeyLib:Init({
        HubName = "SenzyHub",
        KeyLink = "https://skeyaccess.vercel.app",
        SupabaseUrl = "https://PROJECT_ID.supabase.co",
        SupabaseKey = "SUPABASE_ANON_KEY_ของมึง",
        SuccessCallback = function()
            -- โค้ดที่จะรันต่อเมื่อผ่าน (เช่น โหลดสคริปต์หลัก)
            print("Key verified! Loading main script...")
            loadstring(game:HttpGet("ลิงก์สคริปต์หลักของมึง"))()
        end
    })
]]

local KeyLib = {}
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

function KeyLib:Init(config)
    config = config or {}
    local hubName = config.HubName or "SenzyHub"
    local keyLink = config.KeyLink or "https://skeyaccess.vercel.app"
    local supabaseUrl = config.SupabaseUrl or ""
    local supabaseKey = config.SupabaseKey or ""
    local successCallback = config.SuccessCallback or function() end

    -- ลบอันเก่าทิ้งถ้ามี
    if game.CoreGui:FindFirstChild("SenzyHub_KeySystem") then
        game.CoreGui.SenzyHub_KeySystem:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SenzyHub_KeySystem"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Container
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 400, 0, 240)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -120)
    MainFrame.BackgroundColor3 = Color3.fromRGB(11, 15, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 16)
    UICorner.Parent = MainFrame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(236, 72, 153)
    UIStroke.Thickness = 1.5
    UIStroke.Parent = MainFrame

    -- Header / Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 45)
    Title.Position = UDim2.new(0, 0, 0, 15)
    Title.BackgroundTransparency = 1
    Title.Text = hubName .. " — Key System"
    Title.TextColor3 = Color3.fromRGB(244, 114, 182)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.Parent = MainFrame

    -- Subtitle / Info
    local SubTitle = Instance.new("TextLabel")
    SubTitle.Size = UDim2.new(1, 0, 0, 20)
    SubTitle.Position = UDim2.new(0, 0, 0, 40)
    SubTitle.BackgroundTransparency = 1
    SubTitle.Text = "Please enter your key to continue"
    SubTitle.TextColor3 = Color3.fromRGB(156, 163, 175)
    SubTitle.TextSize = 12
    SubTitle.Font = Enum.Font.Gotham
    SubTitle.Parent = MainFrame

    -- TextBox (Input Key)
    local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(0, 340, 0, 45)
    TextBox.Position = UDim2.new(0.5, -170, 0, 80)
    TextBox.BackgroundColor3 = Color3.fromRGB(17, 24, 39)
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.PlaceholderText = "Enter your key (SKEYX...)"
    TextBox.PlaceholderColor3 = Color3.fromRGB(75, 85, 99)
    TextBox.TextSize = 13
    TextBox.Font = Enum.Font.Gotham
    TextBox.ClearTextOnFocus = false
    TextBox.Parent = MainFrame

    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 12)
    BoxCorner.Parent = TextBox

    local BoxStroke = Instance.new("UIStroke")
    BoxStroke.Color = Color3.fromRGB(31, 41, 55)
    BoxStroke.Thickness = 1
    BoxStroke.Parent = TextBox

    -- Verify Button
    local VerifyBtn = Instance.new("TextButton")
    VerifyBtn.Size = UDim2.new(0, 162, 0, 42)
    VerifyBtn.Position = UDim2.new(0.5, -170, 0, 145)
    VerifyBtn.BackgroundColor3 = Color3.fromRGB(219, 39, 119)
    VerifyBtn.Text = "Verify Key"
    VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    VerifyBtn.TextSize = 13
    VerifyBtn.Font = Enum.Font.GothamBold
    VerifyBtn.Parent = MainFrame

    local BtnCorner1 = Instance.new("UICorner")
    BtnCorner1.CornerRadius = UDim.new(0, 12)
    BtnCorner1.Parent = VerifyBtn

    -- Get Key Button
    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(0, 162, 0, 42)
    GetKeyBtn.Position = UDim2.new(0.5, 8, 0, 145)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(31, 41, 55)
    GetKeyBtn.Text = "Get Key Link"
    GetKeyBtn.TextColor3 = Color3.fromRGB(209, 213, 219)
    GetKeyBtn.TextSize = 13
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.Parent = MainFrame

    local BtnCorner2 = Instance.new("UICorner")
    BtnCorner2.CornerRadius = UDim.new(0, 12)
    BtnCorner2.Parent = GetKeyBtn

    -- ฟังก์ชัน Copy Link
    GetKeyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(keyLink)
            GetKeyBtn.Text = "Copied Link!"
            task.wait(1.5)
            GetKeyBtn.Text = "Get Key Link"
        end
    end)

    -- ฟังก์ชันเช็คคีย์กับ Supabase
    VerifyBtn.MouseButton1Click:Connect(function()
        local inputKey = TextBox.Text:gsub("^%s+", ""):gsub("%s+$", "") -- Trim spaces
        
        if inputKey == "" then
            VerifyBtn.Text = "Enter a key first!"
            task.wait(1.5)
            VerifyBtn.Text = "Verify Key"
            return
        end

        VerifyBtn.Text = "Checking..."

        local success, response = pcall(function()
            return HttpService:RequestAsync({
                Url = supabaseUrl .. "/rest/v1/keys?key_string=eq." .. inputKey .. "&select=*",
                Method = "GET",
                Headers = {
                    ["apikey"] = supabaseKey,
                    ["Authorization"] = "Bearer " .. supabaseKey
                }
            })
        end)

        if success and response.Success then
            local data = HttpService:JSONDecode(response.Body)
            if #data > 0 then
                local keyData = data[1]
                
                -- เช็ควันหมดอายุ
                if keyData.expires_at then
                    -- แปลงเวลา ISO string เป็น timestamp (หรือข้ามถ้าใช้ตัวจัดการเวลาฝั่งเว็บเรียบร้อยแล้ว)
                end

                VerifyBtn.Text = "Success!"
                task.wait(0.5)
                ScreenGui:Destroy()
                successCallback()
            else
                VerifyBtn.Text = "Invalid Key!"
                task.wait(1.5)
                VerifyBtn.Text = "Verify Key"
            end
        else
            VerifyBtn.Text = "Connection Error!"
            task.wait(1.5)
            VerifyBtn.Text = "Verify Key"
        end
    end)
end

return KeyLib
