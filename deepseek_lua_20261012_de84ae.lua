-- ============================================================
-- Discord Webhook Sender — Mobile & PC Adaptive GUI
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
    webhookUrl = "insert webhook here...",
    botUsername = "Tys Client",
    avatarUrl = "by Viq",
    message = "",
    count = "6.7",
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

-- ==================== DEVICE DETECTION ====================
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local IS_PC = UserInputService.KeyboardEnabled

local SCALE = IS_MOBILE and 1 or 1.15

local function sz(x) return math.floor(x * SCALE + 0.5) end

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
local old = CoreGui:FindFirstChild("WebhookAdaptiveGui")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "WebhookAdaptiveGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local FRAME_W = IS_MOBILE and 300 or 380
local FRAME_H = IS_MOBILE and 400 or 490

-- ===== Main Frame =====
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, FRAME_W, 0, FRAME_H)
main.Position = UDim2.new(0.5, -FRAME_W / 2, 0.5, -FRAME_H / 2)
main.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(106, 17, 203)
mainStroke.Thickness = 1.5
mainStroke.Parent = main

-- ===== Title Bar =====
local TITLE_H = IS_MOBILE and 36 or 42

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local tbc = Instance.new("UICorner")
tbc.CornerRadius = UDim.new(0, 10)
tbc.Parent = titleBar

local tbFix = Instance.new("Frame")
tbFix.Size = UDim2.new(1, 0, 0, 10)
tbFix.Position = UDim2.new(0, 0, 1, -10)
tbFix.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
tbFix.BorderSizePixel = 0
tbFix.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -110, 1, 0)
title.Position = UDim2.new(0, sz(10), 0, 0)
title.BackgroundTransparency = 1
title.Text = "🎲 Webhook Sender"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = IS_MOBILE and 14 or 15
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- "by Viq" signature
local signature = Instance.new("TextLabel")
signature.Name = "Signature"
signature.Size = UDim2.new(0, 60, 1, 0)
signature.Position = UDim2.new(1, -168, 0, 0)
signature.BackgroundTransparency = 1
signature.Text = "by Viq"
signature.TextColor3 = Color3.fromRGB(150, 120, 220)
signature.TextSize = IS_MOBILE and 11 or 12
signature.Font = Enum.Font.GothamBold
signature.TextXAlignment = Enum.TextXAlignment.Right
signature.TextYAlignment = Enum.TextYAlignment.Center
signature.Parent = titleBar

-- Settings button
local BTN_SIZE = IS_MOBILE and 26 or 30
local settingsBtn = Instance.new("TextButton")
settingsBtn.Size = UDim2.new(0, BTN_SIZE, 0, BTN_SIZE - 2)
settingsBtn.Position = UDim2.new(1, -BTN_SIZE - 36, 0, (TITLE_H - (BTN_SIZE - 2)) / 2)
settingsBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
settingsBtn.Text = "⚙"
settingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsBtn.TextSize = IS_MOBILE and 13 or 15
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.BorderSizePixel = 0
settingsBtn.Parent = titleBar

local sbc = Instance.new("UICorner")
sbc.CornerRadius = UDim.new(0, 5)
sbc.Parent = settingsBtn

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, BTN_SIZE, 0, BTN_SIZE - 2)
closeBtn.Position = UDim2.new(1, -BTN_SIZE - 6, 0, (TITLE_H - (BTN_SIZE - 2)) / 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = IS_MOBILE and 13 or 15
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local cbc = Instance.new("UICorner")
cbc.CornerRadius = UDim.new(0, 5)
cbc.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
makeDraggable(main, titleBar)

-- ==================== LAYOUT HELPERS ====================
local Y = 0
local PAD = sz(10)
local ROW_GAP = sz(6)
local LABEL_H = sz(14)
local INPUT_H = IS_MOBILE and sz(30) or sz(34)

local function nextY(extra)
    Y = Y + (extra or 0)
    return Y
end

local function makeLabel(text)
    local y = nextY(LABEL_H)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -PAD * 2, 0, LABEL_H)
    l.Position = UDim2.new(0, PAD, 0, y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(160, 160, 180)
    l.TextSize = IS_MOBILE and 11 or 12
    l.Font = Enum.Font.GothamMedium
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = main
    return l
end

local function makeInput(placeholder, defaultText, height, width, xOffset)
    local y = nextY(ROW_GAP)
    local h = height or INPUT_H
    local w = width or UDim.new(1, -PAD * 2)
    local x = xOffset or PAD

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(w.Scale, w.Offset, 0, h)
    box.Position = UDim2.new(0, x, 0, y)
    box.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(110, 110, 130)
    box.Text = defaultText or ""
    box.TextSize = IS_MOBILE and 12 or 13
    box.Font = Enum.Font.Gotham
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.BorderSizePixel = 0
    box.Parent = main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = box

    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, sz(8))
    p.PaddingRight = UDim.new(0, sz(8))
    p.Parent = box

    nextY(h)
    return box
