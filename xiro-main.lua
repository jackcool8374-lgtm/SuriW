--!nocheck
-- OXIRO — UNSTOPPABLE TRACKING CHASE + VOID + HUNT + JERK
-- Delta / Mobile Compatible
local MAX_ATTEMPTS = 3
local CORRECT_KEY = "hello"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local attempts = 0
local AIMBOT_ENABLED = false
local AIMBOT_STRENGTH = 0.95
local AIMBOT_SMOOTH = 0.08
local immunePlayers = {}

-- HUNT STATE
local huntingTarget = nil
local isHunting = false

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 3
        })
    end)
end

--========================================================--
-- IMMUNE HOOK FUNCTIONS
--========================================================--
local function getHRP(plr)
    local p = plr or Player
    return p.Character and p.Character:FindFirstChild("HumanoidRootPart")
end

local function isProtected(targetPlayer)
    if not targetPlayer then return false end
    if type(targetPlayer) == "string" then
        for p, safe in pairs(immunePlayers) do
            if safe and (p.Name == targetPlayer or p.DisplayName == targetPlayer) then return true end
        end
    elseif typeof(targetPlayer) == "Instance" then
        if targetPlayer:IsA("Player") then return immunePlayers[targetPlayer] == true
        elseif targetPlayer:IsA("Model") then
            local p = Players:GetPlayerFromCharacter(targetPlayer)
            return p and immunePlayers[p] == true
        end
    end
    return false
end

pcall(function()
    local gmt = getrawmetatable(game)
    local oldNamecall = gmt.__namecall
    setreadonly(gmt, false)
    gmt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            for p, isSafe in pairs(immunePlayers) do
                if isSafe and p and p.Character then
                    for _, arg in pairs(args) do
                        if arg == p or arg == p.Character or (type(arg) == "table" and rawget(arg, "Instance") == p) then
                            return nil
                        end
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(gmt, true)
end)

local function isPlayerSafe(plr) return isProtected(plr) end

-- KEY UI (Redesigned)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OXIROGATE"
ScreenGui.Parent = Player:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -120)
MainFrame.Size = UDim2.new(0, 350, 0, 240)
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local OuterStroke = Instance.new("UIStroke")
OuterStroke.Parent = MainFrame
OuterStroke.Color = Color3.fromRGB(60, 180, 255)
OuterStroke.Thickness = 2
OuterStroke.Transparency = 0.5

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 0, 0, 20)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Font = Enum.Font.GothamBold
Title.Text = "OXIRO SECURITY"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 24

local SubTitle = Instance.new("TextLabel")
SubTitle.Parent = MainFrame
SubTitle.BackgroundTransparency = 1
SubTitle.Position = UDim2.new(0, 0, 0, 55)
SubTitle.Size = UDim2.new(1, 0, 0, 20)
SubTitle.Font = Enum.Font.GothamMedium
SubTitle.Text = "ENTER ACCESS KEY"
SubTitle.TextColor3 = Color3.fromRGB(150, 150, 160)
SubTitle.TextSize = 12

local KeyBox = Instance.new("TextBox")
KeyBox.Parent = MainFrame
KeyBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
KeyBox.Position = UDim2.new(0.1, 0, 0, 90)
KeyBox.Size = UDim2.new(0.8, 0, 0, 40)
KeyBox.Font = Enum.Font.Gotham
KeyBox.PlaceholderText = "Key..."
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.TextSize = 14
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 8)

local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Parent = MainFrame
SubmitBtn.BackgroundColor3 = Color3.fromRGB(40, 130, 220)
SubmitBtn.Position = UDim2.new(0.25, 0, 0, 145)
SubmitBtn.Size = UDim2.new(0.5, 0, 0, 35)
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.Text = "VERIFY"
SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitBtn.TextSize = 14
Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 8)

local Status = Instance.new("TextLabel")
Status.Parent = MainFrame
Status.BackgroundTransparency = 1
Status.Position = UDim2.new(0, 0, 0, 195)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Font = Enum.Font.GothamMedium
Status.Text = ""
Status.TextColor3 = Color3.fromRGB(255, 80, 80)
Status.TextSize = 12

