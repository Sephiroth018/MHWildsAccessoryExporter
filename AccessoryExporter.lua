local CsvWriter = require("AccessoryExporter.CsvWriter")
local AccessoryReader = require("AccessoryExporter.AccessoryReader")
local SettingsManager = require("AccessoryExporter.SettingsManager")
local Utils = require("AccessoryExporter.Utils")

local PlayerManager = sdk.get_managed_singleton("app.PlayerManager")

---@param readerOutput AccessoryReaderOutput
---@param playerName string
local function exportJson(readerOutput, playerName)
  if not SettingsManager.getCurrent().outputJson then
    return
  end

  json.dump_file(Utils.getPath(playerName, "accessories.json"), readerOutput)
end

---@param readerOutput AccessoryReaderOutput
---@param playerName string
local function exportGameWithJson(readerOutput, playerName)
  local path = Utils.getPath(playerName, "GameWith", "MHWildsSimulatorMyset.json")
  local gameWithData = { decos = {} }

  for _, accessory in ipairs(readerOutput.accessories) do
    if accessory.owned <= 5 then
      gameWithData.decos[tostring(accessory.accessoryIndex)] = accessory.owned
    end
  end

  sdk.copy_to_clipboard("window.localStorage.setItem('MHWildsSimulatorMyset', JSON.stringify(Object.assign(JSON.parse(window.localStorage.getItem('MHWildsSimulatorMyset') || '{}'), " ..
    json.dump_string(gameWithData) .. ")))")
end

---@param readerOutput AccessoryReaderOutput
local function exportCecilBowenSearch(readerOutput)
  local data = {}

  for _, accessory in ipairs(readerOutput.accessories) do
    if accessory.accessoryType == "Armor" then
      local name = accessory.name:gsub("[%[|%]]", "")
      data[name] = accessory.owned
    end
  end

  sdk.copy_to_clipboard("window.localStorage.setItem('decoInventory', '" .. json.dump_string(data) .. "')")
end

---@param readerOutput AccessoryReaderOutput
---@param playerName string
local function exportCsv(readerOutput, playerName)
  if not SettingsManager.getCurrent().outputCsv then
    return
  end

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

-- to hook for auto export:
-- app.GUI090700.startExecute() - Melding - calls app.cReceiveItemInfo.recive() and .judge()

re.on_draw_ui(function()
  if imgui.tree_node("AccessoryExporter") then
    local playerName = "N/A"
    local playerAvailable = false

    ---@type app.cPlayerManageInfo
    local masterPlayer = nil
    pcall(function() masterPlayer = PlayerManager:getMasterPlayer() end)

    if masterPlayer then
      playerName = masterPlayer:get_ContextHolder():get_Pl():get_PlayerName()
      playerAvailable = true
    end

    imgui.text("Points from surplus accessories:")
    imgui.same_line()
    imgui.text((AccessoryReader.stats and tostring(AccessoryReader.stats.surplusPoints)) or "N/A")

    if imgui.tree_node("Settings") then
      _, SettingsManager.getCurrent().outputJson = imgui.checkbox("Output data as json", SettingsManager.getCurrent().outputJson)
      _, SettingsManager.getCurrent().outputCsv = imgui.checkbox("Output data as csv", SettingsManager.getCurrent().outputCsv)

      imgui.tree_pop()
    end

    imgui.new_line()

    imgui.begin_disabled(not playerAvailable)
    if imgui.button("Export data") then
      exportData(playerName, { exportJson, exportCsv })
    end
    if imgui.button("Copy cecilbowen export script") then
      exportData(playerName, { exportCecilBowenSearch })
    end
    imgui.end_disabled()
    if imgui.button("Copy GameWith.net export script") then
      exportData(playerName, { exportGameWithJson })
    end
    imgui.end_disabled()

    imgui.tree_pop()
  end
end)

re.on_config_save(function()
  SettingsManager.save()
end)
