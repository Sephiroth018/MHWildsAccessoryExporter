local CsvWriter = require("AccessoryExporter.CsvWriter")
local AccessoryReader = require("AccessoryExporter.AccessoryReader")
local SettingsManager = require("AccessoryExporter.SettingsManager")
local Utils = require("AccessoryExporter.Utils")

local PlayerManager = sdk.get_managed_singleton("app.PlayerManager") --[[@as app.PlayerManager]]

---@param readerOutput AccessoryReaderOutput
---@param playerName string
local function exportJson(readerOutput, playerName)
  json.dump_file(Utils.getPath(playerName, "accessories.json"), readerOutput)
end

---@param readerOutput AccessoryReaderOutput
---@param playerName string
local function exportGameWithJson(readerOutput, playerName)
  local gameWithData = { decos = {} }

  if SettingsManager.getCurrent().mergeGameWithDataWithExisting then
    gameWithData = json.load_file(Utils.getPath(playerName, "gamewith_data.json"))

    gameWithData = gameWithData or { decos = {} }
    if not gameWithData.decos then
      gameWithData.decos = {}
    end
  end

  for _, accessory in ipairs(readerOutput.accessories) do
    if accessory.owned <= 5 then
      gameWithData.decos[tostring(accessory.accessoryIndex)] = accessory.owned
    end
  end

  json.dump_file(Utils.getPath(playerName, "gamewith_data.json"), gameWithData, -1)
end

---@param readerOutput AccessoryReaderOutput
---@param playerName string
local function exportCecilBowenSearch(readerOutput, playerName)
  local data = {}

  for _, accessory in ipairs(readerOutput.accessories) do
    if accessory.accessoryType == "Armor" then
      local name = accessory.name:gsub("[%[|%]]", "")
      data[name] = accessory.owned
    end
  end

  json.dump_file(Utils.getPath(playerName, "cecilBowenSearch.json"), data, -1)
end

---@param readerOutput AccessoryReaderOutput
---@param playerName string
local function exportCsv(readerOutput, playerName)
  local columnOrder = { "accessoryIndex", "name", "slotLevel", "accessoryType", "rarity", "points", "max", "owned" }

  local csvWriter = CsvWriter.new(columnOrder)
  csvWriter:addRecords(readerOutput.accessories)

  fs.write(Utils.getPath(playerName, "accessories.csv"), csvWriter:toCsv())
end

---@param playerName string
---@param exportFunctions fun(accessories: AccessoryReaderOutput, playerName: string)[]
local function exportData(playerName, exportFunctions)
  local readerOutput = AccessoryReader.getAccessories()

  for _, exportFunction in ipairs(exportFunctions) do
    exportFunction(readerOutput, playerName)
  end
end

re.on_draw_ui(function()
  if imgui.tree_node("AccessoryExporter") then
    local playerName = "N/A"
    local playerAvailable = false

    local masterPlayer = nil
    pcall(function() masterPlayer = PlayerManager:getMasterPlayer() end)

    if masterPlayer then
      playerName = masterPlayer:get_ContextHolder():get_Pl():get_PlayerName()
      playerAvailable = true
    end

    imgui.text("Playername:")
    imgui.same_line()
    imgui.text(playerName)

    imgui.text("Export directory:")
    imgui.same_line()
    imgui.text(Utils.getPath(playerName))

    imgui.new_line()

    local mergeSettingChanged, newMergeSetting = imgui.checkbox("Merge existing GameWith data",
      SettingsManager.getCurrent().mergeGameWithDataWithExisting)
    if mergeSettingChanged then
      SettingsManager.getCurrent().mergeGameWithDataWithExisting = newMergeSetting
    end

    imgui.begin_disabled(not playerAvailable)
    if imgui.button("Export data") then
      exportData(playerName, { exportJson, exportGameWithJson, exportCsv, exportCecilBowenSearch })
    end
    imgui.end_disabled()

    imgui.tree_pop()
  end
end)

re.on_config_save(function()
  SettingsManager.save()
end)
