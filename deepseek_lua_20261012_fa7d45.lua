-- ============================================================
-- Discord Webhook Sender — Compact Mobile GUI
-- by Viq
-- ============================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- ==================== HTTP ====================
local requestFunc = (syn and syn.request)
    or (http and http.request)
    or (fluxus and fluxus.request)
    or http_request
    or request

-- ==================== CONFIG ====================
local CONFIG_FILE = "webhook_sender_config.json"

local defaultConfig = {
    webhookUrl = "",
    botUsername = "by Viq",
    avatarUrl = "",
    message = "",
    count = "5",
    delay = "1",
    history = {},
}

local function loadConfig()
    if not (isfile and readfile and isfile(CONFIG_FILE)) then
        return defaultConfig
    end
    local ok, content = pcall(readfile, CONFIG_FILE)
    if not ok or not content or content == "" then return defaultConfig end
    local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 or type(data) ~= "table" then return defaultConfig end
    for k, v in pairs(defaultConfig) do
        if data[k] == nil then data[k] = v end
    end
    if data.username and (not data.botUsername or data.botUsername == "") then
        data.botUsername = data.username
    end
    return data
end

local function saveConfig(cfg)
    if not writefile then return false end
    return pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(cfg))
    end)
end

local config = loadConfig()

-- ==================== DEVICE ====================
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ==================== DRAGGABLE ====================
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local d = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y
                )
            end
        end
    end)
end

-- ==================== GUI ====================
local old = CoreGui:FindFirstChild("WebhookCompactGui")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "WebhookCompactGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

-- ============ SIZE ============
local FRAME_W = 270
local FRAME_H = 480

-- ============ FLOATING TOGGLE BUTTON ============
local TOGGLE_SIZE = 44

local toggle = Instance.new("TextButton")
toggle.Name = "Toggle"
toggle.Size = UDim2.new(0, TOGGLE_SIZE, 0, TOGGLE_SIZE)
toggle.Position = UDim2.new(0, 20, 0.5, -TOGGLE_SIZE / 2)
toggle.BackgroundColor3 = Color3.fromRGB(60, 90, 200)
toggle.Text = "🎲"
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.TextSize = 20
toggle.Font = Enum.Font.GothamBold
toggle.BorderSizePixel = 0
toggle.AutoButtonColor = false
toggle.Active = true
toggle.Draggable = false
toggle.Parent = gui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(1, 0)
toggleCorner.Parent = toggle

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(106, 17, 203)
toggleStroke.Thickness = 2
toggleStroke.Parent = toggle

-- ============ MAIN FRAME ============
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, FRAME_W, 0, FRAME_H)
main.Position = UDim2.new(0.5, -FRAME_W / 2, 0.5, -FRAME_H / 2)
main.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
main.BorderSizePixel = 0
main.Active = true
main.Visible = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 4)  -- прямоугольный вид
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(106, 17, 203)
mainStroke.Thickness = 1.5
mainStroke.Parent = main

-- ===== Title Bar =====
local TITLE_H = 32

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local tbc = Instance.new("UICorner")
tbc.CornerRadius = UDim.new(0, 4)
tbc.Parent = titleBar

local tbFix = Instance.new("Frame")
tbFix.Size = UDim2.new(1, 0, 0, 10)
tbFix.Position = UDim2.new(0, 0, 1, -10)
tbFix.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
tbFix.BorderSizePixel = 0
tbFix.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🎲 Webhook"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 12
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTruncate = Enum.TextTruncate.AtEnd
title.Parent = titleBar

local signature = Instance.new("TextLabel")
signature.Size = UDim2.new(0, 40, 1, 0)
signature.Position = UDim2.new(1, -94, 0, 0)
signature.BackgroundTransparency = 1
signature.Text = "by Viq"
signature.TextColor3 = Color3.fromRGB(150, 120, 220)
signature.TextSize = 10
signature.Font = Enum.Font.GothamBold
signature.TextXAlignment = Enum.TextXAlignment.Right
signature.TextYAlignment = Enum.TextYAlignment.Center
signature.Parent = titleBar

