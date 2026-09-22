-- ============================================================================
-- 👾 KILLER HUB | ENGINE V12.8.0 - SHERIFF SUITE (OPTIMIZED + ULTRA LOW-END PING FIX)
-- ============================================================================
local KillerHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/Salayer09/KillerHub/refs/heads/main/Slayer.lua"))()

if getgenv().__KillerHubSheriff_Loaded then
    KillerHub:NotifyWarn("Already Loaded", "Sheriff script is already running.", 4)
    return
end
getgenv().__KillerHubSheriff_Loaded = true

local function Flag(name, default)
    local f = KillerHub.Flags[name]
    if f == nil or f.CurrentValue == nil then return default end
    return f.CurrentValue
end

local EMPTY_TABLE = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService") 
local Stats = game:GetService("Stats") 
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera

local math_clamp = math.clamp
local math_abs = math.abs
local math_pow = math.pow
local math_min = math.min
local math_floor = math.floor
local math_max = math.max
local vec2New = Vector2.new
local vec3New = Vector3.new
local udim2New = UDim2.new
local cframeNew = CFrame.new
local color3RGB = Color3.fromRGB
local os_clock = os.clock

local workspace_Gravity = workspace.Gravity
local VECTOR_ZERO = vec3New(0, 0, 0)
local PREDICTION_BOOST = 1.10

if _G.KillerHubLines then
    for _, line in pairs(_G.KillerHubLines) do pcall(function() line:Remove() end) end
end
_G.KillerHubLines = {}

local oldGui = game:GetService("CoreGui"):FindFirstChild("KillerHub_SheriffGui")
if oldGui then oldGui:Destroy() end

-- Real-time Ping Reader
local cachedPingValue = 0.05
local pingTask = task.spawn(function()
    while task.wait(0.2) do
        local currentPing = nil
        pcall(function()
            if Stats and Stats.Network and Stats.Network:FindFirstChild("ServerStatsItem") then
                local dataPing = Stats.Network.ServerStatsItem:FindFirstChild("Data Ping")
                if dataPing then currentPing = dataPing:GetValue() / 1000 end
            end
        end)

        if not currentPing or currentPing <= 0 then
            pcall(function()
                if LocalPlayer and LocalPlayer.GetNetworkPing then
                    currentPing = LocalPlayer:GetNetworkPing()
                end
            end)
        end

        if currentPing and currentPing > 0 then cachedPingValue = currentPing end
    end
end)
KillerHub:AddTask(pingTask)

-- UI Setup
local TabSheriff = KillerHub:CreateTab("Sheriff", "rbxassetid://15286655815")

TabSheriff:CreateSection("Silent Aim")
TabSheriff:CreateToggle("Sheriff_SilentAim", "Silent Aim", function() end)
TabSheriff:CreateDropdown("Sheriff_ShotType", "Shot Type", {"Normal", "Piercer Bullet"}, function() end)
TabSheriff:CreateKeybind("Sheriff_ShootKey", "Shoot Key", Enum.KeyCode.F, function() end)
TabSheriff:CreateToggle("Sheriff_JumpPred", "Jump Prediction", function() end)
TabSheriff:CreateToggle("Sheriff_WallCheck", "Wall Check", function() end)

TabSheriff:CreateSection("Prediction")
TabSheriff:CreateSlider("Sheriff_HScale", "Horizontal Prediction", 0, 300, function() end, 100)
TabSheriff:CreateSlider("Sheriff_VScale", "Vertical Prediction", 0, 300, function() end, 100)

local sliderPing = TabSheriff:CreateSlider("Sheriff_PingComp", "Ping Compensation", 0, 300, function() end, 50)

local pingLoopThread
TabSheriff:CreateToggle("Sheriff_PrioritizePing", "Prioritize Ping", function(estado)
    if pingLoopThread then task.cancel(pingLoopThread) pingLoopThread = nil end
    if estado then
        pingLoopThread = task.spawn(function()
            while Flag("Sheriff_PrioritizePing", false) do
                local currentMS = math_floor(cachedPingValue * 1000)
                if sliderPing and sliderPing.Set then sliderPing:Set(currentMS) end
                task.wait(0.3)
            end
        end)
    end
end)

TabSheriff:CreateSlider("Sheriff_MinPredDist", "Min Distance Prediction (studs)", 0, 15, function() end, 4)
TabSheriff:CreateSlider("Sheriff_MaxPredDist", "Max Distance Prediction (studs)", 10, 60, function() end, 22)

TabSheriff:CreateSection("Visuals")
TabSheriff:CreateMultiDropdown("Sheriff_Tracers", "Tracers", {
    "Tracer Prediction", 
    "Min Tracer Prediction", 
    "Lead Time", 
    "Lead Time Prediction",
    "Confirm wall check", 
    "Prediction X/Y offset"
}, function() end)

local cachedShootButton, cachedScreenGui

TabSheriff:CreateSection("Interface")
TabSheriff:CreateToggle("Sheriff_WeaponDetect", "Weapon Detector",
    function() if checkWeaponVisibility then checkWeaponVisibility() end end)
TabSheriff:CreateToggle("Sheriff_ShowButton", "Show Button",
    function() if checkWeaponVisibility then checkWeaponVisibility() end end)

TabSheriff:CreateToggleSlider(
    "Sheriff_CustomBtnSize", "Sheriff_BtnSize",
    "Custom Button Size", 50, 200,
    function(enabled)
        if not cachedShootButton then return end
        local sz = enabled and Flag("Sheriff_BtnSize", 95) or 95
        cachedShootButton.Size = udim2New(0, sz, 0, sz)
    end,
    function(val)
        if not cachedShootButton then return end
        if not Flag("Sheriff_CustomBtnSize", false) then return end
        cachedShootButton.Size = udim2New(0, val, 0, val)
    end,
    false, 95
)

TabSheriff:CreateToggle("Sheriff_LockBtnPos", "Lock Button Position", function() end)

local PageOthers = TabSheriff:CreatePage("Others", "Gear")
PageOthers:CreateSection("Auto Shoot")
PageOthers:CreateToggle("Sheriff_AutoShoot", "Auto shoot", function() end)
PageOthers:CreateDropdown("Sheriff_AutoShootType", "Type Auto shoot", {"Murder visible", "Knife visible"}, function() end)

PageOthers:CreateSection("Wait for Sight")
PageOthers:CreateToggle("Sheriff_WaitSight", "Wait for Sight", function() end)
PageOthers:CreateToggle("Sheriff_CancelOnClick", "Cancel waiting on click", function() end)
PageOthers:CreateSlider("Sheriff_WaitTime", "Wait Time", 5, 67, function() end, 15)

PageOthers:CreateSection("Gun Actions")
PageOthers:CreateToggle("Sheriff_UnEquipGun", "Un-Equip gun", function() end)

-- Weapon & Role Systems
local function isRangedWeapon(tool)
    if not tool or not tool:IsA("Tool") then return false end
    return (tool:FindFirstChild("Shoot") or tool.Name == "Gun" or tool.Name == "Revolver")
end

local function isMeleeWeapon(tool)
    if not tool or not tool:IsA("Tool") then return false end
    return (tool:FindFirstChild("Stab") or tool.Name == "Knife")
end

local function getGunLocation()
    local char = LocalPlayer.Character
    if char then for _, item in pairs(char:GetChildren()) do if isRangedWeapon(item) then return item, char end end end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then for _, item in pairs(bp:GetChildren()) do if isRangedWeapon(item) then return item, bp end end end
    return nil, nil
end

