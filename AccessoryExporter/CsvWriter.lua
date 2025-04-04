---@class CsvWriter
---@field private headerColumns string[]
---@field private output string[]
---@field private separator string
---@field private newline string
local CsvWriter = {}
CsvWriter.__index = CsvWriter

---@param value any
---@return string
local function valueToString(value)
  return "\"" .. tostring(value):gsub("\"", "\"\"") .. "\""
end

function CsvWriter.new(headerColumns, separatorParam, newlineParam)
  local self = setmetatable({}, CsvWriter)

  self.headerColumns = headerColumns
  self.separator = separatorParam or ","
  self.newline = newlineParam or "\n"
  self.output = { self:getHeaderLine() }

  return self
end

---@param recordData table<string, any>
function CsvWriter:addRecord(recordData)
  local record = {}

  for _, column in ipairs(self.headerColumns) do
    table.insert(record, valueToString(recordData[column]))
  end

  table.insert(self.output, table.concat(record, self.separator))
end

---comment
---@param recordTable any[]
function CsvWriter:addRecords(recordTable)
  for _, record in ipairs(recordTable) do
    self:addRecord(record)
  end
end

---@return string
function CsvWriter:getHeaderLine()
  local columns = {}

  for _, column in ipairs(self.headerColumns) do
    table.insert(columns, valueToString(column))
  end

  return table.concat(columns, self.separator)
end

---@return string
function CsvWriter:toCsv()
  return table.concat(self.output, self.newline)
end

return CsvWriter
