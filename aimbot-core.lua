-- AimBot Core Logic - POPRAWIONA WERSJA
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Moduł AimBot
local AimBotCore = {}

-- Domyślna konfiguracja
AimBotCore.Config = {
    Enabled = false,
    TeamCheck = true,
    WallCheck = true,
    FOV = 100,
    Smoothness = 5,
    SilentAim = false,
    Prediction = false,
    PredictionFactor = 0.135,
    BoneSelection = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    CurrentBone = "Head",
    FOVColor = Color3.fromRGB(255, 0, 0),
    FOVVisible = true,
    SnaplineEnabled = false,
    SnaplineColor = Color3.fromRGB(0, 255, 0),
    SnaplineThickness = 1,
    SnaplineTransparency = 0.7
}

-- Zmienne wewnętrzne
local CurrentTarget = nil
local AimConnection = nil
local SilentAimTarget = nil
local FOVCircle = nil
local Snapline = nil

-- Sprawdzenie czy Drawing API jest dostępne
local function IsDrawingSupported()
    return Drawing and Drawing.new
end

-- Debug function
local function DebugPrint(message)
    print("[AimBot Debug]: " .. tostring(message))
end

-- Funkcje pomocnicze
local function IsAlive(player)
    return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

local function GetClosestPlayer()
    local ClosestDistance = math.huge
    local ClosestPlayer = nil
    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and IsAlive(Player) then
            if AimBotCore.Config.TeamCheck and Player.Team and LocalPlayer.Team and Player.Team == LocalPlayer.Team then
                continue
            end

            local Character = Player.Character
            local TargetPart = Character:FindFirstChild(AimBotCore.Config.CurrentBone)
            if not TargetPart then
                TargetPart = Character:FindFirstChild("HumanoidRootPart")
            end

            if TargetPart then
                local Vector, OnScreen = Camera:WorldToViewportPoint(TargetPart.Position)
                if OnScreen then
                    local Distance = (Vector2.new(Vector.X, Vector.Y) - ScreenCenter).Magnitude
                    if Distance < AimBotCore.Config.FOV and Distance < ClosestDistance then
                        if AimBotCore.Config.WallCheck then
                            local RaycastParams = RaycastParams.new()
                            RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist 
                            RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                            
                            local Direction = (TargetPart.Position - Camera.CFrame.Position).Unit
                            local Distance3D = (TargetPart.Position - Camera.CFrame.Position).Magnitude
                            
                            local RaycastResult = workspace:Raycast(Camera.CFrame.Position, Direction * Distance3D, RaycastParams)
                            
                            if not RaycastResult or RaycastResult.Instance:IsDescendantOf(Character) then
                                ClosestDistance = Distance
                                ClosestPlayer = Player
                            end
                        else
                            ClosestDistance = Distance
                            ClosestPlayer = Player
                        end
                    end
                end
            end
        end
    end
    return ClosestPlayer
end

local function AimAt(Player)
    if not Player or not IsAlive(Player) then return end
    
    local TargetPart = Player.Character:FindFirstChild(AimBotCore.Config.CurrentBone)
    if not TargetPart then
        TargetPart = Player.Character:FindFirstChild("HumanoidRootPart")
    end
    if not TargetPart then return end

    local TargetPosition = TargetPart.Position
    
    if AimBotCore.Config.Prediction then
        local Velocity = Vector3.new(0, 0, 0)
        if TargetPart.AssemblyLinearVelocity then
            Velocity = TargetPart.AssemblyLinearVelocity
        elseif TargetPart.Velocity then
            Velocity = TargetPart.Velocity
        end
        TargetPosition = TargetPosition + (Velocity * AimBotCore.Config.PredictionFactor)
    end

    if AimBotCore.Config.SilentAim then
        SilentAimTarget = {
            Position = TargetPosition,
            Player = Player
        }
    else
        local CameraPosition = Camera.CFrame.Position
        local Direction = (TargetPosition - CameraPosition).Unit
        local NewCFrame = CFrame.lookAt(CameraPosition, TargetPosition)
        
        if AimBotCore.Config.Smoothness > 1 then
            local CurrentCFrame = Camera.CFrame
            local LerpedCFrame = CurrentCFrame:Lerp(NewCFrame, 1 / AimBotCore.Config.Smoothness)
            Camera.CFrame = LerpedCFrame
        else
            Camera.CFrame = NewCFrame
        end
    end
end

-- FOV Circle Management
local function CreateFOVCircle()
    if not IsDrawingSupported() then
        DebugPrint("Drawing API nie jest wspierane!")
        return false
    end
    
    if FOVCircle then 
        pcall(function() FOVCircle:Remove() end)
        FOVCircle = nil
    end
    
    local success, err = pcall(function()
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Visible = AimBotCore.Config.FOVVisible and AimBotCore.Config.Enabled
        FOVCircle.Radius = AimBotCore.Config.FOV
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Color = AimBotCore.Config.FOVColor
        FOVCircle.Thickness = 2
        FOVCircle.Filled = false
        FOVCircle.NumSides = 64
        FOVCircle.Transparency = 0.7
    end)
    
    if not success then
        DebugPrint("Błąd tworzenia FOV Circle: " .. tostring(err))
        return false
    end
    
    DebugPrint("FOV Circle utworzony pomyślnie")
    return true
end