end

-- ==================== FORM ====================
Y = TITLE_H + sz(8)

-- ===== Webhook URL =====
makeLabel("Webhook URL")
local urlBox = makeInput("https://discord.com/...", config.webhookUrl)

-- ===== Bot Username + Avatar =====
local rowY = nextY(LABEL_H + ROW_GAP)
local userLbl = Instance.new("TextLabel")
userLbl.Size = UDim2.new(0.5, -PAD * 1.5, 0, LABEL_H)
userLbl.Position = UDim2.new(0, PAD, 0, rowY)
userLbl.BackgroundTransparency = 1
userLbl.Text = "Bot Username"
userLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
userLbl.TextSize = IS_MOBILE and 11 or 12
userLbl.Font = Enum.Font.GothamMedium
userLbl.TextXAlignment = Enum.TextXAlignment.Left
userLbl.Parent = main

local avatarLbl = Instance.new("TextLabel")
avatarLbl.Size = UDim2.new(0.5, -PAD * 1.5, 0, LABEL_H)
avatarLbl.Position = UDim2.new(0.5, PAD * 0.5, 0, rowY)
avatarLbl.BackgroundTransparency = 1
avatarLbl.Text = "Avatar URL"
avatarLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
avatarLbl.TextSize = IS_MOBILE and 11 or 12
avatarLbl.Font = Enum.Font.GothamMedium
avatarLbl.TextXAlignment = Enum.TextXAlignment.Left
avatarLbl.Parent = main

Y = rowY + LABEL_H + ROW_GAP

local usernameBox = Instance.new("TextBox")
usernameBox.Size = UDim2.new(0.5, -PAD * 1.5, 0, INPUT_H)
usernameBox.Position = UDim2.new(0, PAD, 0, Y)
usernameBox.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
usernameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
usernameBox.PlaceholderText = "by Viq"
usernameBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 130)
usernameBox.Text = config.botUsername or ""
usernameBox.TextSize = IS_MOBILE and 12 or 13
usernameBox.Font = Enum.Font.Gotham
usernameBox.TextXAlignment = Enum.TextXAlignment.Left
usernameBox.ClearTextOnFocus = false
usernameBox.BorderSizePixel = 0
usernameBox.Parent = main

local ucC = Instance.new("UICorner")
ucC.CornerRadius = UDim.new(0, 6)
ucC.Parent = usernameBox

local ucP = Instance.new("UIPadding")
ucP.PaddingLeft = UDim.new(0, sz(8))
ucP.PaddingRight = UDim.new(0, sz(8))
ucP.Parent = usernameBox

local avatarBox = Instance.new("TextBox")
avatarBox.Size = UDim2.new(0.5, -PAD * 1.5, 0, INPUT_H)
avatarBox.Position = UDim2.new(0.5, PAD * 0.5, 0, Y)
avatarBox.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
avatarBox.TextColor3 = Color3.fromRGB(255, 255, 255)
avatarBox.PlaceholderText = "Optional"
avatarBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 130)
avatarBox.Text = config.avatarUrl
avatarBox.TextSize = IS_MOBILE and 12 or 13
avatarBox.Font = Enum.Font.Gotham
avatarBox.TextXAlignment = Enum.TextXAlignment.Left
avatarBox.ClearTextOnFocus = false
avatarBox.BorderSizePixel = 0
avatarBox.Parent = main

local acC = Instance.new("UICorner")
acC.CornerRadius = UDim.new(0, 6)
acC.Parent = avatarBox