checkWeaponVisibility = function()
    if not cachedScreenGui then return end
    local showBtn = Flag("Sheriff_ShowButton", false)
    local useDetect = Flag("Sheriff_WeaponDetect", false)
    
    if not showBtn then cachedScreenGui.Enabled = false return end

    if useDetect then
        local gun, _ = getGunLocation()
        cachedScreenGui.Enabled = (gun ~= nil)
    else
        cachedScreenGui.Enabled = true
    end
end

local visTask = task.spawn(function()
    while task.wait(0.3) do pcall(checkWeaponVisibility) end
end)
KillerHub:AddTask(visTask)

local MurdererDetectado = nil
local smoothedVelocity = VECTOR_ZERO
local smoothedVisualY = 0 
local lastTargetChar = nil
local emaDeltaTime = 0.016 
local playerRoles = {}
local playerDeadStatus = {}
local duelTeams = {}
local currentTarget = nil

-- Weak keys para limpiezas de memoria automáticas
local lastPositions = setmetatable({}, {__mode = "k"})
local lagStates = setmetatable({}, {__mode = "k"})
local moveConfidence = setmetatable({}, {__mode = "k"})
local velocityBuffers = setmetatable({}, {__mode = "k"})

-- Sticky Target
local stickyTarget = nil
local stickyTargetTime = 0
local STICKY_DURATION = 0.12

local handLineIsBlocked = false 
local isWaitingForSight = false
local waitSightThread = nil
local Label = nil
local SubLabel = nil
local DecalTexture = nil

local tweenInfoFast = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function resetWaitState()
    isWaitingForSight = false
    local threadToCancel = waitSightThread
    waitSightThread = nil

    if DecalTexture then
        TweenService:Create(DecalTexture, tweenInfoFast, {
            Position = udim2New(0.5, 0, 0.44, 0),
            Size = udim2New(0.38, 0, 0.38, 0)
        }):Play()
    end
    if Label then
        TweenService:Create(Label, tweenInfoFast, {
            Position = udim2New(0, 0, 0.75, 0),
            Size = udim2New(1, 0, 0.2, 0)
        }):Play()
        Label.Text = "SHOOT"
        Label.TextColor3 = color3RGB(255, 255, 255)
    end
    if SubLabel then
        SubLabel.Text = ""
    end

    if threadToCancel and threadToCancel ~= coroutine.running() then
        pcall(function() task.cancel(threadToCancel) end)
    end
end

local function setTarget(nt) currentTarget = nt end

-- Target Buffers & Lag Handlers
local function getLagState(targetChar)
    local s = lagStates[targetChar]
    if not s then
        s = { lagFrames = 0, normalFrames = 0, isLagging = false }
        lagStates[targetChar] = s
    end
    return s
end

local function getMoveConfidence(targetChar)
    local s = moveConfidence[targetChar]
    if not s then
        s = { lastSpeed = 0, variance = 0 }
        moveConfidence[targetChar] = s
    end
    return s
end

local function getVelocityBuffer(targetChar)
    local v = velocityBuffers[targetChar]
    if not v then
        v = { lastValidVelocity = VECTOR_ZERO, staticFrames = 0 }
        velocityBuffers[targetChar] = v
    end
    return v
end

local function setStickyTarget(plr)
    stickyTarget = plr
    stickyTargetTime = os_clock()
end

local function clearStickyTarget()
    stickyTarget = nil
    stickyTargetTime = 0
end

local function getNormalizedTeam(plr)
    if not plr then return nil end
    local dt = duelTeams[plr.Name]
    if dt then return tostring(dt) end
    if plr.Team then return plr.Team.Name end
    return nil
end

local function parsePlayerData(t)
    if type(t) == "table" then
        for name, data in pairs(t) do
            if type(data) == "table" then
                if data.Role then playerRoles[name] = data.Role end
                if data.Dead ~= nil then playerDeadStatus[name] = data.Dead end
                if data.Team then duelTeams[name] = data.Team end
            end
        end
    end
end

local PlayerDataChanged = ReplicatedStorage:FindFirstChild("PlayerDataChanged", true)
if PlayerDataChanged and PlayerDataChanged:IsA("RemoteEvent") then 
    KillerHub:AddTask(PlayerDataChanged.OnClientEvent:Connect(parsePlayerData)) 
end

local function updateDuelState(data)
    table.clear(duelTeams)
    if type(data) == "table" then
        parsePlayerData(data)
        if data.Teams then
            for teamName, teamMembers in pairs(data.Teams) do
                if type(teamMembers) == "table" then
                    for _, pName in pairs(teamMembers) do
                        if type(pName) == "string" then duelTeams[pName] = tostring(teamName) end
                    end
                end
            end
        end
    end
end

for _, rem in pairs(ReplicatedStorage:GetDescendants()) do
    if rem:IsA("RemoteEvent") then
        local rName = rem.Name:lower()
        if rName:find("duel") or rName:find("customgame") then
            KillerHub:AddTask(rem.OnClientEvent:Connect(function(...)
                local args = {...}
                for _, arg in ipairs(args) do
                    if type(arg) == "table" then updateDuelState(arg) end
                end
            end))
        elseif rName:find("roundstart") or rName:find("gamestart") then
            KillerHub:AddTask(rem.OnClientEvent:Connect(function(...)
                resetWaitState()
                table.clear(playerRoles) 
                table.clear(playerDeadStatus) 
                table.clear(lastPositions)
                table.clear(lagStates)
                table.clear(moveConfidence)
                table.clear(velocityBuffers)
                stickyTarget = nil
                stickyTargetTime = 0
                MurdererDetectado = nil 
                local args = {...}
                for _, arg in ipairs(args) do
                    if type(arg) == "table" then parsePlayerData(arg) end
                end
            end))
        elseif rName:find("roundover") or rName:find("gameover") or rName:find("roundend") then
            KillerHub:AddTask(rem.OnClientEvent:Connect(function()
                resetWaitState()
                table.clear(duelTeams)
                table.clear(playerRoles)
                table.clear(playerDeadStatus)
                table.clear(lastPositions)
                table.clear(lagStates)
                table.clear(moveConfidence)
                table.clear(velocityBuffers)
                stickyTarget = nil
                stickyTargetTime = 0
                MurdererDetectado = nil
            end))
        end
    end
end

Players.PlayerRemoving:Connect(function(plr)
    duelTeams[plr.Name] = nil
    playerRoles[plr.Name] = nil
    playerDeadStatus[plr.Name] = nil
    if stickyTarget == plr then clearStickyTarget() end
end)

local floorCastParams = RaycastParams.new()
floorCastParams.FilterType = Enum.RaycastFilterType.Exclude

local function autoEquipWeapon()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if character and character:FindFirstChild("Humanoid") and backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if isRangedWeapon(item) then 
                character.Humanoid:EquipTool(item) 
                task.wait(0.03)
                break 
            end
        end
    end
end

local function autoUnequipWeapon()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:UnequipTools()
        end
    end
end