-- Settings button
local BTN_SIZE = 24
local settingsBtn = Instance.new("TextButton")
settingsBtn.Size = UDim2.new(0, BTN_SIZE, 0, BTN_SIZE)
settingsBtn.Position = UDim2.new(1, -BTN_SIZE * 2 - 4, 0, (TITLE_H - BTN_SIZE) / 2)
settingsBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
settingsBtn.Text = "⚙"
settingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsBtn.TextSize = 12
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.BorderSizePixel = 0
settingsBtn.Parent = titleBar

local sbc = Instance.new("UICorner")
sbc.CornerRadius = UDim.new(0, 3)
sbc.Parent = settingsBtn

-- Collapse button in title (▬)
local collapseBtn = Instance.new("TextButton")
collapseBtn.Size = UDim2.new(0, BTN_SIZE, 0, BTN_SIZE)
collapseBtn.Position = UDim2.new(1, -BTN_SIZE * 3 - 6, 0, (TITLE_H - BTN_SIZE) / 2)
collapseBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 110)
collapseBtn.Text = "▬"
collapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
collapseBtn.TextSize = 12
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.BorderSizePixel = 0
collapseBtn.Parent = titleBar

local colbc = Instance.new("UICorner")
colbc.CornerRadius = UDim.new(0, 3)
colbc.Parent = collapseBtn

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, BTN_SIZE, 0, BTN_SIZE)
closeBtn.Position = UDim2.new(1, -BTN_SIZE - 4, 0, (TITLE_H - BTN_SIZE) / 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local cbc = Instance.new("UICorner")
cbc.CornerRadius = UDim.new(0, 3)
cbc.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
makeDraggable(main, titleBar)

-- ==================== COLLAPSE / EXPAND ====================
local collapsed = false

local function setCollapsed(state)
    collapsed = state
    if collapsed then
        main.Visible = false
        toggle.Visible = true
    else
        main.Visible = true
        toggle.Visible = true
    end
end

-- Button in title collapses
collapseBtn.MouseButton1Click:Connect(function()
    setCollapsed(true)
end)

-- Floating ball toggles
local toggleDragging = false
local toggleDragStart, toggleStartPos

toggle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        toggleDragging = true
        toggleDragStart = input.Position
        toggleStartPos = toggle.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                toggleDragging = false
            end
        end)
    end
end)

toggle.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        if toggleDragging then
            local d = input.Position - toggleDragStart
            toggle.Position = UDim2.new(
                toggleStartPos.X.Scale, toggleStartPos.X.Offset + d.X,
                toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + d.Y
            )
        end
    end
end)

-- Click detection: only toggle if mouse didn't move much
local clickStartPos
toggle.MouseButton1Down:Connect(function()
    clickStartPos = toggle.AbsolutePosition
end)

toggle.MouseButton1Up:Connect(function()
    if clickStartPos then
        local moved = (toggle.AbsolutePosition - clickStartPos).Magnitude
        if moved < 5 then
            -- Toggle
            if main.Visible then
                setCollapsed(true)
            else
                setCollapsed(false)
            end
        end
    end
end)

-- ==================== LAYOUT ====================
local PAD = 8
local GAP = 3
local LBL_H = 13
local INP_H = 26

local Y = TITLE_H + 4

local function addLabel(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -PAD * 2, 0, LBL_H)
    lbl.Position = UDim2.new(0, PAD, 0, Y)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(160, 160, 180)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.Parent = main
    Y = Y + LBL_H + GAP
    return lbl
end

local function addInput(placeholder, defaultText, h)
    h = h or INP_H
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -PAD * 2, 0, h)
    box.Position = UDim2.new(0, PAD, 0, Y)
    box.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(110, 110, 130)
    box.Text = defaultText or ""
    box.TextSize = 11
    box.Font = Enum.Font.Gotham
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.BorderSizePixel = 0
    box.Parent = main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = box

    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 6)
    p.PaddingRight = UDim.new(0, 6)
    p.Parent = box

    Y = Y + h + 4
    return box
end

-- ==================== FIELDS ====================
addLabel("Webhook URL")
local urlBox = addInput("https://discord.com/api/webhooks/...", config.webhookUrl)

addLabel("Bot Username")
local usernameBox = addInput("by Viq", config.botUsername)

addLabel("Avatar (optional)")
local avatarBox = addInput("https://.../avatar.png", config.avatarUrl)

addLabel("Message")
local msgBox = addInput("Type your message here...", config.message, 44)