local function runMainScript()
	ScreenGui:Destroy()

	local OWNER_USERNAME = "Markarenoob"
	local isOwner = Player.Name == OWNER_USERNAME
	local permanentControllers = {}
	local tempControllers = {}

	local function isAuthorized(plr)
		if not plr then return false end
		if plr.Name == OWNER_USERNAME then return true end
		if permanentControllers[plr.UserId] then return true end
		if tempControllers[plr.UserId] then return true end
		return false
	end

	local HVH_MODE = false
	local HVH_TARGET_USERID = nil
	local HVH_VOID = false
	local HVH_NOCLIP = false

	local function findPlayerByFuzzy(str)
		if not str or str == "" then return nil end
		str = str:lower()
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.DisplayName:lower():find(str) or plr.Name:lower():find(str) then return plr end
		end
		return nil
	end

	local mode = "idle"
	local attackTarget = nil
	local savedTargetUserId = nil
	local HITBOX_SIZE = 100
	local UNLIMITED_M1_ENABLED = true
	local M2_SPAM_ENABLED = true
	local NOCLIP_ENABLED = false
	local AUTO_EQUIP_ENABLED = false
	local INF_BLOCK_ENABLED = false
	local playerButtons = {}
	local weaponButtons = {}
	local currentTab = "target"
	local isVoiding = false
	local noclipConnection = nil
	local blockConnection = nil
	local jerkConnection = nil
	local isJerking = false

	-- === JERK SYSTEM ===
	local function startJerk(target)
		if jerkConnection then jerkConnection:Disconnect() end
		isJerking = true
		notify("Troll", "Jerking " .. target.Name)
		jerkConnection = RunService.Heartbeat:Connect(function()
			if not isJerking or not target or not target.Character then
				if jerkConnection then jerkConnection:Disconnect() end
				return
			end
			local tHRP = getHRP(target)
			if tHRP then
				local bv = Instance.new("BodyVelocity")
				bv.Velocity = Vector3.new(math.random(-100, 100), 50, math.random(-100, 100))
				bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				bv.Parent = tHRP
				task.delay(0.1, function() if bv then bv:Destroy() end end)

				local bg = Instance.new("BodyAngularVelocity")
				bg.AngularVelocity = Vector3.new(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50))
				bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
				bg.Parent = tHRP
				task.delay(0.1, function() if bg then bg:Destroy() end end)
			end
		end)
	end

	local function stopJerk()
		isJerking = false
		if jerkConnection then jerkConnection:Disconnect() end
	end

	-- === UNSTOPPABLE TRACKING CHASE ===
	local CHASE_DISTANCE = 3.5 
	local PREDICTION = 0.2     
	local chaseTarget = nil
	local chaseConnection = nil
	local isChasing = false

	local function stopChase()
	    isChasing = false
	    chaseTarget = nil
	    if chaseConnection then
	        chaseConnection:Disconnect()
	        chaseConnection = nil
	    end
	    if Player.Character then
	        for _, v in ipairs(Player.Character:GetDescendants()) do
	            if v:IsA("BasePart") then v.CanCollide = true end
	        end
	    end
	end

	local function startChase(target)
	    if chaseConnection then chaseConnection:Disconnect() end
	    chaseTarget = target
	    isChasing = true

	    chaseConnection = RunService.RenderStepped:Connect(function()
	        if isVoiding then return end
	        if not isChasing or not chaseTarget or not chaseTarget.Character then stopChase() return end

	        local myHRP = getHRP(Player)
	        local tHRP = getHRP(chaseTarget)
	        if not myHRP or not tHRP then stopChase() return end

	        for _, v in ipairs(Player.Character:GetDescendants()) do
	            if v:IsA("BasePart") then v.CanCollide = false end
	        end

	        local targetVelocity = tHRP.Velocity
	        local predictedPos = tHRP.Position + (targetVelocity * PREDICTION)
	        local targetLook = tHRP.CFrame.LookVector
	        local desiredPos = predictedPos - (targetLook * CHASE_DISTANCE) + Vector3.new(0, 1, 0)
	        local distance = (desiredPos - myHRP.Position).Magnitude

	        if distance > 1 then
	            myHRP.CFrame = CFrame.new(desiredPos, tHRP.Position)
	            myHRP.Velocity = Vector3.zero
	            myHRP.RotVelocity = Vector3.zero
	        else
	            myHRP.Velocity = targetVelocity
	        end
	    end)
	end

	-- === VOID SYSTEM (Instant Resume) ===
	local VOID_MODE_ENABLED = false
	local FALL_SPEED = -3500
	local FALL_CHECK_Y = -4900
	local ATTACK_RESET_INTERVAL = 4

	local function goVoid(target)
	    if isVoiding or not VOID_MODE_ENABLED or isPlayerSafe(target) then return end
	    if not target or not target.Character then return end

	    local myChar = Player.Character
	    if not myChar then return end
	    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
	    if not myHRP then return end
	    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
	    if not tHRP then return end

	    isVoiding = true
	    myHRP.CFrame = CFrame.new(tHRP.Position.X, myHRP.Position.Y, tHRP.Position.Z)

	    task.spawn(function()
	        for i = 1, 8 do
	            task.wait(0.015)
	            if not myHRP or not isVoiding then break end
	            myHRP.Velocity = Vector3.new(0, FALL_SPEED, 0)
	        end
	    end)

	    -- 0.1s delay for instant resume
	    task.delay(0.1, function() 
            isVoiding = false 
            if attackTarget and not isPlayerSafe(attackTarget) then
                startChase(attackTarget)
            end
        end)
	end

	task.spawn(function()
	    while true do
	        task.wait(0.03)
	        if not VOID_MODE_ENABLED or mode ~= "attack" or not attackTarget or isPlayerSafe(attackTarget) then continue end
	        local c = Player.Character
	        if not c then continue end
	        local hrp = c:FindFirstChild("HumanoidRootPart")
	        if hrp and hrp.Position.Y < FALL_CHECK_Y then
	            local hum = c:FindFirstChildOfClass("Humanoid")
	            if hum then hum.Health = 0 end
	        end
	    end
	end)

	task.spawn(function()
	    while true do
	        task.wait(ATTACK_RESET_INTERVAL)
	        if VOID_MODE_ENABLED and mode == "attack" and attackTarget and not isPlayerSafe(attackTarget) then
	            goVoid(attackTarget)
	        end
	    end
	end)

	local function setNoclip(enabled)
		NOCLIP_ENABLED = enabled
		if noclipConnection then noclipConnection:Disconnect() end
		if enabled then
			noclipConnection = RunService.Stepped:Connect(function()
				local c = Player.Character if not c then return end
				for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
			end)
		end
	end

	-- === GOD-MODE INFINITE BLOCK ===
	local function setInfBlock(enabled)
		INF_BLOCK_ENABLED = enabled
		if blockConnection then blockConnection:Disconnect() end
		
		if enabled then
			blockConnection = RunService.Stepped:Connect(function()
				if not INF_BLOCK_ENABLED then return end
				local char = Player.Character
				if not char then return end
				
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					if hum:GetState() == Enum.HumanoidStateType.Stunned or hum:GetState() == Enum.HumanoidStateType.FallingDown then
						hum:ChangeState(Enum.HumanoidStateType.Running)
					end
					hum:SetStateEnabled(Enum.HumanoidStateType.Blocking, true)
					hum:ChangeState(Enum.HumanoidStateType.Blocking)
				end
				
				pcall(function()
					local combatRem = ReplicatedStorage:FindFirstChild("CombatRemote")
					if combatRem then
						combatRem:FireServer("Block")
					end
					
					for _, rem in ipairs(ReplicatedStorage:GetDescendants()) do
						if rem:IsA("RemoteEvent") then
							local name = rem.Name:lower()
							if name:find("block") or name:find("guard") or name:find("shield") or name:find("def") then
								rem:FireServer(true)
							end
						end
					end
					
					local backpack = Player:FindFirstChild("Backpack")
					if backpack and hum then
						for _, tool in ipairs(backpack:GetChildren()) do
							if tool:IsA("Tool") and (tool.Name:lower():find("block") or tool.Name:lower():find("shield")) then
								hum:EquipTool(tool)
							end
						end
					end
				end)
			end)
		end
	end

	-- === WEAPON SYSTEM ===
	function refreshWeaponList()
		for _, b in ipairs(weaponButtons) do b:Destroy() end
		table.clear(weaponButtons)

		local backpack = Player:FindFirstChild("Backpack")
		local char = Player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if backpack then
			for _, tool in ipairs(backpack:GetChildren()) do
				if tool:IsA("Tool") then
					local btn = Instance.new("TextButton")
					btn.Size = UDim2.new(1,0,0,36)
					btn.BackgroundColor3 = Color3.fromRGB(30,30,40)
					btn.Font = Enum.Font.Gotham
					btn.Text = "[BAG] "..tool.Name
					btn.TextColor3 = Color3.fromRGB(200,200,220)
					btn.TextSize = 12; btn.Parent = WeaponScroll
					Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
					btn.MouseButton1Click:Connect(function() 
						if hum then 
							pcall(function() hum:EquipTool(tool) end) 
						end
					end)
					table.insert(weaponButtons, btn)
				end
			end
		end

		if char then
			for _, tool in ipairs(char:GetChildren()) do
				if tool:IsA("Tool") then
					local btn = Instance.new("TextButton")
					btn.Size = UDim2.new(1,0,0,36)
					btn.BackgroundColor3 = Color3.fromRGB(20,50,40)
					btn.Font = Enum.Font.Gotham
					btn.Text = "[EQUIPPED] "..tool.Name
					btn.TextColor3 = Color3.fromRGB(120,255,170)
					btn.TextSize = 12; btn.Parent = WeaponScroll
					Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
					table.insert(weaponButtons, btn)
				end
			end
		end
	end

	local function autoEquip()
		local backpack = Player:FindFirstChild("Backpack")
		local char = Player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not backpack or not char or not hum then return end
		
		if char:FindFirstChildOfClass("Tool") then return end
		
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then 
				pcall(function() hum:EquipTool(tool) end)
				break 
			end
		end
	end

	task.spawn(function()
		while true do
			task.wait(0.5)
			if AUTO_EQUIP_ENABLED then autoEquip() end
		end
	end)

	-- Combat Spam
	task.spawn(function()
		while true do
			task.wait()
			if UNLIMITED_M1_ENABLED then
				pcall(function()
					local rem = ReplicatedStorage:FindFirstChild("CombatRemote")
					if rem then rem:FireServer("M1") end
				end)
			end
		end
	end)

	task.spawn(function()
	    while task.wait() do
	        if M2_SPAM_ENABLED then
	            pcall(function()
	                local Remote = ReplicatedStorage:FindFirstChild("CombatRemote")
	                if Remote then Remote:FireServer("M2") end
	            end)
	        end
	    end
	end)

	-- Chat Commands & HUNT
	Player.Chatted:Connect(function(message)
		local args = string.split(message:lower(), " ")
		local cmd = args[1] or ""
		local arg = table.concat(args, " ", 2)

		if cmd == "h" and arg ~= "" then
			huntingTarget = arg
			isHunting = true
			local found = findPlayerByFuzzy(arg)
			if found then
				notify("HUNT", "Found You!")

				UNLIMITED_M1_ENABLED = true
				setNoclip(true)
				setInfBlock(true)
				VOID_MODE_ENABLED = true
				selectTarget(found)
			else
				notify("HUNT", "Target not in server. Hopping...")
				pcall(function()
					local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
					for _, srv in pairs(servers.data) do
						if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
							TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, Player)
							break
						end
					end
				end)
			end
			return
		end

		if cmd == "uh" then
			isHunting = false
			huntingTarget = nil
			notify("HUNT", "Unhunt.")
			stopChase()
			return
		end

		if cmd == "x" then
			isHunting = false
			huntingTarget = nil
			stopChase()
			stopJerk()
			VOID_MODE_ENABLED = false
			setInfBlock(false)
			notify("OXIRO", "Stopped all actions.")
			return
		end

		if cmd == "jerk" and arg ~= "" then
			local t = findPlayerByFuzzy(arg)
			if t then startJerk(t) end
			return
		elseif cmd == "jerk" and arg == "off" then
			stopJerk()
			notify("Troll", "Stopped jerking.")
			return
		end
	end)

	Player.CharacterAdded:Connect(function()
		if isHunting and huntingTarget then
			task.wait(1)
			local found = findPlayerByFuzzy(huntingTarget)
			if found then
				notify("HUNT", "Found You!")
				UNLIMITED_M1_ENABLED = true
				setNoclip(true)
				setInfBlock(true)
				VOID_MODE_ENABLED = true
				selectTarget(found)
			end
		end
	end)

	function selectTarget(plr)
		if plr == Player or isPlayerSafe(plr) then return end
		mode = "attack"; attackTarget = plr; savedTargetUserId = plr.UserId
		startChase(plr)
	end

	-- === NEW MAIN UI (Sleek Redesign) ===
	pcall(function() if CoreGui:FindFirstChild("OxiroGui") then CoreGui.OxiroGui:Destroy() end end)

	local ScreenGuiMain = Instance.new("ScreenGui")
	ScreenGuiMain.Name = "OxiroGui"
	ScreenGuiMain.Parent = Player:WaitForChild("PlayerGui")
	ScreenGuiMain.ResetOnSpawn = false
	ScreenGuiMain.DisplayOrder = 99999

	local OpenBtn = Instance.new("TextButton")
	OpenBtn.Size = UDim2.new(0,140,0,45)
	OpenBtn.Position = UDim2.new(0.82,0,0.88,0)
	OpenBtn.BackgroundColor3 = Color3.fromRGB(15,15,20)
	OpenBtn.Text = "OXIRO"
	OpenBtn.Font = Enum.Font.GothamBold
	OpenBtn.TextColor3 = Color3.fromRGB(200,200,255)
	OpenBtn.TextSize = 18
	OpenBtn.Parent = ScreenGuiMain
	Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0,10)
	Instance.new("UIStroke", OpenBtn).Color = Color3.fromRGB(60,180,255)

	local MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0,380,0,600)
	MainFrame.Position = UDim2.new(0.5,-190,0.5,-300)
	MainFrame.BackgroundColor3 = Color3.fromRGB(12,12,16)
	MainFrame.Active = true; MainFrame.Draggable = true; MainFrame.Visible = false
	MainFrame.Parent = ScreenGuiMain
	Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,12)
	local MainStroke = Instance.new("UIStroke", MainFrame)
	MainStroke.Color = Color3.fromRGB(60,180,255)
	MainStroke.Thickness = 1.5

	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Size = UDim2.new(0,30,0,30)
	CloseBtn.Position = UDim2.new(1,-40,0,10)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(40,20,20)
	CloseBtn.Text = "X"
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextColor3 = Color3.fromRGB(255,150,150)
	CloseBtn.TextSize = 16
	CloseBtn.Parent = MainFrame
	Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,6)

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1,-80,0,35)
	Title.Position = UDim2.new(0,15,0,10)
	Title.BackgroundTransparency = 1
	Title.Text = "OXIRO CONTROL"
	Title.Font = Enum.Font.GothamBold
	Title.TextColor3 = Color3.fromRGB(255,255,255)
	Title.TextSize = 20; Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = MainFrame

	local TabContainer = Instance.new("Frame")
	TabContainer.Size = UDim2.new(1,-30,0,35)
	TabContainer.Position = UDim2.new(0,15,0,50)
	TabContainer.BackgroundTransparency = 1; TabContainer.Parent = MainFrame
	local TabLayout = Instance.new("UIListLayout")
	TabLayout.FillDirection = Enum.FillDirection.Horizontal
	TabLayout.Padding = UDim.new(0,5); TabLayout.Parent = TabContainer

	local function createTabBtn(name, text)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0,80,1,0)
		btn.BackgroundColor3 = Color3.fromRGB(25,25,30)
		btn.Text = text
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.fromRGB(150,150,170)
		btn.TextSize = 12; btn.Parent = TabContainer
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
		return btn
	end

	local TargetTabBtn = createTabBtn("target", "TARGET")
	local WeaponTabBtn = createTabBtn("weapons", "WEAPONS")
	local SettingsTabBtn = createTabBtn("settings", "SETTINGS")
	local ControlTabBtn = nil
	if isOwner then ControlTabBtn = createTabBtn("control", "CONTROL") end
	local ImmuneTabBtn = createTabBtn("immune", "IMMUNE")

	local ContentContainer = Instance.new("Frame")
	ContentContainer.Size = UDim2.new(1,-30,1,-105)
	ContentContainer.Position = UDim2.new(0,15,0,95)
	ContentContainer.BackgroundTransparency = 1; ContentContainer.Parent = MainFrame

	local function createPage()
		local page = Instance.new("Frame")
		page.Size = UDim2.new(1,0,1,0); page.BackgroundTransparency = 1; page.Visible = false
		page.Parent = ContentContainer
		local scroll = Instance.new("ScrollingFrame")
		scroll.Size = UDim2.new(1,0,1,0); scroll.BackgroundTransparency = 1
		scroll.ScrollBarThickness = 4; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.Parent = page
		Instance.new("UIListLayout", scroll).Padding = UDim.new(0,8)
		return page, scroll
	end

	local TargetPage, PlayerScroll = createPage()
	local WeaponPage, WeaponScroll = createPage()
	local SettingsPage, SettingsScroll = createPage()
	local ControlPage, ControlScroll = nil, nil
	if isOwner then ControlPage, ControlScroll = createPage() end
	local ImmunePage, ImmuneScroll = createPage()

	TargetPage.Visible = true

	local function switchTab(name)
		currentTab = name
		TargetPage.Visible = name == "target"
		WeaponPage.Visible = name == "weapons"
		SettingsPage.Visible = name == "settings"
		ImmunePage.Visible = name == "immune"
		if isOwner then ControlPage.Visible = name == "control" end
		
		TargetTabBtn.BackgroundColor3 = name == "target" and Color3.fromRGB(40,40,55) or Color3.fromRGB(25,25,30)
		TargetTabBtn.TextColor3 = name == "target" and Color3.fromRGB(80,200,255) or Color3.fromRGB(150,150,170)
		
		WeaponTabBtn.BackgroundColor3 = name == "weapons" and Color3.fromRGB(40,40,55) or Color3.fromRGB(25,25,30)
		WeaponTabBtn.TextColor3 = name == "weapons" and Color3.fromRGB(80,200,255) or Color3.fromRGB(150,150,170)
		
		SettingsTabBtn.BackgroundColor3 = name == "settings" and Color3.fromRGB(40,40,55) or Color3.fromRGB(25,25,30)
		SettingsTabBtn.TextColor3 = name == "settings" and Color3.fromRGB(80,200,255) or Color3.fromRGB(150,150,170)
		
		ImmuneTabBtn.BackgroundColor3 = name == "immune" and Color3.fromRGB(40,40,55) or Color3.fromRGB(25,25,30)
		ImmuneTabBtn.TextColor3 = name == "immune" and Color3.fromRGB(80,200,255) or Color3.fromRGB(150,150,170)
		
		if ControlTabBtn then 
			ControlTabBtn.BackgroundColor3 = name == "control" and Color3.fromRGB(40,40,55) or Color3.fromRGB(25,25,30)
			ControlTabBtn.TextColor3 = name == "control" and Color3.fromRGB(80,200,255) or Color3.fromRGB(150,150,170)
		end

		if name == "weapons" then refreshWeaponList() end
	end

	TargetTabBtn.MouseButton1Click:Connect(function() switchTab("target") end)
	WeaponTabBtn.MouseButton1Click:Connect(function() switchTab("weapons") end)
	SettingsTabBtn.MouseButton1Click:Connect(function() switchTab("settings") end)
	ImmuneTabBtn.MouseButton1Click:Connect(function() switchTab("immune") end)
	if ControlTabBtn then ControlTabBtn.MouseButton1Click:Connect(function() switchTab("control") end) end

	OpenBtn.MouseButton1Click:Connect(function() 
		MainFrame.Visible = true 
		OpenBtn.Visible = false
	end)
	CloseBtn.MouseButton1Click:Connect(function() 
		MainFrame.Visible = false 
		OpenBtn.Visible = true
	end)

	function refreshPlayerList()
		for _,b in ipairs(playerButtons) do b:Destroy() end
		table.clear(playerButtons)
		for _,plr in ipairs(Players:GetPlayers()) do
			if plr ~= Player then
				local safe = isPlayerSafe(plr)
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1,0,0,40)
				btn.BackgroundColor3 = safe and Color3.fromRGB(20,50,40) or Color3.fromRGB(25,25,30)
				btn.Font = Enum.Font.Gotham
				btn.Text = (safe and "[SAFE] " or "")..plr.DisplayName.." (@"..plr.Name..")"
				btn.TextColor3 = safe and Color3.fromRGB(120,255,170) or Color3.fromRGB(200,200,220)
				btn.TextSize = 13; btn.Parent = PlayerScroll
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
				btn.MouseButton1Click:Connect(function()
					if isOwner then HVH_MODE = true; HVH_TARGET_USERID = plr.UserId end
					selectTarget(plr)
					notify("TARGET", "Locked onto " .. plr.Name)
				end)
				table.insert(playerButtons, btn)
			end
		end
	end
	Players.PlayerAdded:Connect(refreshPlayerList)
	Players.PlayerRemoving:Connect(refreshPlayerList)
	task.spawn(refreshPlayerList)

	local function mkNum(lbl, def, cb, p)
		local c = Instance.new("Frame")
		c.Size = UDim2.new(1,0,0,40); c.BackgroundColor3 = Color3.fromRGB(25,25,30); c.Parent = p
		Instance.new("UICorner", c).CornerRadius = UDim.new(0,6)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(0,160,1,0); l.Position = UDim2.new(0,15,0,0); l.BackgroundTransparency = 1
		l.Text = lbl; l.Font = Enum.Font.Gotham; l.TextColor3 = Color3.fromRGB(150,150,170); l.TextSize = 13; l.Parent = c
		local b = Instance.new("TextBox")
		b.Size = UDim2.new(1,-180,1,-8); b.Position = UDim2.new(0,170,0,4)
		b.BackgroundColor3 = Color3.fromRGB(35,35,45); b.Font = Enum.Font.Gotham; b.Text = tostring(def)
		b.TextColor3 = Color3.fromRGB(255,255,255); b.TextSize = 13; b.Parent = c
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
		b.FocusLost:Connect(function(e) if e then local v = tonumber(b.Text) if v then cb(v) end end end)
	end

	local function mkToggle(lbl, get, set, p)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1,0,0,40)
		local function u()
			local s = get()
			btn.BackgroundColor3 = s and Color3.fromRGB(30,50,40) or Color3.fromRGB(25,25,30)
			btn.TextColor3 = s and Color3.fromRGB(120,255,170) or Color3.fromRGB(150,150,170)
			btn.Text = lbl.." - "..(s and "ON" or "OFF")
		end
		u(); btn.Font = Enum.Font.GothamSemibold
		btn.TextSize = 13; btn.Parent = p
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
		btn.MouseButton1Click:Connect(function() set(not get()) u() end)
	end

	local function mkBtn(lbl, cb, p)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1,0,0,40); btn.BackgroundColor3 = Color3.fromRGB(40,40,55)
		btn.Text = lbl; btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.fromRGB(200,200,255); btn.TextSize = 13; btn.Parent = p
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
		btn.MouseButton1Click:Connect(cb)
	end

	mkNum("Chase Distance", CHASE_DISTANCE, function(v) CHASE_DISTANCE = v end, SettingsScroll)
	mkNum("Prediction", PREDICTION, function(v) PREDICTION = v end, SettingsScroll)
	mkNum("Hitbox Size", HITBOX_SIZE, function(v) HITBOX_SIZE = v end, SettingsScroll)

	mkToggle("Aimbot (Sticky)", function() return AIMBOT_ENABLED end, function(v) AIMBOT_ENABLED = v end, SettingsScroll)
	mkToggle("VOID MODE", function() return VOID_MODE_ENABLED end, function(v) VOID_MODE_ENABLED = v end, SettingsScroll)
	mkToggle("NOCLIP", function() return NOCLIP_ENABLED end, function(v) setNoclip(v) end, SettingsScroll)
	mkToggle("M1 Spam", function() return UNLIMITED_M1_ENABLED end, function(v) UNLIMITED_M1_ENABLED = v end, SettingsScroll)
	mkToggle("M2 Spam", function() return M2_SPAM_ENABLED end, function(v) M2_SPAM_ENABLED = v end, SettingsScroll)
	mkToggle("Infinite Block", function() return INF_BLOCK_ENABLED end, function(v) setInfBlock(v) end, SettingsScroll)
	mkToggle("Auto-Equip", function() return AUTO_EQUIP_ENABLED end, function(v) AUTO_EQUIP_ENABLED = v end, SettingsScroll)
	mkBtn("Stop / Idle", function() stopChase() end, SettingsScroll)

	if isOwner then
		mkToggle("HVH GROUP MODE", function() return HVH_MODE end, function(v)
			HVH_MODE = v
			if not v then HVH_TARGET_USERID = nil; HVH_VOID = false; HVH_NOCLIP = false end
		end, ControlScroll)
		mkBtn("Stop All / HVH OFF", function()
			HVH_MODE = false; HVH_TARGET_USERID = nil; HVH_VOID = false; HVH_NOCLIP = false
			stopChase()
		end, ControlScroll)
	end

	local SafeInputFrame = Instance.new("Frame")
	SafeInputFrame.Size = UDim2.new(1,0,0,40); SafeInputFrame.BackgroundColor3 = Color3.fromRGB(25,40,30); SafeInputFrame.Parent = ImmuneScroll
	Instance.new("UICorner", SafeInputFrame).CornerRadius = UDim.new(0,6)
	local SafeLabel = Instance.new("TextLabel")
	SafeLabel.Size = UDim2.new(0,100,1,0); SafeLabel.Position = UDim2.new(0,12,0,0); SafeLabel.BackgroundTransparency = 1
	SafeLabel.Text = "Safe Player:"; SafeLabel.Font = Enum.Font.GothamBold; SafeLabel.TextColor3 = Color3.fromRGB(120,255,170); SafeLabel.TextSize = 13
	SafeLabel.TextXAlignment = Enum.TextXAlignment.Left; SafeLabel.Parent = SafeInputFrame
	local SafeBox = Instance.new("TextBox")
	SafeBox.Size = UDim2.new(1,-115,1,-8); SafeBox.Position = UDim2.new(0,105,0,4)
	SafeBox.BackgroundColor3 = Color3.fromRGB(35,55,45); SafeBox.Font = Enum.Font.Gotham
	SafeBox.PlaceholderText = "Username -> ENTER"; SafeBox.Text = ""
	SafeBox.TextColor3 = Color3.fromRGB(255,255,255); SafeBox.TextSize = 13; SafeBox.Parent = SafeInputFrame
	Instance.new("UICorner", SafeBox).CornerRadius = UDim.new(0,4)
	SafeBox.FocusLost:Connect(function(enterPressed)
		if enterPressed and SafeBox.Text ~= "" then
			local t = findPlayerByFuzzy(SafeBox.Text)
			if t then immunePlayers[t] = true end
			SafeBox.Text = ""; refreshPlayerList()
		end
	end)

	local RemoveSafeBox = Instance.new("TextBox")
	RemoveSafeBox.Size = UDim2.new(1,-115,1,-8); RemoveSafeBox.Position = UDim2.new(0,105,0,4)
	RemoveSafeBox.BackgroundColor3 = Color3.fromRGB(55,35,45); RemoveSafeBox.Font = Enum.Font.Gotham
	RemoveSafeBox.PlaceholderText = "Remove Safe -> ENTER"; RemoveSafeBox.Text = ""
	RemoveSafeBox.TextColor3 = Color3.fromRGB(255,255,255); RemoveSafeBox.TextSize = 13; RemoveSafeBox.Parent = ImmuneScroll
	Instance.new("UICorner", RemoveSafeBox).CornerRadius = UDim.new(0,4)
	RemoveSafeBox.FocusLost:Connect(function(enterPressed)
		if enterPressed and RemoveSafeBox.Text ~= "" then
			local t = findPlayerByFuzzy(RemoveSafeBox.Text)
			if t then immunePlayers[t] = nil end
			RemoveSafeBox.Text = ""; refreshPlayerList()
		end
	end)
end

local function checkKey()
	local input = KeyBox.Text
	if input == CORRECT_KEY then
		Status.Text = "SUCCESS UNLOCKING..."
		task.wait(0.5)
		runMainScript()
		return
	end
	attempts += 1
	Status.Text = "WRONG KEY! Attempts: "..attempts.."/"..MAX_ATTEMPTS
	if attempts >= MAX_ATTEMPTS then
		Status.Text = "TOO MANY - KICKING..."
		task.wait(1.5)
		Player:Kick("Too many wrong key attempts")
	end
end

SubmitBtn.MouseButton1Click:Connect(checkKey)
KeyBox.FocusLost:Connect(function(entered) if entered then checkKey() end end)