local function getMurderer()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return currentTarget end

    local myTeam = getNormalizedTeam(LocalPlayer)
    local isDuelActive = (next(duelTeams) ~= nil)

    local closestEnemy = nil
    local minDistance = math.huge

    local allPlayers = Players:GetPlayers()
    for i = 1, #allPlayers do
        local pl = allPlayers[i]
        if pl ~= LocalPlayer and pl.Character then
            local pName = pl.Name
            local char = pl.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local isDead = (hum and hum.Health <= 0) or (playerDeadStatus[pName] == true)

            if not isDead and hrp then
                local isEnemy = false
                local pRole = playerRoles[pName]
                local pTeam = getNormalizedTeam(pl)

                if isDuelActive and myTeam and pTeam then
                    if myTeam ~= pTeam then
                        isEnemy = true
                    end
                elseif pRole == "Murderer" or pRole == "Enemy" then
                    isEnemy = true
                else
                    local hasKnife = false
                    for _, item in pairs(char:GetChildren()) do 
                        if isMeleeWeapon(item) then hasKnife = true break end 
                    end
                    if not hasKnife and pl:FindFirstChild("Backpack") then
                        for _, item in pairs(pl.Backpack:GetChildren()) do 
                            if isMeleeWeapon(item) then hasKnife = true break end 
                        end
                    end
                    if hasKnife then
                        playerRoles[pName] = "Murderer"
                        isEnemy = true
                    end
                end

                if isEnemy then
                    local dist = (hrp.Position - myHrp.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        closestEnemy = pl
                    end
                end
            end
        end
    end

    if closestEnemy then
        setTarget(closestEnemy)
        setStickyTarget(closestEnemy)
        return closestEnemy
    end

    if stickyTarget and (os_clock() - stickyTargetTime) < STICKY_DURATION then
        local char = stickyTarget.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                setTarget(stickyTarget)
                return stickyTarget
            end
        end
        clearStickyTarget()
    end

    setTarget(nil)
    return nil
end

local MURDERER_CACHE_INTERVAL = 0.06
local lastMurdererCalc = 0
local cachedMurdererResult = nil

local function getMurdererCached()
    local now = os_clock()
    if (now - lastMurdererCalc) < MURDERER_CACHE_INTERVAL then
        return cachedMurdererResult
    end
    lastMurdererCalc = now
    cachedMurdererResult = getMurderer()
    return cachedMurdererResult
end

local wallCastParams = RaycastParams.new()
wallCastParams.FilterType = Enum.RaycastFilterType.Exclude

local gunCastParams = RaycastParams.new()
gunCastParams.FilterType = Enum.RaycastFilterType.Exclude

local visCastParams = RaycastParams.new()
visCastParams.FilterType = Enum.RaycastFilterType.Exclude

local cachedIgnoreList = {}
local tempIgnoreBuffer = {}

local function updateIgnoreListCache()
    table.clear(cachedIgnoreList)
    if LocalPlayer.Character then table.insert(cachedIgnoreList, LocalPlayer.Character) end
    table.insert(cachedIgnoreList, Camera)
end

KillerHub:AddTask(LocalPlayer.CharacterAdded:Connect(function()
    updateIgnoreListCache()
    resetWaitState()
end))
updateIgnoreListCache()

local function isGunBlocked(targetPos, targetChar)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return true end

    local origin = char.HumanoidRootPart.Position
    if char.HumanoidRootPart:FindFirstChild("GunRaycastAttachment") then
        origin = char.HumanoidRootPart.GunRaycastAttachment.WorldPosition
    else
        local rightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
        if rightHand then origin = rightHand.Position end
    end

    local direction = targetPos - origin
    if direction.Magnitude < 0.1 then return false end

    table.clear(tempIgnoreBuffer)
    for i = 1, #cachedIgnoreList do tempIgnoreBuffer[i] = cachedIgnoreList[i] end
    
    local currentOrigin = origin
    local rayPasses = 0

    while direction.Magnitude > 0.1 and rayPasses < 5 do
        rayPasses = rayPasses + 1
        gunCastParams.FilterDescendantsInstances = tempIgnoreBuffer
        local ray = workspace:Raycast(currentOrigin, direction, gunCastParams)
        if not ray then return false end

        local hitInst = ray.Instance
        if targetChar and hitInst:IsDescendantOf(targetChar) then
            return false
        end

        if hitInst and hitInst.CanCollide and hitInst.Transparency < 0.8 then
            return true
        else
            table.insert(tempIgnoreBuffer, hitInst)
            currentOrigin = ray.Position + (direction.Unit * 0.05)
            direction = targetPos - currentOrigin
        end
    end

    return false
end

local function isStrictlyVisible(targetChar, targetPart)
    if not targetChar or not targetPart then return false end
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    
    if isGunBlocked(targetPos, targetChar) then return false end

    local direction = targetPos - origin
    table.clear(tempIgnoreBuffer)
    for i = 1, #cachedIgnoreList do tempIgnoreBuffer[i] = cachedIgnoreList[i] end

    local currentOrigin = origin
    local rayPasses = 0

    while direction.Magnitude > 0.1 and rayPasses < 5 do
        rayPasses = rayPasses + 1
        visCastParams.FilterDescendantsInstances = tempIgnoreBuffer
        local ray = workspace:Raycast(currentOrigin, direction, visCastParams)
        if not ray then return true end

        local hitInst = ray.Instance
        if hitInst and hitInst:IsDescendantOf(targetChar) then
            return true
        end

        if hitInst and hitInst.CanCollide and hitInst.Transparency < 0.8 then
            return false
        else
            table.insert(tempIgnoreBuffer, hitInst)
            currentOrigin = ray.Position + (direction.Unit * 0.05)
            direction = targetPos - currentOrigin
        end
    end

    return true
end

local function getSmartTargetPart(targetChar)
    if not targetChar then return nil, true end
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, true end
    
    local wallCheck = Flag("Sheriff_WallCheck", true)
    local shotType = Flag("Sheriff_ShotType", "Normal")

    if not wallCheck or shotType == "Piercer Bullet" then 
        return hrp, false 
    end
    
    local origin = Camera.CFrame.Position
    table.clear(tempIgnoreBuffer)
    for i = 1, #cachedIgnoreList do tempIgnoreBuffer[i] = cachedIgnoreList[i] end

    local targetPos = hrp.Position
    local currentOrigin = origin
    local direction = targetPos - currentOrigin
    local blocked = false
    local rayPasses = 0

    while direction.Magnitude > 0.1 and rayPasses < 5 do
        rayPasses = rayPasses + 1
        wallCastParams.FilterDescendantsInstances = tempIgnoreBuffer
        local ray = workspace:Raycast(currentOrigin, direction, wallCastParams)
        if not ray then break end

        local hitInst = ray.Instance
        if hitInst and hitInst:IsDescendantOf(targetChar) then
            break
        end

        if hitInst and hitInst.CanCollide and hitInst.Transparency < 0.8 then
            blocked = true
            break 
        else
            table.insert(tempIgnoreBuffer, hitInst)
            currentOrigin = ray.Position + (direction.Unit * 0.05)
            direction = targetPos - currentOrigin
        end
    end

    if not blocked and isGunBlocked(targetPos, targetChar) then
        blocked = true
    end

    return hrp, blocked
end

local floorCache = setmetatable({}, {__mode = "k"})

local function getFloorHeight(targetHrp, targetChar)
    if not targetHrp then return nil end
    local now = os_clock()
    local posY = targetHrp.Position.Y

    local cached = floorCache[targetChar]
    if cached and (now - cached.Time) < 0.15 and math_abs(posY - cached.BaseY) < 1.5 then
        return cached.FloorY
    end

    floorCastParams.FilterDescendantsInstances = {targetChar, LocalPlayer.Character, Camera}
    local ray = workspace:Raycast(targetHrp.Position, vec3New(0, -25, 0), floorCastParams)
    local floorY = ray and ray.Position.Y or nil

    floorCache[targetChar] = { FloorY = floorY, BaseY = posY, Time = now }
    return floorY
end

-- ⚡ PREDICTION ENGINE OPTIMIZADO PARA LOW-END & BAD PING
local function getPredictedPosition(targetChar, targetPart, customDelta)
    if not targetChar or not targetPart then return nil, nil, nil, nil, nil end
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid or humanoid.Health <= 0 then return nil, nil, nil, nil, nil end

    local activeDT = customDelta or emaDeltaTime
    local targetPosition = targetPart.Position

    local referencePos = Camera and Camera.CFrame.Position or targetPosition
    local distance = (targetPosition - referencePos).Magnitude

    local moveMag = humanoid.MoveDirection.Magnitude
    local rawPhysicsVel = hrp.AssemblyLinearVelocity
    local walkSpeed = (humanoid.WalkSpeed > 0) and humanoid.WalkSpeed or 16

    local calculatedVelY = rawPhysicsVel.Y
    local realDisplacementSpeed = 0
    local lastData = lastPositions[targetChar]
    local now = os_clock()
    local vBuffer = getVelocityBuffer(targetChar)
    
    if not lastData then
        lastData = {Pos = hrp.Position, Time = now, RealSpeed = 0}
        lastPositions[targetChar] = lastData
    else
        local dtPrev = now - lastData.Time
        if dtPrev > 0.005 then
            local distMoved = (hrp.Position - lastData.Pos).Magnitude
            realDisplacementSpeed = distMoved / dtPrev
            lastData.RealSpeed = realDisplacementSpeed
            
            -- Detección de lag o desincronización de paquetes
            if distMoved < 0.05 and (moveMag > 0.1 or rawPhysicsVel.Magnitude > 2) then
                vBuffer.staticFrames = vBuffer.staticFrames + 1
            else
                vBuffer.staticFrames = 0
            end

            local realYVel = (hrp.Position.Y - lastData.Pos.Y) / dtPrev
            if math_abs(realYVel) > 0.5 then calculatedVelY = realYVel end
        else
            realDisplacementSpeed = lastData.RealSpeed or 0
        end
        lastData.Pos = hrp.Position
        lastData.Time = now
    end

    local actualPhysicsH = vec3New(rawPhysicsVel.X, 0, rawPhysicsVel.Z)
    local realSpeedH = actualPhysicsH.Magnitude

    local effectiveSpeed = math_min(realSpeedH, walkSpeed)
    local intendedVel = vec3New(humanoid.MoveDirection.X * effectiveSpeed, 0, humanoid.MoveDirection.Z * effectiveSpeed)

    local speedRatio = math_clamp(realSpeedH / math_max(walkSpeed, 1), 0, 1)
    local rawVelocity = actualPhysicsH:Lerp(intendedVel, speedRatio)

    -- FIX LOW-END/LAG: Si el jugador se congela en paquetes pero sigue moviéndose en input,
    -- no colapsamos a 0. Mantenemos un buffer suave de velocidad (Soft Decay Buffer).
    if vBuffer.staticFrames > 0 and vBuffer.staticFrames <= 8 then
        local decay = math_clamp(1 - (vBuffer.staticFrames * 0.08), 0.4, 0.95)
        rawVelocity = vBuffer.lastValidVelocity * decay
    elseif vBuffer.staticFrames > 8 then
        rawVelocity = VECTOR_ZERO
        smoothedVelocity = VECTOR_ZERO
    else
        vBuffer.lastValidVelocity = rawVelocity
    end

    -- Confianza de movimiento (Jitter Softener)
    local confState = getMoveConfidence(targetChar)
    local speedDelta = math_abs(realSpeedH - confState.lastSpeed)
    confState.variance = confState.variance * 0.88 + speedDelta * 0.12
    confState.lastSpeed = realSpeedH
    local moveConfidenceFactor = math_clamp(1 - (confState.variance - 5) / 120, 0.75, 1.0)

    local minDist = Flag("Sheriff_MinPredDist", 4)
    local maxDist = Flag("Sheriff_MaxPredDist", 22)
    local distRange = math_max(maxDist - minDist, 0.1)
    local predictionWeight = math_clamp((distance - minDist) / distRange, 0, 1)

    if lastTargetChar ~= targetChar then
        smoothedVelocity = rawVelocity 
        smoothedVisualY = 0
        lastTargetChar = targetChar
    end

    local isStopping = (moveMag < 0.1 and rawVelocity.Magnitude < 1.5)
    local isStarting = (moveMag > 0.1 and smoothedVelocity.Magnitude < 1.5)

    local vSmoothAlpha = 0.35
    if isStopping then 
        vSmoothAlpha = 0.85
    elseif isStarting then 
        vSmoothAlpha = 0.20
    else 
        vSmoothAlpha = math_clamp(16 * activeDT, 0.22, 0.60) 
    end
    
    smoothedVelocity = smoothedVelocity:Lerp(rawVelocity, vSmoothAlpha)
    if isStopping and smoothedVelocity.Magnitude < 0.3 then smoothedVelocity = VECTOR_ZERO end

    local horizontalShift = VECTOR_ZERO
    local verticalShift = VECTOR_ZERO

    local prioritizePing = Flag("Sheriff_PrioritizePing", false)
    local vScale = Flag("Sheriff_VScale", 100)
    local hScale = Flag("Sheriff_HScale", 100)

    local effectiveHLatency = 0
    local effectiveVLatency = 0

    if prioritizePing then
        local rawMS = cachedPingValue * 1000
        local autoScale = 90 + (rawMS * 0.6)

        effectiveHLatency = (autoScale / 1000) * PREDICTION_BOOST
        local autoVScale = math_min(autoScale, 120)
        effectiveVLatency = (autoVScale / 1000) * PREDICTION_BOOST
    else
        effectiveHLatency = (hScale / 1000) * PREDICTION_BOOST
        local cappedVScale = math_min(vScale, 120)
        effectiveVLatency = (cappedVScale / 1000) * PREDICTION_BOOST
    end

    horizontalShift = vec3New(smoothedVelocity.X, 0, smoothedVelocity.Z) * effectiveHLatency * predictionWeight * moveConfidenceFactor

    if vScale > 0 then
        local isAir = (humanoid.FloorMaterial == Enum.Material.Air)
        local isStairMovement = (not isAir and math_abs(calculatedVelY) > 0.8)

        if isAir or isStairMovement then
            local adaptiveYFactor = math_clamp((distance - minDist) / 12, 0, 1) * predictionWeight
            local vFactor = effectiveVLatency * adaptiveYFactor

            if isAir then
                if calculatedVelY < -0.5 then
                    local fallSpeed = math_max(calculatedVelY, -18)
                    local fallingYFactor = fallSpeed * 0.30 * vFactor
                    verticalShift = vec3New(0, fallingYFactor, 0)
                else
                    local gravityEffect = 0.5 * workspace_Gravity * math_pow(vFactor, 2)
                    local pY = (calculatedVelY * vFactor) - gravityEffect
                    verticalShift = vec3New(0, pY, 0)
                end
            elseif isStairMovement then
                local pY = calculatedVelY * vFactor
                verticalShift = vec3New(0, pY, 0)
            end
        end
    end

    if horizontalShift.Magnitude > 8.5 then horizontalShift = horizontalShift.Unit * 8.5 end
    if verticalShift.Magnitude > 6.0 then verticalShift = verticalShift.Unit * 6.0 end

    local finalPredNoY = vec3New(targetPosition.X + horizontalShift.X, targetPosition.Y, targetPosition.Z + horizontalShift.Z)
    local minPredNoY = vec3New(targetPosition.X + (horizontalShift.X * 0.4), targetPosition.Y, targetPosition.Z + (horizontalShift.Z * 0.4))

    local finalPredWithY = targetPosition + horizontalShift + verticalShift
    local predXYExaggerated = targetPosition + (horizontalShift * 1.8) + verticalShift
    
    local LEAD_TIME_VISUAL_MULT = 4.2
    local LEAD_TIME_VISUAL_CLAMP = 16

    local rawVisualY = math_clamp(verticalShift.Y * LEAD_TIME_VISUAL_MULT, -LEAD_TIME_VISUAL_CLAMP, LEAD_TIME_VISUAL_CLAMP)
    local yLerpAlpha = math_clamp(14 * activeDT, 0.10, 0.35)
    smoothedVisualY = smoothedVisualY + (rawVisualY - smoothedVisualY) * yLerpAlpha

    local finalLeadPredX = targetPosition + (horizontalShift * LEAD_TIME_VISUAL_MULT) + vec3New(0, smoothedVisualY, 0)

    local floorY = getFloorHeight(hrp, targetChar)
    if floorY then
        local minAllowedY = floorY + (hrp.Size.Y / 2) + 0.15
        if finalPredWithY.Y < minAllowedY then finalPredWithY = vec3New(finalPredWithY.X, minAllowedY, finalPredWithY.Z) end
        if predXYExaggerated.Y < minAllowedY then predXYExaggerated = vec3New(predXYExaggerated.X, minAllowedY, predXYExaggerated.Z) end
        if finalLeadPredX.Y < minAllowedY then finalLeadPredX = vec3New(finalLeadPredX.X, minAllowedY, finalLeadPredX.Z) end
    end

    return finalPredWithY, finalPredNoY, minPredNoY, predXYExaggerated, finalLeadPredX
end

-- Tracers Render Setup
local MinPredictionLine = Drawing.new("Line")
MinPredictionLine.Color = color3RGB(4, 0, 220); MinPredictionLine.Thickness = 2.0; MinPredictionLine.Transparency = 1.0; MinPredictionLine.ZIndex = 5

local PredictionLine = Drawing.new("Line")
PredictionLine.Color = color3RGB(255, 35, 35); PredictionLine.Thickness = 2.0; PredictionLine.Transparency = 1.0; PredictionLine.ZIndex = 10

local LeadTimeLine = Drawing.new("Line")
LeadTimeLine.Color = color3RGB(35, 255, 35); LeadTimeLine.Thickness = 1.8; LeadTimeLine.Transparency = 1.0; LeadTimeLine.ZIndex = 7

local LeadTimePredLine = Drawing.new("Line")
LeadTimePredLine.Color = color3RGB(35, 255, 35); LeadTimePredLine.Thickness = 1.8; LeadTimePredLine.Transparency = 1.0; LeadTimePredLine.ZIndex = 8

local ConfirmWallLine = Drawing.new("Line")
ConfirmWallLine.Color = color3RGB(0, 0, 0); ConfirmWallLine.Thickness = 2.0; ConfirmWallLine.Transparency = 1.0; ConfirmWallLine.ZIndex = 8

local PredictionXYLine = Drawing.new("Line")
PredictionXYLine.Color = color3RGB(170, 0, 255); PredictionXYLine.Thickness = 2.0; PredictionXYLine.Transparency = 1.0; PredictionXYLine.ZIndex = 9

table.insert(_G.KillerHubLines, MinPredictionLine)
table.insert(_G.KillerHubLines, PredictionLine)
table.insert(_G.KillerHubLines, LeadTimeLine)
table.insert(_G.KillerHubLines, LeadTimePredLine)
table.insert(_G.KillerHubLines, ConfirmWallLine)
table.insert(_G.KillerHubLines, PredictionXYLine)

local worldToViewport = Camera.WorldToViewportPoint

-- Dynamic Ultra-Fast Lerp para Tracers
local function adaptiveLerp(cur, tgt, baseA)
    if not cur then return tgt end
    local dev = (tgt - cur).Magnitude
    if dev <= 1.5 then
        return cur:Lerp(tgt, baseA)
    end
    local soft = baseA * math_clamp(3.5 / dev, 0.45, 1.0)
    return cur:Lerp(tgt, soft)
end

local visPredNoY, visMinPredNoY, visPredXYExaggerated, visFinalLeadPredX

local renderConn = RunService.RenderStepped:Connect(function(dt)
    emaDeltaTime = emaDeltaTime + 0.2 * (dt - emaDeltaTime) 

    local murderer = getMurdererCached()
    if not murderer or not murderer.Character then
        PredictionLine.Visible = false
        MinPredictionLine.Visible = false
        LeadTimeLine.Visible = false
        LeadTimePredLine.Visible = false
        ConfirmWallLine.Visible = false
        PredictionXYLine.Visible = false
        visPredNoY = nil
        return
    end

    local targetChar = murderer.Character
    local visualPart, isBlocked = getSmartTargetPart(targetChar) 
    handLineIsBlocked = isBlocked

    local myChar = LocalPlayer.Character
    local rightHand = myChar and (myChar:FindFirstChild("RightHand") or myChar:FindFirstChild("Right Arm"))

    local tracersTable = Flag("Sheriff_Tracers", EMPTY_TABLE)
    local showRed = tracersTable["Tracer Prediction"] == true
    local showBlue = tracersTable["Min Tracer Prediction"] == true
    local showGreen = tracersTable["Lead Time"] == true
    local showLeadPred = tracersTable["Lead Time Prediction"] == true
    local showConfirmWall = tracersTable["Confirm wall check"] == true
    local showXYOffset = tracersTable["Prediction X/Y offset"] == true

    if visualPart then
        local _, predNoY, minPredNoY, predXYExaggerated, finalLeadPredX = getPredictedPosition(targetChar, visualPart, dt)
        
        if predNoY and minPredNoY then
            -- Tracers ultra-rápidos (42 * dt para respuesta instantánea)
            local tracerLerpAlpha = math_clamp(42 * dt, 0.25, 0.85)
            if not visPredNoY then
                visPredNoY = predNoY
                visMinPredNoY = minPredNoY
                visPredXYExaggerated = predXYExaggerated
                visFinalLeadPredX = finalLeadPredX
            else
                visPredNoY = adaptiveLerp(visPredNoY, predNoY, tracerLerpAlpha)
                visMinPredNoY = adaptiveLerp(visMinPredNoY, minPredNoY, tracerLerpAlpha)
                if predXYExaggerated then visPredXYExaggerated = adaptiveLerp(visPredXYExaggerated, predXYExaggerated, tracerLerpAlpha) end
                if finalLeadPredX then visFinalLeadPredX = adaptiveLerp(visFinalLeadPredX, finalLeadPredX, tracerLerpAlpha) end
            end

            local currentViewportSize = Camera.ViewportSize
            local screenOrigin = vec2New(currentViewportSize.X / 2, currentViewportSize.Y)

            if showBlue then
                local screenPos, onScreen = worldToViewport(Camera, visMinPredNoY)
                if onScreen then
                    MinPredictionLine.From = screenOrigin 
                    MinPredictionLine.To = vec2New(screenPos.X, screenPos.Y) 
                    MinPredictionLine.Visible = true
                else MinPredictionLine.Visible = false end
            else MinPredictionLine.Visible = false end

            if showRed then
                local screenPos, onScreen = worldToViewport(Camera, visPredNoY)
                if onScreen then
                    PredictionLine.From = screenOrigin 
                    PredictionLine.To = vec2New(screenPos.X, screenPos.Y) 
                    PredictionLine.Visible = true
                else PredictionLine.Visible = false end
            else PredictionLine.Visible = false end

            if showLeadPred and visFinalLeadPredX then
                local screenPos, onScreen = worldToViewport(Camera, visFinalLeadPredX)
                if onScreen then
                    LeadTimePredLine.From = screenOrigin
                    LeadTimePredLine.To = vec2New(screenPos.X, screenPos.Y)
                    LeadTimePredLine.Visible = true
                else LeadTimePredLine.Visible = false end
            else LeadTimePredLine.Visible = false end

            if showXYOffset and visPredXYExaggerated then
                local screenPos, onScreen = worldToViewport(Camera, visPredXYExaggerated)
                if onScreen then
                    PredictionXYLine.From = screenOrigin
                    PredictionXYLine.To = vec2New(screenPos.X, screenPos.Y)
                    PredictionXYLine.Visible = true
                else PredictionXYLine.Visible = false end
            else PredictionXYLine.Visible = false end

            if rightHand and showGreen then
                local targetPosForLead = showLeadPred and visFinalLeadPredX or visPredNoY
                if targetPosForLead then
                    local handScreenPos, handOnScreen = worldToViewport(Camera, rightHand.Position)
                    local predScreenPos, predOnScreen = worldToViewport(Camera, targetPosForLead)

                    if handOnScreen and predOnScreen then
                        LeadTimeLine.Color = color3RGB(35, 255, 35)
                        LeadTimeLine.From = vec2New(handScreenPos.X, handScreenPos.Y)
                        LeadTimeLine.To = vec2New(predScreenPos.X, predScreenPos.Y)
                        LeadTimeLine.Visible = true
                    else LeadTimeLine.Visible = false end
                else LeadTimeLine.Visible = false end
            else LeadTimeLine.Visible = false end
        end

        if showConfirmWall and myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local myHrp = myChar.HumanoidRootPart
            local myScreenPos, myOnScreen = worldToViewport(Camera, myHrp.Position)
            local targetScreenPos, targetOnScreen = worldToViewport(Camera, visualPart.Position)

            if myOnScreen and targetOnScreen then
                ConfirmWallLine.From = vec2New(myScreenPos.X, myScreenPos.Y)
                ConfirmWallLine.To = vec2New(targetScreenPos.X, targetScreenPos.Y)
                if isBlocked then
                    ConfirmWallLine.Color = color3RGB(0, 0, 0)
                else
                    ConfirmWallLine.Color = color3RGB(130, 35, 190)
                end
                ConfirmWallLine.Visible = true
            else
                ConfirmWallLine.Visible = false
            end
        else
            ConfirmWallLine.Visible = false
        end
    else
        PredictionLine.Visible = false
        MinPredictionLine.Visible = false
        LeadTimeLine.Visible = false
        LeadTimePredLine.Visible = false
        ConfirmWallLine.Visible = false
        PredictionXYLine.Visible = false
        visPredNoY = nil
    end 
end)
KillerHub:AddTask(renderConn)

-- Core Shoot Handler
local executeActualShoot

executeActualShoot = function(targetChar, bestPart)
    local shotType = Flag("Sheriff_ShotType", "Normal")
    local wallCheck = Flag("Sheriff_WallCheck", true)
    local char = LocalPlayer.Character
    if not char then return false end

    local gun, _ = getGunLocation()
    if not gun then return false end

    local finalPredictedPos = getPredictedPosition(targetChar, bestPart)
    if finalPredictedPos then
        if wallCheck and shotType ~= "Piercer Bullet" then
            if isGunBlocked(finalPredictedPos, targetChar) then
                return false
            end
        end

        autoEquipWeapon()
        
        local activeGun, _ = getGunLocation()
        if activeGun and activeGun:FindFirstChild("Shoot") then
            local originCFrame = char.HumanoidRootPart and char.HumanoidRootPart.CFrame or Camera.CFrame
            if char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart:FindFirstChild("GunRaycastAttachment") then 
                originCFrame = char.HumanoidRootPart.GunRaycastAttachment.WorldCFrame 
            end

            if shotType == "Piercer Bullet" then
                local camLook = Camera.CFrame.LookVector
                local horizDir = vec3New(camLook.X, 0, camLook.Z)
                
                if horizDir.Magnitude < 0.01 then
                    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
                    if hrp then horizDir = vec3New(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z) end
                end
                
                if horizDir.Magnitude < 0.01 then
                    horizDir = vec3New(1, 0, 0)
                else
                    horizDir = horizDir.Unit
                end

                local spawnOrigin = finalPredictedPos - (horizDir * 1.5)
                originCFrame = cframeNew(spawnOrigin, finalPredictedPos)
            end

            activeGun.Shoot:FireServer(originCFrame, cframeNew(finalPredictedPos))

            if Flag("Sheriff_UnEquipGun", false) then
                task.delay(0.20, autoUnequipWeapon)
            end
            
            return true
        end
    end
    return false
end

-- Wait for Sight
local function startWaitingForSight(initialTarget)
    resetWaitState()

    local gun, _ = getGunLocation()
    if not gun then return end

    isWaitingForSight = true

    if DecalTexture then
        TweenService:Create(DecalTexture, tweenInfoFast, {Position = udim2New(0.5, 0, 0.28, 0), Size = udim2New(0.38, 0, 0.38, 0)}):Play()
    end
    if Label then
        TweenService:Create(Label, tweenInfoFast, {Position = udim2New(0, 0, 0.52, 0), Size = udim2New(1, 0, 0.2, 0)}):Play()
        Label.Text = "WAITING..."
        Label.TextColor3 = color3RGB(255, 50, 50)
    end

    local maxWaitTime = Flag("Sheriff_WaitTime", 15)
    local startTime = os_clock()
    local lostSightCounter = 0 
    local sightTimeAcc = 0

    waitSightThread = task.spawn(function()
        while isWaitingForSight do
            local currentGun, _ = getGunLocation()
            if not currentGun then
                resetWaitState()
                break
            end

            local elapsed = os_clock() - startTime
            local remaining = maxWaitTime - elapsed

            if remaining <= 0 then
                resetWaitState()
                break
            end

            if SubLabel then
                SubLabel.Text = string.format("%.1fs", math_max(0, remaining))
            end

            local murderer = getMurdererCached()
            if not murderer or not murderer.Character then
                lostSightCounter = lostSightCounter + 0.016
                sightTimeAcc = 0
                if lostSightCounter > 0.15 then
                    resetWaitState()
                    break
                end
            else
                local targetChar = murderer.Character
                local hum = targetChar:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then
                    resetWaitState()
                    break
                end

                local shotType = Flag("Sheriff_ShotType", "Normal")
                local bestPart, isBlocked = getSmartTargetPart(targetChar)

                local isClearSight = bestPart and (not isBlocked or shotType == "Piercer Bullet")

                if isClearSight then
                    lostSightCounter = 0
                    sightTimeAcc = sightTimeAcc + 0.016
                    
                    if sightTimeAcc >= 0.035 then
                        local shotFired = executeActualShoot(targetChar, bestPart)
                        if shotFired then
                            resetWaitState()
                            break
                        end
                    end
                else
                    sightTimeAcc = 0
                end
            end

            RunService.RenderStepped:Wait()
        end
    end)
end

local function fireAtMurdererDirectly()
    local cancelOnClick = Flag("Sheriff_CancelOnClick", false)

    if isWaitingForSight then
        if cancelOnClick then resetWaitState() end
        return
    end

    local gun, _ = getGunLocation()
    if not gun then return end

    local shotType = Flag("Sheriff_ShotType", "Normal")
    local wallCheck = Flag("Sheriff_WallCheck", true)
    local waitSight = Flag("Sheriff_WaitSight", false)
    
    local murderer = getMurdererCached()
    if murderer and murderer.Character then
        local targetChar = murderer.Character
        local bestPart, isBlocked = getSmartTargetPart(targetChar) 
        
        local allowWaitSight = waitSight and (shotType ~= "Piercer Bullet")

        if wallCheck and isBlocked and shotType ~= "Piercer Bullet" then
            if allowWaitSight then
                startWaitingForSight(targetChar)
            end
            return
        end

        if bestPart then
            executeActualShoot(targetChar, bestPart)
        end
    end
end

-- Auto Shoot Engine
local lastAutoShootTime = 0
local autoShootConn = RunService.Heartbeat:Connect(function()
    if not Flag("Sheriff_AutoShoot", false) then return end

    local now = os_clock()
    if now - lastAutoShootTime < 0.18 then return end

    local gun, _ = getGunLocation()
    if not gun then return end

    local murderer = getMurdererCached()
    if not murderer or not murderer.Character then return end
    local targetChar = murderer.Character

    local autoType = Flag("Sheriff_AutoShootType", "Murder visible")
    if autoType == "Knife visible" then
        local knifeEquipped = false
        for _, item in pairs(targetChar:GetChildren()) do
            if isMeleeWeapon(item) then knifeEquipped = true break end
        end
        if not knifeEquipped then return end
    end

    local bestPart, _ = getSmartTargetPart(targetChar)
    if bestPart and isStrictlyVisible(targetChar, bestPart) then
        lastAutoShootTime = now
        fireAtMurdererDirectly()
    end
end)
KillerHub:AddTask(autoShootConn)

-- Keybinds & Mobile GUI
local function safeGetEnum(enumType, name)
    local ok, result = pcall(function() return enumType[name] end)
    return ok and result or nil
end

local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local targetKeyName = Flag("Sheriff_ShootKey", "F")
    local kc = safeGetEnum(Enum.KeyCode, targetKeyName)
    local uit = safeGetEnum(Enum.UserInputType, targetKeyName)
    if (kc and input.KeyCode == kc) or (uit and input.UserInputType == uit) then
        task.spawn(fireAtMurdererDirectly)
    end
end)
KillerHub:AddTask(inputConn)