-- Count + Delay
local cLbl = Instance.new("TextLabel")
cLbl.Size = UDim2.new(0.5, -PAD * 1.5, 0, LBL_H)
cLbl.Position = UDim2.new(0, PAD, 0, Y)
cLbl.BackgroundTransparency = 1
cLbl.Text = "Count"
cLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
cLbl.TextSize = 10
cLbl.Font = Enum.Font.GothamMedium
cLbl.TextXAlignment = Enum.TextXAlignment.Left
cLbl.TextTruncate = Enum.TextTruncate.AtEnd
cLbl.Parent = main

local dLbl = Instance.new("TextLabel")
dLbl.Size = UDim2.new(0.5, -PAD * 1.5, 0, LBL_H)
dLbl.Position = UDim2.new(0.5, PAD * 0.5, 0, Y)
dLbl.BackgroundTransparency = 1
dLbl.Text = "Delay"
dLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
dLbl.TextSize = 10
dLbl.Font = Enum.Font.GothamMedium
dLbl.TextXAlignment = Enum.TextXAlignment.Left
dLbl.TextTruncate = Enum.TextTruncate.AtEnd
dLbl.Parent = main

Y = Y + LBL_H + GAP

local countBox = Instance.new("TextBox")
countBox.Size = UDim2.new(0.5, -PAD * 1.5, 0, INP_H)
countBox.Position = UDim2.new(0, PAD, 0, Y)
countBox.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
countBox.TextColor3 = Color3.fromRGB(255, 255, 255)
countBox.PlaceholderText = "5"
countBox.Text = config.count
countBox.TextSize = 11
countBox.Font = Enum.Font.Gotham
countBox.ClearTextOnFocus = false
countBox.BorderSizePixel = 0
countBox.Parent = main

local ccC = Instance.new("UICorner")
ccC.CornerRadius = UDim.new(0, 3)
ccC.Parent = countBox

local ccP = Instance.new("UIPadding")
ccP.PaddingLeft = UDim.new(0, 6)
ccP.Parent = countBox

local delayBox = Instance.new("TextBox")
delayBox.Size = UDim2.new(0.5, -PAD * 1.5, 0, INP_H)
delayBox.Position = UDim2.new(0.5, PAD * 0.5, 0, Y)
delayBox.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
delayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
delayBox.PlaceholderText = "1"
delayBox.Text = config.delay
delayBox.TextSize = 11
delayBox.Font = Enum.Font.Gotham
delayBox.ClearTextOnFocus = false
delayBox.BorderSizePixel = 0
delayBox.Parent = main

local dcC = Instance.new("UICorner")
dcC.CornerRadius = UDim.new(0, 3)
dcC.Parent = delayBox

local dcP = Instance.new("UIPadding")
dcP.PaddingLeft = UDim.new(0, 6)
dcP.Parent = delayBox

Y = Y + INP_H + 4

-- Buttons
local BTN_H = 30

local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(1, -PAD * 2, 0, BTN_H)
sendBtn.Position = UDim2.new(0, PAD, 0, Y)
sendBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 200)
sendBtn.Text = "📨 Send"
sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sendBtn.TextSize = 12
sendBtn.Font = Enum.Font.GothamBold
sendBtn.BorderSizePixel = 0
sendBtn.AutoButtonColor = true
sendBtn.Parent = main

local sendCorner = Instance.new("UICorner")
sendCorner.CornerRadius = UDim.new(0, 3)
sendCorner.Parent = sendBtn

Y = Y + BTN_H + 3

local spamBtn = Instance.new("TextButton")
spamBtn.Size = UDim2.new(1, -PAD * 2, 0, BTN_H)
spamBtn.Position = UDim2.new(0, PAD, 0, Y)
spamBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
spamBtn.Text = "⚡ Spam"
spamBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spamBtn.TextSize = 12
spamBtn.Font = Enum.Font.GothamBold
spamBtn.BorderSizePixel = 0
spamBtn.AutoButtonColor = true
spamBtn.Parent = main

local spamCorner = Instance.new("UICorner")
spamCorner.CornerRadius = UDim.new(0, 3)
spamCorner.Parent = spamBtn

Y = Y + BTN_H + 3

-- Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -PAD * 2, 0, LBL_H)
statusLabel.Position = UDim2.new(0, PAD, 0, Y)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: idle"
statusLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
statusLabel.Parent = main

Y = Y + LBL_H + 3

-- Log
local LOG_H = FRAME_H - Y - PAD - 14
if LOG_H < 30 then LOG_H = 30 end

local logScroll = Instance.new("ScrollingFrame")
logScroll.Size = UDim2.new(1, -PAD * 2, 0, LOG_H)
logScroll.Position = UDim2.new(0, PAD, 0, Y)
logScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
logScroll.BorderSizePixel = 0
logScroll.ScrollBarThickness = 3
logScroll.ScrollBarImageColor3 = Color3.fromRGB(106, 17, 203)
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.Parent = main

local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 3)
logCorner.Parent = logScroll

local logList = Instance.new("UIListLayout")
logList.Padding = UDim.new(0, 2)
logList.SortOrder = Enum.SortOrder.LayoutOrder
logList.Parent = logScroll

local logPad = Instance.new("UIPadding")
logPad.PaddingLeft = UDim.new(0, 5)
logPad.PaddingRight = UDim.new(0, 5)
logPad.PaddingTop = UDim.new(0, 4)
logPad.PaddingBottom = UDim.new(0, 4)
logPad.Parent = logScroll

local logCounter = 0
local function addLog(text, ok)
    logCounter = logCounter + 1
    local e = Instance.new("TextLabel")
    e.Size = UDim2.new(1, 0, 0, 12)
    e.BackgroundTransparency = 1
    e.Text = "[" .. os.date("%H:%M:%S") .. "] " .. text
    e.TextColor3 = ok and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(220, 120, 120)
    e.TextSize = 9
    e.Font = Enum.Font.Code
    e.TextXAlignment = Enum.TextXAlignment.Left
    e.TextTruncate = Enum.TextTruncate.AtEnd
    e.LayoutOrder = logCounter
    e.Parent = logScroll
end

-- Footer
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, -PAD * 2, 0, 12)
footer.Position = UDim2.new(0, PAD, 1, -14)
footer.BackgroundTransparency = 1
footer.Text = "by Viq"
footer.TextColor3 = Color3.fromRGB(130, 100, 200)
footer.TextSize = 9
footer.Font = Enum.Font.GothamBold
footer.TextXAlignment = Enum.TextXAlignment.Right
footer.Parent = main

-- ============================================================
-- SETTINGS PANEL
-- ============================================================
local settingsPanel = Instance.new("Frame")
settingsPanel.Size = UDim2.new(1, 0, 1, 0)
settingsPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
settingsPanel.BackgroundTransparency = 0.05
settingsPanel.BorderSizePixel = 0
settingsPanel.Visible = false
settingsPanel.ZIndex = 50
settingsPanel.Parent = main

local spc = Instance.new("UICorner")
spc.CornerRadius = UDim.new(0, 4)
spc.Parent = settingsPanel

local SY = 6

local spTitle = Instance.new("TextLabel")
spTitle.Size = UDim2.new(1, -PAD * 2, 0, 18)
spTitle.Position = UDim2.new(0, PAD, 0, SY)
spTitle.BackgroundTransparency = 1
spTitle.Text = "⚙ Settings"
spTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
spTitle.TextSize = 13
spTitle.Font = Enum.Font.GothamBold
spTitle.TextXAlignment = Enum.TextXAlignment.Left
spTitle.ZIndex = 51
spTitle.Parent = settingsPanel

local spSig = Instance.new("TextLabel")
spSig.Size = UDim2.new(0, 50, 0, 18)
spSig.Position = UDim2.new(1, -50 - PAD, 0, SY)
spSig.BackgroundTransparency = 1
spSig.Text = "by Viq"
spSig.TextColor3 = Color3.fromRGB(150, 120, 220)
spSig.TextSize = 10
spSig.Font = Enum.Font.GothamBold
spSig.TextXAlignment = Enum.TextXAlignment.Right
spSig.ZIndex = 51
spSig.Parent = settingsPanel

SY = SY + 22

