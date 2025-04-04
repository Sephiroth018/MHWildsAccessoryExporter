---@class Utils
local Utils = {}

---@param ... any
function Utils.writeToLog(...)
  local args = { ... }
  local msg = ""

  for _, v in ipairs(args) do
    msg = msg .. tostring(v)
  end

  log.info(msg)
end

---@param table table|nil
function Utils.writeTableToLog(table)
  if not table then
    Utils.writeToLog("nil")
    return
  end

  Utils.writeToLog("{")

  for key, value in pairs(table) do
    Utils.writeToLog(key, ": ", value)
  end

  Utils.writeToLog("}")
end

---@param ... string
---@return string
function Utils.getPath(...)
  local args = { ... }
  local path = "AccessoryExporter"

  for _, v in ipairs(args) do
    path = path .. "/" .. v
  end

  return path
end

---@generic K, V
---@param origTable table<K, V>
---@return table<K,V>
function Utils.copyTable(origTable)
  local result = {}

  for key, value in pairs(origTable) do
    if type(value) == "table" then
      result[key] = Utils.copyTable(value)
    else
      result[key] = value
    end
  end

  return result
end

---@param enumType RETypeDefinition
---@param value integer
---@return string
function Utils.getEnumNameFromValue(enumType, value)
  local enumTypeName = enumType:get_full_name()
  if enumTypeName:sub(- #"_Serializable") == "_Serializable" then
    enumType = sdk.find_type_definition(enumTypeName:sub(1, #enumTypeName - #"_Serializable") .. "_Fixed")
  end

  local fields = enumType:get_fields()

  for _, field in ipairs(fields) do
    if field:is_static() then
      local fieldValue = field:get_data(nil)

      if fieldValue == value then
        return field:get_name()
      end
    end
  end

  return ""
end

return Utils