local POS_FILE = "KillerHub_ButtonPos.txt"
local function loadButtonPosition()
    if isfile and readfile and isfile(POS_FILE) then
        local ok, result = pcall(function() return HttpService:JSONDecode(readfile(POS_FILE)) end)
        if ok and type(result) == "table" and result.X and result.Y then
            return udim2New(result.X, 0, result.Y, 0)
        end
    end
    if getgenv().__KillerHub_ButtonPos then return getgenv().__KillerHub_ButtonPos end
    return udim2New(0.7, 0, 0.6, 0)
end

local function saveButtonPosition(pos)
    getgenv().__KillerHub_ButtonPos = pos
    if writefile then
        pcall(function() writefile(POS_FILE, HttpService:JSONEncode({X = pos.X.Scale, Y = pos.Y.Scale})) end)
    end
end

local VoidGui = Instance.new("ScreenGui")
VoidGui.Name = "KillerHub_SheriffGui"; VoidGui.ResetOnSpawn = false; VoidGui.Parent = game:GetService("CoreGui")
KillerHub:AddTask(VoidGui)

local btnSize = 95
if Flag("Sheriff_CustomBtnSize", false) then
    btnSize = Flag("Sheriff_BtnSize", 95)
end

local ShootButton = Instance.new("ImageButton")
ShootButton.Name = "ShootButton"
ShootButton.Size = udim2New(0, btnSize, 0, btnSize)
ShootButton.Position = loadButtonPosition()
ShootButton.BackgroundColor3 = color3RGB(15, 6, 26); ShootButton.BackgroundTransparency = 0.05
ShootButton.BorderSizePixel = 0; ShootButton.AutoButtonColor = false; ShootButton.ClipsDescendants = true; ShootButton.Parent = VoidGui