local histLabel = Instance.new("TextLabel")
histLabel.Size = UDim2.new(1, -PAD * 2, 0, 12)
histLabel.Position = UDim2.new(0, PAD, 0, SY)
histLabel.BackgroundTransparency = 1
histLabel.Text = "Saved:"
histLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
histLabel.TextSize = 10
histLabel.Font = Enum.Font.GothamMedium
histLabel.TextXAlignment = Enum.TextXAlignment.Left
histLabel.ZIndex = 51
histLabel.Parent = settingsPanel

SY = SY + 15

local HIST_H = 300

local histScroll = Instance.new("ScrollingFrame")
histScroll.Size = UDim2.new(1, -PAD * 2, 0, HIST_H)
histScroll.Position = UDim2.new(0, PAD, 0, SY)
histScroll.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
histScroll.BorderSizePixel = 0
histScroll.ScrollBarThickness = 3
histScroll.ScrollBarImageColor3 = Color3.fromRGB(106, 17, 203)
histScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
histScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
histScroll.ZIndex = 51
histScroll.Parent = settingsPanel

local hc = Instance.new("UICorner")
hc.CornerRadius = UDim.new(0, 3)
hc.Parent = histScroll

local hlist = Instance.new("UIListLayout")
hlist.Padding = UDim.new(0, 3)
hlist.SortOrder = Enum.SortOrder.LayoutOrder
hlist.Parent = histScroll

local hp = Instance.new("UIPadding")
hp.PaddingLeft = UDim.new(0, 5)
hp.PaddingRight = UDim.new(0, 5)
hp.PaddingTop = UDim.new(0, 5)
hp.PaddingBottom = UDim.new(0, 5)
hp.Parent = histScroll

if not config.history then config.history = {} end

