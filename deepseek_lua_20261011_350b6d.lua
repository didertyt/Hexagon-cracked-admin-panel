-- ============================================================
-- HEXAGON X (rewritten version)
-- ============================================================

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local jobId = game.JobId

-- ==================== STATE ====================
local state = {
    jailedPlayers = {},
    nametags = {},
    loopSit = {},
    loopKill = {},
    kamui = {
        Active = false,
        ThroneActive = false,
        ThroneModel = nil,
        OriginalCFrame = nil,
        Sound = nil,
        Player = nil,
        WalkSpeed = 0,
        JumpPower = 0,
        Gui = nil,
        Dimension = nil,
    },
}

-- ==================== WEBSOCKET / ADMIN CHANNEL ====================
local Net = {
    socket = nil,
    connected = false,
    remoteSend = nil,
    remoteGlobal = nil,
}

local function connectWebSocket()
    local ok, socket = pcall(function()
        return WebSocket.connect(
            "wss://free.blr2.piesocket.com/v3/1?api_key=oBXJCb6LQIqh1XuNUTqh2nUv0FmGKCypgzsFX5VO&notify_self=1"
        )
    end)
    if ok and socket then
        Net.socket = socket
        Net.connected = true
    else
        warn("[HEXAGON] WebSocket connection failed")
        Net.connected = false
    end
end

local function parseIncoming(raw)
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not ok then return nil end

    if decoded.type == "ch" then
        return decoded, decoded.message or ""
    elseif decoded.global then
        return decoded, string.lower(decoded.global)
    else
        return decoded
    end
end

local function sendChat(target, message)
    if not Net.socket or not Net.connected then return end
    Net.socket:Send(HttpService:JSONEncode({
        type = "ch",
        target = target,
        message = message,
        jobid = jobId,
    }))
end

local function sendCommand(command, payload)
    if not Net.socket or not Net.connected then return end
    local full = command
    if payload and payload ~= "" then
        full = command .. ":" .. LocalPlayer.Name .. ":" .. payload
    end
    Net.socket:Send(HttpService:JSONEncode({ command = full, jobid = jobId }))
    Net.remoteSend = true
end

local function sendGlobal(command, extraFields)
    if not Net.socket or not Net.connected then return end
    local packet = { global = command, sender = LocalPlayer.Name }
    if extraFields then
        for k, v in pairs(extraFields) do
            packet[k] = v
        end
    end
    Net.socket:Send(HttpService:JSONEncode(packet))
    Net.remoteGlobal = true
end

local function verifySession()
    if Net.socket and Net.connected then
        Net.socket:Send(HttpService:JSONEncode({ jobid = jobId, user = LocalPlayer.Name }))
    end
end

local function getSelfSender()
    return LocalPlayer.Name .. ":" .. game.JobId .. ":" .. game.PlaceId
end

-- ==================== UTILITIES ====================
local function getPlayer(name)
    if not name or name == "" then return nil end
    local lower = tostring(name):lower()
    if lower == LocalPlayer.Name:lower() then return LocalPlayer end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower() == lower then
            return plr
        end
    end
    return nil
end

--- Returns array of player NAMES (strings) — required by WindUI Dropdown
local function getPlayerNames()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    if #names == 0 then
        table.insert(names, "None")
    end
    return names
end