local acP = Instance.new("UIPadding")
acP.PaddingLeft = UDim.new(0, sz(8))
acP.PaddingRight = UDim.new(0, sz(8))
acP.Parent = avatarBox

nextY(INPUT_H)

-- ===== Message =====
makeLabel("Message")
local MSG_H = IS_MOBILE and sz(60) or sz(75)
local msgBox = Instance.new("TextBox")
msgBox.Size = UDim2.new(1, -PAD * 2, 0, MSG_H)
msgBox.Position = UDim2.new(0, PAD, 0, nextY(ROW_GAP))
msgBox.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
msgBox.TextColor3 = Color3.fromRGB(255, 255, 255)
msgBox.PlaceholderText = "Type your message here..."
msgBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 130)
msgBox.Text = config.message
msgBox.TextSize = IS_MOBILE and 12 or 13
msgBox.Font = Enum.Font.Gotham
msgBox.TextXAlignment = Enum.TextXAlignment.Left
msgBox.TextYAlignment = Enum.TextYAlignment.Top
msgBox.TextWrapped = true
msgBox.MultiLine = true
msgBox.ClearTextOnFocus = false
msgBox.BorderSizePixel = 0
msgBox.Parent = main

local msgC = Instance.new("UICorner")
msgC.CornerRadius = UDim.new(0, 6)
msgC.Parent = msgBox

local msgP = Instance.new("UIPadding")
msgP.PaddingLeft = UDim.new(0, sz(8))
msgP.PaddingRight = UDim.new(0, sz(8))
msgP.PaddingTop = UDim.new(0, sz(6))
msgP.PaddingBottom = UDim.new(0, sz(6))
msgP.Parent = msgBox

nextY(MSG_H)

-- ===== Spam row =====
local spamRowY = nextY(LABEL_H + ROW_GAP)
local cLbl = Instance.new("TextLabel")
cLbl.Size = UDim2.new(0.5, -PAD * 1.5, 0, LABEL_H)
cLbl.Position = UDim2.new(0, PAD, 0, spamRowY)
cLbl.BackgroundTransparency = 1
cLbl.Text = "Count"
cLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
cLbl.TextSize = IS_MOBILE and 11 or 12
cLbl.Font = Enum.Font.GothamMedium
cLbl.TextXAlignment = Enum.TextXAlignment.Left
cLbl.Parent = main

local dLbl = Instance.new("TextLabel")
dLbl.Size = UDim2.new(0.5, -PAD * 1.5, 0, LABEL_H)
dLbl.Position = UDim2.new(0.5, PAD * 0.5, 0, spamRowY)
dLbl.BackgroundTransparency = 1
dLbl.Text = "Delay (seconds)"
dLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
dLbl.TextSize = IS_MOBILE and 11 or 12
dLbl.Font = Enum.Font.GothamMedium
dLbl.TextXAlignment = Enum.TextXAlignment.Left
dLbl.Parent = main

Y = spamRowY + LABEL_H + ROW_GAP

local countBox = Instance.new("TextBox")
countBox.Size = UDim2.new(0.5, -PAD * 1.5, 0, INPUT_H)
countBox.Position = UDim2.new(0, PAD, 0, Y)
countBox.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
countBox.TextColor3 = Color3.fromRGB(255, 255, 255)
countBox.PlaceholderText = "5"
countBox.Text = config.count
countBox.TextSize = IS_MOBILE and 12 or 13
countBox.Font = Enum.Font.Gotham
countBox.ClearTextOnFocus = false
countBox.BorderSizePixel = 0
countBox.Parent = main

local ccC = Instance.new("UICorner")
ccC.CornerRadius = UDim.new(0, 6)
ccC.Parent = countBox

local ccP = Instance.new("UIPadding")
ccP.PaddingLeft = UDim.new(0, sz(8))
ccP.Parent = countBox

local delayBox = Instance.new("TextBox")
delayBox.Size = UDim2.new(0.5, -PAD * 1.5, 0, INPUT_H)
delayBox.Position = UDim2.new(0.5, PAD * 0.5, 0, Y)
delayBox.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
delayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
delayBox.PlaceholderText = "1"
delayBox.Text = config.delay
delayBox.TextSize = IS_MOBILE and 12 or 13
delayBox.Font = Enum.Font.Gotham
delayBox.ClearTextOnFocus = false
delayBox.BorderSizePixel = 0
delayBox.Parent = main

