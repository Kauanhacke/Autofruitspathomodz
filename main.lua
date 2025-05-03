repeat wait() until game:IsLoaded()

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Remotes
local CommF_ = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("CommF_")

-- Auto team select: Marines
local function autoSelectTeam()
    local teamEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChooseTeam")
    pcall(function()
        teamEvent:FireServer("Marines")
    end)
end

autoSelectTeam()
wait(1)

-- Start time
local startTime = tick()

-- Show logo
local function createLogo()
    local gui = Instance.new("ScreenGui", game.CoreGui)
    gui.Name = "KaitunFruitLogo"

    local img = Instance.new("ImageLabel", gui)
    img.BackgroundTransparency = 1
    img.Size = UDim2.new(0, 200, 0, 200)
    img.Position = UDim2.new(0.5, -100, 0.1, 0)
    img.Image = "rbxassetid://17376121791" -- Substitua pelo seu ID após upload no Roblox
end

createLogo()

-- Teleport to position
local function teleportTo(pos)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end

-- Collect fruit
local function collectFruit(fruit)
    teleportTo(fruit.Position)
    wait(1.5)
    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, fruit, 0)
    wait(0.2)
    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, fruit, 1)
end

-- Store fruit
local function storeEquippedFruit()
    local tool = LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool") or LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    if not tool then return false end

    local fruitName = tool.Name

    if not LocalPlayer.Character:FindFirstChild(fruitName) then
        LocalPlayer.Character.Humanoid:EquipTool(tool)
        wait(0.5)
    end

    local success, response = pcall(function()
        return CommF_:InvokeServer("StoreFruit", "Eat", fruitName)
    end)

    return success and typeof(response) == "string" and string.find(response:lower(), "success")
end

-- Server Hop
local function serverHop()
    local gameId = game.PlaceId
    local success, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..gameId.."/servers/Public?sortOrder=Asc&limit=100")).data
    end)

    if success then
        for _, server in pairs(servers) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(gameId, server.id, LocalPlayer)
                break
            end
        end
    else
        warn("[Kaitun] Failed to get server list.")
    end
end

-- Main logic
local function main()
    local fruitFound = false
    local checkStart = tick()

    while tick() - checkStart < 10 do
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj:IsA("Tool") and obj:FindFirstChild("Handle") and string.find(obj.Name:lower(), "fruit") then
                fruitFound = true
                print("[Kaitun] Fruit found: " .. obj.Name)
                collectFruit(obj.Handle)
                wait(2)
                if storeEquippedFruit() then
                    print("[Kaitun] Fruit stored successfully!")
                else
                    warn("[Kaitun] Failed to store fruit.")
                end
                wait(1)
                break
            end
        end
        wait(0.5)
        if fruitFound then break end
    end

    if not fruitFound then
        print("[Kaitun] No fruit found. Hopping server...")
        wait(1)
        serverHop()
    end
end

-- Show time in server
spawn(function()
    while true do
        local elapsed = math.floor(tick() - startTime)
        print("[Kaitun] Time in server: " .. elapsed .. "s")
        wait(5)
    end
end)

main()