local function UpdateFOVCircle()
    if FOVCircle then
        local success, err = pcall(function()
            FOVCircle.Visible = AimBotCore.Config.FOVVisible and AimBotCore.Config.Enabled
            FOVCircle.Radius = AimBotCore.Config.FOV
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            FOVCircle.Color = AimBotCore.Config.FOVColor
        end)
        if not success then
            DebugPrint("Błąd aktualizacji FOV Circle: " .. tostring(err))
        end
    end
end

-- Snapline Management
local function CreateSnapline()
    if not IsDrawingSupported() then
        return false
    end
    
    local success, err = pcall(function()
        Snapline = Drawing.new("Line")
        Snapline.Visible = false
    end)
    
    if not success then
        DebugPrint("Błąd tworzenia Snapline: " .. tostring(err))
        return false
    end
    
    return true
end

local function UpdateSnapline()
    if not Snapline then return end
    
    pcall(function()
        if AimBotCore.Config.SnaplineEnabled and AimBotCore.Config.Enabled and CurrentTarget and IsAlive(CurrentTarget) then
            local TargetPart = CurrentTarget.Character:FindFirstChild(AimBotCore.Config.CurrentBone) or CurrentTarget.Character.HumanoidRootPart
            local Vector, OnScreen = Camera:WorldToViewportPoint(TargetPart.Position)
            if OnScreen then
                Snapline.Visible = true
                Snapline.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                Snapline.To = Vector2.new(Vector.X, Vector.Y)
                Snapline.Color = AimBotCore.Config.SnaplineColor
                Snapline.Thickness = AimBotCore.Config.SnaplineThickness
                Snapline.Transparency = AimBotCore.Config.SnaplineTransparency
            else
                Snapline.Visible = false
            end
        else
            Snapline.Visible = false
        end
    end)
end

-- Silent Aim Hook (tylko jeśli jest wspierany)
local OldNamecall
if hookmetamethod then
    OldNamecall = hookmetamethod(game, "__namecall", function(Self, ...)
        local Method = getnamecallmethod()
        local Args = {...}
        
        if Method == "FireServer" or Method == "InvokeServer" then
            if SilentAimTarget and AimBotCore.Config.SilentAim and AimBotCore.Config.Enabled then
                if string.find(tostring(Self), "Remot") and (string.find(string.lower(tostring(Self)), "fire") or string.find(string.lower(tostring(Self)), "shoot")) then
                    for i, v in pairs(Args) do
                        if typeof(v) == "Vector3" then
                            Args[i] = SilentAimTarget.Position
                            break
                        end
                    end
                end
            end
        elseif Method == "Raycast" then
            if SilentAimTarget and AimBotCore.Config.SilentAim and AimBotCore.Config.Enabled then
                if Args[2] and typeof(Args[2]) == "Vector3" then
                    local Direction = (SilentAimTarget.Position - Args[1]).Unit
                    Args[2] = Direction * Args[2].Magnitude
                end
            end
        end
        
        return OldNamecall(Self, unpack(Args))
    end)
else
    DebugPrint("hookmetamethod nie jest wspierane - Silent Aim nie będzie działać")
end

-- Główna pętla AimBot
local function MainLoop()
    -- ZMIENIONO: Usunięto warunek prawego przycisku myszy dla testów
    -- Teraz aimbot będzie działać gdy jest włączony
    if AimBotCore.Config.Enabled then
        CurrentTarget = GetClosestPlayer()
        if CurrentTarget then
            -- Tylko dla testów - dodaj warunek z przyciskiem myszy jeśli chcesz
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                AimAt(CurrentTarget)
            end
        end
    else
        CurrentTarget = nil
    end
    UpdateFOVCircle()
    UpdateSnapline()
end

-- Publiczne funkcje modułu
function AimBotCore:Initialize()
    DebugPrint("Inicjalizacja AimBot Core...")
    
    -- Sprawdź wsparcie dla Drawing API
    if IsDrawingSupported() then
        DebugPrint("Drawing API wspierane")
        CreateFOVCircle()
        CreateSnapline()
    else
        DebugPrint("Drawing API NIE jest wspierane!")
    end
    
    if AimConnection then 
        AimConnection:Disconnect() 
        AimConnection = nil
    end
    AimConnection = RunService.Heartbeat:Connect(MainLoop)
    
    DebugPrint("AimBot Core zainicjalizowany")
    return true
end

function AimBotCore:UpdateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if AimBotCore.Config[key] ~= nil then
            AimBotCore.Config[key] = value
            DebugPrint("Zaktualizowano " .. key .. " na " .. tostring(value))
        end
    end
    UpdateFOVCircle()
    UpdateSnapline()
end

function AimBotCore:GetConfig()
    return AimBotCore.Config
end

function AimBotCore:SetEnabled(enabled)
    AimBotCore.Config.Enabled = enabled
    DebugPrint("AimBot " .. (enabled and "WŁĄCZONY" or "WYŁĄCZONY"))
    if not enabled then
        SilentAimTarget = nil
        CurrentTarget = nil
    end
    UpdateFOVCircle()
    UpdateSnapline()
end

function AimBotCore:Cleanup()
    if AimConnection then
        AimConnection:Disconnect()
        AimConnection = nil
    end
    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
        FOVCircle = nil
    end
    if Snapline then
        pcall(function() Snapline:Remove() end)
        Snapline = nil
    end
    DebugPrint("Cleanup zakończony")
end

function AimBotCore:GetCurrentTarget()
    return CurrentTarget
end

-- Cleanup po wyjściu gracza
Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        AimBotCore:Cleanup()
    end
end)

return AimBotCore