local function refreshHistory()
    for _, c in ipairs(histScroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then
            c:Destroy()
        end
    end

    if #config.history == 0 then
        local e = Instance.new("TextLabel")
        e.Size = UDim2.new(1, 0, 0, 18)
        e.BackgroundTransparency = 1
        e.Text = "Empty"
        e.TextColor3 = Color3.fromRGB(110, 110, 130)
        e.TextSize = 10
        e.Font = Enum.Font.Gotham
        e.ZIndex = 52
        e.Parent = histScroll
        return
    end

    for i, item in ipairs(config.history) do
        local url, botName, avatarUrl
        if type(item) == "string" then
            url = item
            botName = ""
            avatarUrl = ""
        else
            url = item.url or ""
            botName = item.botUsername or ""
            avatarUrl = item.avatarUrl or ""
        end

        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 34)
        row.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        row.Text = ""
        row.BorderSizePixel = 0
        row.AutoButtonColor = false
        row.ZIndex = 52
        row.LayoutOrder = i
        row.Parent = histScroll

        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 3)
        rc.Parent = row

        local nameLine = Instance.new("TextLabel")
        nameLine.Size = UDim2.new(1, -70, 0, 12)
        nameLine.Position = UDim2.new(0, 5, 0, 2)
        nameLine.BackgroundTransparency = 1
        nameLine.Text = botName ~= "" and ("🤖 " .. botName) or "🤖 (no name)"
        nameLine.TextColor3 = Color3.fromRGB(180, 160, 255)
        nameLine.TextSize = 9
        nameLine.Font = Enum.Font.GothamBold
        nameLine.TextXAlignment = Enum.TextXAlignment.Left
        nameLine.TextTruncate = Enum.TextTruncate.AtEnd
        nameLine.ZIndex = 53
        nameLine.Parent = row

        local preview = url:sub(1, 22) .. (#url > 22 and ".." or "")

        local urlLine = Instance.new("TextLabel")
        urlLine.Size = UDim2.new(1, -70, 0, 10)
        urlLine.Position = UDim2.new(0, 5, 0, 15)
        urlLine.BackgroundTransparency = 1
        urlLine.Text = preview
        urlLine.TextColor3 = Color3.fromRGB(180, 180, 200)
        urlLine.TextSize = 8
        urlLine.Font = Enum.Font.Code
        urlLine.TextXAlignment = Enum.TextXAlignment.Left
        urlLine.TextTruncate = Enum.TextTruncate.AtEnd
        urlLine.ZIndex = 53
        urlLine.Parent = row

        local useB = Instance.new("TextButton")
        useB.Size = UDim2.new(0, 28, 0, 18)
        useB.Position = UDim2.new(1, -62, 0, 8)
        useB.BackgroundColor3 = Color3.fromRGB(60, 130, 200)
        useB.Text = "Use"
        useB.TextColor3 = Color3.fromRGB(255, 255, 255)
        useB.TextSize = 9
        useB.Font = Enum.Font.GothamBold
        useB.BorderSizePixel = 0
        useB.ZIndex = 53
        useB.Parent = row

        local uc = Instance.new("UICorner")
        uc.CornerRadius = UDim.new(0, 3)
        uc.Parent = useB

        local delB = Instance.new("TextButton")
        delB.Size = UDim2.new(0, 28, 0, 18)
        delB.Position = UDim2.new(1, -30, 0, 8)
        delB.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        delB.Text = "Del"
        delB.TextColor3 = Color3.fromRGB(255, 255, 255)
        delB.TextSize = 9
        delB.Font = Enum.Font.GothamBold
        delB.BorderSizePixel = 0
        delB.ZIndex = 53
        delB.Parent = row

        local dc = Instance.new("UICorner")
        dc.CornerRadius = UDim.new(0, 3)
        dc.Parent = delB

        useB.MouseButton1Click:Connect(function()
            urlBox.Text = url
            usernameBox.Text = botName
            avatarBox.Text = avatarUrl
            config.webhookUrl = url
            config.botUsername = botName
            config.avatarUrl = avatarUrl
            saveConfig(config)
            addLog("Loaded: " .. (botName ~= "" and botName or "by Viq"), true)
        end)

        delB.MouseButton1Click:Connect(function()
            table.remove(config.history, i)
            saveConfig(config)
            refreshHistory()
            addLog("Removed", false)
        end)
    end
end

SY = SY + HIST_H + 6

local function makeSettingBtn(text, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -PAD * 2, 0, 26)
    b.Position = UDim2.new(0, PAD, 0, SY)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.ZIndex = 51
    b.Parent = settingsPanel

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = b

    SY = SY + 26 + 3
    return b
end

local saveHistBtn = makeSettingBtn("💾 Save", Color3.fromRGB(60, 150, 90))
local clearHistBtn = makeSettingBtn("🗑 Clear history", Color3.fromRGB(180, 60, 60))
local resetBtn = makeSettingBtn("↺ Reset settings", Color3.fromRGB(120, 90, 200))
local backBtn = makeSettingBtn("← Back", Color3.fromRGB(80, 80, 100))

local spFooter = Instance.new("TextLabel")
spFooter.Size = UDim2.new(1, -PAD * 2, 0, 12)
spFooter.Position = UDim2.new(0, PAD, 1, -14)
spFooter.BackgroundTransparency = 1
spFooter.Text = "by Viq"
spFooter.TextColor3 = Color3.fromRGB(130, 100, 200)
spFooter.TextSize = 9
spFooter.Font = Enum.Font.GothamBold
spFooter.TextXAlignment = Enum.TextXAlignment.Right
spFooter.ZIndex = 51
spFooter.Parent = settingsPanel

-- ===== Settings actions =====
saveHistBtn.MouseButton1Click:Connect(function()
    local url = urlBox.Text
    if url == "" then addLog("URL empty", false) return end
    local botName = usernameBox.Text
    local avatarUrl = avatarBox.Text

    for _, v in ipairs(config.history) do
        local existingUrl = (type(v) == "string") and v or v.url
        if existingUrl == url then
            addLog("Already saved", false)
            return
        end
    end

    table.insert(config.history, 1, {
        url = url,
        botUsername = botName,
        avatarUrl = avatarUrl,
    })
    while #config.history > 20 do table.remove(config.history) end

    config.webhookUrl = url
    config.botUsername = botName
    config.avatarUrl = avatarUrl
    saveConfig(config)
    refreshHistory()
    addLog("Saved: " .. (botName ~= "" and botName or "by Viq"), true)
end)

clearHistBtn.MouseButton1Click:Connect(function()
    config.history = {}
    saveConfig(config)
    refreshHistory()
    addLog("History cleared", false)
end)

resetBtn.MouseButton1Click:Connect(function()
    config = {
        webhookUrl = defaultConfig.webhookUrl,
        botUsername = defaultConfig.botUsername,
        avatarUrl = "",
        message = "",
        count = "5",
        delay = "1",
        history = {},
    }
    saveConfig(config)
    urlBox.Text = config.webhookUrl
    usernameBox.Text = config.botUsername
    avatarBox.Text = config.avatarUrl
    msgBox.Text = config.message
    countBox.Text = config.count
    delayBox.Text = config.delay
    refreshHistory()
    addLog("Settings reset", true)
end)

backBtn.MouseButton1Click:Connect(function()
    settingsPanel.Visible = false
end)

settingsBtn.MouseButton1Click:Connect(function()
    settingsPanel.Visible = not settingsPanel.Visible
    if settingsPanel.Visible then refreshHistory() end
end)

-- ============================================================
-- LOGIC
-- ============================================================
local spamRunning = false
local spamStop = false

local function validate()
    if not requestFunc then
        addLog("No HTTP request function", false)
        return false
    end
    if urlBox.Text == "" then
        addLog("Webhook URL empty", false)
        return false
    end
    if not urlBox.Text:find("discord") then
        addLog("Invalid webhook URL", false)
        return false
    end
    if msgBox.Text == "" then
        addLog("Message is empty", false)
        return false
    end
    return true
end

local function sendOne()
    if not validate() then return false end

    local payload = { content = msgBox.Text }

    local botName = usernameBox.Text
    if botName ~= "" then
        payload.username = botName
    end

    if avatarBox.Text ~= "" then
        payload.avatar_url = avatarBox.Text
    end

    local ok, r = pcall(function()
        return requestFunc({
            Url = urlBox.Text,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload),
        })
    end)

    if ok and r then
        if r.StatusCode == 204 or r.StatusCode == 200 then return true end
        if r.StatusCode == 429 then addLog("Rate limited (429)", false) return false end
        if r.StatusCode == 401 then addLog("Invalid webhook (401)", false) return false end
        addLog("HTTP " .. tostring(r.StatusCode), false)
        return false
    end
    addLog("Request error", false)
    return false