local dcC = Instance.new("UICorner")
dcC.CornerRadius = UDim.new(0, 6)
dcC.Parent = delayBox

local dcP = Instance.new("UIPadding")
dcP.PaddingLeft = UDim.new(0, sz(8))
dcP.Parent = delayBox

nextY(INPUT_H)

-- ===== Buttons =====
local BTN_H = IS_MOBILE and sz(36) or sz(42)
local btnY = nextY(ROW_GAP + sz(4))

local function makeButton(text, xPos, width, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(width.Scale, width.Offset, 0, BTN_H)
    btn.Position = UDim2.new(0, xPos, 0, btnY)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = IS_MOBILE and 13 or 14
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Parent = main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    return btn
end

local sendBtn = makeButton("📨 Send", PAD, UDim.new(0.5, -PAD * 1.5), Color3.fromRGB(60, 90, 200))
local spamBtn = makeButton("⚡ Spam", PAD * 0.5 + FRAME_W * 0.5, UDim.new(0.5, -PAD * 1.5), Color3.fromRGB(180, 60, 60))

nextY(BTN_H)

-- ===== Status label =====
local statusY = nextY(ROW_GAP)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -PAD * 2, 0, LABEL_H)
statusLabel.Position = UDim2.new(0, PAD, 0, statusY)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: idle"
statusLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
statusLabel.TextSize = IS_MOBILE and 11 or 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = main

nextY(LABEL_H + ROW_GAP)

-- ===== Log area =====
local remainingY = Y
local LOG_H = FRAME_H - remainingY - PAD - sz(14)

local logScroll = Instance.new("ScrollingFrame")
logScroll.Size = UDim2.new(1, -PAD * 2, 0, LOG_H)
logScroll.Position = UDim2.new(0, PAD, 0, remainingY)
logScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
logScroll.BorderSizePixel = 0
logScroll.ScrollBarThickness = 3
logScroll.ScrollBarImageColor3 = Color3.fromRGB(106, 17, 203)
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.Parent = main

local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 6)
logCorner.Parent = logScroll

local logList = Instance.new("UIListLayout")
logList.Padding = UDim.new(0, 3)
logList.SortOrder = Enum.SortOrder.LayoutOrder
logList.Parent = logScroll

local logPad = Instance.new("UIPadding")
logPad.PaddingLeft = UDim.new(0, sz(6))
logPad.PaddingRight = UDim.new(0, sz(6))
logPad.PaddingTop = UDim.new(0, sz(6))
logPad.PaddingBottom = UDim.new(0, sz(6))
logPad.Parent = logScroll

local logCounter = 0
local function addLog(text, ok)
    logCounter = logCounter + 1
    local e = Instance.new("TextLabel")
    e.Size = UDim2.new(1, 0, 0, sz(14))
    e.BackgroundTransparency = 1
    e.Text = "[" .. os.date("%H:%M:%S") .. "] " .. text
    e.TextColor3 = ok and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(220, 120, 120)
    e.TextSize = IS_MOBILE and 10 or 11
    e.Font = Enum.Font.Code
    e.TextXAlignment = Enum.TextXAlignment.Left
    e.LayoutOrder = logCounter
    e.Parent = logScroll
end

-- ===== Footer =====
local footer = Instance.new("TextLabel")
footer.Name = "Footer"
footer.Size = UDim2.new(1, -PAD * 2, 0, sz(14))
footer.Position = UDim2.new(0, PAD, 1, -sz(16))
footer.BackgroundTransparency = 1
footer.Text = "by Viq"
footer.TextColor3 = Color3.fromRGB(130, 100, 200)
footer.TextSize = IS_MOBILE and 10 or 11
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
spc.CornerRadius = UDim.new(0, 10)
spc.Parent = settingsPanel

local SY = sz(8)

local spTitle = Instance.new("TextLabel")
spTitle.Size = UDim2.new(1, -PAD * 2, 0, sz(22))
spTitle.Position = UDim2.new(0, PAD, 0, SY)
spTitle.BackgroundTransparency = 1
spTitle.Text = "⚙ Settings"
spTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
spTitle.TextSize = IS_MOBILE and 15 or 17
spTitle.Font = Enum.Font.GothamBold
spTitle.TextXAlignment = Enum.TextXAlignment.Left
spTitle.ZIndex = 51
spTitle.Parent = settingsPanel