cachedScreenGui = VoidGui
cachedShootButton = ShootButton

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0.28, 0); Corner.Parent = ShootButton

local GlowOverlay = Instance.new("Frame")
GlowOverlay.Size = udim2New(1, 0, 1, 0); GlowOverlay.BackgroundTransparency = 1; GlowOverlay.ZIndex = ShootButton.ZIndex + 1; GlowOverlay.Parent = ShootButton

local GlowCorner = Instance.new("UICorner")
GlowCorner.CornerRadius = UDim.new(0.28, 0); GlowCorner.Parent = GlowOverlay

local UiGradient = Instance.new("UIGradient")
UiGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, color3RGB(24, 8, 43)), 
    ColorSequenceKeypoint.new(0.5, color3RGB(131, 46, 222)), 
    ColorSequenceKeypoint.new(1, color3RGB(24, 8, 43))
})
UiGradient.Offset = vec2New(0, 0); UiGradient.Rotation = 0; UiGradient.Parent = GlowOverlay

local tweenRot = TweenService:Create(UiGradient, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360})
tweenRot:Play()
KillerHub:AddTask(tweenRot)

DecalTexture = Instance.new("ImageLabel")
DecalTexture.Name = "CrosshairDecal"
DecalTexture.Size = udim2New(0.38, 0, 0.38, 0)
DecalTexture.AnchorPoint = vec2New(0.5, 0.5)
DecalTexture.Position = udim2New(0.5, 0, 0.44, 0)
DecalTexture.BackgroundTransparency = 1
DecalTexture.Image = "rbxassetid://125754446555599"
DecalTexture.ZIndex = ShootButton.ZIndex + 2; DecalTexture.Parent = ShootButton

