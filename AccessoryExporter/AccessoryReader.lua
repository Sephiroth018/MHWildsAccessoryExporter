local Utils = require("AccessoryExporter.Utils")

local RARE_FIXED = sdk.create_instance("app.ItemDef.RARE_Fixed")
local ACCESSORY_TYPE_Fixed = sdk.create_instance("app.EquipDef.ACCESSORY_TYPE_Fixed")
local AccessoryUtil = sdk.find_type_definition("app.AccessoryUtil")
local EquipDef = sdk.find_type_definition("app.EquipDef")
local EquipUtil = sdk.find_type_definition("app.EquipUtil")
local GuiTextData = sdk.find_type_definition("via.gui.message")
local VariousDataManager = sdk.get_managed_singleton("app.VariousDataManager")

---@enum
local AccessoryTypeNameMapping = {
  [ACCESSORY_TYPE_Fixed.ACC_TYPE_00] = "Weapon",
  [ACCESSORY_TYPE_Fixed.ACC_TYPE_01] = "Armor",
  [ACCESSORY_TYPE_Fixed.MAX] = "-"
}

---@enum AccessoryPoints
local AccessoryPoints = {
  [RARE_FIXED.RARE2] = 1,
  [RARE_FIXED.RARE3] = 4,
  [RARE_FIXED.RARE4] = 20,
  [RARE_FIXED.RARE5] = 80,
  [RARE_FIXED.RARE6] = 120
}

---@class SkillInfo
---@field name string
---@field level integer
---@field maxLevel integer

---@class Accessory
---@field accessoryIndex integer
---@field name string
---@field max integer
---@field accessoryType string
---@field slotLevel string
---@field rarity string
---@field points integer
---@field skills SkillInfo[]

---@class OwnedAccessory : Accessory
---@field owned integer

---@class AccessoryStats
---@field overheadPoints integer

---@class AccessoryReaderOutput
---@field accessories OwnedAccessory[]
---@field accessoryStats AccessoryStats

---@param guid System.Guid
---@return string
local function getText(guid)
  return GuiTextData:get_method("get(System.Guid)"):call(nil, guid)
end

---@class AccessoryReader
---@field allAccessories table<string, Accessory>
local AccessoryReader = {
  allAccessories = {}
}

---@private
function AccessoryReader.readAllAccessories()
  if #AccessoryReader.allAccessories > 0 then
    return
  end

  local allAccessories = VariousDataManager._Setting._EquipDatas._AccessoryData:getValues()

  for i = 0, allAccessories:get_Count() - 1 do
    local accessory = allAccessories[i]
    local name = getText(accessory._Name)
    ---@type app.EquipDef.ACCESSORY_ID
    local id = AccessoryUtil:get_method("getAccessoryId(app.EquipDef.ACCESSORY_ID_Serializable)"):call(nil,
      accessory._AccessoryId)
    local accessoryType = AccessoryTypeNameMapping[accessory._AccessoryType._Value]
    local rarity = Utils.getEnumNameFromValue(accessory._Rare:get_type_definition(), accessory._Rare._Value)

    ---@type Accessory
    local ownedAccessory = {
      accessoryIndex = i + 1,
      name = name,
      owned = 0,
      max = 0,
      accessoryType = accessoryType,
      slotLevel = Utils.getEnumNameFromValue(accessory._SlotLevelAcc:get_type_definition(),
        accessory._SlotLevelAcc._Value),
      rarity = rarity,
      points = AccessoryPoints[accessory._Rare._Value],
      skills = {}
    }

    ---@type System.Collections.Generic.List<app.EquipDef.EquipSkillInfo>
    local skills = EquipUtil:get_method("getAccessorySkillList(app.EquipDef.ACCESSORY_ID)"):call(nil, id)

    local max = 0

    for i2 = 0, skills:get_Count() - 1 do
      local skill = skills[i2]
      local skillData = skill:get_SkillData()
      local skillMaxSkillLevel = skill:get_SkillMaxLv()
      local skillSkillLevel = skill:get_SkillLv()
      local skillMax = math.ceil(skillMaxSkillLevel / skillSkillLevel)

      local skillInfo = {
        name = getText(skillData:get_skillName()),
        level = skillSkillLevel,
        maxLevel = skillMaxSkillLevel
      }

      table.insert(ownedAccessory.skills, skillInfo)

      if max < skillMax then
        max = skillMax
      end
    end

    if accessoryType == "Weapon" then
      max = math.min(max * 2, 6)
    end

    ownedAccessory.max = max

    AccessoryReader.allAccessories[name] = ownedAccessory
  end
end

---@private
---@return table<string, OwnedAccessory>
function AccessoryReader.readOwnedAccessories()
  ---@type table<string, OwnedAccessory>
  local result = Utils.copyTable(AccessoryReader.allAccessories) --[[@as table<string, OwnedAccessory>]]

  ---@type System.Collections.Generic.List<app.EquipDef.AccessoryWorkInfo>
  local ownedAccessories = AccessoryUtil:get_method("getAllAccessoryWorks()"):call(nil)

  for i = 0, ownedAccessories:get_Count() - 1 do
    local accesory = ownedAccessories[i]
    local accessoryWork = accesory:get_AccessoryWork()
    local name = getText(EquipDef:get_method("Name(app.EquipDef.ACCESSORY_ID)"):call(nil, accessoryWork.ID) --[[@as System.Guid]])
    local owned = accessoryWork.Num

    result[name].owned = (result[name].owned or 0) + owned
  end

  return result
end

---@private
---@param accessories table<string, OwnedAccessory>
---@return AccessoryReaderOutput
function AccessoryReader.prepareForOutput(accessories)
  ---@type OwnedAccessory[]
  local result = {}
  local overheadPoints = 0

  for _, accessory in pairs(accessories) do
    table.insert(result, accessory)
    local overhead = math.max(0, accessory.owned - accessory.max)
    overheadPoints = overheadPoints + (overhead * accessory.points)
  end

  accessories = result

  table.sort(accessories, function(a, b)
    return a.accessoryIndex < b.accessoryIndex
  end)

  return { accessories = result, accessoryStats = { overheadPoints = overheadPoints } }
end

---@return AccessoryReaderOutput
function AccessoryReader.getAccessories()
  AccessoryReader.readAllAccessories()
  local accessories = AccessoryReader.readOwnedAccessories()

  return AccessoryReader.prepareForOutput(accessories)
end

return AccessoryReader