local spSignature = Instance.new("TextLabel")
spSignature.Size = UDim2.new(0, 80, 0, sz(22))
spSignature.Position = UDim2.new(1, -80 - PAD, 0, SY)
spSignature.BackgroundTransparency = 1
spSignature.Text = "by Viq"
spSignature.TextColor3 = Color3.fromRGB(150, 120, 220)
spSignature.TextSize = IS_MOBILE and 12 or 13
spSignature.Font = Enum.Font.GothamBold
spSignature.TextXAlignment = Enum.TextXAlignment.Right
spSignature.ZIndex = 51
spSignature.Parent = settingsPanel

SY = SY + sz(24)

local histLabel = Instance.new("TextLabel")
histLabel.Size = UDim2.new(1, -PAD * 2, 0, sz(14))
histLabel.Position = UDim2.new(0, PAD, 0, SY)
histLabel.BackgroundTransparency = 1
histLabel.Text = "Saved webhooks (url + bot name):"
histLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
histLabel.TextSize = IS_MOBILE and 11 or 12
histLabel.Font = Enum.Font.GothamMedium
histLabel.TextXAlignment = Enum.TextXAlignment.Left
histLabel.ZIndex = 51
histLabel.Parent = settingsPanel

SY = SY + sz(18)

local HIST_H = IS_MOBILE and sz(180) or sz(240)

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
hc.CornerRadius = UDim.new(0, 6)
hc.Parent = histScroll

local hlist = Instance.new("UIListLayout")
hlist.Padding = UDim.new(0, 4)
hlist.SortOrder = Enum.SortOrder.LayoutOrder
hlist.Parent = histScroll