end

sendBtn.MouseButton1Click:Connect(function()
    config.webhookUrl = urlBox.Text
    config.botUsername = usernameBox.Text
    config.avatarUrl = avatarBox.Text
    config.message = msgBox.Text
    saveConfig(config)

    local nameShown = usernameBox.Text ~= "" and usernameBox.Text or "by Viq"
    addLog("Sending as: " .. nameShown)
    if sendOne() then
        addLog("Message sent!", true)
        statusLabel.Text = "Status: sent"
        statusLabel.TextColor3 = Color3.fromRGB(120, 220, 120)
    else
        statusLabel.Text = "Status: error"
        statusLabel.TextColor3 = Color3.fromRGB(220, 120, 120)
    end
end)

spamBtn.MouseButton1Click:Connect(function()
    if spamRunning then
        spamStop = true
        spamBtn.Text = "⚡ Spam"
        addLog("Stopped", false)
        return
    end

    if not validate() then return end

    config.webhookUrl = urlBox.Text
    config.botUsername = usernameBox.Text
    config.avatarUrl = avatarBox.Text
    config.message = msgBox.Text
    config.count = countBox.Text
    config.delay = delayBox.Text
    saveConfig(config)

    local count = tonumber(countBox.Text) or 5
    local delay = tonumber(delayBox.Text) or 1
    if delay < 0.5 then delay = 0.5 end
    if count < 1 then count = 1 end

    spamRunning = true
    spamStop = false
    spamBtn.Text = "⏹ Stop"

    addLog("Spam: " .. count .. " x " .. delay .. "s")

    task.spawn(function()
        local sent = 0
        for i = 1, count do
            if spamStop then break end
            if sendOne() then
                sent = sent + 1
                statusLabel.Text = "Sent " .. sent .. "/" .. count
                statusLabel.TextColor3 = Color3.fromRGB(120, 220, 120)
            end
            if i < count and not spamStop then task.wait(delay) end
        end
        spamRunning = false
        spamStop = false
        spamBtn.Text = "⚡ Spam"
        addLog("Finished: " .. sent .. "/" .. count, true)
    end)
end)

-- ==================== INIT ====================
addLog("Ready to use", true)
if config.webhookUrl == "" then
    addLog("Enter webhook URL", false)
else
    addLog("Webhook loaded", true)
end
addLog("by Viq", true)