-- ==================== NAMETAG ====================
local function createNametag(plr, text)
    local char = plr.Character
    if not char then return end
    if char:FindFirstChild("HexagonNametag") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HexagonNametag"
    billboard.Size = UDim2.new(0, 180, 0, 70)
    billboard.StudsOffset = Vector3.new(0, 4.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 100
    billboard.Parent = char

    local thumb = Instance.new("ImageLabel")
    thumb.Name = "Thumbnail"
    thumb.Size = UDim2.new(0.187, 0, 0.44, 0)
    thumb.Position = UDim2.new(0.5, 0, 0.22, 0)
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.BackgroundTransparency = 1
    thumb.Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=100&h=100"
    thumb.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = thumb

    local nameTxt = Instance.new("TextLabel")
    nameTxt.Name = "NameTxt"
    nameTxt.Size = UDim2.new(1, 0, 0.273, 0)
    nameTxt.Position = UDim2.new(0, 0, 0.446, 0)
    nameTxt.BackgroundTransparency = 1
    nameTxt.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
    nameTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameTxt.TextScaled = true
    nameTxt.Font = Enum.Font.FredokaOne
    nameTxt.TextWrapped = true
    nameTxt.Parent = billboard

    local sizeConstraint = Instance.new("UITextSizeConstraint")
    sizeConstraint.MaxTextSize = 98
    sizeConstraint.Parent = nameTxt

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Parent = nameTxt

    local tag = Instance.new("TextLabel")
    tag.Name = "Tag"
    tag.Size = UDim2.new(1, 0, 0.246, 0)
    tag.Position = UDim2.new(0, 0, 0.8, 0)
    tag.BackgroundTransparency = 1
    tag.Text = text or "User"
    tag.TextColor3 = Color3.fromRGB(255, 255, 255)
    tag.TextScaled = true
    tag.Font = Enum.Font.FredokaOne
    tag.TextWrapped = true
    tag.Parent = billboard

    local tagSize = Instance.new("UITextSizeConstraint")
    tagSize.MaxTextSize = 74
    tagSize.Parent = tag

    local tagStroke = Instance.new("UIStroke")
    tagStroke.Color = Color3.fromRGB(99, 99, 99)
    tagStroke.Thickness = 1.5
    tagStroke.Parent = tag

    local gradient = Instance.new("UIGradient")
    gradient.Name = "NametagGradient"
    gradient.Rotation = 60
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(113, 113, 113)),
    })
    gradient.Parent = tag

    state.nametags[plr.Name] = true
end

-- ==================== BASIC COMMANDS ====================
local Commands = {}

