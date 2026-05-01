local player = game.Players.LocalPlayer

--// CONFIG
local config = require(game:GetService("ReplicatedStorage").Shared.Configs["Brainrot.config"])

--// UI
local ScreenGui = Instance.new("ScreenGui")
local Button = Instance.new("TextButton")

ScreenGui.Parent = game.CoreGui
Button.Parent = ScreenGui

Button.Size = UDim2.new(0, 150, 0, 50)
Button.Position = UDim2.new(0, 20, 0, 200)
Button.Text = "AUTO FARM: OFF"
Button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

--// STATE
local running = false

--// BOX (area waiting)
local boxCFrame = CFrame.new(-0.933, 45.275, 75.885)
local boxSize = Vector3.new(125.979, 52.991, 62.528)

local function getRandomPointInBox()
    return boxCFrame * CFrame.new(
        (math.random() - 0.5) * boxSize.X,
        (math.random() - 0.5) * boxSize.Y,
        (math.random() - 0.5) * boxSize.Z
    )
end

--// DETECT WAITING TEXT
local function getWaitingLabel()
    for _, v in pairs(player.PlayerGui:GetDescendants()) do
        if v:IsA("TextLabel") and v.Text:find("Waiting for Players") then
            return v
        end
    end
end

--// MOVE
local function moveTo(targetCFrame)
    local player = game.Players.LocalPlayer
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local speed = 350
    local duration = distance / speed

    local start = tick()
    local startCF = hrp.CFrame

    while tick() - start < duration do
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
            print("🟡 Masuk waiting → teleport SEKALI ke kotak")
            moveTo(getRandomPointInBox())
            inWaiting = true
			farmedThisRound = false
        end
        return true
    else
        if inWaiting then
            print("🟢 Game mulai → keluar dari waiting")
            inWaiting = false
        end
        return false
    end
end

local function clickOK()
    for _, v in pairs(player.PlayerGui:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            local text = string.lower(v.Text or "")

            if text == "okay" then
                print("🖱️ Klik OK")

                pcall(function()
                    firesignal(v.MouseButton1Click)
                end)

                return true -- langsung stop setelah ketemu
            end
        end
    end

    return false -- gak ada tombol OK
end

--// FARM
local function farm()
    -- HANDLE WAITING DULU
    if handleWaiting() then return end
	
	if farmedThisRound then
		print("⏳ Sudah farm ronde ini → nunggu next waiting")
		return
	end

    local folder = workspace:FindFirstChild("SpawnedBrainrots")
    local targetPosition = CFrame.new(-26, 23, 36)

    if not folder then return end

    local list = {}

    for _, obj in pairs(folder:GetChildren()) do
        if obj:GetAttribute("Rarity") == "Mythical" then
            table.insert(list, obj)
        end
    end
	
	if #list == 0 then
    print("❌ Tidak ada Mythical → skip ronde & nunggu respawn")

    farmedThisRound = true -- 🔥 anggap sudah selesai ronde ini

    -- opsional: balik ke base biar rapi
    moveTo(targetPosition)

    return
end

    table.sort(list, function(a, b)
        return getIncome(a) > getIncome(b)
    end)
	
	print("===== TOP 3 INCOME =====")

for i = 1, math.min(3, #list) do
    local obj = list[i]
    print(
        "#" .. i,
        obj:GetAttribute("BrainrotName"),
        "| Income:", getIncome(obj)
    )
end

    local count = 0

    for _, obj in ipairs(list) do
        if not running then return end
        if count >= 3 then break end

        if obj:IsA("Model") then
            moveTo(obj:GetPivot())
        elseif obj:IsA("BasePart") then
            moveTo(obj.CFrame)
        end

        task.wait(0.2)

        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            fireproximityprompt(prompt)
            count += 1
        end

        task.wait(0.3)
    end

    if count > 0 then
		moveTo(targetPosition)
		farmedThisRound = true -- 🔥 TANDA SUDAH FARM
		print("✅ Selesai farm ronde ini")
	end
end

--// BUTTON
Button.MouseButton1Click:Connect(function()
    running = not running

    if running then
        Button.Text = "AUTO FARM: ON"
        Button.BackgroundColor3 = Color3.fromRGB(0, 255, 0)

        task.spawn(function()
            while running do
				clickOK()
                farm()
                task.wait(2)
            end
        end)
    else
        Button.Text = "AUTO FARM: OFF"
        Button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
end)