local tiLoop = TweenInfo.new(0.80, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local rotAnim = TweenService:Create(DecalTexture, tiLoop, {Rotation = 360})
rotAnim:Play()
KillerHub:AddTask(rotAnim)

Label = Instance.new("TextLabel")
Label.Name = "ShootLabel"
Label.Size = udim2New(1, 0, 0.2, 0)
Label.Position = udim2New(0, 0, 0.75, 0)
Label.BackgroundTransparency = 1
Label.Text = "SHOOT"; Label.TextColor3 = color3RGB(255, 255, 255); Label.TextSize = 14; Label.Font = Enum.Font.GothamBold
Label.TextScaled = true; Label.ZIndex = ShootButton.ZIndex + 2; Label.Parent = ShootButton

local LabelConstraint = Instance.new("UITextSizeConstraint")
LabelConstraint.MaxTextSize = 15; LabelConstraint.MinTextSize = 8; LabelConstraint.Parent = Label

SubLabel = Instance.new("TextLabel")
SubLabel.Name = "SubTimerLabel"
SubLabel.Size = udim2New(1, 0, 0.18, 0)
SubLabel.Position = udim2New(0, 0, 0.74, 0)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = ""
SubLabel.TextColor3 = color3RGB(255, 255, 255)
SubLabel.TextSize = 12
SubLabel.Font = Enum.Font.GothamBold
SubLabel.TextScaled = true
SubLabel.ZIndex = ShootButton.ZIndex + 2
SubLabel.Parent = ShootButton

local SubConstraint = Instance.new("UITextSizeConstraint")
SubConstraint.MaxTextSize = 13; SubConstraint.MinTextSize = 7; SubConstraint.Parent = SubLabel

local dragging, dragInput, dragStart, startPos
KillerHub:AddTask(ShootButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(GlowOverlay, TweenInfo.new(0.01, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.02}):Play()
        task.spawn(fireAtMurdererDirectly)
        
        if not Flag("Sheriff_LockBtnPos", false) then
            dragging = true; dragStart = input.Position; startPos = ShootButton.Position
            local cChanged
            cChanged = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false 
                    cChanged:Disconnect()
                    saveButtonPosition(ShootButton.Position)
                end
            end)
        end
     end
end))