function Commands.kick(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr then return false end
    return true
end

function Commands.kill(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr then return false end
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        return true
    end
    return false
end

function Commands.loopkill(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr then return false end
    state.loopKill[targetName] = true
    return true
end

function Commands.unloopkill(sender, targetName)
    if not getPlayer(targetName) then return false end
    state.loopKill[targetName] = nil
    return true
end

function Commands.bring(sender, targetName)
    local senderPlr = getPlayer(sender)
    local targetPlr = getPlayer(targetName)
    if not senderPlr or not targetPlr then return false end
    local myRoot = senderPlr.Character and senderPlr.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and targetRoot then
        targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 2, 0)
        return true
    end
    return false
end

function Commands.freeze(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr or not plr.Character then return false end
    for _, part in ipairs(plr.Character:GetChildren()) do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end
    return true
end

function Commands.unfreeze(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr or not plr.Character then return false end
    for _, part in ipairs(plr.Character:GetChildren()) do
        if part:IsA("BasePart") then
            part.Anchored = false
        end
    end
    return true
end

function Commands.loopsit(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr then return false end
    state.loopSit[plr.Name] = true
    return true
end

function Commands.unloopsit(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr then return false end
    state.loopSit[plr.Name] = nil
    return true
end

function Commands.jail(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr then return false end
    local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return false end

    local cageName = plr.Name .. "_Jail"
    local existing = Workspace:FindFirstChild(cageName)
    if existing then existing:Destroy() end

    local model = Instance.new("Model")
    model.Name = cageName
    model.Parent = Workspace

    local function createPart(position, size)
        local part = Instance.new("Part")
        part.Size = size
        part.Anchored = true
        part.CanCollide = true
        part.Material = Enum.Material.ForceField
        part.Color = Color3.fromRGB(255, 0, 0)
        part.Transparency = 0.3
        part.CFrame = CFrame.new(position)
        part.Parent = model

        local light = Instance.new("SurfaceLight")
        light.Face = Enum.NormalId.Top
        light.Range = 10
        light.Brightness = 2
        light.Color = Color3.fromRGB(75, 0, 130)
        light.Parent = part
    end

    local basePos = root.Position
    createPart(basePos + Vector3.new(0, 4, 0), Vector3.new(8, 1, 8))
    createPart(basePos + Vector3.new(0, -4, 0), Vector3.new(8, 1, 8))
    createPart(basePos + Vector3.new(4, 0, 0), Vector3.new(1, 8, 8))
    createPart(basePos + Vector3.new(-4, 0, 0), Vector3.new(1, 8, 8))
    createPart(basePos + Vector3.new(0, 0, 4), Vector3.new(8, 8, 1))
    createPart(basePos + Vector3.new(0, 0, -4), Vector3.new(8, 8, 1))

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not model.Parent or not root.Parent or not hum.Parent then
            conn:Disconnect()
            state.jailedPlayers[plr.Name] = nil
            return
        end
        local box = model:GetBoundingBox()
        if (root.Position - box.Position).Magnitude > 4 or hum.WalkSpeed > 16 or hum.PlatformStand then
            root.CFrame = CFrame.new(box.Position)
            root.Velocity = Vector3.new(0, 0, 0)
        end
    end)

    state.jailedPlayers[plr.Name] = {loop = conn, cageName = cageName}
    return true
end

function Commands.unjail(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr then return false end
    local cage = Workspace:FindFirstChild(plr.Name .. "_Jail")
    if not cage then return false end
    cage:Destroy()
    local data = state.jailedPlayers[plr.Name]
    if data and data.loop then data.loop:Disconnect() end
    state.jailedPlayers[plr.Name] = nil
    return true
end

function Commands.ragdoll(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr or not plr.Character then return false end
    local char = plr.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    if char:GetAttribute("IsRagdolled") then return false end

    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("Motor6D") then
            local p0, p1 = obj.Part0, obj.Part1
            local c0, c1 = obj.C0, obj.C1
            obj.Enabled = false

            if p0 and p1 then
                local a0 = Instance.new("Attachment")
                a0.CFrame = c0
                a0.Parent = p0
                local a1 = Instance.new("Attachment")
                a1.CFrame = c1
                a1.Parent = p1

                local ball = Instance.new("BallSocketConstraint")
                ball.Attachment0 = a0
                ball.Attachment1 = a1
                ball.LimitsEnabled = true
                ball.TwistLimitsEnabled = true
                ball.UpperAngle = 45
                ball.TwistLowerAngle = -45
                ball.TwistUpperAngle = 45
                ball.Parent = p0

                local noCol = Instance.new("NoCollisionConstraint")
                noCol.Part0 = p0
                noCol.Part1 = p1
                noCol.Parent = p0
            end
        end
    end

    hum.PlatformStand = true
    char:SetAttribute("IsRagdolled", true)
    return true
end

function Commands.unragdoll(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr or not plr.Character then return false end
    local char = plr.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not char:GetAttribute("IsRagdolled") then return false end

    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BallSocketConstraint") or obj:IsA("NoCollisionConstraint") then
            obj:Destroy()
        end
    end

    hum.PlatformStand = false
    char:SetAttribute("IsRagdolled", false)
    return true
end

function Commands.backrooms(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr or not plr.Character then return false end
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(59.06, 9996.7, 19.42)
        return true
    end
    return false
end

function Commands.unbackrooms(sender, targetName)
    return true
end

function Commands.lightning(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end

    hum.Health = 0
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new((math.random() - 0.5) * 300, 350, (math.random() - 0.5) * 300)
    bv.Parent = root

    Debris:AddItem(bv, 0.5)
    return true
end

function Commands.crash(sender, targetName)
    if not getPlayer(targetName) then return false end
    for i = 1, 1000 do
        local p = Instance.new("Part")
        p.Parent = Workspace
    end
    return true
end

-- ==================== KAMUI / SPECIAL ====================
local function createKamuiDimension()
    local origin = Vector3.new(0, 1000000, 0)
    local folder = Instance.new("Folder")
    folder.Name = "KamuiDimension"
    folder.Parent = Workspace

    local floor = Instance.new("Part")
    floor.Size = Vector3.new(300, 1, 300)
    floor.Anchored = true
    floor.Position = origin
    floor.Color = Color3.new(0, 0, 0)
    floor.Material = Enum.Material.SmoothPlastic
    floor.Parent = folder

    local walls = {
        {Vector3.new(150, 75, 0), Vector3.new(1, 150, 300)},
        {Vector3.new(-150, 75, 0), Vector3.new(1, 150, 300)},
        {Vector3.new(0, 75, 150), Vector3.new(300, 150, 1)},
        {Vector3.new(0, 75, -150), Vector3.new(300, 150, 1)},
    }
    for _, w in ipairs(walls) do
        local part = Instance.new("Part")
        part.Position = origin + w[1]
        part.Size = w[2]
        part.Anchored = true
        part.Color = Color3.new(0, 0, 0)
        part.Material = Enum.Material.SmoothPlastic
        part.Parent = folder
    end

    local ceiling = Instance.new("Part")
    ceiling.Size = Vector3.new(300, 1, 300)
    ceiling.Position = origin + Vector3.new(0, 150, 0)
    ceiling.Anchored = true
    ceiling.Color = Color3.new(0, 0, 0)
    ceiling.Material = Enum.Material.SmoothPlastic
    ceiling.Parent = folder

    local spawnPoint = nil
    for i = 1, 130 do
        local part = Instance.new("Part")
        part.Anchored = true
        part.Material = Enum.Material.SmoothPlastic
        part.Color = Color3.new(1, 1, 1)
        if i == 1 then
            part.Size = Vector3.new(30, 25, 30)
            part.Position = origin
        else
            part.Size = Vector3.new(math.random(10, 20), math.random(18, 30), math.random(10, 20))
            part.Position = origin + Vector3.new(math.random(-142, 142), part.Size.Y / 2, math.random(-142, 142))
        end
        part.Parent = folder

        local light = Instance.new("PointLight")
        light.Brightness = 2
        light.Range = 18
        light.Color = Color3.new(1, 1, 1)
        light.Parent = part

        if i == 1 then
            spawnPoint = part.Position + Vector3.new(0, part.Size.Y / 2 + 3, 0)
        end
    end

    return folder, spawnPoint
end

function Commands.kamui(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr or not plr.Character then return false end
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    state.kamui.Player = plr
    state.kamui.OriginalCFrame = root.CFrame

    local dim, spawn = createKamuiDimension()
    state.kamui.Dimension = dim

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://9039981149"
    sound.Looped = true
    sound.Volume = 0.5
    sound.Parent = root
    state.kamui.Sound = sound

    if spawn then
        root.CFrame = CFrame.new(spawn)
    end
    state.kamui.Active = true
    return true
end

function Commands.unkamui(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr or not plr.Character then return false end
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    if state.kamui.OriginalCFrame then
        root.CFrame = state.kamui.OriginalCFrame
    end
    if state.kamui.Sound then
        state.kamui.Sound:Destroy()
        state.kamui.Sound = nil
    end
    if state.kamui.Dimension then
        state.kamui.Dimension:Destroy()
        state.kamui.Dimension = nil
    end
    state.kamui.Active = false
    return true
end

function Commands.kamuitrhone(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end

    state.kamui.WalkSpeed = hum.WalkSpeed
    state.kamui.JumpPower = hum.JumpPower

    if state.kamui.ThroneModel then
        state.kamui.ThroneModel:Destroy()
    end

    local throne = Instance.new("Model")
    throne.Name = "KamuiThrone"

    local color = Color3.fromRGB(35, 35, 35)
    local baseCF = root.CFrame * CFrame.Angles(0, math.rad(180), 0)

    local seat = Instance.new("Seat")
    seat.Name = "ThroneSeat"
    seat.Size = Vector3.new(4, 2, 4)
    seat.Anchored = true
    seat.Color = color
    seat.Material = Enum.Material.Slate
    seat.CFrame = baseCF * CFrame.new(0, -2.5, 0)
    seat.Parent = throne

    local back = Instance.new("Part")
    back.Size = Vector3.new(4, 7, 1.5)
    back.Anchored = true
    back.Color = color
    back.Material = Enum.Material.Slate
    back.CFrame = seat.CFrame * CFrame.new(0, 4, -1.75)
    back.Parent = throne

    for _, x in ipairs({-2, 2}) do
        local arm = Instance.new("Part")
        arm.Size = Vector3.new(1.5, 3.5, 4)
        arm.Anchored = true
        arm.Color = color
        arm.Material = Enum.Material.Slate
        arm.CFrame = seat.CFrame * CFrame.new(x, 1.5, 0)
        arm.Parent = throne
    end

    for _, x in ipairs({-1.8, 1.8}) do
        local spike = Instance.new("Part")
        spike.Size = Vector3.new(1.5, 3, 1.5)
        spike.Anchored = true
        spike.Color = Color3.fromRGB(25, 25, 25)
        spike.Material = Enum.Material.Slate
        spike.CFrame = back.CFrame * CFrame.new(x, 4, 0)
        spike.Parent = throne
    end

    throne.Parent = Workspace
    state.kamui.ThroneModel = throne

    hum.WalkSpeed = 0
    hum.JumpPower = 0
    hum.Sit = true
    state.kamui.ThroneActive = true

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://7437785043"
    sound.Volume = 1
    sound.Parent = root
    return true
end

function Commands.unkamuitrhone(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = state.kamui.WalkSpeed
        hum.JumpPower = state.kamui.JumpPower
        hum.Sit = false
    end
    if state.kamui.ThroneModel then
        state.kamui.ThroneModel:Destroy()
        state.kamui.ThroneModel = nil
    end
    state.kamui.ThroneActive = false
    return true
end

function Commands.domainexpansion(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr or not plr.Character then return false end
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local oldLighting = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        FogColor = Lighting.FogColor,
        ClockTime = Lighting.ClockTime,
        ShadowSoftness = Lighting.ShadowSoftness,
    }

    root.CFrame = CFrame.new(Vector3.new(5000, 100, 5000))

    Lighting.Brightness = 0.3
    Lighting.ClockTime = 0
    Lighting.ShadowSoftness = 1
    Lighting.Ambient = Color3.fromRGB(60, 0, 0)
    Lighting.OutdoorAmbient = Color3.fromRGB(40, 0, 0)
    Lighting.FogStart = 5
    Lighting.FogEnd = 60
    Lighting.FogColor = Color3.fromRGB(5, 0, 0)

    local sky = Instance.new("Sky")
    sky.SkyboxBk = "rbxassetid://6444884337"
    sky.SkyboxDn = "rbxassetid://6444884337"
    sky.SkyboxFt = "rbxassetid://6444884337"
    sky.SkyboxLf = "rbxassetid://6444884337"
    sky.SkyboxRt = "rbxassetid://6444884337"
    sky.SkyboxUp = "rbxassetid://6444884337"
    sky.Parent = Lighting

    local atmo = Instance.new("Atmosphere")
    atmo.Density = 1
    atmo.Offset = 0
    atmo.Color = Color3.fromRGB(30, 0, 0)
    atmo.Decay = Color3.fromRGB(10, 0, 0)
    atmo.Glare = 0
    atmo.Haze = 2.3
    atmo.Parent = Lighting

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Brightness = -0.04
    cc.Contrast = 0.3
    cc.Saturation = -0.6
    cc.TintColor = Color3.fromRGB(255, 80, 80)
    cc.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 0.6
    bloom.Size = 24
    bloom.Threshold = 0.8
    bloom.Parent = Lighting

    local ground = Instance.new("Part")
    ground.Size = Vector3.new(300, 1, 300)
    ground.Anchored = true
    ground.CanCollide = true
    ground.Material = Enum.Material.SmoothPlastic
    ground.Color = Color3.fromRGB(10, 3, 3)
    ground.CFrame = CFrame.new(root.Position - Vector3.new(0, 3, 0))
    ground.Parent = Workspace

    local tex = Instance.new("Texture")
    tex.Texture = "rbxassetid://74258839"
    tex.Color3 = Color3.fromRGB(80, 0, 0)
    tex.Transparency = 0.85
    tex.StudsPerTileU = 6
    tex.StudsPerTileV = 6
    tex.Face = Enum.NormalId.Top
    tex.Parent = ground

    local orb = Instance.new("Part")
    orb.Shape = Enum.PartType.Ball
    orb.Size = Vector3.new(1, 1, 1)
    orb.Anchored = true
    orb.CanCollide = false
    orb.CastShadow = false
    orb.Material = Enum.Material.SmoothPlastic
    orb.Color = Color3.new(0, 0, 0)
    orb.Transparency = 0
    orb.Position = root.Position
    orb.Parent = Workspace

    local sphere = Instance.new("Part")
    sphere.Shape = Enum.PartType.Ball
    sphere.Size = Vector3.new(1, 1, 1)
    sphere.Anchored = true
    sphere.CanCollide = false
    sphere.CastShadow = false
    sphere.Material = Enum.Material.Neon
    sphere.Color = Color3.fromRGB(120, 0, 0)
    sphere.Transparency = 0.92
    sphere.Position = root.Position
    sphere.Parent = Workspace

    local ok, models = pcall(function()
        return game:GetObjects("rbxassetid://16639433873")
    end)
    if ok and models and #models > 0 then
        local shrine = models[1]
        shrine.Parent = Workspace
        if shrine.PrimaryPart then
            shrine:PivotTo(CFrame.lookAt(root.Position + Vector3.new(0, 0, 20), root.Position))
        end
    end

    local emitterPart = Instance.new("Part")
    emitterPart.Size = Vector3.new(1, 1, 1)
    emitterPart.Anchored = true
    emitterPart.CanCollide = false
    emitterPart.Transparency = 1
    emitterPart.Position = root.Position + Vector3.new(0, 2, 0)
    emitterPart.Parent = Workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 0, 0)),
    })
    emitter.LightEmission = 0.3
    emitter.LightInfluence = 0.8
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Lifetime = NumberRange.new(3, 6)
    emitter.Rate = 60
    emitter.Speed = NumberRange.new(2, 8)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.RotSpeed = NumberRange.new(-45, 45)
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.Parent = emitterPart

    task.delay(15, function()
        if sky then sky:Destroy() end
        if atmo then atmo:Destroy() end
        if cc then cc:Destroy() end
        if bloom then bloom:Destroy() end
        if ground then ground:Destroy() end
        if orb then orb:Destroy() end
        if sphere then sphere:Destroy() end
        if emitterPart then emitterPart:Destroy() end
        Lighting.Brightness = oldLighting.Brightness
        Lighting.Ambient = oldLighting.Ambient
        Lighting.OutdoorAmbient = oldLighting.OutdoorAmbient
        Lighting.FogEnd = oldLighting.FogEnd
        Lighting.FogStart = oldLighting.FogStart
        Lighting.FogColor = oldLighting.FogColor
        Lighting.ClockTime = oldLighting.ClockTime
        Lighting.ShadowSoftness = oldLighting.ShadowSoftness
    end)

    return true
end

function Commands.lostmemories(sender, targetName)
    local plr = getPlayer(targetName)
    if not plr then return false end

    local oldBrightness = Lighting.Brightness
    local oldClock = Lighting.ClockTime
    local oldFogEnd = Lighting.FogEnd
    local oldFogColor = Lighting.FogColor

    Lighting.Brightness = 0
    Lighting.ClockTime = 0
    Lighting.FogEnd = 25
    Lighting.FogColor = Color3.new(0, 0, 0)

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Parent = Lighting
    cc.Saturation = -0.8
    cc.Contrast = 0.3
    cc.TintColor = Color3.fromRGB(150, 150, 180)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://125711629811786"
    sound.Looped = true
    sound.Volume = 1
    sound.Parent = SoundService

    local gui = Instance.new("ScreenGui")
    gui.Name = "LostMemoriesGui"
    gui.ResetOnSpawn = false
    gui.Parent = plr:FindFirstChild("PlayerGui") or CoreGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Position = UDim2.new(0, 0, 0.9, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SpecialElite
    label.TextSize = 22
    label.Text = "It is 300 blocks away from You"
    label.Parent = gui

    for i = 300, 0, -1 do
        if not label.Parent then break end
        label.Text = "It is " .. i .. " blocks away from You"
        if i <= 60 then
            label.TextColor3 = Color3.new(1, 0, 0)
        end
        task.wait(0.05)
    end

    local scareGui = Instance.new("ScreenGui")
    scareGui.IgnoreGuiInset = true
    scareGui.DisplayOrder = 999999
    scareGui.Parent = plr:FindFirstChild("PlayerGui") or CoreGui

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(1, 0, 1, 0)
    img.Image = "rbxassetid://135710059856776"
    img.Parent = scareGui

    local scareSound = Instance.new("Sound")
    scareSound.SoundId = "rbxassetid://137120797573299"
    scareSound.Volume = 5
    scareSound.Parent = img

    task.wait(3)
    gui:Destroy()
    scareGui:Destroy()
    sound:Destroy()
    cc:Destroy()

    Lighting.Brightness = oldBrightness
    Lighting.ClockTime = oldClock
    Lighting.FogEnd = oldFogEnd
    Lighting.FogColor = oldFogColor

    return true
end

-- ==================== GLOBAL ADMIN COMMANDS ====================
local function joinAllHandler(packet)
    local sender = packet.sender or ""
    local placeId, targetJobId, code = sender:match("^([^:]+):([^:]+):([^:]+)$")

    local bindable = Instance.new("BindableFunction")
    bindable.OnInvoke = function(action)
        if action == "Teleport" then
            game:GetService("TeleportService"):TeleportToPlaceInstance(
                tonumber(placeId),
                targetJobId,
                LocalPlayer
            )
        end
    end

    return packet, sender, placeId, targetJobId, code, bindable
end

local function announceHandler(packet)
    local message = packet.message or "No message"
    local sender = packet.sender or "Unknown"
    return packet, sender, message
end

-- ==================== UI ====================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/nxvap/windui/main/1.6.61.lua"))()

local Window = WindUI:CreateWindow({
    Title = "HEXAGON X ( Premium )",
    Author = "Admin * " .. LocalPlayer.DisplayName,
    Icon = "rbxassetid://91852397255207",
    Background = "rbxassetid://102266309145667",
    BackgroundImageTransparency = 0.48,
    Size = UDim2.fromOffset(550, 430),
    Transparent = true,
    Theme = "Indigo",
    HideSearchBar = false,
    SideBarWidth = 200,
    HasOutline = true,
    User = {Enabled = true},
    OpenButton = {
        Title = "Hexagon",
        Icon = "rbxassetid://91852397255207",
        CornerRadius = UDim.new(0, 15),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        Color = ColorSequence.new(Color3.fromHex("6A11CB"), Color3.fromHex("2575FC")),
    },
    NewElements = true,
})

local TabGeneral = Window:Tab({Title = "General", Icon = "crown"})
local TabSpecial = Window:Tab({Title = "Special", Icon = "sparkles"})
local TabJumps   = Window:Tab({Title = "Jumps", Icon = "skull"})
local TabGlobal  = Window:Tab({Title = "Global", Icon = "globe"})
local TabBrook   = Window:Tab({Title = "Brookhaven", Icon = "star"})

local SecGeneral = TabGeneral:Section({Title = "Commands", Icon = "terminal", Opened = true})
local SecSpecial = TabSpecial:Section({Title = "Commands", Icon = "terminal", Opened = true})
local SecJumps   = TabJumps:Section({Title = "Commands", Icon = "terminal", Opened = true})
local SecGlobal  = TabGlobal:Section({Title = "Commands", Icon = "terminal", Opened = true})
local SecBrook   = TabBrook:Section({Title = "Addons", Icon = "star", Opened = true})

-- ==================== TARGET DROPDOWNS ====================
-- selectedTargets is a shared object ref, updated by all dropdowns
local targetRef = { value = nil }

local function setTarget(name)
    targetRef.value = getPlayer(name)
end

local targetDropdown = SecGeneral:Dropdown({
    Title = "Select Player",
    Values = getPlayerNames(),
    Value = getPlayerNames()[1],
    Callback = function(v) setTarget(v) end,
})

local specialTarget = SecSpecial:Dropdown({
    Title = "Select Target",
    Values = getPlayerNames(),
    Value = getPlayerNames()[1],
    Callback = function(v) setTarget(v) end,
})

local jumpsTarget = SecJumps:Dropdown({
    Title = "Select Target",
    Values = getPlayerNames(),
    Value = getPlayerNames()[1],
    Callback = function(v) setTarget(v) end,
})

local globalTarget = SecGlobal:Dropdown({
    Title = "Select Target",
    Values = getPlayerNames(),
    Value = getPlayerNames()[1],
    Callback = function(v) setTarget(v) end,
})

-- ==================== GENERAL TAB ====================
local generalCommands = {
    {name = "verify",         needsTarget = false, desc = "Verify server users"},
    {name = "kick",           needsTarget = true,  desc = "Kick a player"},
    {name = "kill",           needsTarget = true,  desc = "Instantly kill a player"},
    {name = "loopkill",       needsTarget = true,  desc = "Repeatedly kill a player"},
    {name = "unloopkill",     needsTarget = true,  desc = "Stop loopkill"},
    {name = "bring",          needsTarget = true,  desc = "Bring a player to you"},
    {name = "jail",           needsTarget = true,  desc = "Trap in a red forcefield cage"},
    {name = "unjail",         needsTarget = true,  desc = "Release from cage"},
    {name = "freeze",         needsTarget = true,  desc = "Freeze player in place"},
    {name = "unfreeze",       needsTarget = true,  desc = "Unfreeze player"},
    {name = "loopsit",        needsTarget = true,  desc = "Force player to sit"},
    {name = "unloopsit",      needsTarget = true,  desc = "Stop forced sitting"},
    {name = "ragdoll",        needsTarget = true,  desc = "Ragdoll a player"},
    {name = "unragdoll",      needsTarget = true,  desc = "Unragdoll a player"},
    {name = "backrooms",      needsTarget = true,  desc = "Send player to Backrooms"},
    {name = "unbackrooms",    needsTarget = false, desc = "Remove Backrooms map"},
    {name = "lightning",      needsTarget = true,  desc = "Strike player with lightning"},
    {name = "crash",          needsTarget = true,  desc = "Crash the player game"},
}

for _, cmd in ipairs(generalCommands) do
    local c = cmd
    SecGeneral:Button({
        Title = c.name:upper(),
        Desc = c.desc,
        Icon = "chevron-right",
        Callback = function()
            if c.needsTarget and not targetRef.value then return end
            local targetName = targetRef.value and targetRef.value.Name or nil
            if Commands[c.name] then
                Commands[c.name](LocalPlayer.Name, targetName)
            end
            sendCommand(c.name, targetName or "")
        end,
    })
end

-- ==================== SPECIAL TAB ====================
local specialCommands = {
    {name = "domainexpansion", needsTarget = true, desc = "Jujutsu Kaisen Domain"},
    {name = "kamui",           needsTarget = true, desc = "Enter Kamui dimension"},
    {name = "unkamui",         needsTarget = true, desc = "Leave Kamui dimension"},
    {name = "kamuitrhone",     needsTarget = true, desc = "Activate throne"},
    {name = "unkamuitrhone",   needsTarget = true, desc = "Deactivate throne"},
}

for _, cmd in ipairs(specialCommands) do
    local c = cmd
    SecSpecial:Button({
        Title = c.name:upper(),
        Desc = c.desc,
        Icon = "chevron-right",
        Callback = function()
            if c.needsTarget and not targetRef.value then return end
            local targetName = targetRef.value and targetRef.value.Name or nil
            if Commands[c.name] then
                Commands[c.name](LocalPlayer.Name, targetName)
            end
            sendCommand(c.name, targetName or "")
        end,
    })
end

-- ==================== JUMPS TAB ====================
SecJumps:Button({
    Title = "LOSTMEMORIES",
    Desc = "Lost Memories jumpscare",
    Icon = "chevron-right",
    Callback = function()
        if targetRef.value then
            Commands.lostmemories(LocalPlayer.Name, targetRef.value.Name)
            sendCommand("lostmemories", targetRef.value.Name)
        end
    end,
})

-- ==================== GLOBAL TAB ====================
SecGlobal:Button({
    Title = "JOIN ALL",
    Desc = "Force all Hexagon users to join your server",
    Icon = "chevron-right",
    Callback = function()
        sendGlobal("joinall", { sender = getSelfSender() })
    end,
})

SecGlobal:Button({
    Title = "ANNOUNCE",
    Desc = "Send a global announcement to all Hexagon users",
    Icon = "chevron-right",
    Callback = function()
        sendGlobal("announce", { message = "Announcement from " .. LocalPlayer.Name })
    end,
})

SecGlobal:Button({
    Title = "SUPERCELL",
    Desc = "Make a global Mutivortex across all players",
    Icon = "chevron-right",
    Callback = function()
        sendGlobal("SUPERCELL")
    end,
})

-- ==================== BROOKHAVEN TAB ====================
local propKillSpeed = 6
local propFlingSpeed = 6
local propBringSpeed = 6

SecBrook:Slider({
    Title = "Prop Kill Speed",
    Value = {Min = 1, Max = 20, Default = 6},
    Callback = function(v) propKillSpeed = v end,
})

SecBrook:Slider({
    Title = "Prop Fling Speed",
    Value = {Min = 1, Max = 20, Default = 6},
    Callback = function(v) propFlingSpeed = v end,
})

SecBrook:Slider({
    Title = "Prop Bring Speed",
    Value = {Min = 1, Max = 20, Default = 6},
    Callback = function(v) propBringSpeed = v end,
})

-- ==================== PLAYER LIST UPDATES ====================
Players.PlayerAdded:Connect(function(plr)
    task.wait(1)
    local names = getPlayerNames()
    targetDropdown:Refresh(names)
    specialTarget:Refresh(names)
    jumpsTarget:Refresh(names)
    globalTarget:Refresh(names)
end)

Players.PlayerRemoving:Connect(function(plr)
    task.wait(1)
    local names = getPlayerNames()
    targetDropdown:Refresh(names)
    specialTarget:Refresh(names)
    jumpsTarget:Refresh(names)
    globalTarget:Refresh(names)
end)

-- ==================== INIT ====================
connectWebSocket()

if Net.connected then
    verifySession()

    Net.socket.OnMessage:Connect(function(raw)
        local decoded = parseIncoming(raw)
        if not decoded then return end

        if decoded.global then
            local cmd = string.lower(decoded.global)
            if cmd == "joinall" then
                joinAllHandler(decoded)
            elseif cmd == "announce" then
                announceHandler(decoded)
            end
            return
        end

        if decoded.command then
            local cmdName, senderName, payload = decoded.command:match("^([^:]+):([^:]+):(.*)$")
            if cmdName and Commands[cmdName] then
                Commands[cmdName](senderName, payload)
            end
        end
    end)
end