--// PLAYER
local player = game.Players.LocalPlayer
local speaker = game:GetService("Players").LocalPlayer

--// CONFIG
local config = require(game:GetService("ReplicatedStorage").Shared.Configs["Brainrot.config"])

--// STATE
local running = false
local farmedThisRound = false
local maxTake = 3
local minIncome = 0

local MiniButton = Instance.new("TextButton")
MiniButton.Parent = game.CoreGui
MiniButton.Size = UDim2.new(0, 120, 0, 35)
MiniButton.Position = UDim2.new(0, 20, 0, 20)
MiniButton.Text = "OPEN UI"
MiniButton.Visible = false
MiniButton.ZIndex = 999

--// LOAD WINDUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Turbo Waffle Hub",
    Author = "Nerxx",
    Folder = "BrainrotFarm",
    Size = UDim2.fromOffset(500, 350),
    Theme = "Dark",
})

Window:EditOpenButton({
    Title = "Turbo Waffle Hub",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"), 
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "play"
})

--// UI
MainTab:Toggle({
    Title = "Auto Farm",
    Default = false,
    Callback = function(state)
        running = state

        if running then
            print("Auto Farm ON")
            
            -- === LOGIKA ANTI AFK (INTI IY) ===
            if getconnections then
                for _, connection in pairs(getconnections(speaker.Idled)) do
                    if connection["Disable"] then
                        connection["Disable"](connection)
                    elseif connection["Disconnect"] then
                        connection["Disconnect"](connection)
                    end
                end
            else
                -- Cadangan jika executor tidak mendukung getconnections
                speaker.Idled:Connect(function()
                    game:GetService("VirtualUser"):CaptureController()
                    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
                end)
            end
            -- ================================

            task.spawn(function()
                while running do
                    farm()
                    task.wait(2)
                end
            end)
        else
            print("Auto Farm OFF")
        end
    end
})

MainTab:Input({
    Title = "Max Take",
    Default = "3",
    Callback = function(val)
        local num = tonumber(val)
        if num and num > 0 then
            maxTake = num
            print("MaxTake:", maxTake)
        end
    end
})

MainTab:Input({
    Title = "Minimum Income",
    Default = "0",
    Callback = function(val)
        local num = tonumber(val)
        if num then
            minIncome = num
            print("MinIncome:", minIncome)
        end
    end
})

--// WAITING BOX
local boxCFrame = CFrame.new(-0.933, 45.275, 75.885)
local boxSize = Vector3.new(125.979, 52.991, 62.528)

local function getRandomPointInBox()
    return boxCFrame * CFrame.new(
        (math.random()-0.5)*boxSize.X,
        (math.random()-0.5)*boxSize.Y,
        (math.random()-0.5)*boxSize.Z
    )
end

--// DETECT WAITING
local function getWaitingLabel()
    for _, v in pairs(player.PlayerGui:GetDescendants()) do
        if v:IsA("TextLabel") and v.Text:find("Waiting for Players") then
            return v
        end
    end
end

--// MOVE SMOOTH (ANTI TELEPORT DETECT)
local function moveTo(targetCFrame)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local speed = 350
    local duration = distance / speed

    local start = tick()
    local startCF = hrp.CFrame

    while tick() - start < duration do
        if not running then return end
        local alpha = (tick() - start) / duration
        hrp.CFrame = startCF:Lerp(targetCFrame, alpha)
        task.wait()
    end

    hrp.CFrame = targetCFrame
end

--// GET INCOME
local function getIncome(obj)
    local id = obj:GetAttribute("BrainrotId")
    if not id then return 0 end

    local data = config[id] or (config.Brainrots and config.Brainrots[id])
    return data and data.BaseIncome or 0
end

--// WAITING HANDLER
local inWaiting = false

local function handleWaiting()
    local label = getWaitingLabel()
    local isWaiting = label and label.Text:find("Waiting for Players")

    if isWaiting then
        if not inWaiting then
            moveTo(getRandomPointInBox())
            inWaiting = true
            farmedThisRound = false
        end
        return true
    else
        if inWaiting then
            inWaiting = false
        end
        return false
    end
end

--// FARM
function farm()
    if handleWaiting() then return end

    if farmedThisRound then return end

    local folder = workspace:FindFirstChild("SpawnedBrainrots")
    local targetPosition = CFrame.new(-26,23,36)

    if not folder then return end

    local count = 0
    local taken = {}
    local startTime = tick()
	local endTime = 22

    print("Farming start")

    while count < maxTake and tick() - startTime < endTime do
        if not running then return end

        local found = false

        for _, obj in pairs(folder:GetChildren()) do
            if obj:GetAttribute("Rarity") == "Mythical"
            and getIncome(obj) >= minIncome
            and not taken[obj] then

                taken[obj] = true
                found = true

                print(obj:GetAttribute("BrainrotName"), "|", getIncome(obj))

                if obj:IsA("Model") then
                    moveTo(obj:GetPivot())
                else
                    moveTo(obj.CFrame)
                end

                task.wait(0.2)

                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    fireproximityprompt(prompt)
                    count += 1
					endTime += 3
                end

                task.wait(0.5)

                if count >= maxTake then break end
            end
        end

        if not found then
            task.wait(1)
        end
    end

    moveTo(targetPosition)
    farmedThisRound = true

    print("Done | Total:", count)
end