KillerHub:AddTask(ShootButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(GlowOverlay, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
        if dragging then dragging = false; saveButtonPosition(ShootButton.Position) end
    end
end))

KillerHub:AddTask(ShootButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end))

KillerHub:AddTask(UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging and not Flag("Sheriff_LockBtnPos", false) then
        local delta = input.Position - dragStart
        ShootButton.Position = udim2New(startPos.X.Scale + (delta.X / Camera.ViewportSize.X), 0, startPos.Y.Scale + (delta.Y / Camera.ViewportSize.Y), 0)
    end
end))

-- Silent Aim Hooks
local WeaponService = nil
local ClientServices = ReplicatedStorage:FindFirstChild("ClientServices") or ReplicatedStorage:FindFirstChild("Services")
if ClientServices then
    local ws = ClientServices:FindFirstChild("WeaponService") or ClientServices:FindFirstChild("GunService")
    if ws and ws:IsA("ModuleScript") then pcall(function() WeaponService = require(ws) end) end
end

if not WeaponService then
    local descendants = ReplicatedStorage:GetDescendants()
    for i = 1, #descendants do
        local obj = descendants[i]
        if obj:IsA("ModuleScript") then
            local n = obj.Name:lower()
            if n:find("weapon") or n:find("gun") or n:find("shoot") or n:find("tool") then
                local success, mod = pcall(require, obj)
                if success and type(mod) == "table" and (mod.GetTargetPosition or mod.GetMouseTargetCFrame) then
                    WeaponService = mod
                    break
                end
            end
        end
    end