local hp = Instance.new("UIPadding")
hp.PaddingLeft = UDim.new(0, sz(6))
hp.PaddingRight = UDim.new(0, sz(6))
hp.PaddingTop = UDim.new(0, sz(6))
hp.PaddingBottom = UDim.new(0, sz(6))
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
        e.Size = UDim2.new(1, 0, 0, sz(20))
        e.BackgroundTransparency = 1
        e.Text = "Empty"
        e.TextColor3 = Color3.fromRGB(110, 110, 130)
        e.TextSize = IS_MOBILE and 11 or 12
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
        row.Size = UDim2.new(1, 0, 0, sz(38))
        row.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        row.Text = ""
        row.BorderSizePixel = 0
        row.AutoButtonColor = false
        row.ZIndex = 52
        row.LayoutOrder = i
        row.Parent = histScroll

        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 5)
        rc.Parent = row

        local nameLine = Instance.new("TextLabel")
        nameLine.Size = UDim2.new(1, -sz(85), 0, sz(14))
        nameLine.Position = UDim2.new(0, sz(6), 0, sz(2))
        nameLine.BackgroundTransparency = 1
        nameLine.Text = botName ~= "" and ("🤖 " .. botName) or "🤖 (no name)"
        nameLine.TextColor3 = Color3.fromRGB(180, 160, 255)
        nameLine.TextSize = IS_MOBILE and 10 or 11
        nameLine.Font = Enum.Font.GothamBold
        nameLine.TextXAlignment = Enum.TextXAlignment.Left
        nameLine.ZIndex = 53
        nameLine.Parent = row

        local previewLen = IS_MOBILE and 22 or 34
        local preview = url:sub(1, previewLen) .. (#url > previewLen and ".." or "")

        local urlLine = Instance.new("TextLabel")
        urlLine.Size = UDim2.new(1, -sz(85), 0, sz(12))
        urlLine.Position = UDim2.new(0, sz(6), 0, sz(16))
        urlLine.BackgroundTransparency = 1
        urlLine.Text = preview
        urlLine.TextColor3 = Color3.fromRGB(180, 180, 200)
        urlLine.TextSize = IS_MOBILE and 9 or 10
        urlLine.Font = Enum.Font.Code
        urlLine.TextXAlignment = Enum.TextXAlignment.Left
        urlLine.ZIndex = 53
        urlLine.Parent = row

        local useB = Instance.new("TextButton")
        useB.Size = UDim2.new(0, sz(34), 0, sz(20))
        useB.Position = UDim2.new(1, -sz(74), 0, sz(9))
        useB.BackgroundColor3 = Color3.fromRGB(60, 130, 200)
        useB.Text = "Use"
        useB.TextColor3 = Color3.fromRGB(255, 255, 255)
        useB.TextSize = IS_MOBILE and 10 or 11
        useB.Font = Enum.Font.GothamBold
        useB.BorderSizePixel = 0
        useB.ZIndex = 53
        useB.Parent = row

        local uc = Instance.new("UICorner")
        uc.CornerRadius = UDim.new(0, 4)
        uc.Parent = useB

        local delB = Instance.new("TextButton")
        delB.Size = UDim2.new(0, sz(34), 0, sz(20))
        delB.Position = UDim2.new(1, -sz(36), 0, sz(9))
        delB.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        delB.Text = "Del"
        delB.TextColor3 = Color3.fromRGB(255, 255, 255)
        delB.TextSize = IS_MOBILE and 10 or 11
        delB.Font = Enum.Font.GothamBold
        delB.BorderSizePixel = 0
        delB.ZIndex = 53
        delB.Parent = row

        local dc = Instance.new("UICorner")
        dc.CornerRadius = UDim.new(0, 4)
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

SY = SY + HIST_H + sz(8)

local function makeSettingBtn(text, xPos, width, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(width.Scale, width.Offset, 0, sz(30))
    b.Position = UDim2.new(0, xPos, 0, SY)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = IS_MOBILE and 11 or 12
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.ZIndex = 51
    b.Parent = settingsPanel

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = b

    return b
end

local saveHistBtn = makeSettingBtn("💾 Save", PAD, UDim.new(0.5, -PAD * 1.5), Color3.fromRGB(60, 150, 90))
local clearHistBtn = makeSettingBtn("🗑 Clear", PAD * 0.5 + FRAME_W * 0.5, UDim.new(0.5, -PAD * 1.5), Color3.fromRGB(180, 60, 60))

SY = SY + sz(30) + sz(6)

local resetBtn = makeSettingBtn("↺ Reset", PAD, UDim.new(0.5, -PAD * 1.5), Color3.fromRGB(120, 90, 200))
local backBtn = makeSettingBtn("← Back", PAD * 0.5 + FRAME_W * 0.5, UDim.new(0.5, -PAD * 1.5), Color3.fromRGB(80, 80, 100))

SY = SY + sz(30) + sz(6)

local pathInfo = Instance.new("TextLabel")
pathInfo.Size = UDim2.new(1, -PAD * 2, 0, sz(20))
pathInfo.Position = UDim2.new(0, PAD, 0, SY)
pathInfo.BackgroundTransparency = 1
pathInfo.Text = "Config: " .. CONFIG_FILE
pathInfo.TextColor3 = Color3.fromRGB(110, 110, 130)
pathInfo.TextSize = IS_MOBILE and 10 or 11
pathInfo.Font = Enum.Font.Code
pathInfo.TextXAlignment = Enum.TextXAlignment.Left
pathInfo.ZIndex = 51
pathInfo.Parent = settingsPanel

local spFooter = Instance.new("TextLabel")
spFooter.Size = UDim2.new(1, -PAD * 2, 0, sz(14))
spFooter.Position = UDim2.new(0, PAD, 1, -sz(16))
spFooter.BackgroundTransparency = 1
spFooter.Text = "by Viq"
spFooter.TextColor3 = Color3.fromRGB(130, 100, 200)
spFooter.TextSize = IS_MOBILE and 10 or 11
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
    addLog("Saved with name: " .. (botName ~= "" and botName or "by Viq"), true)
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
    if urlBox.Text == "" or not urlBox.Text:find("discord") then
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
        statusLabel.Text = "Status: sent as " .. nameShown
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

    local nameShown = usernameBox.Text ~= "" and usernameBox.Text or "by Viq"
    addLog("Spam started as: " .. nameShown .. " | " .. count .. " x " .. delay .. "s")

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
addLog("Bot name: " .. (config.botUsername ~= "" and config.botUsername or "by Viq"), true)
if IS_MOBILE then
    addLog("Mobile mode enabled", true)
else
    addLog("PC mode enabled", true)
end
addLog("by Viq", true)
