-- Wraith Menu Interface
-- Główny plik z interfejsem użytkownika

-- Ładowanie biblioteki Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Opóźnienie inicjalizacji dla bezpieczeństwa
task.wait(4)

-- Ładowanie logiki AimBot z GitHub (zamień URL na swój)
local AimBotCore
local success, err = pcall(function()
    AimBotCore = loadstring(game:HttpGet('https://raw.githubusercontent.com/TWOJE_NAZWA_UZYTKOWNIKA/TWOJE_REPOZYTORIUM/main/aimbot-core.lua'))()
end)

if not success then
    warn("Nie udało się załadować AimBot Core: " .. tostring(err))
    return
end

-- Tworzenie okna
local Window = Rayfield:CreateWindow({
   Name = "wraith",
   LoadingTitle = "loading modules",
   LoadingSubtitle = "by wraith team",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "wraith"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
   KeySettings = {
      Title = "",
      Subtitle = "m",
      Note = "",
      FileName = "",
      SaveKey = false,
      GrabKeyFromSite = false,
      Key = {""}
   }
})

-- Inicjalizacja AimBot Core
task.spawn(function()
    local initSuccess = AimBotCore:Initialize()
    if initSuccess then
        print("AimBot Core załadowany pomyślnie!")
    else
        warn("Błąd inicjalizacji AimBot Core")
    end
end)

-- Zakładka AimBot
local AimBotTab = Window:CreateTab("🎯 AimBot", nil)

-- Pobieranie aktualnej konfiguracji
local Config = AimBotCore:GetConfig()

-- Toggle główny
AimBotTab:CreateToggle({
    Name = "Enable AimBot",
    CurrentValue = Config.Enabled,
    Callback = function(Value)
        AimBotCore:SetEnabled(Value)
    end
})

-- Team Check
AimBotTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Config.TeamCheck,
    Callback = function(Value)
        AimBotCore:UpdateConfig({TeamCheck = Value})
    end
})

-- Wall Check
AimBotTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = Config.WallCheck,
    Callback = function(Value)
        AimBotCore:UpdateConfig({WallCheck = Value})
    end
})

-- Silent Aim
AimBotTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = Config.SilentAim,
    Callback = function(Value)
        AimBotCore:UpdateConfig({SilentAim = Value})
    end
})

-- Prediction
AimBotTab:CreateToggle({
    Name = "Prediction",
    CurrentValue = Config.Prediction,
    Callback = function(Value)
        AimBotCore:UpdateConfig({Prediction = Value})
    end
})

-- FOV Size
AimBotTab:CreateSlider({
    Name = "FOV Size",
    Range = {10, 500},
    Increment = 10,
    CurrentValue = Config.FOV,
    Callback = function(Value)
        AimBotCore:UpdateConfig({FOV = Value})
    end
})

-- Smoothness
AimBotTab:CreateSlider({
    Name = "Smoothness",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = Config.Smoothness,
    Callback = function(Value)
        AimBotCore:UpdateConfig({Smoothness = Value})
    end
})

-- Prediction Factor
AimBotTab:CreateSlider({
    Name = "Prediction Factor",
    Range = {0.1, 0.5},
    Increment = 0.01,
    CurrentValue = Config.PredictionFactor,
    Callback = function(Value)
        AimBotCore:UpdateConfig({PredictionFactor = Value})
    end
})

-- Target Bone Selection
AimBotTab:CreateDropdown({
    Name = "Target Bone",
    Options = Config.BoneSelection,
    CurrentOption = Config.CurrentBone,
    Callback = function(Option)
        AimBotCore:UpdateConfig({CurrentBone = Option})
    end
})

-- FOV Circle Visibility
AimBotTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = Config.FOVVisible,
    Callback = function(Value)
        AimBotCore:UpdateConfig({FOVVisible = Value})
    end
})

-- FOV Circle Color
AimBotTab:CreateColorPicker({
    Name = "FOV Circle Color",
    Color = Config.FOVColor,
    Callback = function(Value)
        AimBotCore:UpdateConfig({FOVColor = Value})
    end
})

-- Snapline Toggle
AimBotTab:CreateToggle({
    Name = "Show Snapline",
    CurrentValue = Config.SnaplineEnabled,
    Callback = function(Value)
        AimBotCore:UpdateConfig({SnaplineEnabled = Value})
    end
})

-- Snapline Color
AimBotTab:CreateColorPicker({
    Name = "Snapline Color",
    Color = Config.SnaplineColor,
    Callback = function(Value)
        AimBotCore:UpdateConfig({SnaplineColor = Value})
    end
})

-- Snapline Thickness
AimBotTab:CreateSlider({
    Name = "Snapline Thickness",
    Range = {1, 5},
    Increment = 1,
    CurrentValue = Config.SnaplineThickness,
    Callback = function(Value)
        AimBotCore:UpdateConfig({SnaplineThickness = Value})
    end
})

-- Snapline Transparency
AimBotTab:CreateSlider({
    Name = "Snapline Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = Config.SnaplineTransparency,
    Callback = function(Value)
        AimBotCore:UpdateConfig({SnaplineTransparency = Value})
    end
})

-- Debug info (opcjonalne)
AimBotTab:CreateButton({
    Name = "Show Current Target",
    Callback = function()
        local target = AimBotCore:GetCurrentTarget()
        if target then
            Rayfield:Notify({
                Title = "Current Target",
                Content = "Targeting: " .. target.Name,
                Duration = 3
            })
        else
            Rayfield:Notify({
                Title = "Current Target",
                Content = "No target found",
                Duration = 3
            })
        end
    end
})

-- Opóźniona notyfikacja o załadowaniu
task.wait(1.5)
Rayfield:Notify({
   Title = "wraith loaded!",
   Content = "all modules loaded and good to use",
   Duration = 5,
   Image = 4483362458,
   Actions = {
      Ignore = {
         Name = "Got it!",
         Callback = function()
            print("wraith")
         end
      },
   },
})

-- Cleanup przy zamknięciu
game:BindToClose(function()
    if AimBotCore then
        AimBotCore:Cleanup()
    end
end)