end

if WeaponService then
    local oldGetTargetPosition = WeaponService.GetTargetPosition
    local oldGetMouseTargetCFrame = WeaponService.GetMouseTargetCFrame
    local lastHookCallTime = os_clock()
    local frameCachedTime = 0
    local frameCachedCF = nil

    local function getPredictedTargetCFrame(customDelta)
        local currentTime = os_clock()
        if currentTime == frameCachedTime then return frameCachedCF end

        local silentAim = Flag("Sheriff_SilentAim", false)
        if not silentAim then frameCachedTime = currentTime; frameCachedCF = nil; return nil end

        local shotType = Flag("Sheriff_ShotType", "Normal")
        local useDetect = Flag("Sheriff_WeaponDetect", false)

        local gun, _ = getGunLocation()
        if useDetect and not gun then frameCachedTime = currentTime; frameCachedCF = nil; return nil end

        local murderer = getMurdererCached()
        if not murderer or not murderer.Character then frameCachedTime = currentTime; frameCachedCF = nil; return nil end

        local bestPart, isBlocked = getSmartTargetPart(murderer.Character)
        if not bestPart or (isBlocked and shotType ~= "Piercer Bullet") then 
            frameCachedTime = currentTime; frameCachedCF = nil; return nil 
        end

        local dt = customDelta or math_clamp(currentTime - lastHookCallTime, 0.008, 0.033)
        lastHookCallTime = currentTime

        local finalPredictedPos = getPredictedPosition(murderer.Character, bestPart, dt)
        frameCachedCF = finalPredictedPos and cframeNew(finalPredictedPos) or nil
        frameCachedTime = currentTime
        return frameCachedCF
    end

    if oldGetTargetPosition then
        WeaponService.GetTargetPosition = function(self, ...)
            local targetCF = getPredictedTargetCFrame()
            return targetCF or oldGetTargetPosition(self, ...)
        end
    end

    if oldGetMouseTargetCFrame then
        WeaponService.GetMouseTargetCFrame = function(self, ...)
            local targetCF = getPredictedTargetCFrame()
            return targetCF or oldGetMouseTargetCFrame(self, ...)
        end
    end
end

-- ============================================================================
-- 🚀 MÓDULO EXTRA (FLICK & TARGET SELECTION)
-- ============================================================================
task.spawn(function()
    task.wait(0.1)

    local TabSheriffObj = KillerHub:GetTab("Sheriff")
    local PageOthersObj = TabSheriffObj and TabSheriffObj:GetPage("Others")
    if not PageOthersObj then return end

    PageOthersObj:CreateSection("Flick Shoot Suite")
    PageOthersObj:CreateToggle("Sheriff_FlickShoot", "Flick Shoot", function() end)
    PageOthersObj:CreateToggle("Sheriff_AutoShiftLock", "Auto Shift Lock", function() end)

    local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts", 2)
    local PlayerModule = PlayerScripts and PlayerScripts:FindFirstChild("PlayerModule")

    local function isShiftLockEnabled()
        if PlayerModule then
            local success, cameraModule = pcall(function() return require(PlayerModule).cameras end)
            if success and cameraModule and cameraModule.activeMouseLockController then
                return cameraModule.activeMouseLockController.isMouseLocked == true
            end
        end
        return UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
    end

    local function forceEnableShiftLock()
        if PlayerModule then
            local success, cameraModule = pcall(function() return require(PlayerModule).cameras end)
            if success and cameraModule and cameraModule.activeMouseLockController then
                if not cameraModule.activeMouseLockController.isMouseLocked then
                    cameraModule.activeMouseLockController:OnMouseLockToggled()
                end
            end
        end
    end

    local isFlicking = false
    local function performFlickAnimation(targetPos)
        if isFlicking then return end

        if Flag("Sheriff_AutoShiftLock", false) then
            forceEnableShiftLock()
        end

        if not isShiftLockEnabled() then return end

        isFlicking = true
        local originalCamCF = Camera.CFrame
        local targetCamCF = cframeNew(Camera.CFrame.Position, targetPos)

        local flickInTween = TweenService:Create(Camera, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = targetCamCF
        })
        flickInTween:Play()
        flickInTween.Completed:Wait()

        local flickOutTween = TweenService:Create(Camera, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            CFrame = originalCamCF
        })
        flickOutTween:Play()
        flickOutTween.Completed:Wait()

        isFlicking = false
    end

    local baseExecuteShoot = executeActualShoot
    executeActualShoot = function(targetChar, bestPart)
        if Flag("Sheriff_FlickShoot", false) and targetChar and bestPart then
            local targetPos = bestPart.Position
            task.spawn(function()
                performFlickAnimation(targetPos)
            end)
        end
        return baseExecuteShoot(targetChar, bestPart)
    end

    PageOthersObj:CreateSection("Target Selection")
    
    local customTargetEnabled = false
    local selectedPlayerName = "None"
    local cachedTargetPlayer = nil
    local lastTargetCheck = 0

    PageOthersObj:CreateToggle("Sheriff_ShootPlayers", "Shoot Players", function(estado)
        customTargetEnabled = estado
        if not estado then cachedTargetPlayer = nil end
    end, false)

    local targetDropdown = PageOthersObj:CreateDropdown("Sheriff_SelectedPlayer", "Select Player Target", {"None"}, function(sel)
        selectedPlayerName = sel
        cachedTargetPlayer = (sel ~= "None") and Players:FindFirstChild(sel) or nil
    end, "None")

    targetDropdown:BindToDynamicList(function()
        local list = {"None"}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(list, p.Name)
            end
        end
        return list
    end, 3)

    Players.PlayerRemoving:Connect(function(plr)
        if plr.Name == selectedPlayerName then
            selectedPlayerName = "None"
            cachedTargetPlayer = nil
        end
    end)

    local baseGetMurderer = getMurderer
    getMurderer = function()
        if customTargetEnabled and selectedPlayerName ~= "None" then
            local now = os_clock()
            
            if not cachedTargetPlayer or not cachedTargetPlayer.Parent or (now - lastTargetCheck > 0.1) then
                lastTargetCheck = now
                cachedTargetPlayer = Players:FindFirstChild(selectedPlayerName)
            end

            if cachedTargetPlayer then
                local char = cachedTargetPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local isDead = (hum and hum.Health <= 0) or (playerDeadStatus[selectedPlayerName] == true)

                    if not isDead and hrp then
                        setTarget(cachedTargetPlayer)
                        return cachedTargetPlayer
                    end
                end
            end
        end

        return baseGetMurderer()
    end
end)

return KillerHub
