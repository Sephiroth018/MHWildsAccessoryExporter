---@class Settings
---@field public outputJson boolean
---@field public outputGameWithData boolean
---@field public mergeGameWithDataWithExisting boolean
---@field public outputCecilBowenSearchData boolean
---@field public outputCsv boolean

---@return Settings
local function getDefaultSettings()
  return {
    outputJson = true,
    outputGameWithData = true,
    mergeGameWithDataWithExisting = true,
    outputCecilBowenSearchData = true,
    outputCsv = true
  }
end

---@class SettingsManager
---@field private settings Settings
---@field private isLoaded boolean
local SettingsManager = {
  settings = getDefaultSettings(),
  isLoaded = false,
}

local filePath = "AccessoryExporter/settings.json"

function SettingsManager.save()
  json.dump_file(filePath, SettingsManager.settings)
end

function SettingsManager.load()
  local loadedSettings = json.load_file(filePath)

  ---@diagnostic disable-next-line: missing-fields
  SettingsManager.settings = {}

  for field, defaultValue in pairs(getDefaultSettings()) do
    SettingsManager.settings[field] = (loadedSettings and loadedSettings[field]) or defaultValue
  end
end

---@return Settings
function SettingsManager.getCurrent()
  if not SettingsManager.isLoaded then
    SettingsManager.load()
    SettingsManager.isLoaded = true
  end

  return SettingsManager.settings
end

return SettingsManager
