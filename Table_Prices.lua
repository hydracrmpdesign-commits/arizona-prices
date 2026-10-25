local _0x90EB = require('ffi')
local _0x4928 = require('encoding')
_0x4928.default ='CP1251'local _0xACD5 = _0x4928.UTF8local _0x69E6, _0xAAB1 = pcall(require,'mimgui')
local _0x0A1B, _0x19D1 = pcall(require,'fAwesome6')
if not _0x69E6 or not _0x0A1B then
local _0xB202 = {}
if not _0x69E6 then _0xB202[#_0xB202 + 1] ="mimgui"end
if not _0x0A1B then _0xB202[#_0xB202 + 1] ="fAwesome6"end
function main()
while not isSampAvailable() do wait(100) end
sampAddChatMessage(_0xACD5:decode("{FF5555}[Arizona Prices] {FFFFFF}Не найдены библиотеки: {FFCC33}".. table.concat(_0xB202,", ") .."{FFFFFF}. Положите их в папку {FFCC33}moonloader\\lib{FFFFFF} и перезапустите игру."), -1)
sampAddChatMessage(_0xACD5:decode("{FF5555}[Arizona Prices] {FFFFFF}Где скачать, смотрите в нашем ТГК: {33AAFF}@arizona_prices"), -1)
thisScript():unload()
end
return
endlocal _0xB72A = setmetatable({}, { __index = function(_0x374C, _0x6B6F) return _0x19D1[_0x6B6F] or""end })
_0x90EB.cdef[[
    int ShellExecuteA(void* hwnd, const char* op, const char* file, const char* params, const char* dir, int show);
]]local _0xE3D9 = _0x90EB.load('shell32')
local _0x27CF = nillocal function _0x1810(_0xEE69)
_0x27CF = _0xEE69
end
local _0xF7A7 = _0xAAB1.new.bool(false)
local _0x602D = _0xAAB1.new.bool(false)
local _0x312F = _0xB72A.CIRCLE_PLUS .." Добавить предмет###item_modal"local _0x88DA = _0xB72A.PEN_LINE .." Редактировать предмет###item_modal"local _0x7972 = _0xAAB1.new.char[256]()
local _0x2279 = _0xAAB1.new.char[256]()
local _0xE998 = _0xAAB1.new.char[64]()
local _0x15D8 = _0xAAB1.new.char[64]()
local _0xC4BB = _0xAAB1.new.int(0)
local _0x03B9 = false
local _0x94C4 = nil
local _0x149C = false
local _0xDEBC = false
local _0x12C4 = nil
local _0x134E = nillocal _0xBB1A = false
local _0xF928 = 0
local _0x3E98 = false
local _0xF7A3 = false
local _0x169C = false
local _0x1217 = {}
local _0xCE02 = getWorkingDirectory() .."\\config\\item_prices.json"local _0x294A = {}
local function _0x913B(_0xC139, _0x93A6)
_0x294A[#_0x294A + 1] = { _0xC139 = _0xC139, _0x93A6 = _0x93A6 }
end
local _0x8869 = {}
local function _0x76CF(_0x40E5)
return debug.traceback(tostring(_0x40E5), 2)
end
local function _0x04D5(where, _0x847E)
local _0xC139 = tostring(_0x847E)
_0x8869[#_0x8869 + 1] = os.date("%H:%M:%S") .." [".. tostring(where) .."] ".. (_0xC139:sub(1, 300):gsub("%s+"," "))
if #_0x8869 > 8 then table.remove(_0x8869, 1) end
pcall(function()
print("[Arizona Prices] ".. tostring(where) ..": ".. _0xC139)
local _0x6A3E = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0x6A3E) then createDirectory(_0x6A3E) end
local _0x1D80 = _0x6A3E .."\\arizona_prices_errors.log"local _0x16E5 = io.open(_0x1D80,"ab")
if _0x16E5 then
if (_0x16E5:seek("end") or 0) > 200000 then
_0x16E5:close()
_0x16E5 = io.open(_0x1D80,"wb")
end
if _0x16E5 then
_0x16E5:write(os.date("%Y-%m-%d %H:%M:%S") .." [".. tostring(where) .."] ".. _0xC139 .."\n\n")
_0x16E5:close()
end
end
end)
endlocal function _0x076F(where, fn, ...)
local _0xE0E1 = { ... }
local _0x2457, _0x847E = xpcall(function() return fn(unpack(_0xE0E1)) end, _0x76CF)
if not _0x2457 then _0x04D5(where, _0x847E) end
return _0x2457
endlocal _0x9041 = {}
local function _0x0EA0(fn)
_0x9041[#_0x9041 + 1] = fn
endlocal function _0x7DD2(_0x6E19, fn, on_fail)
return function(...)
local _0xE0E1 = { ... }
local _0xB322 = select("#", ...)
local _0x2457, _0x847E = xpcall(function() return fn(unpack(_0xE0E1, 1, _0xB322)) end, _0x76CF)
if not _0x2457 then
_0x04D5("frame:".. _0x6E19, _0x847E)
_0x913B("Ошибка в окне (".. _0x6E19 .."). Откройте Настройки и нажмите «Сообщить об ошибке»","err")
if on_fail then pcall(on_fail) end
end
end
end
local function _0xDB95(_0x1D80)
local _0x16E5 = io.open(_0x1D80,"rb")
if not _0x16E5 then return nil end
local _0x6D18 = _0x16E5:read("*a")
_0x16E5:close()
return _0x6D18
end
local function _0x490E(_0x1D80, content)
local _0x16E5 = io.open(_0x1D80,"wb")
if not _0x16E5 then return false end
local _0x2457 = _0x16E5:write(content)
_0x16E5:close()
return _0x2457 ~= nil and _0x2457 ~= false
end
local function _0x1B9F(str)
if type(str) ~="string"or str ==""then return false end
local _0x2457, _0x47FC = pcall(decodeJson, str)
return _0x2457 and type(_0x47FC) =="table"endlocal function _0x8F51(_0x1D80, content)
if type(content) ~="string"or content ==""then return false end
local _0x0296 = _0x1D80 ..".tmp"if not _0x490E(_0x0296, content) then os.remove(_0x0296); return false end
if _0xDB95(_0x0296) ~= content then os.remove(_0x0296); return false end
local _0x4E65 = _0xDB95(_0x1D80)
if _0x4E65 and _0x1B9F(_0x4E65) then _0x490E(_0x1D80 ..".bak", _0x4E65) end
os.remove(_0x1D80)
if not os.rename(_0x0296, _0x1D80) then
local _0x2457 = _0x490E(_0x1D80, content)
os.remove(_0x0296)
return _0x2457
end
return true
endlocal function _0xF239(_0x1D80)
local _0x6D18 = _0xDB95(_0x1D80)
if _0x1B9F(_0x6D18) then return decodeJson(_0x6D18) end
local _0x527F = _0xDB95(_0x1D80 ..".bak")
if _0x1B9F(_0x527F) then
if _0x6D18 and _0x6D18 ~=""then
_0x913B("Файл данных был повреждён - восстановили из резервной копии","warn")
_0x490E(_0x1D80 ..".broken", _0x6D18)
end
_0x490E(_0x1D80, _0x527F)
return decodeJson(_0x527F)
end
if _0x6D18 and _0x6D18 ~=""then
_0x490E(_0x1D80 ..".broken", _0x6D18)
_0x913B("Файл данных повреждён и копии нет - начинаем с чистого листа","err")
end
return nil
endlocal _0xAADF = {
on = false,
HASH = 888940931,
LIQ = { ["Ликвид"] = true, ["Средне"] = true, ["Неликвид"] = true },
_0x1D80 = getWorkingDirectory() .."\\config\\arizona_prices_admin.json",
}
function _0xAADF.hash(_0x14C4)
local _0xB734 ="arzp|".. tostring(_0x14C4):lower()
local _0x86ED = 5381
for _0x4E41 = 1, #_0xB734 do _0x86ED = (_0x86ED * 33 + _0xB734:byte(_0x4E41)) % 4294967296 end
return _0x86ED
end
function _0xAADF.valid_liq(_0x1545)
if type(_0x1545) =="string"and _0xAADF.LIQ[_0x1545] then return _0x1545 end
return nil
end
function _0xAADF.enable(_0x14C4)
if _0xAADF.hash(_0x14C4) ~= _0xAADF.HASH then return false end
_0xAADF.on = true
local _0x6A3E = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0x6A3E) then createDirectory(_0x6A3E) end
_0x490E(_0xAADF.path, encodeJson({ hash = _0xAADF.HASH }))
return true
end
function _0xAADF.disable()
_0xAADF.on = false
os.remove(_0xAADF.path)
end
do
local _0x47FC = _0xF239(_0xAADF.path)
if type(_0x47FC) =="table"and tonumber(_0x47FC.hash) == _0xAADF.HASH then _0xAADF.on = true end
end
local function _0x9060()
local _0xA9F3 = _0xF239(_0xCE02)
if _0xA9F3 then
local _0x9D3F = {}
for _0x374C, _0x1545 in ipairs(_0xA9F3) do
if type(_0x1545) =="table"then
_0x9D3F[#_0x9D3F + 1] = { _0x3EBB = tostring(_0x1545.item or""), _0x2FFC = tonumber(_0x1545.buy) or 0, _0xE824 = tonumber(_0x1545.sell) or 0, _0x000B = _0xAADF.valid_liq(_0x1545.liq) }
end
end
_0x1217 = _0x9D3F
elseif not doesFileExist(_0xCE02) then
_0x1217 = {}
end
end
local function _0x64DF()
local _0x6A3E = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0x6A3E) then
createDirectory(_0x6A3E)
end
local _0x2457, _0x3621 = pcall(encodeJson, _0x1217)
if _0x2457 and type(_0x3621) =="string"and _0x3621 ~=""then
if not _0x8F51(_0xCE02, _0x3621) then
_0x913B("Не удалось сохранить список предметов","err")
end
end
end
local function _0x3882(amount)
local _0xEC65 = tonumber(amount)
if not _0xEC65 then return tostring(amount) end
local _0x4B0A = _0xEC65 < 0 and"-"or""_0xEC65 = math.abs(_0xEC65)
local _0xB734 = (_0xEC65 == math.floor(_0xEC65)) and string.format("%.0f", _0xEC65) or tostring(_0xEC65)
local _0x970D, _0xF044 = _0xB734:match("^(%d+)(.*)$")
if not _0x970D then return _0x4B0A .. _0xB734 end
_0x970D = _0x970D:reverse():gsub("(%d%d%d)","%1."):reverse()
if _0x970D:sub(1, 1) =="."then _0x970D = _0x970D:sub(2) end
return _0x4B0A .. _0x970D .. _0xF044
end
local function _0xF8EB(str)
local _0x0DFF, _0xE11F = pcall(function() return _0xACD5:decode(tostring(str or"")) end)
str = _0x0DFF and _0xE11F or tostring(str or"")
return (str:gsub(".", function(char)
local _0xC24B = char:byte()
if _0xC24B >= 192 and _0xC24B <= 223 then
return string.char(_0xC24B + 32)
elseif _0xC24B == 168 then
return string.char(184)
end
return char:lower()
end))
end
local function _0x2EFC()
_0x602D[0] = false
_0xAAB1.CloseCurrentPopup()
end
local function _0xEE8F()
_0x03B9 = false
_0x94C4 = nil
_0xAAB1.StrCopy(_0x2279,"")
_0xAAB1.StrCopy(_0xE998,"")
_0xAAB1.StrCopy(_0x15D8,"")
_0x602D[0] = true
_0x149C = true
end
local function _0x906A(_0xE0A2)
local _0x3EBB = _0x1217[_0xE0A2]
if not _0x3EBB then return end
_0x03B9 = true
_0x94C4 = _0xE0A2
_0xAAB1.StrCopy(_0x2279, _0x3EBB.item or"")
_0xAAB1.StrCopy(_0xE998, tostring(_0x3EBB.buy or 0))
_0xAAB1.StrCopy(_0x15D8, tostring(_0x3EBB.sell or 0))
_0x602D[0] = true
_0x149C = true
endlocal _0x3CC0 = {
accent = {0.98, 0.55, 0.12}, opacity = 1.0, overlay_scale = 1.0, open_key = 0, _0xC83F = true, toast_corner = 3,
halloween = true,border_mode = 1, border_speed = 1.0, shadow = true, _0xC867 ="seguisb",
win_w = 835, win_h = 500, bg_fx = true, splash = true,
}local _0xD3A9 = {
_0xF192 = 0,_0x31C5 = 1,base = 1,tab_t = -10,table_t = -10,was_open = false,
splashed = false,TAB_ORDER = { 1, 2, 3, 4, 8, 6, 5, 7 },}local _0xAC4E = {
{ _0xE53D ="seguisb", _0x6E19 ="Segoe UI Semibold", file ="seguisb.ttf"},
{ _0xE53D ="segoeui", _0x6E19 ="Segoe UI", file ="segoeui.ttf"},
{ _0xE53D ="bahnschrift", _0x6E19 ="Bahnschrift", file ="bahnschrift.ttf"},
{ _0xE53D ="corbel", _0x6E19 ="Corbel", file ="corbel.ttf"},
{ _0xE53D ="candara", _0x6E19 ="Candara", file ="candara.ttf"},
{ _0xE53D ="calibri", _0x6E19 ="Calibri", file ="calibri.ttf"},
{ _0xE53D ="verdana", _0x6E19 ="Verdana", file ="verdana.ttf"},
{ _0xE53D ="tahoma", _0x6E19 ="Tahoma", file ="tahoma.ttf"},
}
local _0xA90D = { { _0xE53D ="default", _0x6E19 ="Системный (Trebuchet)"} }
pcall(function()
local _0x6A3E = getFolderPath(0x14)
for _0x374C, _0x16E5 in ipairs(_0xAC4E) do
local _0x1D80 = _0x6A3E .."\\".. _0x16E5.file
if doesFileExist(_0x1D80) then
_0xA90D[#_0xA90D + 1] = { _0xE53D = _0x16E5.key, _0x6E19 = _0x16E5.name, _0x1D80 = _0x1D80 }
end
end
end)
local function _0x43DE(_0x6BF7, lo, hi)
return math.max(lo, math.min(hi, _0x6BF7))
end
local function _0xB079(mult, _0xF192)
local _0x1C8E = _0x3CC0.accent
local _0x31C5 = mult or 1.0
return _0xAAB1.ImVec4(math.min(1, _0x1C8E[1] * _0x31C5), math.min(1, _0x1C8E[2] * _0x31C5), math.min(1, _0x1C8E[3] * _0x31C5), _0xF192 or 1.0)
endlocal function _0x82F6(_0x70A2, _0x2126, _0x527F, _0x1C8E)
return _0xAAB1.ColorConvertFloat4ToU32(_0xAAB1.ImVec4(_0x70A2, _0x2126, _0x527F, _0x1C8E * _0xD3A9.m))
end
local function _0xE167(_0x86ED, _0xB734, _0x1545)
_0x86ED = _0x86ED % 1
local _0x4E41 = math.floor(_0x86ED * 6)
local _0x16E5 = _0x86ED * 6 - _0x4E41
local _0x721A, _0xE719, _0xC5C0 = _0x1545 * (1 - _0xB734), _0x1545 * (1 - _0x16E5 * _0xB734), _0x1545 * (1 - (1 - _0x16E5) * _0xB734)
_0x4E41 = _0x4E41 % 6
if _0x4E41 == 0 then return _0x1545, _0xC5C0, _0x721A
elseif _0x4E41 == 1 then return _0xE719, _0x1545, _0x721A
elseif _0x4E41 == 2 then return _0x721A, _0x1545, _0xC5C0
elseif _0x4E41 == 3 then return _0x721A, _0xE719, _0x1545
elseif _0x4E41 == 4 then return _0xC5C0, _0x721A, _0x1545
end
return _0x1545, _0x721A, _0xE719
end
local function _0xEC63(_0x70A2, _0x2126, _0x527F)
local _0xE62A, _0x6812 = math.max(_0x70A2, _0x2126, _0x527F), math.min(_0x70A2, _0x2126, _0x527F)
local _0x47FC = _0xE62A - _0x6812
local _0x86ED = 0
if _0x47FC > 0 then
if _0xE62A == _0x70A2 then _0x86ED = ((_0x2126 - _0x527F) / _0x47FC) % 6
elseif _0xE62A == _0x2126 then _0x86ED = (_0x527F - _0x70A2) / _0x47FC + 2
else _0x86ED = (_0x70A2 - _0x2126) / _0x47FC + 4 end
_0x86ED = _0x86ED / 6
end
return _0x86ED, (_0xE62A == 0) and 0 or _0x47FC / _0xE62A, _0xE62A
endlocal function _0x0376(_0x2FEE, _0x1C8E)
local _0x86C5 = _0x3CC0.accent
if _0x3CC0.halloween then
return _0xAAB1.ImVec4(math.min(1, _0x2FEE + 0.022), math.min(1, _0x2FEE + 0.002), math.min(1, _0x2FEE + 0.058), _0x1C8E or 1.0)
end
return _0xAAB1.ImVec4(math.min(1, _0x2FEE + _0x86C5[1] * 0.04), math.min(1, _0x2FEE + _0x86C5[2] * 0.04), math.min(1, _0x2FEE + _0x86C5[3] * 0.06), _0x1C8E or 1.0)
endlocal function _0x0A8C(_0x2FEE, _0x6B6F, _0x1C8E)
local _0x86C5 = _0x3CC0.accent
local _0x47FC = _0x0376(_0x2FEE)
return _0xAAB1.ImVec4(_0x47FC.x + (_0x86C5[1] - _0x47FC.x) * _0x6B6F, _0x47FC.y + (_0x86C5[2] - _0x47FC.y) * _0x6B6F, _0x47FC.z + (_0x86C5[3] - _0x47FC.z) * _0x6B6F, _0x1C8E or 1.0)
endlocal function _0x47E7(fallback)
if _0xAAB1.GetForegroundDrawList then
local _0x2457, _0xFCBC = pcall(_0xAAB1.GetForegroundDrawList)
if _0x2457 and _0xFCBC ~= nil then return _0xFCBC end
end
return fallback()
end
local function _0x9379(_0x700B, _0xA7B6, _0x0DBB, _0x4326, _0x70A2)
local _0x4EF0, _0x7130 = {}, {}
local function _0x7D6C(_0x6BF7, _0x7077) _0x4EF0[#_0x4EF0 + 1] = _0x6BF7; _0x7130[#_0x7130 + 1] = _0x7077 end
local function _0xC3CF(ax, ay, _0x037E, _0x47CC)
local _0xA422 = math.sqrt((_0x037E - ax) ^ 2 + (_0x47CC - ay) ^ 2)
local _0xB322 = math.max(1, math.floor(_0xA422 / 14))
for _0x4E41 = 0, _0xB322 - 1 do
local _0xC5C0 = _0x4E41 / _0xB322
_0x7D6C(ax + (_0x037E - ax) * _0xC5C0, ay + (_0x47CC - ay) * _0xC5C0)
end
end
local function _0x125E(_0x4335, _0x952C, a0)
for _0x4E41 = 0, 5 do
local _0x1C8E = a0 + (math.pi / 2) * (_0x4E41 / 5)
_0x7D6C(_0x4335 + math.cos(_0x1C8E) * _0x70A2, _0x952C + math.sin(_0x1C8E) * _0x70A2)
end
end
_0xC3CF(_0x700B + _0x70A2, _0xA7B6, _0x0DBB - _0x70A2, _0xA7B6)
_0x125E(_0x0DBB - _0x70A2, _0xA7B6 + _0x70A2, -math.pi / 2)
_0xC3CF(_0x0DBB, _0xA7B6 + _0x70A2, _0x0DBB, _0x4326 - _0x70A2)
_0x125E(_0x0DBB - _0x70A2, _0x4326 - _0x70A2, 0)
_0xC3CF(_0x0DBB - _0x70A2, _0x4326, _0x700B + _0x70A2, _0x4326)
_0x125E(_0x700B + _0x70A2, _0x4326 - _0x70A2, math.pi / 2)
_0xC3CF(_0x700B, _0x4326 - _0x70A2, _0x700B, _0xA7B6 + _0x70A2)
_0x125E(_0x700B + _0x70A2, _0xA7B6 + _0x70A2, math.pi)
return _0x4EF0, _0x7130
endlocal function _0x65D7(_0x700B, _0xA7B6, _0x0DBB, _0x4326)
local _0x4EF0, _0x7130 = _0x9379(_0x700B + 1, _0xA7B6 + 1, _0x0DBB - 1, _0x4326 - 1, 12)
local _0xB322 = #_0x4EF0
local _0x44B4 = {}
for _0x4E41 = 1, _0xB322 do _0x44B4[_0x4E41] = _0xAAB1.ImVec2(_0x4EF0[_0x4E41], _0x7130[_0x4E41]) end
local _0xFCBC = _0x47E7(_0xAAB1.GetWindowDrawList)
local _0x86C5 = _0x3CC0.accent
local _0xFC27 = _0x3CC0.border_mode
local _0xC5C0 = os.clock() * _0x3CC0.border_speed
local _0x200F, _0xF1AD, _0x0D13 = 1, 1, 1
if _0xFC27 == 1 then
local _0x86ED, _0x5E76 = _0xEC63(_0x86C5[1], _0x86C5[2], _0x86C5[3])
_0x200F, _0xF1AD, _0x0D13 = _0xE167(_0x86ED + 0.08, math.max(0.35, _0x5E76 * 0.75), 1.0)
end
for _0x4E41 = 1, _0xB322 do
local _0x4290 = _0x4E41 % _0xB322 + 1
local _0x16E5 = (_0x4E41 - 1) / _0xB322
local _0x70A2, _0x2126, _0x527F
if _0xFC27 == 1 then
local _0x8E44 = 0.5 + 0.5 * math.sin((_0x16E5 * 2 - _0xC5C0 * 0.6) * math.pi * 2)
local _0x2306, _0xB1AC, _0x0B49 = _0x86C5[1] * 0.55, _0x86C5[2] * 0.55, _0x86C5[3] * 0.55
_0x70A2, _0x2126, _0x527F = _0x2306 + (_0x200F - _0x2306) * _0x8E44, _0xB1AC + (_0xF1AD - _0xB1AC) * _0x8E44, _0x0B49 + (_0x0D13 - _0x0B49) * _0x8E44
elseif _0xFC27 == 2 then
_0x70A2, _0x2126, _0x527F = _0xE167(_0x16E5 - _0xC5C0 * 0.3, 0.75, 1.0)
else
_0x70A2, _0x2126, _0x527F = _0x86C5[1], _0x86C5[2], _0x86C5[3]
end
_0xFCBC:AddLine(_0x44B4[_0x4E41], _0x44B4[_0x4290], _0x82F6(_0x70A2, _0x2126, _0x527F, 0.16), 5.0)
_0xFCBC:AddLine(_0x44B4[_0x4E41], _0x44B4[_0x4290], _0x82F6(_0x70A2, _0x2126, _0x527F, 0.95), 2.0)
end
endlocal _0x2838 = false
local function _0x8386(_0x700B, _0xA7B6, _0x0DBB, _0x4326)
if _0x2838 then return end
local _0x2457, _0x847E = pcall(function()
if _0x3CC0.shadow then
local _0x4961 = _0xAAB1.GetBackgroundDrawList()
for _0x4E41 = 1, 6 do
local _0x40E5 = _0x4E41 * 3
_0x4961:AddRectFilled(_0xAAB1.ImVec2(_0x700B - _0x40E5, _0xA7B6 - _0x40E5 + 5), _0xAAB1.ImVec2(_0x0DBB + _0x40E5, _0x4326 + _0x40E5 + 5), _0x82F6(0, 0, 0, 0.045), 12 + _0x40E5)
end
end
if _0x3CC0.border_mode ~= 0 then _0x65D7(_0x700B, _0xA7B6, _0x0DBB, _0x4326) end
end)
if not _0x2457 then
_0x2838 = true
_0x04D5("window_fx", _0x847E)
end
if _0x3CC0.halloween then _0xD3A9.hw_safe(_0xD3A9.hw_front, _0x700B, _0xA7B6, _0x0DBB, _0x4326) end
end
function apply_theme()
local _0x2FD8 = _0xAAB1.GetStyle()
local _0x0BE1 = _0x2FD8.Colors
local _0x86C5 = _0x3CC0.accent
local function _0x3391(_0x6E19, _0x1545) pcall(function() _0x2FD8[_0x6E19] = _0x1545 end) end
local function _0xAC1D(_0x6E19, _0x1545)
local _0xCA44 = _0xAAB1.Col[_0x6E19]
if _0xCA44 ~= nil then _0x0BE1[_0xCA44] = _0x1545 end
end_0x3391("WindowPadding", _0xAAB1.ImVec2(5, 5))
_0x3391("FramePadding", _0xAAB1.ImVec2(5, 5))
_0x3391("ItemSpacing", _0xAAB1.ImVec2(5, 5))
_0x3391("ItemInnerSpacing", _0xAAB1.ImVec2(2, 2))
_0x3391("WindowTitleAlign", _0xAAB1.ImVec2(0.5, 0.5))
_0x3391("ScrollbarSize", 10)
_0x3391("WindowBorderSize", 0)
_0x3391("PopupBorderSize", 0)
_0x3391("ChildBorderSize", 1)
_0x3391("FrameBorderSize", 0)_0x3391("WindowRounding", 12)
_0x3391("ChildRounding", 8)
_0x3391("FrameRounding", 6)
_0x3391("PopupRounding", 10)
_0x3391("ScrollbarRounding", 8)
_0x3391("GrabRounding", 6)
_0x3391("TabRounding", 6)_0xAC1D("Text", _0xAAB1.ImVec4(0.93, 0.94, 0.97, 1.00))
_0xAC1D("TextDisabled", _0xAAB1.ImVec4(0.52, 0.55, 0.62, 1.00))
_0xAC1D("WindowBg", _0x0376(0.058, _0x3CC0.opacity))
_0xAC1D("ChildBg", _0x0376(0.080, 0.50))
_0xAC1D("PopupBg", _0x0376(0.085, 0.98))
_0xAC1D("Border", _0xAAB1.ImVec4(_0x86C5[1], _0x86C5[2], _0x86C5[3], 0.20))
_0xAC1D("TitleBg", _0x0376(0.058))
_0xAC1D("TitleBgActive", _0x0376(0.058))
_0xAC1D("TitleBgCollapsed", _0x0376(0.058))
_0xAC1D("FrameBg", _0x0376(0.105))
_0xAC1D("FrameBgHovered", _0x0A8C(0.105, 0.14))
_0xAC1D("FrameBgActive", _0x0A8C(0.105, 0.22))
_0xAC1D("Button", _0x0376(0.115))
_0xAC1D("ButtonHovered", _0x0A8C(0.115, 0.30))
_0xAC1D("ButtonActive", _0x0A8C(0.115, 0.50))
_0xAC1D("Header", _0x0A8C(0.115, 0.22))
_0xAC1D("HeaderHovered", _0x0A8C(0.115, 0.34))
_0xAC1D("HeaderActive", _0x0A8C(0.115, 0.48))
_0xAC1D("ScrollbarBg", _0xAAB1.ImVec4(0, 0, 0, 0))
_0xAC1D("ScrollbarGrab", _0x0A8C(0.12, 0.30))
_0xAC1D("ScrollbarGrabHovered", _0x0A8C(0.12, 0.50))
_0xAC1D("ScrollbarGrabActive", _0x0A8C(0.12, 0.75))
_0xAC1D("Separator", _0xAAB1.ImVec4(1, 1, 1, 0.07))
_0xAC1D("ModalWindowDimBg", _0xAAB1.ImVec4(0, 0, 0, 0.65))
_0xAC1D("CheckMark", _0xB079(1.15))
_0xAC1D("SliderGrab", _0xB079(1.0))
_0xAC1D("SliderGrabActive", _0xB079(1.25))
_0xAC1D("PlotHistogram", _0xB079(1.0))
_0xAC1D("TextSelectedBg", _0xAAB1.ImVec4(_0x86C5[1], _0x86C5[2], _0x86C5[3], 0.35))
_0xAC1D("ResizeGrip", _0xAAB1.ImVec4(_0x86C5[1], _0x86C5[2], _0x86C5[3], 0.45))
_0xAC1D("ResizeGripHovered", _0xAAB1.ImVec4(_0x86C5[1], _0x86C5[2], _0x86C5[3], 0.75))
_0xAC1D("ResizeGripActive", _0xAAB1.ImVec4(_0x86C5[1], _0x86C5[2], _0x86C5[3], 1.00))
endlocal _0x2546 = 200
local _0x4C9D = { _0x8E44 = 835, _0x86ED = 500, tab_h = 42, block_y = 340, force = false }local _0x307A = 1local _0x5D04 =""local _0x3203 =""local _0x56E4 = nil
local _0x58E8 = false
local _0x61A3 = { hover = {}, press = {}, ripple = {}, hist = {}, hist_open = false, pop_t = -10, grown = false }
local function _0x4BFE(_0x6E19, fallback)
return _0x19D1[_0x6E19] or fallback
endlocal _0xC83F = {}
local _0x03BE = {
info = { _0x2149 ="CIRCLE_INFO", _0xA1E8 = nil },
_0x2457 = { _0x2149 ="CIRCLE_CHECK", _0xA1E8 = {0.30, 0.78, 0.45} },
warn = { _0x2149 ="TRIANGLE_EXCLAMATION", _0xA1E8 = {1.00, 0.75, 0.20} },
_0x847E = { _0x2149 ="CIRCLE_XMARK", _0xA1E8 = {0.92, 0.32, 0.32} },
}
local _0x6D93 = false
local function _0x774D(_0xC139, _0x93A6, _0x6164)
if _0x3CC0.toasts == false or _0x6D93 then return false end
_0xC83F[#_0xC83F + 1] = { _0xC139 = tostring(_0xC139), _0x93A6 = _0x03BE[_0x93A6] and _0x93A6 or"info", t0 = os.clock(), _0x6164 = _0x6164 or 3.5 }
if #_0xC83F > 5 then table.remove(_0xC83F, 1) end
return true
endlocal function _0x3EA3(_0xC139, _0x93A6, _0x6164)
if not _0x774D(_0xC139, _0x93A6, _0x6164) then
if sampAddChatMessage then
pcall(sampAddChatMessage, _0xACD5:decode("{33AAFF}[Arizona Prices] {FFFFFF}".. tostring(_0xC139)), -1)
end
end
endlocal function _0x6EE9()
local _0x4E32 = os.clock()
for _0x4E41 = #_0xC83F, 1, -1 do
if _0x4E32 - _0xC83F[_0x4E41].t0 > _0xC83F[_0x4E41].dur then table.remove(_0xC83F, _0x4E41) end
end
if #_0xC83F == 0 then return end
local _0xFCBC = _0x47E7(_0xAAB1.GetBackgroundDrawList)
local _0x17E0, _0xFBEC = getScreenResolution()
local _0xCCAB = _0x3CC0.toast_corner or 3local _0x4D29 = (_0xCCAB == 1 or _0xCCAB == 3)
local _0x0FF8 = (_0xCCAB == 2 or _0xCCAB == 3)
local _0x0AD1, _0x842E, _0xADCB = 46, 8, 20
for _0x4E41, _0xC5C0 in ipairs(_0xC83F) do
local _0x93A6 = _0x03BE[_0xC5C0.kind] or _0x03BE.info
local _0x0F4A = _0xAAB1.CalcTextSize(_0xC5C0.text)
local _0x8E44 = math.min(760, _0x0F4A.x + 84)
local _0xFCB7 = _0x4E32 - _0xC5C0.t0
local _0x17F1 = math.min(1, _0xFCB7 / 0.25)
local _0xB261 = 1 - (1 - _0x17F1) ^ 3
local _0xF192 = math.max(0, math.min(1, (_0xC5C0.dur - _0xFCB7) / 0.4))
local _0xE54C = (1 - _0xB261) * (_0x8E44 + _0xADCB + 10)
local _0xAE25 = #_0xC83F - _0x4E41
local _0x6BF7 = _0x4D29 and (_0x17E0 - _0xADCB - _0x8E44 + _0xE54C) or (_0xADCB - _0xE54C)
local _0x7077 = _0x0FF8 and (_0xFBEC - _0xADCB - 80 - _0x0AD1 - _0xAE25 * (_0x0AD1 + _0x842E)) or (_0xADCB + _0xAE25 * (_0x0AD1 + _0x842E))
local _0x6D18 = _0x93A6.color or _0x3CC0.accent
local _0x8C9B = _0x7077 + (_0x0AD1 - _0x0F4A.y) / 2
local _0x5CEA, _0x870A = _0xAAB1.ImVec2(_0x6BF7, _0x7077), _0xAAB1.ImVec2(_0x6BF7 + _0x8E44, _0x7077 + _0x0AD1)
local _0x4335, _0x952C = _0x6BF7 + 28, _0x7077 + _0x0AD1 / 2
_0xFCBC:AddRectFilled(_0x5CEA, _0x870A, _0x82F6(0.07, 0.075, 0.09, 0.96 * _0xF192), 10)
pcall(function()
_0xFCBC:AddRect(_0x5CEA, _0x870A, _0x82F6(_0x6D18[1], _0x6D18[2], _0x6D18[3], 0.60 * _0xF192), 10, 0, 1.5)
_0xFCBC:AddCircleFilled(_0xAAB1.ImVec2(_0x4335, _0x952C), 17, _0x82F6(_0x6D18[1], _0x6D18[2], _0x6D18[3], 0.20 * _0xF192), 28)
end)local _0x0440 = _0x82F6(_0x6D18[1], _0x6D18[2], _0x6D18[3], _0xF192)
local function _0xB1F0(ax, ay, _0x037E, _0x47CC)
_0xFCBC:AddLine(_0xAAB1.ImVec2(_0x4335 + ax, _0x952C + ay), _0xAAB1.ImVec2(_0x4335 + _0x037E, _0x952C + _0x47CC), _0x0440, 3.0)
end
if _0xC5C0.kind =="ok"then
_0xB1F0(-7, 0.5, -2.5, 5.5)
_0xB1F0(-2.5, 5.5, 7.5, -5.5)
_0xFCBC:AddCircleFilled(_0xAAB1.ImVec2(_0x4335 - 2.5, _0x952C + 5.5), 1.5, _0x0440, 12)
elseif _0xC5C0.kind =="err"then
_0xB1F0(-6, -6, 6, 6)
_0xB1F0(-6, 6, 6, -6)
elseif _0xC5C0.kind =="warn"then
_0xB1F0(0, -8, 0, 2)
_0xFCBC:AddCircleFilled(_0xAAB1.ImVec2(_0x4335, _0x952C + 7), 2.0, _0x0440, 12)
else
_0xFCBC:AddCircleFilled(_0xAAB1.ImVec2(_0x4335, _0x952C - 7), 2.0, _0x0440, 12)
_0xB1F0(0, -2.5, 0, 8)
end
_0xFCBC:AddText(_0xAAB1.ImVec2(_0x6BF7 + 56, _0x8C9B), _0x82F6(1, 1, 1, _0xF192), _0xC5C0.text)
end
end
local _0x9CC6
_0x9CC6 = _0xAAB1.OnFrame(
function()
_0x9CC6.HideCursor = true
return #_0xC83F > 0
end,
function()
local _0x2457, _0x847E = xpcall(_0x6EE9, _0x76CF)
if not _0x2457 then
_0x6D93 = true
_0xC83F = {}
_0x04D5("toast", _0x847E)
_0x913B("Карточки уведомлений отключены из-за ошибки, сообщения будут в чате","warn")
end
end
)local function _0xBE00(_0xB734)
if _0xB734 ==""then return"0"end
local _0x70A2 = _0xB734:reverse():gsub("(%d%d%d)","%1."):reverse()
if _0x70A2:sub(1, 1) =="."then _0x70A2 = _0x70A2:sub(2) end
return _0x70A2
end
local function _0xF021(expr)
local _0x8DAB = expr:gsub("[%d%.]+", function(_0xEC65)
local _0xAA78, _0xD3DB = _0xEC65:match("^(%d*)%.(%d*)$")
if _0xAA78 then
return _0xBE00(_0xAA78) ..",".. _0xD3DB
end
return _0xBE00(_0xEC65)
end)
_0x8DAB = _0x8DAB:gsub("%*"," x "):gsub("/"," / "):gsub("%+"," + "):gsub("%-"," - ")
_0x8DAB = _0x8DAB:gsub("^%s+",""):gsub("%s+$","")
_0x8DAB = _0x8DAB:gsub("^%- ","-")
return _0x8DAB
end
local function _0x5B24(_0x6BF7)
if _0x6BF7 >= 0 then
_0x6BF7 = math.floor(_0x6BF7 * 100 + 0.5) / 100
else
_0x6BF7 = -math.floor(-_0x6BF7 * 100 + 0.5) / 100
end
local _0xB734 = string.format("%.2f", _0x6BF7)
_0xB734 = _0xB734:gsub("0+$",""):gsub("%.$","")
if _0xB734 =="-0"or _0xB734 ==""then _0xB734 ="0"end
return _0xB734
end
local function _0xC313(expr)
local _0x3B59 = {}
local _0x4E41, _0xB322 = 1, #expr
while _0x4E41 <= _0xB322 do
local _0x6D18 = expr:sub(_0x4E41, _0x4E41)
if _0x6D18:match("[%d%.]") then
local _0xEC65 = expr:match("^[%d%.]+", _0x4E41)
_0x4E41 = _0x4E41 + #_0xEC65
local _0x1545 = tonumber(_0xEC65)
if not _0x1545 then return nil,"Ошибка"end
local _0xD28C = false
if expr:sub(_0x4E41, _0x4E41) =="%"then
_0xD28C = true
_0x4E41 = _0x4E41 + 1
end
_0x3B59[#_0x3B59 + 1] = {_0xEC65 = _0x1545, _0xD28C = _0xD28C}
elseif _0x6D18:match("[%+%-%*/]") then
_0x3B59[#_0x3B59 + 1] = {op = _0x6D18}
_0x4E41 = _0x4E41 + 1
else
return nil,"Ошибка"end
end
if _0x3B59[#_0x3B59] and _0x3B59[#_0x3B59].op then _0x3B59[#_0x3B59] = nil end
local _0xCA44, _0x4B0A = 1, 1
if _0x3B59[1] and _0x3B59[1].op =="-"then
_0x4B0A = -1
_0xCA44 = 2
end
if _0xCA44 > #_0x3B59 then return nil,"Ошибка"end
local _0x5362, _0x6ADB, _0x250D = 0,"+", true
while _0xCA44 <= #_0x3B59 do
local _0x496C = _0x3B59[_0xCA44]
if not _0x496C.num then return nil,"Ошибка"end
local _0x26CC = _0x496C.pct and (_0x496C.num / 100) or _0x496C.num
local _0x381D = true
_0xCA44 = _0xCA44 + 1
while _0x3B59[_0xCA44] and (_0x3B59[_0xCA44].op =="*"or _0x3B59[_0xCA44].op =="/") do
local _0xB147 = _0x3B59[_0xCA44 + 1]
if not _0xB147 or not _0xB147.num then return nil,"Ошибка"end
local _0x805B = _0xB147.pct and (_0xB147.num / 100) or _0xB147.num
if _0x3B59[_0xCA44].op =="*"then
_0x26CC = _0x26CC * _0x805B
else
if _0x805B == 0 then return nil,"Деление на ноль"end
_0x26CC = _0x26CC / _0x805B
end
_0x381D = false
_0xCA44 = _0xCA44 + 2
end
if _0x250D then
_0x26CC = _0x26CC * _0x4B0A
_0x5362 = _0x26CC
_0x250D = false
else
if _0x381D and _0x496C.pct then _0x26CC = _0x5362 * _0x496C.num / 100 end
if _0x6ADB =="+"then _0x5362 = _0x5362 + _0x26CC else _0x5362 = _0x5362 - _0x26CC end
end
local _0xA5F3 = _0x3B59[_0xCA44]
if _0xA5F3 then
if _0xA5F3.op ~="+"and _0xA5F3.op ~="-"then return nil,"Ошибка"end
_0x6ADB = _0xA5F3.op
_0xCA44 = _0xCA44 + 1
end
end
return _0x5362
end
local function _0x654E()
if _0x58E8 then
_0x5D04 =""_0x3203 =""_0x58E8 = false
end
end
local function _0x7ED8(_0x47FC)
_0x56E4 = nil
_0x654E()
if #_0x5D04 > 45 then return end
if _0x5D04:sub(-1) =="%"then return end
local _0x181D = _0x5D04:match("[%d%.]*$")
if _0x47FC =="000"then
if _0x181D ==""or _0x181D =="0"then return end
_0x5D04 = _0x5D04 .."000"return
end
if _0x181D =="0"then
if _0x47FC =="0"then return end
_0x5D04 = _0x5D04:sub(1, -2) .. _0x47FC
else
_0x5D04 = _0x5D04 .. _0x47FC
end
end
local function _0x9BCE()
_0x56E4 = nil
_0x654E()
if #_0x5D04 > 45 then return end
if _0x5D04:sub(-1) =="%"then return end
local _0x181D = _0x5D04:match("[%d%.]*$")
if _0x181D:find(".", 1, true) then return end
if _0x181D ==""then
_0x5D04 = _0x5D04 .."0."else
_0x5D04 = _0x5D04 .."."end
end
local function _0xAA2D(op)
_0x56E4 = nil
if _0x58E8 then
_0x58E8 = false
_0x3203 =""end
if _0x5D04 ==""then
if op =="-"then _0x5D04 ="-"end
return
end
local _0x5D8A = _0x5D04:sub(-1)
if _0x5D8A:match("[%+%-%*/]") then
if #_0x5D04 == 1 then return end
_0x5D04 = _0x5D04:sub(1, -2) .. op
else
if _0x5D8A =="."then _0x5D04 = _0x5D04:sub(1, -2) end
_0x5D04 = _0x5D04 .. op
end
end
local function _0x00AB()
_0x56E4 = nil
if _0x58E8 then
_0x58E8 = false
_0x3203 =""end
if _0x5D04:sub(-1):match("%d") then
_0x5D04 = _0x5D04 .."%"end
end
local function _0x4DB0()
_0x56E4 = nil
if _0x58E8 then
_0x58E8 = false
_0x3203 =""end
_0x5D04 = _0x5D04:sub(1, -2)
end
local function _0xF233()
_0x5D04 =""_0x3203 =""_0x56E4 = nil
_0x58E8 = false
end
local function _0xDFEA()
if _0x5D04 ==""or _0x58E8 then return end
local _0x93DD, _0x847E = _0xC313(_0x5D04)
if not _0x93DD then
_0x56E4 = _0x847E or"Ошибка"return
end
local _0xDD2C = _0xF021(_0x5D04)
_0x3203 = _0xDD2C .." ="_0x5D04 = _0x5B24(_0x93DD)
_0x58E8 = true
_0x61A3.pop_t = _0xAAB1.GetTime()
_0x61A3.hist[#_0x61A3.hist + 1] = { expr = _0xDD2C, _0x93DD = _0xF021(_0x5D04), raw = _0x5D04 }
if #_0x61A3.hist > 15 then table.remove(_0x61A3.hist, 1) end
endlocal function _0xE514(_0xE35E)
local _0xFCBC = _0xAAB1.GetWindowDrawList()
local _0x50A5 = _0xAAB1.ColorConvertFloat4ToU32(_0x0376(0.088, _0xD3A9.m))
_0xFCBC:AddRectFilled(_0xE35E, _0xAAB1.ImVec2(_0xE35E.x + _0x2546 - 1, _0xE35E.y + _0x4C9D.h), _0x50A5, 12)
_0xFCBC:AddRectFilled(_0xAAB1.ImVec2(_0xE35E.x + 14, _0xE35E.y), _0xAAB1.ImVec2(_0xE35E.x + _0x2546 - 1, _0xE35E.y + _0x4C9D.h), _0x50A5)
_0xFCBC:AddLine(_0xAAB1.ImVec2(_0xE35E.x + _0x2546 - 1, _0xE35E.y + 8), _0xAAB1.ImVec2(_0xE35E.x + _0x2546 - 1, _0xE35E.y + _0x4C9D.h - 8), _0xAAB1.GetColorU32(_0xAAB1.Col.Separator), 1.0)
if _0x3CC0.halloween then _0xD3A9.hw_safe(_0xD3A9.hw_web, _0xFCBC, _0xE35E.x + 7, _0xE35E.y + _0x4C9D.h - 7, 84, 1, -1, 0.18) end
endfunction _0xD3A9.liq_color(_0x2FEE)
if _0x2FEE =="Ликвид"then return _0xAAB1.ImVec4(0.45, 0.95, 0.55, 1) end
if _0x2FEE =="Средне"then return _0xAAB1.ImVec4(1.00, 0.85, 0.40, 1) end
if _0x2FEE =="Неликвид"then return _0xAAB1.ImVec4(1.00, 0.45, 0.45, 1) end
return _0xAAB1.ImVec4(0.50, 0.52, 0.58, 1)
end
function _0xD3A9.liq_next(_0x2FEE)
if _0x2FEE == nil then return"Ликвид"end
if _0x2FEE =="Ликвид"then return"Средне"end
if _0x2FEE =="Средне"then return"Неликвид"end
return nil
end
function _0xD3A9.set_alpha(_0x1C8E)
_0x1C8E = _0x43DE(_0x1C8E, 0, 1)
_0xD3A9.m = _0x1C8E
pcall(function() _0xAAB1.GetStyle().Alpha = _0x1C8E end)
endfunction _0xD3A9.go_tab(_0xBA15)
if _0xBA15 ~= _0x307A then
_0x307A = _0xBA15
local _0x4E32 = _0xAAB1.GetTime()
_0xD3A9.tab_t, _0xD3A9.table_t = _0x4E32, _0x4E32
end
endfunction _0xD3A9.tick()
local _0xE6CC = _0xAAB1.GetIO().DeltaTime
local _0xCC32 = _0xF7A7[0]
local _0x0C85 = _0xCC32 and 1 or 0
_0xD3A9.alpha = _0xD3A9.alpha + (_0x0C85 - _0xD3A9.alpha) * math.min(1, _0xE6CC * (_0xCC32 and 11 or 15))
if not _0xCC32 and _0xD3A9.alpha < 0.03 then _0xD3A9.alpha = 0 end
if _0xCC32 and _0xD3A9.alpha > 0.99 then _0xD3A9.alpha = 1 end
if _0xCC32 and not _0xD3A9.was_open then
local _0x4E32 = _0xAAB1.GetTime()
_0xD3A9.table_t, _0xD3A9.tab_t = _0x4E32, _0x4E32
if _0x3CC0.splash and not _0xD3A9.splashed then
_0xD3A9.splash_t = _0x4E32
_0xD3A9.splashed = true
end
end
_0xD3A9.was_open = _0xCC32
if _0xD3A9.pending_tab then
_0xD3A9.go_tab(_0xD3A9.pending_tab)
_0xD3A9.pending_tab = nil
end
endfunction _0xD3A9.draw_bar(_0xE35E)
if not _0xD3A9.bar_ty then return end
local _0xE6CC = _0xAAB1.GetIO().DeltaTime
if not _0xD3A9.bar_cur then _0xD3A9.bar_cur = _0xD3A9.bar_ty end
_0xD3A9.bar_cur = _0xD3A9.bar_cur + (_0xD3A9.bar_ty - _0xD3A9.bar_cur) * math.min(1, _0xE6CC * 16)
local _0x86C5 = _0x3CC0.accent
local _0x6BF7, _0x7077 = _0xE35E.x + _0xD3A9.bar_x, _0xE35E.y + _0xD3A9.bar_cur
_0xAAB1.GetWindowDrawList():AddRectFilled(_0xAAB1.ImVec2(_0x6BF7, _0x7077 - 13), _0xAAB1.ImVec2(_0x6BF7 + 3, _0x7077 + 13),
_0x82F6(math.min(1, _0x86C5[1] * 1.15), math.min(1, _0x86C5[2] * 1.15), math.min(1, _0x86C5[3] * 1.15), 1), 2)
endfunction _0xD3A9.draw_bg()
local _0x721A, _0xB734 = _0xAAB1.GetWindowPos(), _0xAAB1.GetWindowSize()
local _0xFCBC = _0xAAB1.GetWindowDrawList()
local _0xC5C0, _0x86C5 = _0xAAB1.GetTime(), _0x3CC0.accent
for _0x4E41 = 1, 3 do
local _0x4335 = _0x721A.x + _0xB734.x * (0.5 + 0.38 * math.sin(_0xC5C0 * 0.11 * _0x4E41 + _0x4E41 * 2.1))
local _0x952C = _0x721A.y + _0xB734.y * (0.5 + 0.38 * math.cos(_0xC5C0 * 0.09 * _0x4E41 + _0x4E41 * 1.3))
for _0x70A2 = 4, 1, -1 do
_0xFCBC:AddCircleFilled(_0xAAB1.ImVec2(_0x4335, _0x952C), _0x70A2 * 55, _0x82F6(_0x86C5[1], _0x86C5[2], _0x86C5[3], 0.014), 32)
end
end
for _0x4E41 = 1, 26 do
local _0x8B9F = 10 + (_0x4E41 * 7) % 17
local _0x6BF7 = _0x721A.x + ((_0x4E41 * 137) % 100) / 100 * _0xB734.x + math.sin(_0xC5C0 * 0.5 + _0x4E41) * 12
local _0x7077 = _0x721A.y + _0xB734.y - ((_0xC5C0 * _0x8B9F + _0x4E41 * 61) % (_0xB734.y + 20)) + 10
local _0x4032 = 0.5 + 0.5 * math.sin(_0xC5C0 * 1.5 + _0x4E41 * 1.7)
_0xFCBC:AddCircleFilled(_0xAAB1.ImVec2(_0x6BF7, _0x7077), 1.2 + (_0x4E41 % 3) * 0.7,
_0x82F6(_0x86C5[1] * 0.5 + 0.5, _0x86C5[2] * 0.5 + 0.5, _0x86C5[3] * 0.5 + 0.5, 0.05 + 0.14 * _0x4032), 8)
end
endfunction _0xD3A9.hw_safe(fn, ...)
if _0xD3A9.hw_broken then return end
local _0x2457, _0x847E = pcall(fn, ...)
if not _0x2457 then
_0xD3A9.hw_broken = true
pcall(_0x04D5,"halloween", _0x847E)
end
endfunction _0xD3A9.hw_tri(_0xFCBC, _0x50A5, ax, ay, _0x037E, _0x47CC, _0x4335, _0x952C)
local _0x6A7C = _0xAAB1.ImVec2
if (_0x037E - ax) * (_0x952C - ay) - (_0x47CC - ay) * (_0x4335 - ax) < 0 then
_0x037E, _0x47CC, _0x4335, _0x952C = _0x4335, _0x952C, _0x037E, _0x47CC
end
_0xFCBC:AddTriangleFilled(_0x6A7C(ax, ay), _0x6A7C(_0x037E, _0x47CC), _0x6A7C(_0x4335, _0x952C), _0x50A5)
endfunction _0xD3A9.hw_pumpkin(_0xFCBC, _0x4335, _0x952C, _0x70A2, _0x6B6F, hat)
local _0x6A7C = _0xAAB1.ImVec2
local _0xC5C0 = _0xAAB1.GetTime()
local _0xB47B = 0.85 + 0.15 * math.sin(_0xC5C0 * 7 + _0x4335 * 0.05) * math.sin(_0xC5C0 * 3.1 + _0x952C * 0.1)for _0x4E41 = 3, 1, -1 do
_0xFCBC:AddCircleFilled(_0x6A7C(_0x4335, _0x952C), _0x70A2 * (1.0 + _0x4E41 * 0.45), _0x82F6(1.0, 0.45, 0.05, 0.04 * _0x6B6F * _0xB47B), 28)
end
local _0x737B = _0x952C - _0x70A2 * 0.78
local _0xB42C = _0x82F6(0.80, 0.33, 0.03, _0x6B6F)
local _0x27A4 = _0x82F6(1.00, 0.52, 0.08, _0x6B6F)
_0xFCBC:AddCircleFilled(_0x6A7C(_0x4335 - _0x70A2 * 0.45, _0x952C + _0x70A2 * 0.03), _0x70A2 * 0.62, _0xB42C, 22)
_0xFCBC:AddCircleFilled(_0x6A7C(_0x4335 + _0x70A2 * 0.45, _0x952C + _0x70A2 * 0.03), _0x70A2 * 0.62, _0xB42C, 22)
_0xFCBC:AddCircleFilled(_0x6A7C(_0x4335, _0x952C), _0x70A2 * 0.78, _0x27A4, 28)
_0xFCBC:AddCircleFilled(_0x6A7C(_0x4335 - _0x70A2 * 0.38, _0x952C - _0x70A2 * 0.38), _0x70A2 * 0.13, _0x82F6(1.0, 0.82, 0.55, 0.35 * _0x6B6F), 12)local _0x0852 = _0x82F6(1.0, 0.88, 0.30, _0x6B6F * _0xB47B)
_0xD3A9.hw_tri(_0xFCBC, _0x0852, _0x4335 - _0x70A2 * 0.55, _0x952C - _0x70A2 * 0.02, _0x4335 - _0x70A2 * 0.18, _0x952C - _0x70A2 * 0.02, _0x4335 - _0x70A2 * 0.36, _0x952C - _0x70A2 * 0.34)
_0xD3A9.hw_tri(_0xFCBC, _0x0852, _0x4335 + _0x70A2 * 0.18, _0x952C - _0x70A2 * 0.02, _0x4335 + _0x70A2 * 0.55, _0x952C - _0x70A2 * 0.02, _0x4335 + _0x70A2 * 0.36, _0x952C - _0x70A2 * 0.34)
_0xD3A9.hw_tri(_0xFCBC, _0x0852, _0x4335 - _0x70A2 * 0.08, _0x952C + _0x70A2 * 0.14, _0x4335 + _0x70A2 * 0.08, _0x952C + _0x70A2 * 0.14, _0x4335, _0x952C + _0x70A2 * 0.03)
_0xFCBC:AddRectFilled(_0x6A7C(_0x4335 - _0x70A2 * 0.58, _0x952C + _0x70A2 * 0.26), _0x6A7C(_0x4335 + _0x70A2 * 0.58, _0x952C + _0x70A2 * 0.48), _0x0852, _0x70A2 * 0.06)
for _0x4290 = -2, 2, 2 do
local _0x6BF7 = _0x4335 + _0x4290 * _0x70A2 * 0.22
_0xD3A9.hw_tri(_0xFCBC, _0x27A4, _0x6BF7 - _0x70A2 * 0.09, _0x952C + _0x70A2 * 0.26, _0x6BF7 + _0x70A2 * 0.09, _0x952C + _0x70A2 * 0.26, _0x6BF7, _0x952C + _0x70A2 * 0.37)
end
for _0x4290 = -1, 1, 2 do
local _0x6BF7 = _0x4335 + _0x4290 * _0x70A2 * 0.22
_0xD3A9.hw_tri(_0xFCBC, _0x27A4, _0x6BF7 - _0x70A2 * 0.09, _0x952C + _0x70A2 * 0.48, _0x6BF7 + _0x70A2 * 0.09, _0x952C + _0x70A2 * 0.48, _0x6BF7, _0x952C + _0x70A2 * 0.37)
end
if hat then
local _0xF5E5 = _0x82F6(0.22, 0.10, 0.38, _0x6B6F)
local _0xE4F4 = _0x737B + _0x70A2 * 0.12
_0xD3A9.hw_tri(_0xFCBC, _0xF5E5, _0x4335 - _0x70A2 * 0.55, _0xE4F4 - _0x70A2 * 0.05, _0x4335 + _0x70A2 * 0.55, _0xE4F4 - _0x70A2 * 0.05, _0x4335 + _0x70A2 * 0.22, _0xE4F4 - _0x70A2 * 1.35)
_0xFCBC:AddRectFilled(_0x6A7C(_0x4335 - _0x70A2 * 0.44, _0xE4F4 - _0x70A2 * 0.30), _0x6A7C(_0x4335 + _0x70A2 * 0.44, _0xE4F4 - _0x70A2 * 0.10), _0x27A4, 2)
_0xFCBC:AddRectFilled(_0x6A7C(_0x4335 - _0x70A2 * 0.95, _0xE4F4 - _0x70A2 * 0.10), _0x6A7C(_0x4335 + _0x70A2 * 0.95, _0xE4F4 + _0x70A2 * 0.08), _0xF5E5, _0x70A2 * 0.08)
else
local _0x88C9 = _0x82F6(0.30, 0.45, 0.10, _0x6B6F)
_0xD3A9.hw_tri(_0xFCBC, _0x88C9, _0x4335 - _0x70A2 * 0.10, _0x737B + _0x70A2 * 0.08, _0x4335 + _0x70A2 * 0.14, _0x737B + _0x70A2 * 0.08, _0x4335 + _0x70A2 * 0.20, _0x737B - _0x70A2 * 0.28)
_0xD3A9.hw_tri(_0xFCBC, _0x88C9, _0x4335 - _0x70A2 * 0.10, _0x737B + _0x70A2 * 0.08, _0x4335 + _0x70A2 * 0.20, _0x737B - _0x70A2 * 0.28, _0x4335 - _0x70A2 * 0.02, _0x737B - _0x70A2 * 0.30)
end
endfunction _0xD3A9.hw_bat(_0xFCBC, _0x6BF7, _0x7077, _0xB734, _0xB47B, _0x6B6F)
local _0x6A7C = _0xAAB1.ImVec2
local _0x6D18 = _0x82F6(0.36, 0.23, 0.52, 0.90 * _0x6B6F)
local _0x16E5 = _0xB47B * _0xB734 * 0.55
for _0x47FC = -1, 1, 2 do
_0xD3A9.hw_tri(_0xFCBC, _0x6D18, _0x6BF7, _0x7077 - _0xB734 * 0.15, _0x6BF7 + _0x47FC * _0xB734 * 1.35, _0x7077 - _0xB734 * 0.45 + _0x16E5, _0x6BF7 + _0x47FC * _0xB734 * 0.85, _0x7077 + _0xB734 * 0.05)
_0xD3A9.hw_tri(_0xFCBC, _0x6D18, _0x6BF7, _0x7077 - _0xB734 * 0.15, _0x6BF7 + _0x47FC * _0xB734 * 0.85, _0x7077 + _0xB734 * 0.05, _0x6BF7 + _0x47FC * _0xB734 * 0.45, _0x7077 + _0xB734 * 0.32)
_0xD3A9.hw_tri(_0xFCBC, _0x6D18, _0x6BF7, _0x7077 - _0xB734 * 0.05, _0x6BF7 + _0x47FC * _0xB734 * 0.45, _0x7077 + _0xB734 * 0.32, _0x6BF7, _0x7077 + _0xB734 * 0.22)
end
_0xFCBC:AddCircleFilled(_0x6A7C(_0x6BF7, _0x7077 + _0xB734 * 0.02), _0xB734 * 0.30, _0x6D18, 12)
_0xD3A9.hw_tri(_0xFCBC, _0x6D18, _0x6BF7 - _0xB734 * 0.26, _0x7077 - _0xB734 * 0.12, _0x6BF7 - _0xB734 * 0.06, _0x7077 - _0xB734 * 0.22, _0x6BF7 - _0xB734 * 0.24, _0x7077 - _0xB734 * 0.52)
_0xD3A9.hw_tri(_0xFCBC, _0x6D18, _0x6BF7 + _0xB734 * 0.06, _0x7077 - _0xB734 * 0.22, _0x6BF7 + _0xB734 * 0.26, _0x7077 - _0xB734 * 0.12, _0x6BF7 + _0xB734 * 0.24, _0x7077 - _0xB734 * 0.52)
local _0xEC46 = _0x82F6(1.0, 0.40, 0.10, _0x6B6F)
_0xFCBC:AddCircleFilled(_0x6A7C(_0x6BF7 - _0xB734 * 0.11, _0x7077), _0xB734 * 0.05, _0xEC46, 6)
_0xFCBC:AddCircleFilled(_0x6A7C(_0x6BF7 + _0xB734 * 0.11, _0x7077), _0xB734 * 0.05, _0xEC46, 6)
endfunction _0xD3A9.hw_web(_0xFCBC, _0x4335, _0x952C, size, dx, dy, _0x1C8E)
local _0x6A7C = _0xAAB1.ImVec2
local _0x50A5 = _0x82F6(0.85, 0.85, 1.0, _0x1C8E)
local _0xB322 = 5
for _0x6B6F = 0, _0xB322 do
local _0x147B = (_0x6B6F / _0xB322) * (math.pi / 2)
_0xFCBC:AddLine(_0x6A7C(_0x4335, _0x952C), _0x6A7C(_0x4335 + dx * math.cos(_0x147B) * size, _0x952C + dy * math.sin(_0x147B) * size), _0x50A5, 1.0)
end
for _0x4290 = 1, 4 do
local _0x9CEA = size * _0x4290 / 4
for _0x6B6F = 0, _0xB322 - 1 do
local _0xC024, _0xD639, _0xF5E8 = (_0x6B6F / _0xB322) * (math.pi / 2), ((_0x6B6F + 1) / _0xB322) * (math.pi / 2), ((_0x6B6F + 0.5) / _0xB322) * (math.pi / 2)
local _0x0DBB, _0x4326 = _0x4335 + dx * math.cos(_0xC024) * _0x9CEA, _0x952C + dy * math.sin(_0xC024) * _0x9CEA
local _0x8301, _0x7F5C = _0x4335 + dx * math.cos(_0xD639) * _0x9CEA, _0x952C + dy * math.sin(_0xD639) * _0x9CEA
local _0x39F5, _0xBF48 = _0x4335 + dx * math.cos(_0xF5E8) * _0x9CEA * 0.86, _0x952C + dy * math.sin(_0xF5E8) * _0x9CEA * 0.86
_0xFCBC:AddLine(_0x6A7C(_0x0DBB, _0x4326), _0x6A7C(_0x39F5, _0xBF48), _0x50A5, 1.0)
_0xFCBC:AddLine(_0x6A7C(_0x39F5, _0xBF48), _0x6A7C(_0x8301, _0x7F5C), _0x50A5, 1.0)
end
end
endfunction _0xD3A9.hw_bg()
local _0x721A, _0xB734 = _0xAAB1.GetWindowPos(), _0xAAB1.GetWindowSize()
local _0xFCBC = _0xAAB1.GetWindowDrawList()
local _0x6A7C = _0xAAB1.ImVec2
local _0xC5C0 = _0xAAB1.GetTime()
local _0xE62A, _0x813B = _0x721A.x + _0xB734.x - 78, _0x721A.y + 70
for _0x4E41 = 5, 1, -1 do
_0xFCBC:AddCircleFilled(_0x6A7C(_0xE62A, _0x813B), 40 + _0x4E41 * 14, _0x82F6(1.0, 0.82, 0.45, 0.012), 40)
end
_0xFCBC:AddCircleFilled(_0x6A7C(_0xE62A, _0x813B), 40, _0x82F6(1.0, 0.90, 0.62, 0.15), 40)
_0xFCBC:AddCircleFilled(_0x6A7C(_0xE62A - 12, _0x813B - 8), 9, _0x82F6(0.9, 0.7, 0.4, 0.08), 16)
_0xFCBC:AddCircleFilled(_0x6A7C(_0xE62A + 14, _0x813B + 10), 6, _0x82F6(0.9, 0.7, 0.4, 0.08), 16)
_0xFCBC:AddCircleFilled(_0x6A7C(_0xE62A + 6, _0x813B - 20), 5, _0x82F6(0.9, 0.7, 0.4, 0.08), 16)
local _0x0CF6, _0x29A9 = _0x721A.x + _0xB734.x * (0.30 + 0.20 * math.sin(_0xC5C0 * 0.13)), _0x721A.y + _0xB734.y * (0.65 + 0.15 * math.cos(_0xC5C0 * 0.10))
for _0x70A2 = 4, 1, -1 do
_0xFCBC:AddCircleFilled(_0x6A7C(_0x0CF6, _0x29A9), _0x70A2 * 60, _0x82F6(0.55, 0.20, 0.85, 0.016), 36)
end
for _0x4E41 = 1, 4 do
local _0x9E94 = _0xB734.x + 140
local _0x037E = _0x721A.x - 70 + ((_0xC5C0 * (22 + _0x4E41 * 6) + _0x4E41 * 173) % _0x9E94)
local _0x47CC = _0x721A.y + _0xB734.y * (0.12 + 0.17 * _0x4E41) + math.sin(_0xC5C0 * 0.8 + _0x4E41 * 2.0) * 16
_0xD3A9.hw_bat(_0xFCBC, _0x037E, _0x47CC, 10 + (_0x4E41 % 3) * 4, math.sin(_0xC5C0 * 9 + _0x4E41 * 1.7), 0.85)
end
_0xD3A9.hw_web(_0xFCBC, _0x721A.x + _0xB734.x - 6, _0x721A.y + 6, 80, -1, 1, 0.20)
_0xD3A9.hw_web(_0xFCBC, _0x721A.x + _0xB734.x - 6, _0x721A.y + _0xB734.y - 6, 100, -1, -1, 0.17)
endfunction _0xD3A9.hw_front(_0x700B, _0xA7B6, _0x0DBB, _0x4326)
local _0xFCBC = _0x47E7(_0xAAB1.GetWindowDrawList)
_0xD3A9.hw_pumpkin(_0xFCBC, _0x0DBB - 135, _0xA7B6 + 3 - 22 * 0.78, 22, 1, true)
_0xD3A9.hw_pumpkin(_0xFCBC, _0x0DBB - 66, _0xA7B6 + 3 - 16 * 0.78, 16, 1, false)
_0xD3A9.hw_pumpkin(_0xFCBC, _0x700B + 80, _0xA7B6 + 3 - 19 * 0.78, 19, 1, false)
end
local function _0x207F(_0x479B, _0xBA15, tip)
local _0x4A35 = (_0x307A == _0xBA15)
local _0x86C5 = _0x3CC0.accent
if _0x4A35 then
_0xAAB1.PushStyleColor(_0xAAB1.Col.Button, _0x0A8C(0.115, 0.28))
end
_0xAAB1.SetWindowFontScale(1.15)
local _0xD4EF = _0xAAB1.Button(_0x479B .."##tab".. _0xBA15, _0xAAB1.ImVec2(_0x2546 - 10, _0x4C9D.tab_h))
local _0xDE7C = _0xAAB1.IsItemHovered()
_0xAAB1.SetWindowFontScale(1.0)
if _0xD4EF then _0xD3A9.go_tab(_0xBA15) end
if _0xDE7C and tip then _0xAAB1.SetTooltip(tip) end
if _0x4A35 then
_0xAAB1.PopStyleColor(1)
local _0x7EF5, _0xD8B1 = _0xAAB1.GetItemRectMin(), _0xAAB1.GetItemRectMax()
local _0x9E14 = _0xAAB1.GetWindowPos()
_0xD3A9.bar_ty = (_0x7EF5.y + _0xD8B1.y) / 2 - _0x9E14.y
_0xD3A9.bar_x = _0x7EF5.x + 2 - _0x9E14.xlocal _0xFCBC = _0xAAB1.GetWindowDrawList()
for _0x4E41 = 3, 1, -1 do
_0xFCBC:AddRect(_0xAAB1.ImVec2(_0x7EF5.x - _0x4E41 * 1.5, _0x7EF5.y - _0x4E41 * 1.5), _0xAAB1.ImVec2(_0xD8B1.x + _0x4E41 * 1.5, _0xD8B1.y + _0x4E41 * 1.5),
_0x82F6(_0x86C5[1], _0x86C5[2], _0x86C5[3], 0.07 * (4 - _0x4E41)), 8 + _0x4E41, 15, 1.2)
end
end
endfunction _0x61A3.step(tbl, _0xE53D, _0x0C85, speed, _0xE6CC)
local _0x1545 = tbl[_0xE53D] or 0
_0x1545 = _0x1545 + (_0x0C85 - _0x1545) * math.min(1, _0xE6CC * speed)
tbl[_0xE53D] = _0x1545
return _0x1545
endfunction _0x61A3.button(_0xBA15, _0x479B, _0x93A6, _0x8E44, _0x86ED, action)
local _0xFCBC = _0xAAB1.GetWindowDrawList()
local _0x721A = _0xAAB1.GetCursorScreenPos()
local _0x4E32 = _0xAAB1.GetTime()
local _0xE6CC = _0xAAB1.GetIO().DeltaTime
local _0xD4EF = _0xAAB1.InvisibleButton("##cb".. _0xBA15, _0xAAB1.ImVec2(_0x8E44, _0x86ED))
local _0xDE7C, _0x40CF = _0xAAB1.IsItemHovered(), _0xAAB1.IsItemActive()
if _0xD4EF then
local _0x31C5 = _0xAAB1.GetMousePos()
_0x61A3.ripple[_0xBA15] = { _0xC5C0 = _0x4E32, _0x6BF7 = _0x31C5.x, _0x7077 = _0x31C5.y }
action()
end
local _0x9061 = _0x61A3.step(_0x61A3.hover, _0xBA15, _0xDE7C and 1 or 0, 14, _0xE6CC)
local _0x17F1 = _0x61A3.step(_0x61A3.press, _0xBA15, _0x40CF and 1 or 0, 24, _0xE6CC)local _0xEE8A, _0xC747, _0x33B0
if _0x93A6 == 2 then
local _0x1C8E = _0x3CC0.accent
_0xEE8A, _0xC747, _0x33B0 = _0x1C8E[1], _0x1C8E[2], _0x1C8E[3]
elseif _0x93A6 == 3 then
_0xEE8A, _0xC747, _0x33B0 = 0.55, 0.18, 0.20
elseif _0x93A6 == 1 then
_0xEE8A, _0xC747, _0x33B0 = 0.20, 0.20, 0.23
else
_0xEE8A, _0xC747, _0x33B0 = 0.145, 0.145, 0.165
end
local _0xE627 = 0.07 * _0x9061 - 0.05 * _0x17F1
local _0x70A2, _0x2126, _0x527F = _0x43DE(_0xEE8A + _0xE627, 0, 1), _0x43DE(_0xC747 + _0xE627, 0, 1), _0x43DE(_0x33B0 + _0xE627, 0, 1)
local _0x27E1 = 2.5 * _0x17F1local _0x0DBB, _0x4326 = _0x721A.x + _0x27E1, _0x721A.y + _0x27E1
local _0x8301, _0x7F5C = _0x721A.x + _0x8E44 - _0x27E1, _0x721A.y + _0x86ED - _0x27E1
local _0xDCDD = 11local _0x86C5 = _0x3CC0.accent
local _0x9D46 = _0x9061
if _0x93A6 == 2 then _0x9D46 = math.max(_0x9061, 0.35 + 0.25 * math.sin(_0x4E32 * 3.0)) end
if _0x9D46 > 0.02 then
for _0x4E41 = 3, 1, -1 do
_0xFCBC:AddRect(_0xAAB1.ImVec2(_0x0DBB - _0x4E41 * 1.6, _0x4326 - _0x4E41 * 1.6), _0xAAB1.ImVec2(_0x8301 + _0x4E41 * 1.6, _0x7F5C + _0x4E41 * 1.6),
_0x82F6(_0x86C5[1], _0x86C5[2], _0x86C5[3], 0.10 * _0x9D46 * (4 - _0x4E41) / 3), _0xDCDD + _0x4E41, 15, 1.4)
end
end
_0xFCBC:AddRectFilled(_0xAAB1.ImVec2(_0x0DBB, _0x4326), _0xAAB1.ImVec2(_0x8301, _0x7F5C), _0x82F6(_0x70A2, _0x2126, _0x527F, 1), _0xDCDD)_0xFCBC:AddRectFilled(_0xAAB1.ImVec2(_0x0DBB + 2, _0x4326 + 2), _0xAAB1.ImVec2(_0x8301 - 2, _0x4326 + (_0x7F5C - _0x4326) * 0.45), _0x82F6(1, 1, 1, 0.045 + 0.03 * _0x9061), _0xDCDD - 2)local _0xE3E6 = 0.10 + 0.75 * _0x9061
_0xFCBC:AddRect(_0xAAB1.ImVec2(_0x0DBB, _0x4326), _0xAAB1.ImVec2(_0x8301, _0x7F5C), _0x82F6(_0x86C5[1], _0x86C5[2], _0x86C5[3], _0xE3E6), _0xDCDD, 15, 1.2)local _0x7376 = _0x61A3.ripple[_0xBA15]
if _0x7376 then
local _0x6B6F = (_0x4E32 - _0x7376.t) / 0.5
if _0x6B6F >= 1 then
_0x61A3.ripple[_0xBA15] = nil
else
_0xFCBC:PushClipRect(_0xAAB1.ImVec2(_0x0DBB, _0x4326), _0xAAB1.ImVec2(_0x8301, _0x7F5C), true)
_0xFCBC:AddCircleFilled(_0xAAB1.ImVec2(_0x7376.x, _0x7376.y), _0x6B6F * math.max(_0x8E44, _0x86ED) * 1.1, _0x82F6(1, 1, 1, 0.30 * (1 - _0x6B6F)), 32)
_0xFCBC:PopClipRect()
end
endlocal _0x0F4A = _0xAAB1.CalcTextSize(_0x479B)
_0xFCBC:AddText(_0xAAB1.ImVec2(_0x721A.x + (_0x8E44 - _0x0F4A.x) / 2, _0x721A.y + (_0x86ED - _0x0F4A.y) / 2 + _0x17F1), _0x82F6(1, 1, 1, 0.95), _0x479B)
endfunction _0x61A3.display(_0x8E44, _0x86ED)
local _0x4E32 = _0xAAB1.GetTime()
local _0x86C5 = _0x3CC0.accent
local _0x721A = _0xAAB1.GetCursorScreenPos()
local _0xFCBC = _0xAAB1.GetWindowDrawList()
local _0xEABA = _0x43DE(1 - (_0x4E32 - _0x61A3.pop_t) / 0.6, 0, 1)
_0xFCBC:AddRectFilled(_0x721A, _0xAAB1.ImVec2(_0x721A.x + _0x8E44, _0x721A.y + _0x86ED), _0x82F6(0.075, 0.075, 0.09, 1), 14)
_0xFCBC:AddRectFilled(_0x721A, _0xAAB1.ImVec2(_0x721A.x + _0x8E44, _0x721A.y + _0x86ED), _0x82F6(_0x86C5[1], _0x86C5[2], _0x86C5[3], 0.05 + 0.10 * _0xEABA), 14)
_0xFCBC:AddRect(_0x721A, _0xAAB1.ImVec2(_0x721A.x + _0x8E44, _0x721A.y + _0x86ED), _0x82F6(_0x86C5[1], _0x86C5[2], _0x86C5[3], 0.35 + 0.55 * _0xEABA), 14, 15, 1.5)
local _0xA09E = _0x43DE(_0x86ED / 100 * 1.9, 1.7, 3.2)
local _0xF6A5, _0xA1E8
if _0x56E4 then
_0xF6A5, _0xA1E8 = _0x56E4, { 1.0, 0.38, 0.38 }
else
_0xF6A5, _0xA1E8 = (_0x5D04 =="") and"0"or _0xF021(_0x5D04), { 1, 1, 1 }
end_0xAAB1.SetWindowFontScale(1.1)
local _0x8681 = _0x3203 ~=""and _0x3203 or""local _0x924C = _0xAAB1.CalcTextSize(_0x8681)
_0xFCBC:AddText(_0xAAB1.ImVec2(_0x721A.x + _0x8E44 - 16 - _0x924C.x, _0x721A.y + 10), _0x82F6(0.62, 0.62, 0.68, 1), _0x8681)local _0x04E9 = 1 + 0.16 * _0xEABA * _0xEABA
local _0x044D = _0xA09E
_0xAAB1.SetWindowFontScale(_0x044D)
while _0x044D > 0.9 and _0xAAB1.CalcTextSize(_0xF6A5).x > (_0x8E44 - 36) / _0x04E9 do
_0x044D = _0x044D - 0.1
_0xAAB1.SetWindowFontScale(_0x044D)
end
local _0x0F4A = _0xAAB1.CalcTextSize(_0xF6A5)
local _0x1FA4 = _0x044D * _0x04E9
_0xAAB1.SetWindowFontScale(_0x1FA4)
_0x0F4A = _0xAAB1.CalcTextSize(_0xF6A5)
local _0x3F32 = _0x721A.x + _0x8E44 - 18 - _0x0F4A.x
local _0x8C9B = _0x721A.y + _0x86ED - 12 - _0x0F4A.y + 4 * (1 - _0xEABA)
_0xFCBC:AddText(_0xAAB1.ImVec2(_0x3F32 + 1.5, _0x8C9B + 1.5), _0x82F6(0, 0, 0, 0.5), _0xF6A5)
_0xFCBC:AddText(_0xAAB1.ImVec2(_0x3F32, _0x8C9B), _0x82F6(_0xA1E8[1], _0xA1E8[2], _0xA1E8[3], 1), _0xF6A5)
_0xAAB1.SetWindowFontScale(1.0)
_0xAAB1.Dummy(_0xAAB1.ImVec2(_0x8E44, _0x86ED))
endfunction _0x61A3.history(_0x8E44, _0x86ED)
local _0x86C5 = _0x3CC0.accent
if _0xAAB1.BeginChild("##calc_hist", _0xAAB1.ImVec2(_0x8E44, _0x86ED), true) then
_0xAAB1.TextColored(_0xB079(1.2), _0x4BFE("CLOCK_ROTATE_LEFT","") .." История")
_0xAAB1.Separator()
if #_0x61A3.hist == 0 then
_0xAAB1.TextColored(_0xAAB1.ImVec4(0.55, 0.55, 0.6, 1),"Пока пусто")
else
for _0x4E41 = #_0x61A3.hist, 1, -1 do
local _0x40E5 = _0x61A3.hist[_0x4E41]
_0xAAB1.PushStyleColor(_0xAAB1.Col.Button, _0xAAB1.ImVec4(0, 0, 0, 0))
_0xAAB1.PushStyleColor(_0xAAB1.Col.ButtonHovered, _0xB079(1.0, 0.25))
_0xAAB1.PushStyleColor(_0xAAB1.Col.ButtonActive, _0xB079(1.0, 0.4))
if _0xAAB1.Button(_0x40E5.res .."##h".. _0x4E41, _0xAAB1.ImVec2(-1, 34)) then
_0x5D04, _0x3203, _0x56E4, _0x58E8 = _0x40E5.raw,"", nil, false
end
_0xAAB1.PopStyleColor(3)
_0xAAB1.TextColored(_0xAAB1.ImVec4(0.55, 0.55, 0.6, 1), _0x40E5.expr)
_0xAAB1.Spacing()
end
end
if #_0x61A3.hist > 0 then
if _0xAAB1.Button("Очистить##hclr", _0xAAB1.ImVec2(-1, 28)) then _0x61A3.hist = {} end
end
end
_0xAAB1.EndChild()
end
local function _0x92BA()
local _0x17E0, _0xFBEC = getScreenResolution()if not _0x61A3.grown then
_0x61A3.grown = true
if _0x4C9D.w < 960 or _0x4C9D.h < 640 then
_0x4C9D.req = { _0x8E44 = math.min(math.max(_0x4C9D.w, 980), _0x17E0 - 40), _0x86ED = math.min(math.max(_0x4C9D.h, 660), _0xFBEC - 40) }
end
end_0xAAB1.AlignTextToFramePadding()
_0xAAB1.SetCursorPosX(9)
_0xAAB1.Text(_0x4BFE("CALCULATOR","") .." Калькулятор")
_0xAAB1.SameLine(_0x4C9D.w - _0x2546 - 76)
_0xAAB1.PushStyleColor(_0xAAB1.Col.Button, _0xAAB1.ImVec4(0, 0, 0, 0))
if _0xAAB1.Button(_0x4BFE("CLOCK_ROTATE_LEFT","H") .."##calc_hist_btn", _0xAAB1.ImVec2(30, 24)) then
_0x61A3.hist_open = not _0x61A3.hist_open
end
_0xAAB1.SameLine(_0x4C9D.w - _0x2546 - 29)
if _0xAAB1.Button(_0xB72A.CIRCLE_XMARK .."##close_calc", _0xAAB1.ImVec2(24, 24)) then
_0xF7A7[0] = false
end
if _0xAAB1.IsItemHovered() then _0xAAB1.SetTooltip("Закрыть") end
_0xAAB1.PopStyleColor(1)
_0xAAB1.Spacing()
local _0xE3A2 = _0xAAB1.GetContentRegionAvail()
local _0x8DFD = 9
local _0x8F35 = _0x61A3.hist_open and 200 or 0
local _0xCF43 = _0xE3A2.x - _0x8F35 - (_0x8F35 > 0 and 12 or 0) - 16
local _0x06D0 = _0x43DE(_0xCF43, 300, 720)
local _0x9A9A = _0x43DE(_0xE3A2.y * 0.25, 92, 160)
local _0x5488 = _0x43DE((_0xE3A2.y - _0x9A9A - 6 * _0x8DFD - 6) / 5, 40, 110)
local _0x624F = (_0x06D0 - 3 * _0x8DFD) / 4
local _0x700B = 8 + math.max(0, (_0xCF43 - _0x06D0) / 2)
local _0xA7B6 = _0xAAB1.GetCursorPosY()
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(_0x700B, _0xA7B6))
_0x61A3.display(_0x06D0, _0x9A9A)
local function _0x47FC(_0xB322) return function() _0x7ED8(_0xB322) end end
local function _0x463E(_0xB322) return function() _0xAA2D(_0xB322) end end
local _0x4A55 = {
{ {"C", _0xF233, 3}, {_0x4BFE("DELETE_LEFT","<"), _0x4DB0, 1}, {_0x4BFE("PERCENT","%"), _0x00AB, 1}, {_0x4BFE("DIVIDE","/"), _0x463E("/"), 1} },
{ {"7", _0x47FC("7"), 0}, {"8", _0x47FC("8"), 0}, {"9", _0x47FC("9"), 0}, {_0x4BFE("XMARK","x"), _0x463E("*"), 1} },
{ {"4", _0x47FC("4"), 0}, {"5", _0x47FC("5"), 0}, {"6", _0x47FC("6"), 0}, {_0x4BFE("MINUS","-"), _0x463E("-"), 1} },
{ {"1", _0x47FC("1"), 0}, {"2", _0x47FC("2"), 0}, {"3", _0x47FC("3"), 0}, {_0x4BFE("PLUS","+"), _0x463E("+"), 1} },
{ {"0", _0x47FC("0"), 0}, {"000", _0x47FC("000"), 0}, {",", _0x9BCE, 0}, {_0x4BFE("EQUALS","="), _0xDFEA, 2} },
}
_0xAAB1.SetWindowFontScale(_0x43DE(_0x5488 / 54 * 1.25, 1.2, 2.0))
for _0x70A2, row in ipairs(_0x4A55) do
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(_0x700B, _0xA7B6 + _0x9A9A + _0x8DFD + (_0x70A2 - 1) * (_0x5488 + _0x8DFD)))
for _0x6D18, _0x527F in ipairs(row) do
if _0x6D18 > 1 then _0xAAB1.SameLine(0, _0x8DFD) end
_0x61A3.button(_0x70A2 .."_".. _0x6D18, _0x527F[1], _0x527F[3], _0x624F, _0x5488, _0x527F[2])
end
end
_0xAAB1.SetWindowFontScale(1.0)
if _0x8F35 > 0 then
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(_0x700B + _0x06D0 + 12 + math.max(0, (_0xCF43 - _0x06D0) / 2) * 0, _0xA7B6))
_0x61A3.history(_0x8F35, _0x9A9A + 5 * (_0x5488 + _0x8DFD))
end
endlocal _0xFF7B = getWorkingDirectory() .."\\config\\arizona_prices_settings.json"local _0xED9C = { ui = _0x3CC0, favs = {}, notes ="", payday = { enabled = false, _0x6BF7 = 20, _0x7077 = 300 }, phrases = {}, clock = { enabled = false, country ="Узбекистан", _0x6BF7 = 20, _0x7077 = 340 } }
local function _0x7E07()
local _0xA9F3 = _0xF239(_0xFF7B)
if not _0xA9F3 then return end
if type(_0xA9F3.payday) =="table"then
_0xED9C.payday.enabled = (_0xA9F3.payday.enabled == true)
_0xED9C.payday.x = tonumber(_0xA9F3.payday.x) or 20
_0xED9C.payday.y = tonumber(_0xA9F3.payday.y) or 300
end
if type(_0xA9F3.phrases) =="table"then
local _0xB6EB = {}
for _0x374C, _0x1545 in ipairs(_0xA9F3.phrases) do
if type(_0x1545) =="string"and _0x1545 ~=""then _0xB6EB[#_0xB6EB + 1] = _0x1545 end
end
_0xED9C.phrases = _0xB6EB
end
if type(_0xA9F3.clock) =="table"then
_0xED9C.clock.enabled = (_0xA9F3.clock.enabled == true)
if type(_0xA9F3.clock.country) =="string"then _0xED9C.clock.country = _0xA9F3.clock.country end
_0xED9C.clock.x = tonumber(_0xA9F3.clock.x) or 20
_0xED9C.clock.y = tonumber(_0xA9F3.clock.y) or 340
end
if type(_0xA9F3.favs) =="table"then
local _0x16E5 = {}
for _0x6B6F, _0x1545 in pairs(_0xA9F3.favs) do
if type(_0x6B6F) =="string"and _0x1545 == true then _0x16E5[_0x6B6F] = true end
end
_0xED9C.favs = _0x16E5
end
if type(_0xA9F3.notes) =="string"then _0xED9C.notes = _0xA9F3.notes:sub(1, 8000) end
if type(_0xA9F3.ui) =="table"then
local _0x6E27 = _0xA9F3.ui
if type(_0x6E27.accent) =="table"and tonumber(_0x6E27.accent[1]) and tonumber(_0x6E27.accent[2]) and tonumber(_0x6E27.accent[3]) then
_0x3CC0.accent = { _0x43DE(tonumber(_0x6E27.accent[1]), 0, 1), _0x43DE(tonumber(_0x6E27.accent[2]), 0, 1), _0x43DE(tonumber(_0x6E27.accent[3]), 0, 1) }
end
_0x3CC0.opacity = _0x43DE(tonumber(_0x6E27.opacity) or 1.0, 0.3, 1.0)
_0x3CC0.overlay_scale = _0x43DE(tonumber(_0x6E27.overlay_scale) or 1.0, 0.7, 2.0)
_0x3CC0.open_key = math.max(0, math.floor(tonumber(_0x6E27.open_key) or 0))
_0x3CC0.toasts = (_0x6E27.toasts ~= false)
_0x3CC0.toast_corner = _0x43DE(math.floor(tonumber(_0x6E27.toast_corner) or 3), 0, 3)
_0x3CC0.border_mode = _0x43DE(math.floor(tonumber(_0x6E27.border_mode) or 1), 0, 3)
_0x3CC0.border_speed = _0x43DE(tonumber(_0x6E27.border_speed) or 1.0, 0.2, 3.0)
_0x3CC0.shadow = (_0x6E27.shadow ~= false)
_0x3CC0.bg_fx = (_0x6E27.bg_fx ~= false)
_0x3CC0.splash = (_0x6E27.splash ~= false)
if _0x6E27.halloween == nil then
_0x3CC0.halloween = true
_0x3CC0.accent = { 0.98, 0.55, 0.12 }
else
_0x3CC0.halloween = (_0x6E27.halloween == true)
end
if type(_0x6E27.font) =="string"then _0x3CC0.font = _0x6E27.font end
_0x3CC0.win_w = _0x43DE(math.floor(tonumber(_0x6E27.win_w) or 835), 700, 2400)
_0x3CC0.win_h = _0x43DE(math.floor(tonumber(_0x6E27.win_h) or 500), 400, 1400)
end
end
local function _0x16A4()
local _0x6A3E = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0x6A3E) then
createDirectory(_0x6A3E)
end
local _0x2457, _0x3621 = pcall(encodeJson, _0xED9C)
if _0x2457 and type(_0x3621) =="string"and _0x3621 ~=""then
_0x8F51(_0xFF7B, _0x3621)
end
end
_0x076F("load_settings", _0x7E07)_0xD3A9.notes = _0xAAB1.new.char[8192]()
_0xAAB1.StrCopy(_0xD3A9.notes, _0xED9C.notes or"")
function _0xD3A9.toggle_fav(_0x6E19)
if _0xED9C.favs[_0x6E19] then _0xED9C.favs[_0x6E19] = nil else _0xED9C.favs[_0x6E19] = true end
_0x16A4()
end
local _0xF906 = _0xAAB1.new.bool(_0xED9C.payday.enabled)
local _0xD790 = false
local _0x87E3 = { _0x6BF7 = _0xED9C.payday.x, _0x7077 = _0xED9C.payday.y }
local _0xD2EA = _0xAAB1.new.char[256]()
local function _0xB8D8()
local _0x31C5 = tonumber(os.date("%M")) or 0
if _0x31C5 < 30 then return 30 - _0x31C5 end
return 60 - _0x31C5
end
local function _0x9A77()
local _0x47FC = os.date("*t")
local _0x9772 = 1800 - ((_0x47FC.min % 30) * 60 + _0x47FC.sec)
return"До PayDay: ".. math.floor(_0x9772 / 60) .." мин ".. string.format("%02d", _0x9772 % 60) .." сек"end
local function _0x397C(_0xB322)
local _0xECB5, _0x67A1 = _0xB322 % 10, _0xB322 % 100
if _0x67A1 >= 11 and _0x67A1 <= 14 then return"минут"end
if _0xECB5 == 1 then return"минута"end
if _0xECB5 >= 2 and _0xECB5 <= 4 then return"минуты"end
return"минут"end
local function _0x4D2B(_0x2149, _0x6FF2)
_0xAAB1.AlignTextToFramePadding()
_0xAAB1.SetCursorPosX(9)
_0xAAB1.Text(_0x2149 .." ".. _0x6FF2)
_0xAAB1.SameLine(_0x4C9D.w - _0x2546 - 29)
_0xAAB1.PushStyleColor(_0xAAB1.Col.Button, _0xAAB1.ImVec4(0, 0, 0, 0))
if _0xAAB1.Button(_0xB72A.CIRCLE_XMARK .."##close_section", _0xAAB1.ImVec2(24, 24)) then
_0xF7A7[0] = false
end
if _0xAAB1.IsItemHovered() then _0xAAB1.SetTooltip("Закрыть") end
_0xAAB1.PopStyleColor(1)
_0xAAB1.Spacing()
end
local function _0x4747()
_0x4D2B(_0x4BFE("CLOCK",""),"Отчет до PayDay")
if _0xAAB1.BeginChild("##payday_child", _0xAAB1.ImVec2(-1, _0x4C9D.h - 79), true) then
_0xAAB1.SetWindowFontScale(1.35)
_0xAAB1.TextWrapped("На экране появится надпись «До PayDay: N мин N сек». PayDay выплачивается каждые 30 минут: в :00 и :30.")
_0xAAB1.Spacing()
if _0xAAB1.Checkbox(" Включить", _0xF906) then
_0xED9C.payday.enabled = _0xF906[0]
_0x16A4()
end
_0xAAB1.Spacing()
_0xAAB1.Separator()
_0xAAB1.Spacing()
_0xAAB1.Text("Положение надписи на экране:")
_0xAAB1.Spacing()
if not _0xD790 then
if _0xAAB1.Button(_0x4BFE("UP_DOWN_LEFT_RIGHT","") .." Передвинуть надпись", _0xAAB1.ImVec2(360, 56)) then
_0xD790 = true
_0xF906[0] = true
end
else
_0xAAB1.TextColored(_0xAAB1.ImVec4(0.45, 1.00, 0.55, 1.00),"Перетащи надпись мышкой, затем нажми «Сохранить».")
if _0xAAB1.Button(_0xB72A.FLOPPY_DISK .." Сохранить положение", _0xAAB1.ImVec2(360, 56)) then
_0xED9C.payday.x = _0x87E3.x
_0xED9C.payday.y = _0x87E3.y
_0xED9C.payday.enabled = _0xF906[0]
_0x16A4()
_0xD790 = false
_0x3EA3("Положение надписи сохранено","ok")
end
end
_0xAAB1.Spacing()
_0xAAB1.TextDisabled("Сейчас: ".. _0x9A77())
_0xAAB1.SetWindowFontScale(1.0)
end
_0xAAB1.EndChild()
end
local function _0x3DC3()
_0x4D2B(_0x4BFE("COMMENT_DOTS",""),"Фразы для автоотправки")
_0xAAB1.SetWindowFontScale(1.3)
_0xAAB1.SetNextItemWidth(_0xAAB1.GetContentRegionAvail().x - 190)
local _0xDA6A = _0xAAB1.InputTextWithHint("##phrase_input","Введи фразу или команду (например /time)", _0xD2EA, _0x90EB.sizeof(_0xD2EA), _0xAAB1.InputTextFlags.EnterReturnsTrue)
_0xAAB1.SameLine()
local _0x384B = _0xAAB1.Button(_0xB72A.CIRCLE_PLUS .." Добавить##add_phrase", _0xAAB1.ImVec2(180, 0))
if _0xDA6A or _0x384B then
local _0xC139 = _0x90EB.string(_0xD2EA)
if _0xC139:gsub("%s","") ~=""then
table.insert(_0xED9C.phrases, _0xC139)
_0x16A4()
_0xAAB1.StrCopy(_0xD2EA,"")
end
end
_0xAAB1.Spacing()
if _0xAAB1.BeginChild("##phrases_list", _0xAAB1.ImVec2(-1, -36), true) then
if #_0xED9C.phrases == 0 then
_0xAAB1.TextDisabled("Пока нет фраз. Добавь первую выше.")
end
local _0x5D5C = nil
for _0x4E41, phrase in ipairs(_0xED9C.phrases) do
if _0xAAB1.Button(_0xB72A.PAPER_PLANE .."##send_phrase_".. _0x4E41, _0xAAB1.ImVec2(52, 40)) then
local _0xD6C6 = phrase
_0x0EA0(function() sampSendChat(_0xACD5:decode(_0xD6C6)) end)
end
if _0xAAB1.IsItemHovered() then _0xAAB1.SetTooltip("Отправить в чат") end
_0xAAB1.SameLine()
if _0xAAB1.Button(_0xB72A.TRASH_CAN .."##del_phrase_".. _0x4E41, _0xAAB1.ImVec2(52, 40)) then
_0x5D5C = _0x4E41
end
if _0xAAB1.IsItemHovered() then _0xAAB1.SetTooltip("Удалить фразу") end
_0xAAB1.SameLine()
_0xAAB1.AlignTextToFramePadding()
_0xAAB1.TextUnformatted(phrase)
end
if _0x5D5C then
table.remove(_0xED9C.phrases, _0x5D5C)
_0x16A4()
end
end
_0xAAB1.EndChild()
_0xAAB1.SetWindowFontScale(1.0)
end
local _0xCA5D = {
{ _0x2149 ="PAPER_PLANE", _0x6FF2 ="Telegram-канал", _0xEE69 ="https://t.me/arizona_prices", _0xA1E8 = {0.16, 0.62, 0.86} },
{ _0x2149 ="COMMENTS", _0x6FF2 ="Discord-канал", _0xEE69 ="https://discord.gg/z4UmCnRwd", _0xA1E8 = {0.35, 0.40, 0.95} },
{ _0x2149 ="MUSIC", _0x6FF2 ="TikTok-канал", _0xEE69 ="https://www.tiktok.com/@cosmychesky_jetpack", _0xA1E8 = {0.86, 0.15, 0.40} },
{ _0x2149 ="USER", _0x6FF2 ="Discord разработчика", copy ="sawnoff_karabin07", _0xA1E8 = {0.35, 0.40, 0.95} },
{ _0x2149 ="PAPER_PLANE", _0x6FF2 ="ЛС разработчика в Telegram", _0xEE69 ="https://t.me/xi_vivide", _0xA1E8 = {0.16, 0.62, 0.86} },
{ _0x2149 ="PAPER_PLANE", _0x6FF2 ="ЛС разработчика в Telegram 2", _0xEE69 ="https://t.me/obrezik", _0xA1E8 = {0.16, 0.62, 0.86} },
}
local function _0x7265()
_0x4D2B(_0x4BFE("CIRCLE_INFO",""),"О скрипте")
if _0xAAB1.BeginChild("##about_child", _0xAAB1.ImVec2(-1, _0x4C9D.h - 79), true) then
_0xAAB1.SetWindowFontScale(1.25)
_0xAAB1.TextColored(_0xAAB1.ImVec4(0.30, 0.65, 1.00, 1.00),"Arizona Prices V2.0")
_0xAAB1.TextWrapped("Спасибо, что пользуешься скриптом! Заходи в наши соцсети: там актуальные цены, новости и обновления. Нашёл ошибку или есть идея - пиши разработчику в личные сообщения.")
_0xAAB1.Spacing()
_0xAAB1.Separator()
_0xAAB1.Spacing()
for _0x4E41, _0x2FEE in ipairs(_0xCA5D) do
local _0x6D18 = _0x2FEE.color
_0xAAB1.PushStyleColor(_0xAAB1.Col.Button, _0xAAB1.ImVec4(_0x6D18[1] * 0.55, _0x6D18[2] * 0.55, _0x6D18[3] * 0.55, 1.00))
_0xAAB1.PushStyleColor(_0xAAB1.Col.ButtonHovered, _0xAAB1.ImVec4(_0x6D18[1] * 0.80, _0x6D18[2] * 0.80, _0x6D18[3] * 0.80, 1.00))
_0xAAB1.PushStyleColor(_0xAAB1.Col.ButtonActive, _0xAAB1.ImVec4(_0x6D18[1], _0x6D18[2], _0x6D18[3], 1.00))
if _0xAAB1.Button("##about_".. _0x4E41, _0xAAB1.ImVec2(-1, 56)) then
if _0x2FEE.url then
_0x1810(_0x2FEE.url)
elseif _0x2FEE.copy then
_0xAAB1.SetClipboardText(_0x2FEE.copy)
_0x3EA3("Ник скопирован: ".. _0x2FEE.copy,"ok")
end
end
local _0x7EF5, _0xD8B1 = _0xAAB1.GetItemRectMin(), _0xAAB1.GetItemRectMax()
local _0xFCBC = _0xAAB1.GetWindowDrawList()
local _0x952C = (_0x7EF5.y + _0xD8B1.y) / 2
local _0x0F4A = _0xAAB1.CalcTextSize(_0x2FEE.title)
_0xFCBC:AddText(_0xAAB1.ImVec2((_0x7EF5.x + _0xD8B1.x) / 2 - _0x0F4A.x / 2, _0x952C - _0x0F4A.y / 2), 0xFFFFFFFF, _0x2FEE.title)
local _0x2149 = _0x4BFE(_0x2FEE.icon,"")
local _0x3F3E = _0xAAB1.CalcTextSize(_0x2149)
_0xFCBC:AddText(_0xAAB1.ImVec2(_0x7EF5.x + 18, _0x952C - _0x3F3E.y / 2), 0xFFFFFFFF, _0x2149)
_0xAAB1.PopStyleColor(3)
end
_0xAAB1.SetWindowFontScale(1.0)
end
_0xAAB1.EndChild()
endlocal function _0xF88E(_0x7077, _0x31C5, _0x47FC)
if _0x31C5 <= 2 then _0x7077 = _0x7077 - 1 end
local _0x3210 = math.floor(_0x7077 / 400)
local _0x0BF5 = _0x7077 - _0x3210 * 400
local _0xF201 = (_0x31C5 + 9) % 12
local _0xDE79 = math.floor((153 * _0xF201 + 2) / 5) + _0x47FC - 1
local _0x8C4F = _0x0BF5 * 365 + math.floor(_0x0BF5 / 4) - math.floor(_0x0BF5 / 100) + _0xDE79
return _0x3210 * 146097 + _0x8C4F - 719468
end
local function _0x24A6(_0x7077, _0x31C5, _0x47FC, _0x86ED)
return _0xF88E(_0x7077, _0x31C5, _0x47FC) * 86400 + _0x86ED * 3600
end
local function _0xE55D(_0x7077, _0x31C5, _0x47FC)return (_0xF88E(_0x7077, _0x31C5, _0x47FC) + 4) % 7
end
local function _0x5DBF(_0x7077, _0x31C5, _0xB322)
local _0x250D = 1 + (7 - _0xE55D(_0x7077, _0x31C5, 1)) % 7
return _0x250D + (_0xB322 - 1) * 7
end
local function _0x449A(_0x7077, _0x31C5)
local _0x060B = ({31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31})[_0x31C5]
return _0x060B - _0xE55D(_0x7077, _0x31C5, _0x060B)
end
local function _0xD255(rule, std_offset, _0x4E32)
local _0x7077 = tonumber(os.date("!%Y", _0x4E32))
if rule =="eu"then
local _0xB734 = _0x24A6(_0x7077, 3, _0x449A(_0x7077, 3), 1)
local _0x40E5 = _0x24A6(_0x7077, 10, _0x449A(_0x7077, 10), 1)
return _0x4E32 >= _0xB734 and _0x4E32 < _0x40E5
elseif rule =="us"then
local _0xB734 = _0x24A6(_0x7077, 3, _0x5DBF(_0x7077, 3, 2), 2) - std_offset * 3600
local _0x40E5 = _0x24A6(_0x7077, 11, _0x5DBF(_0x7077, 11, 1), 2) - (std_offset + 1) * 3600
return _0x4E32 >= _0xB734 and _0x4E32 < _0x40E5
end
return false
end
local function _0x8259()
local _0x4E32 = os.time()
local _0x2FEE = os.date("*t", _0x4E32)
local _0x6E27 = os.date("!*t", _0x4E32)
_0x6E27.isdst = _0x2FEE.isdst
return os.difftime(os.time(_0x2FEE), os.time(_0x6E27)) / 3600
end
local _0x7344 = {
{ _0x6E19 ="Азербайджан", _0xE54C = 4 },
{ _0x6E19 ="Армения", _0xE54C = 4 },
{ _0x6E19 ="Беларусь", _0xE54C = 3 },
{ _0x6E19 ="Великобритания", _0xE54C = 0, dst ="eu"},
{ _0x6E19 ="Германия", _0xE54C = 1, dst ="eu"},
{ _0x6E19 ="Грузия", _0xE54C = 4 },
{ _0x6E19 ="Индия", _0xE54C = 5.5 },
{ _0x6E19 ="Казахстан", _0xE54C = 5 },
{ _0x6E19 ="Китай", _0xE54C = 8 },
{ _0x6E19 ="Кыргызстан", _0xE54C = 6 },
{ _0x6E19 ="Москва (время Аризоны)", _0xE54C = 3 },
{ _0x6E19 ="ОАЭ", _0xE54C = 4 },
{ _0x6E19 ="Польша", _0xE54C = 1, dst ="eu"},
{ _0x6E19 ="Россия, Владивосток", _0xE54C = 10 },
{ _0x6E19 ="Россия, Екатеринбург", _0xE54C = 5 },
{ _0x6E19 ="Россия, Новосибирск", _0xE54C = 7 },
{ _0x6E19 ="США, Лос-Анджелес", _0xE54C = -8, dst ="us"},
{ _0x6E19 ="США, Нью-Йорк", _0xE54C = -5, dst ="us"},
{ _0x6E19 ="Таджикистан", _0xE54C = 5 },
{ _0x6E19 ="Таиланд", _0xE54C = 7 },
{ _0x6E19 ="Турция", _0xE54C = 3 },
{ _0x6E19 ="Узбекистан", _0xE54C = 5 },
{ _0x6E19 ="Украина", _0xE54C = 2, dst ="eu"},
{ _0x6E19 ="Япония", _0xE54C = 9 },
}
local _0x02CA = 1
for _0x4E41, _0x6D18 in ipairs(_0x7344) do
if _0x6D18.name =="Узбекистан"then _0x02CA = _0x4E41 end
end
local function _0xF666(_0x6D18)
local _0x4E32 = os.time()
local _0xE54C
if _0x6D18.pc then
_0xE54C = _0x8259()
else
_0xE54C = _0x6D18.off
if _0x6D18.dst and _0xD255(_0x6D18.dst, _0x6D18.off, _0x4E32) then _0xE54C = _0xE54C + 1 end
end
local _0xB8EB = _0x4E32 + _0xE54C * 3600
return os.date("!%H:%M:%S", _0xB8EB), os.date("!%d.%m.%Y", _0xB8EB)
end
local function _0x50C2(_0xA1E8, _0xC139)
local _0x721A = _0xAAB1.GetCursorScreenPos()
_0xAAB1.GetWindowDrawList():AddText(_0xAAB1.ImVec2(_0x721A.x + 1, _0x721A.y + 1), 0xFF000000, _0xC139)
_0xAAB1.TextColored(_0xA1E8, _0xC139)
end
local _0xADC2 = false
local _0x7C67 = { _0x6BF7 = _0xED9C.clock.x, _0x7077 = _0xED9C.clock.y }
local _0x971E = false
local _0x5692 = nil
local _0xF18F ="Время на экране###clock_modal"local function _0x6AE9(_0x6E19)
for _0x374C, _0x6D18 in ipairs(_0x7344) do
if _0x6D18.name == _0x6E19 then return _0x6D18 end
end
return _0x7344[1]
end
local function _0x1F6B()
_0x4D2B(_0x4BFE("GLOBE",""),"Время стран")
if _0xAAB1.BeginChild("##time_child", _0xAAB1.ImVec2(-1, _0x4C9D.h - 79), true) then
local _0x5575 = _0x7344[_0x02CA]
local _0x5BDC, _0xE6CC = _0xF666(_0x5575)
local _0x86AD = _0xAAB1.GetWindowWidth()
_0xAAB1.SetWindowFontScale(2.4)
local _0x0F4A = _0xAAB1.CalcTextSize(_0x5BDC)
_0xAAB1.SetCursorPosX(math.max(5, (_0x86AD - _0x0F4A.x) / 2))
_0xAAB1.TextColored(_0xAAB1.ImVec4(1.00, 0.85, 0.30, 1.00), _0x5BDC)
_0xAAB1.SetWindowFontScale(1.0)
local _0x479B = _0x5575.name .."  |  ".. _0xE6CC
local _0xA2F4 = _0xAAB1.CalcTextSize(_0x479B)
_0xAAB1.SetCursorPosX(math.max(5, (_0x86AD - _0xA2F4.x) / 2))
_0xAAB1.Text(_0x479B)
_0xAAB1.Spacing()
_0xAAB1.Separator()
_0xAAB1.Spacing()
if _0xED9C.clock.enabled then
_0xAAB1.AlignTextToFramePadding()
_0xAAB1.Text("На экране: ".. _0xED9C.clock.country)
_0xAAB1.SameLine()
if not _0xADC2 then
if _0xAAB1.Button("Передвинуть##clock_move") then _0xADC2 = true end
else
if _0xAAB1.Button(_0xB72A.FLOPPY_DISK .." Сохранить положение##clock_save") then
_0xED9C.clock.x = _0x7C67.x
_0xED9C.clock.y = _0x7C67.y
_0x16A4()
_0xADC2 = false
end
end
_0xAAB1.SameLine()
if _0xAAB1.Button("Убрать с экрана##clock_hide") then
_0xED9C.clock.enabled = false
_0xADC2 = false
_0x16A4()
end
if _0xADC2 then
_0xAAB1.TextColored(_0xAAB1.ImVec4(0.45, 1.00, 0.55, 1.00),"Перетащи надпись мышкой, затем нажми «Сохранить положение».")
end
_0xAAB1.Spacing()
_0xAAB1.Separator()
_0xAAB1.Spacing()
end
if _0xAAB1.BeginChild("##time_list", _0xAAB1.ImVec2(-1, -1), false) then
local _0xAC10 = math.floor((_0xAAB1.GetContentRegionAvail().x - 10 - 16) / 3)
for _0x4E41, _0x6D18 in ipairs(_0x7344) do
if (_0x4E41 - 1) % 3 ~= 0 then _0xAAB1.SameLine() end
local _0x97C4 = _0xF666(_0x6D18)
local _0x4A35 = (_0x4E41 == _0x02CA)
if _0x4A35 then
_0xAAB1.PushStyleColor(_0xAAB1.Col.Button, _0xB079(1.0))
end
if _0xAAB1.Button(_0x6D18.name .."\n".. _0x97C4 .."###country_".. _0x4E41, _0xAAB1.ImVec2(_0xAC10, 44)) then
_0x02CA = _0x4E41
_0x5692 = _0x4E41
_0x971E = true
local _0x7634, _0xF9DC = _0xF666(_0x6D18)
local _0xA255 = _0xACD5:decode("{33AAFF}[Arizona Prices] {FFFFFF}Время (".. _0x6D18.name .."): {33AAFF}".. _0x7634 .." {FFFFFF}(".. _0xF9DC ..")")
_0x0EA0(function() sampAddChatMessage(_0xA255, -1) end)
end
if _0x4A35 then _0xAAB1.PopStyleColor(1) end
end
end
_0xAAB1.EndChild()
if _0x971E then
_0xAAB1.OpenPopup(_0xF18F)
_0x971E = false
end
local _0x17E0, _0xFBEC = getScreenResolution()
_0xAAB1.SetNextWindowPos(_0xAAB1.ImVec2(_0x17E0 / 2, _0xFBEC / 2), _0xAAB1.Cond.Always, _0xAAB1.ImVec2(0.5, 0.5))
_0xAAB1.SetNextWindowSize(_0xAAB1.ImVec2(400, 135), _0xAAB1.Cond.Always)
if _0xAAB1.BeginPopupModal(_0xF18F, nil, bit.bor(_0xAAB1.WindowFlags.NoCollapse, _0xAAB1.WindowFlags.NoResize)) then
local _0xDD5F = _0x7344[_0x5692 or _0x02CA]
_0xAAB1.TextColored(_0xAAB1.ImVec4(1.00, 0.85, 0.30, 1.00), _0xDD5F.name)
_0xAAB1.TextWrapped("Показывать время этой страны на экране?")
_0xAAB1.Spacing()
local _0xE1B5 = (_0xAAB1.GetContentRegionAvail().x - 5) / 2
if _0xAAB1.Button(_0x4BFE("CIRCLE_CHECK","") .." Да##clock_yes", _0xAAB1.ImVec2(_0xE1B5, 34)) then
_0xED9C.clock.enabled = true
_0xED9C.clock.country = _0xDD5F.name
_0x16A4()
_0xAAB1.CloseCurrentPopup()
end
_0xAAB1.SameLine()
if _0xAAB1.Button(_0xB72A.CIRCLE_XMARK .." Нет##clock_no", _0xAAB1.ImVec2(_0xE1B5, 34)) then
_0xAAB1.CloseCurrentPopup()
end
_0xAAB1.EndPopup()
end
end
_0xAAB1.EndChild()
end
local _0xB46F
_0xB46F = _0xAAB1.OnFrame(
function()
_0xB46F.HideCursor = not _0xADC2
return _0xED9C.clock.enabled
end,
_0x7DD2("clock", function()
if _0xADC2 and not _0xF7A7[0] then _0xADC2 = false end
local _0x8D1B = bit.bor(_0xAAB1.WindowFlags.NoTitleBar, _0xAAB1.WindowFlags.AlwaysAutoResize, _0xAAB1.WindowFlags.NoScrollbar, _0xAAB1.WindowFlags.NoSavedSettings)
if not _0xADC2 then
_0x8D1B = bit.bor(_0x8D1B, _0xAAB1.WindowFlags.NoMove, _0xAAB1.WindowFlags.NoInputs, _0xAAB1.WindowFlags.NoBackground)
_0xAAB1.SetNextWindowPos(_0xAAB1.ImVec2(_0x7C67.x, _0x7C67.y), _0xAAB1.Cond.Always)
end
_0xAAB1.SetNextWindowBgAlpha(0.45)
_0xAAB1.Begin("##clock_overlay", nil, _0x8D1B)
_0xAAB1.SetWindowFontScale(_0x3CC0.overlay_scale)
local _0x6D18 = _0x6AE9(_0xED9C.clock.country)
_0x50C2(_0xAAB1.ImVec4(0.55, 0.85, 1.00, 1.00), _0x6D18.name ..": ".. _0xF666(_0x6D18))
if _0xADC2 then
local _0x731B = _0xAAB1.GetWindowPos()
_0x7C67.x, _0x7C67.y = _0x731B.x, _0x731B.y
end
_0xAAB1.End()
end, function() _0xED9C.clock.enabled = false end)
)local _0x59FB ="3.2"local _0x8735 ="https://raw.githubusercontent.com/hydracrmpdesign-commits/arizona-prices/main/"local _0x5F5C = 1800local _0xF640 = getWorkingDirectory() .."\\config\\"local _0x8650 = _0xF640 .."arizona_prices_state.json"local _0x22E1 = { prices_sig ="", auto_prices = true }
local _0x52F7 = { available = false, version ="", _0xAD15 = false, status =""}
local _0xCE08 = {}
local _0xA34D = false
local _0x3A29 = false
local _0x12D8 = 0
local _0xE2F1, _0x5386 = pcall(require,'moonloader')
local _0xCD86 = _0xE2F1 and _0x5386.download_status or nil
local function _0x1F9F(_0x1D80)
local _0x16E5 = io.open(_0x1D80,"rb")
if not _0x16E5 then return nil end
local _0x6D18 = _0x16E5:read("*a")
_0x16E5:close()
return _0x6D18
end
local function _0x8D8B(_0x1D80, content)
local _0x16E5 = io.open(_0x1D80,"wb")
if not _0x16E5 then return false end
_0x16E5:write(content)
_0x16E5:close()
return true
end
local function _0x1B9D()
local _0x6D18 = _0x1F9F(_0x8650)
if _0x6D18 then
local _0x2457, _0x47FC = pcall(decodeJson, _0x6D18)
if _0x2457 and type(_0x47FC) =="table"then
if type(_0x47FC.prices_sig) =="string"then _0x22E1.prices_sig = _0x47FC.prices_sig end
if _0x47FC.auto_prices == false then _0x22E1.auto_prices = false end
end
end
end
local function _0x413F()
if not doesDirectoryExist(_0xF640) then createDirectory(_0xF640) end
_0x8F51(_0x8650, encodeJson(_0x22E1))
end
_0x076F("load_state", _0x1B9D)
local _0x2225 = _0xAAB1.new.bool(_0x22E1.auto_prices)
local function _0xCCF7(_0x27DC, current)
local _0x1C8E, _0x527F = {}, {}
for _0xB322 in tostring(_0x27DC):gmatch("%d+") do _0x1C8E[#_0x1C8E + 1] = tonumber(_0xB322) end
for _0xB322 in tostring(current):gmatch("%d+") do _0x527F[#_0x527F + 1] = tonumber(_0xB322) end
for _0x4E41 = 1, math.max(#_0x1C8E, #_0x527F) do
local _0x6BF7, _0x7077 = _0x1C8E[_0x4E41] or 0, _0x527F[_0x4E41] or 0
if _0x6BF7 ~= _0x7077 then return _0x6BF7 > _0x7077 end
end
return false
end
local function _0x12A5(_0xB734)
local _0x529B = 0
for _0x4E41 = 1, #_0xB734 do _0x529B = (_0x529B * 31 + _0xB734:byte(_0x4E41)) % 4294967291 end
return #_0xB734 ..":".. _0x529B
endlocal function _0x1CEC(_0x6E19, _0xB28C, flag)
os.remove(_0xB28C)
if not _0xCD86 or not downloadUrlToFile then
_0x52F7.status ="Загрузка недоступна"return false
end
local _0xEE69 = _0x8735 .. _0x6E19 .."?t=".. os.time()
local _0x2457 = pcall(downloadUrlToFile, _0xEE69, _0xB28C, function(_0xBA15, status, _0x870A, p2)
if status == _0xCD86.STATUSEX_ENDDOWNLOAD then
_0xCE08[flag] = true
end
end)
return _0x2457
end
local function _0x8A6A()
if not doesDirectoryExist(_0xF640) then createDirectory(_0xF640) end
_0x1CEC("version.txt", _0xF640 .."arizona_prices_remote_version.txt","version")
if _0x22E1.auto_prices then
_0x1CEC("item_prices.json", _0xF640 .."arizona_prices_remote.json","prices")
end
end
local function _0xB19B()
local _0x1D80 = _0xF640 .."arizona_prices_remote_version.txt"local _0x6D18 = _0x1F9F(_0x1D80)
os.remove(_0x1D80)
local _0x1545 = _0x6D18 and _0x6D18:match("%d[%d%.]*")
if _0x1545 and _0xCCF7(_0x1545, _0x59FB) then
if not _0x52F7.available then
_0x3EA3("Вышла новая версия ".. _0x1545 .."! Откройте /prices и нажмите «Обновить»","info", 8)
end
_0x52F7.available = true
_0x52F7.version = _0x1545
_0x52F7.status =""elseif _0x3A29 then
_0x52F7.status = _0x1545 and"У вас последняя версия"or"Не удалось проверить"end
_0x3A29 = false
end
local function _0x94C8()
local _0xB28C = _0xF640 .."arizona_prices_update.lua"local _0x6D18 = _0x1F9F(_0xB28C)
_0x52F7.busy = false
if not _0x6D18 or #_0x6D18 < 2000 then
_0x52F7.status ="Ошибка загрузки"return
end
if not loadstring(_0x6D18) or not _0x6D18:find("SCRIPT_VERSION", 1, true) then
_0x52F7.status ="Файл повреждён"return
end
local _0x3D8A = thisScript().path
local _0x4E65 = _0x1F9F(_0x3D8A)
if _0x4E65 then _0x8D8B(_0xF640 .."Table_Prices.lua.bak", _0x4E65) end
if _0x8D8B(_0x3D8A, _0x6D18) then
os.remove(_0xB28C)
_0x52F7.status ="Готово, перезапуск..."_0xA34D = true
else
_0x52F7.status ="Не удалось записать файл"end
end
local function _0xD764()
local _0x1D80 = _0xF640 .."arizona_prices_remote.json"local _0x6D18 = _0x1F9F(_0x1D80)
os.remove(_0x1D80)
if not _0x6D18 or #_0x6D18 < 2 then return end
local _0x741D = _0x12A5(_0x6D18)
local _0x2457, _0x27DC = pcall(decodeJson, _0x6D18)
if not _0x2457 or type(_0x27DC) ~="table"then return endif not _0xAADF.on then
local _0x5C31 = {}
for _0x374C, _0x70A2 in ipairs(_0x27DC) do
local _0x2FFC = type(_0x70A2) =="table"and tonumber(_0x70A2.buy) or nil
local _0xE824 = type(_0x70A2) =="table"and tonumber(_0x70A2.sell) or nil
if _0x2FFC and _0xE824 and type(_0x70A2.item) =="string"then
_0x5C31[#_0x5C31 + 1] = { _0x3EBB = _0x70A2.item, _0x2FFC = _0x2FFC, _0xE824 = _0xE824, _0x000B = _0xAADF.valid_liq(_0x70A2.liq) }
end
end
if #_0x5C31 == 0 then return end
local _0xE14F = false
local _0x743F, _0xC024, _0xD639 = pcall(function() return encodeJson(_0x5C31), encodeJson(_0x1217) end)
if _0x743F and _0xC024 == _0xD639 then _0xE14F = true end
if not _0xE14F then
_0x1217 = _0x5C31
_0x64DF()
if _0x741D ~= _0x22E1.prices_sig then _0x3EA3("Цены обновлены из канала","ok", 5) end
end
_0x22E1.prices_sig = _0x741D
_0x413F()
return
endif _0x741D == _0x22E1.prices_sig then return end
local _0xE0A2 = {}
for _0x4E41, it in ipairs(_0x1217) do
if it.item then _0xE0A2[it.item] = _0x4E41 end
end
local _0x8767, _0x7EE3 = 0, 0
for _0x374C, _0x70A2 in ipairs(_0x27DC) do
local _0x2FFC = type(_0x70A2) =="table"and tonumber(_0x70A2.buy) or nil
local _0xE824 = type(_0x70A2) =="table"and tonumber(_0x70A2.sell) or nil
if _0x2FFC and _0xE824 and type(_0x70A2.item) =="string"then
local _0x4E41 = _0xE0A2[_0x70A2.item]
if _0x4E41 then
local _0x2FEE = _0x1217[_0x4E41]
if tonumber(_0x2FEE.buy) ~= _0x2FFC or tonumber(_0x2FEE.sell) ~= _0xE824 then
_0x2FEE.buy, _0x2FEE.sell = _0x2FFC, _0xE824
_0x7EE3 = _0x7EE3 + 1
end
else
_0x1217[#_0x1217 + 1] = { _0x3EBB = _0x70A2.item, _0x2FFC = _0x2FFC, _0xE824 = _0xE824, _0x000B = _0xAADF.valid_liq(_0x70A2.liq) }
_0xE0A2[_0x70A2.item] = #_0x1217
_0x8767 = _0x8767 + 1
end
end
end
_0x22E1.prices_sig = _0x741D
_0x413F()
if _0x8767 + _0x7EE3 > 0 then
_0x64DF()
_0x3EA3("Цены обновлены: новых ".. _0x8767 ..", изменено ".. _0x7EE3,"ok", 5)
end
end
local function _0xF41A()
if _0xCE08.version then _0xCE08.version = nil; pcall(_0xB19B) end
if _0xCE08.script then _0xCE08.script = nil; pcall(_0x94C8) end
if _0xCE08.prices then _0xCE08.prices = nil; pcall(_0xD764) end
if _0x52F7.busy and os.time() - _0x12D8 > 40 then
_0x52F7.busy = false
_0x52F7.status ="Не удалось скачать"end
end
local _0x6AA2 = _0xAAB1.new.bool(false)
local function _0x9200()
_0x52F7.busy = true
_0x52F7.status =""_0x12D8 = os.time()
if not _0x1CEC("Table_Prices.lua", _0xF640 .."arizona_prices_update.lua","script") then
_0x52F7.busy = false
if _0x52F7.status ==""then _0x52F7.status ="Ошибка загрузки"end
end
end
local function _0x2DFB()
_0x52F7.busy = true
_0x52F7.status =""_0x12D8 = os.time()
_0x0EA0(_0x9200)
end
local function _0x2351()
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(5, _0x4C9D.block_y))
_0xAAB1.TextDisabled("Версия ".. _0x59FB)
_0xAAB1.SetCursorPosX(5)
if _0x52F7.available then
_0xAAB1.TextColored(_0xAAB1.ImVec4(0.45, 1.00, 0.55, 1.00),"Вышла версия ".. _0x52F7.version)
_0xAAB1.SetCursorPosX(5)
if _0x52F7.busy then
_0xAAB1.TextDisabled("Скачивание...")
elseif _0xAAB1.Button(_0x4BFE("DOWNLOAD","") .." Обновить##do_update", _0xAAB1.ImVec2(_0x2546 - 10, 32)) then
_0x2DFB()
end
else
if _0xAAB1.Button(_0x4BFE("ARROWS_ROTATE","") .." Проверить##check_update", _0xAAB1.ImVec2(_0x2546 - 10, 28)) then
_0x3A29 = true
_0x52F7.status ="Проверка..."_0x0EA0(_0x8A6A)
end
end
if _0x52F7.status ~=""then
_0xAAB1.SetCursorPosX(5)
_0xAAB1.TextDisabled(_0x52F7.status)
end
_0xAAB1.SetCursorPosX(5)
if _0xAAB1.Checkbox(" Автообновление цен##auto_prices", _0x2225) then
_0x22E1.auto_prices = _0x2225[0]
_0x413F()
if _0x22E1.auto_prices then _0x0EA0(_0x8A6A) end
end
endlocal _0x547A = { binding = false, typing = false }
local _0x7E26, _0x948C = pcall(require,'vkeys')
local function _0xB94F(_0x14C4)
if not _0x14C4 or _0x14C4 == 0 then return"Не задана"end
if _0x7E26 and _0x948C.id_to_name then
local _0xB322 = _0x948C.id_to_name(_0x14C4)
if _0xB322 then return _0xB322 end
end
return"VK ".. tostring(_0x14C4)
end
local _0x5A68 = {
accent = _0xAAB1.new.float[3](_0x3CC0.accent[1], _0x3CC0.accent[2], _0x3CC0.accent[3]),
opacity = _0xAAB1.new.float(_0x3CC0.opacity),
_0x044D = _0xAAB1.new.float(_0x3CC0.overlay_scale),
_0xC83F = _0xAAB1.new.bool(_0x3CC0.toasts),
border_speed = _0xAAB1.new.float(_0x3CC0.border_speed),
shadow = _0xAAB1.new.bool(_0x3CC0.shadow),
bg_fx = _0xAAB1.new.bool(_0x3CC0.bg_fx),
splash = _0xAAB1.new.bool(_0x3CC0.splash),
halloween = _0xAAB1.new.bool(_0x3CC0.halloween),
font_pending = false,
}
local _0x475E = nil
local function _0xEC9A()
_0x475E = os.clock()
end
local function _0x26A7(force)
if _0x475E and (force or os.clock() - _0x475E > 0.8) then
_0x475E = nil
_0x16A4()
end
endlocal _0x3A41 = {
ACCESS_CODE ="PRICES2026",
_0x1D80 = getWorkingDirectory() .."\\config\\arizona_prices_auth.json",
_0xCC32 = _0xAAB1.new.bool(false),
_0x2BF3 = _0xAAB1.new.char[48](),
_0x14C4 = _0xAAB1.new.char[48](),
error ="",
_0x2457 = false,
}do
local _0x47FC = _0xF239(_0x3A41.path)
if type(_0x47FC) =="table"and tostring(_0x47FC.code or""):lower() == _0x3A41.ACCESS_CODE:lower() then
_0x3A41.ok = true
end
end
function _0x3A41.try_login()
local _0x2BF3 = _0x90EB.string(_0x3A41.nick):gsub("^%s+",""):gsub("%s+$","")
local _0x14C4 = _0x90EB.string(_0x3A41.code):gsub("%s","")
if _0x2BF3 ==""then _0x3A41.error ="Введите ваш никнейм"; return end
if _0x14C4 ==""then _0x3A41.error ="Введите код из телеграм-канала"; return end
if _0x3A41.loading then return end
_0x3A41.error =""_0x3A41.loading = { _0xC5C0 = _0xAAB1.GetTime(), _0x2BF3 = _0x2BF3, _0x14C4 = _0x14C4 }
endfunction _0x3A41.finish()
local _0x2BF3, _0x14C4 = _0x3A41.loading.nick, _0x3A41.loading.code
_0x3A41.loading = nil
if _0x14C4:lower() ~= _0x3A41.ACCESS_CODE:lower() then
_0x3A41.error ="Неверный код. Получите актуальный код в телеграм-канале"return
end
_0x3A41.ok = true
_0x3A41.error =""_0x3A41.open[0] = false
local _0x6A3E = getWorkingDirectory() .."\\config"if not doesDirectoryExist(_0x6A3E) then createDirectory(_0x6A3E) end
_0x490E(_0x3A41.path, encodeJson({ _0x2BF3 = _0x2BF3, _0x14C4 = _0x14C4 }))
_0x3EA3("Доступ открыт. Добро пожаловать, ".. _0x2BF3 .."!","ok", 5)
_0xF7A7[0] = true
end
_0xAAB1.OnFrame(function() return _0x3A41.open[0] end, _0x7DD2("auth", function()
local _0x17E0, _0xFBEC = getScreenResolution()
local _0x7B62, _0x0AD1 = 560, 380
_0xAAB1.SetNextWindowPos(_0xAAB1.ImVec2(_0x17E0 / 2, _0xFBEC / 2), _0xAAB1.Cond.Always, _0xAAB1.ImVec2(0.5, 0.5))
_0xAAB1.SetNextWindowSize(_0xAAB1.ImVec2(_0x7B62, _0x0AD1), _0xAAB1.Cond.Always)
_0xAAB1.PushStyleColor(_0xAAB1.Col.WindowBg, _0xAAB1.ImVec4(0.075, 0.07, 0.095, 1.0))
_0xAAB1.Begin("##auth_window", nil, bit.bor(_0xAAB1.WindowFlags.NoTitleBar, _0xAAB1.WindowFlags.NoResize,
_0xAAB1.WindowFlags.NoCollapse, _0xAAB1.WindowFlags.NoScrollbar, _0xAAB1.WindowFlags.NoSavedSettings))
local _0x721A = _0xAAB1.GetWindowPos()
local _0x86C5 = _0x3CC0.accent
_0xAAB1.GetWindowDrawList():AddRectFilled(_0x721A, _0xAAB1.ImVec2(_0x721A.x + _0x7B62, _0x721A.y + 5), _0x82F6(_0x86C5[1], _0x86C5[2], _0x86C5[3], 1))
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(26, 24))
_0xAAB1.SetWindowFontScale(1.7)
_0xAAB1.TextColored(_0xB079(1.2), _0x4BFE("LOCK","") .." Авторизация")
_0xAAB1.SetWindowFontScale(1.15)
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(26, 76))
_0xAAB1.PushTextWrapPos(_0x7B62 - 26)
_0xAAB1.TextWrapped("Вы попали в окно авторизации. Введите свой никнейм и код. Код можно получить в телеграм-канале.")
_0xAAB1.PopTextWrapPos()
if _0x3A41.loading thenlocal _0x4E32 = _0xAAB1.GetTime()
local _0x6B6F = _0x43DE((_0x4E32 - _0x3A41.loading.t) / 3.0, 0, 1)
local _0xFCBC = _0xAAB1.GetWindowDrawList()
local _0x4335, _0x952C = _0x721A.x + _0x7B62 / 2, _0x721A.y + 165
for _0x4E41 = 0, 11 do
local _0x147B = _0x4E41 / 12 * math.pi * 2 - _0x4E32 * 6
local _0x11E9 = ((_0x4E41 / 12) - (_0x4E32 * 1.5) % 1) % 1
_0xFCBC:AddCircleFilled(_0xAAB1.ImVec2(_0x4335 + math.cos(_0x147B) * 34, _0x952C + math.sin(_0x147B) * 34), 5.5,
_0x82F6(_0x86C5[1], _0x86C5[2], _0x86C5[3], 0.15 + 0.85 * (1 - _0x11E9)), 12)
end
local _0x6273 = {"Подключение к серверу...","Проверка кода...","Верификация никнейма...","Доступ разрешён"}
local _0x6568 = _0x6273[math.min(#_0x6273, 1 + math.floor(_0x6B6F * #_0x6273))]
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(0, 232))
_0xAAB1.SetWindowFontScale(1.6)
local _0xA3AC = string.rep(".", math.floor(_0x4E32 * 3) % 4)
local _0x6FF2 ="Загрузка".. _0xA3AC
_0xAAB1.SetCursorPosX((_0x7B62 - _0xAAB1.CalcTextSize("Загрузка...").x) / 2)
_0xAAB1.Text(_0x6FF2)
_0xAAB1.SetWindowFontScale(1.1)
_0xAAB1.SetCursorPosX((_0x7B62 - _0xAAB1.CalcTextSize(_0x6568).x) / 2)
_0xAAB1.TextColored(_0xAAB1.ImVec4(0.65, 0.65, 0.72, 1), _0x6568)
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(60, _0x0AD1 - 46))
_0xAAB1.PushStyleColor(_0xAAB1.Col.PlotHistogram, _0xB079(1.1))
_0xAAB1.ProgressBar(_0x6B6F, _0xAAB1.ImVec2(_0x7B62 - 120, 10),"")
_0xAAB1.PopStyleColor(1)
_0xAAB1.SetWindowFontScale(1.0)
_0xAAB1.End()
_0xAAB1.PopStyleColor(1)
if _0x6B6F >= 1 then _0x3A41.finish() end
return
end
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(26, 150))
_0xAAB1.SetNextItemWidth(_0x7B62 - 52)
_0xAAB1.InputTextWithHint("##auth_nick","Ваш никнейм", _0x3A41.nick, _0x90EB.sizeof(_0x3A41.nick))
_0xAAB1.SetCursorPosX(26)
_0xAAB1.SetNextItemWidth(_0x7B62 - 52)
local _0xDA6A = _0xAAB1.InputTextWithHint("##auth_code","Код из телеграм-канала", _0x3A41.code, _0x90EB.sizeof(_0x3A41.code), _0xAAB1.InputTextFlags.EnterReturnsTrue)
if _0xDA6A then _0x3A41.try_login() end
_0xAAB1.SetCursorPosX(26)
if _0x3A41.error ~=""then
_0xAAB1.TextColored(_0xAAB1.ImVec4(1.0, 0.4, 0.4, 1.0), _0x3A41.error)
else
_0xAAB1.Text(" ")
end
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(26, _0x0AD1 - 26 - 46))
local _0xAC10 = (_0x7B62 - 52 - 20) / 3
_0xAAB1.PushStyleColor(_0xAAB1.Col.Button, _0xB079(1.0))
_0xAAB1.PushStyleColor(_0xAAB1.Col.ButtonHovered, _0xB079(1.15))
_0xAAB1.PushStyleColor(_0xAAB1.Col.ButtonActive, _0xB079(0.85))
if _0xAAB1.Button(_0x4BFE("RIGHT_TO_BRACKET","") .." Войти##auth_go", _0xAAB1.ImVec2(_0xAC10, 46)) then _0x3A41.try_login() end
_0xAAB1.PopStyleColor(3)
_0xAAB1.SameLine()
if _0xAAB1.Button(_0x4BFE("PAPER_PLANE","") .." Получить код##auth_tg", _0xAAB1.ImVec2(_0xAC10 + 40, 46)) then
_0x1810("https://t.me/arizona_prices")
end
_0xAAB1.SameLine()
if _0xAAB1.Button(_0xB72A.CIRCLE_XMARK .." Закрыть##auth_close", _0xAAB1.ImVec2(_0xAC10 - 40, 46)) then _0x3A41.open[0] = false end
_0xAAB1.SetWindowFontScale(1.0)
_0xAAB1.End()
_0xAAB1.PopStyleColor(1)
end, function() _0x3A41.open[0] = false; _0x3A41.loading = nil end))
local function _0x7EF9()
if not _0x3A41.ok then_0xF7A7[0] = false
_0x3A41.loading = nil
_0x3A41.open[0] = not _0x3A41.open[0]
if _0x3A41.open[0] and _0x90EB.string(_0x3A41.nick) ==""then
local _0x9C4F, _0xBA15 = pcall(function() local _0x374C, _0x4E41 = sampGetPlayerIdByCharHandle(PLAYER_PED); return sampGetPlayerNickname(_0x4E41) end)
if _0x9C4F and _0xBA15 then _0xAAB1.StrCopy(_0x3A41.nick, _0xBA15) end
end
return
end
_0xF7A7[0] = not _0xF7A7[0]
if _0xF7A7[0] and _0x52F7.available then
_0x6AA2[0] = true
end
end
local function _0xA589(msg, wparam, lparam)
if msg ~= 0x100 and msg ~= 0x104 then return end
local _0x7C1A = bit.band(lparam, 0x40000000) ~= 0
if _0x547A.binding then
consumeWindowMessage(true, true)
if _0x7C1A then return end
_0x547A.binding = false
if wparam == 0x08 then
_0x3CC0.open_key = 0
_0xEC9A()
_0x3EA3("Горячая клавиша убрана","info")
elseif wparam ~= 0x1B then
_0x3CC0.open_key = wparam
_0xEC9A()
_0x3EA3("Клавиша открытия меню: ".. _0xB94F(wparam),"ok")
end
return
end
if _0x7C1A then return endif _0xF7A7[0] and _0xD3A9.alpha > 0.5 and not _0x547A.typing then
local _0x743F, _0xAD15 = pcall(function() return sampIsChatInputActive() or sampIsDialogActive() end)
if not (_0x743F and _0xAD15) then
if wparam >= 0x31 and wparam <= 0x38 then
_0xD3A9.pending_tab = _0xD3A9.TAB_ORDER[wparam - 0x30]
consumeWindowMessage(true, true)
return
elseif wparam == 0x46 then
local _0x1ECB, _0x2FD7 = pcall(isKeyDown, 0x11)
if _0x1ECB and _0x2FD7 then
_0xD3A9.pending_tab = 1
_0xD3A9.focus_search = true
consumeWindowMessage(true, true)
return
end
end
end
end
local _0xE53D = _0x3CC0.open_key
if _0xE53D and _0xE53D ~= 0 and wparam == _0xE53D then
local _0x743F, _0xAD15 = pcall(function() return sampIsChatInputActive() or sampIsDialogActive() end)
if _0x743F and _0xAD15 then return end
if _0xF7A7[0] and _0x547A.typing then return end
_0x7EF9()
end
end
local function _0x43B3()
local _0xC543 = {}
local function _0x7D6C(_0xC5C0) _0xC543[#_0xC543 + 1] = _0xC5C0 end
_0x7D6C("Arizona Prices - отчёт об ошибке")
_0x7D6C("Версия скрипта: ".. _0x59FB)
_0x7D6C("Журнал ошибок: moonloader\\config\\arizona_prices_errors.log")
_0x7D6C("Дата: ".. os.date("%Y-%m-%d %H:%M:%S"))
local _0x326F, _0xC6BC = pcall(function() return getMoonloaderVersion() end)
_0x7D6C("MoonLoader: ".. (_0x326F and tostring(_0xC6BC) or"?"))
_0x7D6C("Lua: ".. tostring(_VERSION) .. (jit and (" / ".. tostring(jit.version)) or""))
local _0x1EC6, _0x9846, _0xA135 = pcall(getScreenResolution)
_0x7D6C("Экран: ".. (_0x1EC6 and (tostring(_0x9846) .."x".. tostring(_0xA135)) or"?"))
_0x7D6C("Предметов в списке: ".. #_0x1217)
_0x7D6C("Автообновление цен: ".. tostring(_0x22E1.auto_prices))
_0x7D6C("Загрузка файлов: ".. ((downloadUrlToFile and _0xCD86) and"доступна"or"недоступна"))
_0x7D6C("Уведомления: ".. tostring(_0x3CC0.toasts) ..", горячая клавиша: ".. _0xB94F(_0x3CC0.open_key))
if #_0x8869 > 0 then
_0x7D6C("Последние ошибки:")
for _0x374C, _0x40E5 in ipairs(_0x8869) do _0x7D6C("  ".. _0x40E5) end
else
_0x7D6C("Ошибок в журнале нет")
end
_0x7D6C("")
_0x7D6C("Что вы делали перед ошибкой:")
return table.concat(_0xC543,"\n")
end
local function _0x8081()
local _0x2457, _0xC139 = pcall(_0x43B3)
local _0x27A4 = _0x2457 and _0xC139 or ("Arizona Prices ".. _0x59FB)
_0xAAB1.SetClipboardText("Привет. Заметил о баге:\n\n\n".. _0x27A4)
_0x1810("https://t.me/xi_vivide")
_0x3EA3("Сообщение скопировано - допишите, что случилось, и отправьте (Ctrl+V)","ok", 6)
end
local _0xB5C5 = {
{ _0x6E19 ="Океан", _0x6D18 = {0.18, 0.45, 0.85} }, { _0x6E19 ="Изумруд", _0x6D18 = {0.20, 0.70, 0.45} },
{ _0x6E19 ="Аметист", _0x6D18 = {0.60, 0.35, 0.90} }, { _0x6E19 ="Рубин", _0x6D18 = {0.90, 0.30, 0.35} },
{ _0x6E19 ="Янтарь", _0x6D18 = {0.95, 0.60, 0.15} }, { _0x6E19 ="Бирюза", _0x6D18 = {0.15, 0.72, 0.78} },
{ _0x6E19 ="Сакура", _0x6D18 = {0.90, 0.40, 0.70} }, { _0x6E19 ="Неон", _0x6D18 = {0.55, 1.00, 0.20} },
}
local _0x57F9 = {"Выключена","Переливы цвета","Радуга","Статичная"}
local _0x1FC9 = {
{ _0x6E19 ="Справа снизу", _0x1545 = 3 }, { _0x6E19 ="Справа сверху", _0x1545 = 1 },
{ _0x6E19 ="Слева снизу", _0x1545 = 2 }, { _0x6E19 ="Слева сверху", _0x1545 = 0 },
}
local function _0xBF21(icon_name, _0xC139)
_0xAAB1.Spacing()
_0xAAB1.TextColored(_0xB079(1.2), _0x4BFE(icon_name,"") .." ".. _0xC139)
_0xAAB1.Separator()
_0xAAB1.Spacing()
end
local function _0x4B2A()
_0x4D2B(_0x4BFE("GEAR",""),"Настройки")
if _0xAAB1.BeginChild("##settings_child", _0xAAB1.ImVec2(-1, _0x4C9D.h - 79), true) then
_0xBF21("PALETTE","Темы оформления")
for _0x4E41, th in ipairs(_0xB5C5) do
local _0x6D18 = th.c
_0xAAB1.PushStyleColor(_0xAAB1.Col.Button, _0xAAB1.ImVec4(_0x6D18[1] * 0.55, _0x6D18[2] * 0.55, _0x6D18[3] * 0.55, 1.0))
_0xAAB1.PushStyleColor(_0xAAB1.Col.ButtonHovered, _0xAAB1.ImVec4(_0x6D18[1] * 0.80, _0x6D18[2] * 0.80, _0x6D18[3] * 0.80, 1.0))
_0xAAB1.PushStyleColor(_0xAAB1.Col.ButtonActive, _0xAAB1.ImVec4(_0x6D18[1], _0x6D18[2], _0x6D18[3], 1.0))
if _0xAAB1.Button(th.name .."##theme".. _0x4E41, _0xAAB1.ImVec2(110, 30)) then
_0x3CC0.accent = { _0x6D18[1], _0x6D18[2], _0x6D18[3] }
_0x5A68.accent[0], _0x5A68.accent[1], _0x5A68.accent[2] = _0x6D18[1], _0x6D18[2], _0x6D18[3]
apply_theme()
_0xEC9A()
end
_0xAAB1.PopStyleColor(3)
if _0x4E41 % 4 ~= 0 and _0x4E41 < #_0xB5C5 then _0xAAB1.SameLine() end
end
_0xAAB1.Spacing()
if _0xAAB1.ColorEdit3("Свой цвет##accent_custom", _0x5A68.accent, _0xAAB1.ColorEditFlags.NoInputs) then
_0x3CC0.accent = { _0x5A68.accent[0], _0x5A68.accent[1], _0x5A68.accent[2] }
apply_theme()
_0xEC9A()
end
_0xAAB1.SetNextItemWidth(260)
if _0xAAB1.SliderFloat("Прозрачность окна##opacity", _0x5A68.opacity, 0.3, 1.0,"%.2f") then
_0x3CC0.opacity = _0x5A68.opacity[0]
apply_theme()
_0xEC9A()
end
_0xBF21("WAND_MAGIC_SPARKLES","Рамка и эффекты")
_0xAAB1.SetNextItemWidth(220)
if _0xAAB1.BeginCombo("Рамка окна##border_mode", _0x57F9[_0x3CC0.border_mode + 1] or _0x57F9[2]) then
for _0x4E41, _0x6E19 in ipairs(_0x57F9) do
if _0xAAB1.Selectable(_0x6E19 .."##bm".. _0x4E41, _0x3CC0.border_mode == _0x4E41 - 1) then
_0x3CC0.border_mode = _0x4E41 - 1
_0xEC9A()
end
end
_0xAAB1.EndCombo()
end
if _0x3CC0.border_mode == 1 or _0x3CC0.border_mode == 2 then
_0xAAB1.SetNextItemWidth(260)
if _0xAAB1.SliderFloat("Скорость переливов##border_speed", _0x5A68.border_speed, 0.2, 3.0,"%.1f") then
_0x3CC0.border_speed = _0x5A68.border_speed[0]
_0xEC9A()
end
end
if _0xAAB1.Checkbox("Тень под окном##shadow", _0x5A68.shadow) then
_0x3CC0.shadow = _0x5A68.shadow[0]
_0xEC9A()
end
if _0xAAB1.Checkbox("Анимированный фон##bgfx", _0x5A68.bg_fx) then
_0x3CC0.bg_fx = _0x5A68.bg_fx[0]
_0xEC9A()
end
if _0xAAB1.Checkbox("Заставка при первом открытии меню##splash", _0x5A68.splash) then
_0x3CC0.splash = _0x5A68.splash[0]
_0xEC9A()
end
if _0xAAB1.Checkbox("Хэллоуин: тыквы, летучие мыши, паутина##halloween", _0x5A68.halloween) then
_0x3CC0.halloween = _0x5A68.halloween[0]
local _0x6D18 = _0x3CC0.halloween and { 0.98, 0.55, 0.12 } or { 0.18, 0.45, 0.85 }
_0x3CC0.accent = _0x6D18
_0x5A68.accent[0], _0x5A68.accent[1], _0x5A68.accent[2] = _0x6D18[1], _0x6D18[2], _0x6D18[3]
apply_theme()
_0xEC9A()
end
_0xBF21("FONT","Шрифт")
local _0x9040 = _0xA90D[1].name
for _0x374C, _0x16E5 in ipairs(_0xA90D) do
if _0x16E5.key == _0x3CC0.font then _0x9040 = _0x16E5.name end
end
_0xAAB1.SetNextItemWidth(260)
if _0xAAB1.BeginCombo("Шрифт интерфейса##font", _0x9040) then
for _0x374C, _0x16E5 in ipairs(_0xA90D) do
if _0xAAB1.Selectable(_0x16E5.name .."##font_".. _0x16E5.key, _0x3CC0.font == _0x16E5.key) then
_0x3CC0.font = _0x16E5.key
_0x5A68.font_pending = true
_0xEC9A()
end
end
_0xAAB1.EndCombo()
end
if _0x5A68.font_pending then
if _0xAAB1.Button(_0x4BFE("ARROWS_ROTATE","") .." Применить шрифт (перезапуск скрипта)##apply_font", _0xAAB1.ImVec2(360, 28)) then
_0x0EA0(function()
_0x26A7(true)
thisScript():reload()
end)
end
else
_0xAAB1.TextDisabled("Шрифт меняется после перезапуска скрипта. Берётся из папки Fonts в Windows.")
end
_0xBF21("EXPAND","Надписи на экране")
_0xAAB1.SetNextItemWidth(260)
if _0xAAB1.SliderFloat("Размер надписей на экране##overlay_scale", _0x5A68.scale, 0.7, 2.0,"%.1f") then
_0x3CC0.overlay_scale = _0x5A68.scale[0]
_0xEC9A()
end
_0xAAB1.TextDisabled("Касается надписей PayDay и часов, которые показываются поверх игры.")
_0xAAB1.Spacing()
if _0xAAB1.Button(_0x4BFE("ROTATE_LEFT","") .." Сбросить внешний вид##reset_look", _0xAAB1.ImVec2(230, 28)) then
_0x3CC0.accent = _0x3CC0.halloween and { 0.98, 0.55, 0.12 } or { 0.18, 0.45, 0.85 }
_0x3CC0.opacity = 1.0
_0x3CC0.overlay_scale = 1.0
_0x3CC0.border_mode = 1
_0x3CC0.border_speed = 1.0
_0x3CC0.shadow = true
if _0x3CC0.font ~="seguisb"then
_0x3CC0.font ="seguisb"_0x5A68.font_pending = true
end
_0x5A68.accent[0], _0x5A68.accent[1], _0x5A68.accent[2] = _0x3CC0.accent[1], _0x3CC0.accent[2], _0x3CC0.accent[3]
_0x5A68.opacity[0] = 1.0
_0x5A68.scale[0] = 1.0
_0x5A68.border_speed[0] = 1.0
_0x5A68.shadow[0] = true
apply_theme()
_0xEC9A()
end
_0xAAB1.SameLine()
if _0xAAB1.Button(_0x4BFE("EXPAND","") .." Сбросить размер окна##reset_size", _0xAAB1.ImVec2(230, 28)) then
_0x4C9D.force = true
end
_0xBF21("KEYBOARD","Управление")
_0xAAB1.AlignTextToFramePadding()
_0xAAB1.Text("Клавиша открытия меню:")
_0xAAB1.SameLine()
local _0xF8B1 = _0x547A.binding and"Нажмите клавишу..."or _0xB94F(_0x3CC0.open_key)
if _0xAAB1.Button(_0xF8B1 .."##bind_open_key", _0xAAB1.ImVec2(190, 26)) then
_0x547A.binding = not _0x547A.binding
end
_0xAAB1.TextDisabled("Esc - отмена, Backspace - убрать клавишу. Команда /prices работает всегда.")
_0xBF21("BELL","Уведомления")
if _0xAAB1.Checkbox("Всплывающие карточки вместо сообщений в чате", _0x5A68.toasts) then
_0x3CC0.toasts = _0x5A68.toasts[0]
_0xEC9A()
end
local _0x0730 = _0x1FC9[1].name
for _0x374C, _0x6D18 in ipairs(_0x1FC9) do
if _0x6D18.v == _0x3CC0.toast_corner then _0x0730 = _0x6D18.name end
end
_0xAAB1.SetNextItemWidth(220)
if _0xAAB1.BeginCombo("Угол экрана##toast_corner", _0x0730) then
for _0x374C, _0x6D18 in ipairs(_0x1FC9) do
if _0xAAB1.Selectable(_0x6D18.name, _0x6D18.v == _0x3CC0.toast_corner) then
_0x3CC0.toast_corner = _0x6D18.v
_0xEC9A()
end
end
_0xAAB1.EndCombo()
end
if _0xAAB1.Button(_0x4BFE("BELL","") .." Показать пример##toast_test", _0xAAB1.ImVec2(230, 28)) then
_0x3EA3("Так выглядят уведомления","ok")
end
_0xBF21("BUG","Поддержка")
if _0xAAB1.Button(_0x4BFE("BUG","") .." Сообщить об ошибке##report_error", _0xAAB1.ImVec2(230, 30)) then
_0x8081()
end
_0xAAB1.TextDisabled("Скопирует версию скрипта и данные для диагностики и откроет Telegram разработчика.")
if #_0x8869 > 0 then
_0xAAB1.TextColored(_0xAAB1.ImVec4(1.0, 0.55, 0.40, 1.0),"Записей в журнале ошибок: ".. #_0x8869)
end
end
_0xAAB1.EndChild()
end
local function _0xDDEF()
_0x4D2B(_0x4BFE("NOTE_STICKY",""),"Заметки")
if _0xAAB1.BeginChild("##notes_child", _0xAAB1.ImVec2(-1, _0x4C9D.h - 79), true) then
_0xAAB1.TextDisabled("Записывай сюда всё важное: цены, договорённости, ники. Сохраняется само.")
_0xAAB1.Spacing()
_0xAAB1.SetWindowFontScale(1.15)
local _0x86ED = _0xAAB1.GetContentRegionAvail().y - 48
if _0xAAB1.InputTextMultiline("##notes_text", _0xD3A9.notes, _0x90EB.sizeof(_0xD3A9.notes), _0xAAB1.ImVec2(-1, math.max(80, _0x86ED))) then
_0xED9C.notes = _0x90EB.string(_0xD3A9.notes)
_0xEC9A()
end
_0xAAB1.SetWindowFontScale(1.0)
local _0x7949 = math.floor(#_0xED9C.notes / 81.91)
_0xAAB1.AlignTextToFramePadding()
_0xAAB1.TextDisabled("Заполнено: ".. _0x7949 .."%")
_0xAAB1.SameLine()
if _0xAAB1.Button(_0x4BFE("TRASH_CAN","") .." Очистить##notes_clear", _0xAAB1.ImVec2(130, 28)) then
_0xAAB1.StrCopy(_0xD3A9.notes,"")
_0xED9C.notes =""_0xEC9A()
end
end
_0xAAB1.EndChild()
end
local function _0xA7A2(_0xBA15)
if _0xBA15 == 3 then
_0x4747()
elseif _0xBA15 == 4 then
_0x3DC3()
elseif _0xBA15 == 5 then
_0x7265()
elseif _0xBA15 == 6 then
_0x1F6B()
elseif _0xBA15 == 7 then
_0x4B2A()
elseif _0xBA15 == 8 then
_0xDDEF()
end
end
local _0xA945
_0xA945 = _0xAAB1.OnFrame(
function()
_0xA945.HideCursor = not _0xD790
return _0xF906[0]
end,
_0x7DD2("payday", function()
if _0xD790 and not _0xF7A7[0] then _0xD790 = false end
local _0x8D1B = bit.bor(_0xAAB1.WindowFlags.NoTitleBar, _0xAAB1.WindowFlags.AlwaysAutoResize, _0xAAB1.WindowFlags.NoScrollbar, _0xAAB1.WindowFlags.NoSavedSettings)
if not _0xD790 then
_0x8D1B = bit.bor(_0x8D1B, _0xAAB1.WindowFlags.NoMove, _0xAAB1.WindowFlags.NoInputs, _0xAAB1.WindowFlags.NoBackground)
_0xAAB1.SetNextWindowPos(_0xAAB1.ImVec2(_0x87E3.x, _0x87E3.y), _0xAAB1.Cond.Always)
end
_0xAAB1.SetNextWindowBgAlpha(0.45)
_0xAAB1.Begin("##payday_overlay", nil, _0x8D1B)
_0xAAB1.SetWindowFontScale(_0x3CC0.overlay_scale)
_0x50C2(_0xAAB1.ImVec4(1.00, 0.85, 0.30, 1.00), _0x9A77())
if _0xD790 then
local _0x731B = _0xAAB1.GetWindowPos()
_0x87E3.x, _0x87E3.y = _0x731B.x, _0x731B.y
end
_0xAAB1.End()
end, function() _0xF906[0] = false end)
)
_0xAAB1.OnInitialize(function()_0x076F("fa_init", function() _0x19D1.Init() end)_0x076F("custom_font", function()
local _0x1D80
for _0x374C, _0x16E5 in ipairs(_0xA90D) do
if _0x16E5.key == _0x3CC0.font and _0x16E5.path then _0x1D80 = _0x16E5.path end
end
if not _0x1D80 thenlocal _0x2457, _0x6A3E = pcall(getFolderPath, 0x14)
if _0x2457 and _0x6A3E then
for _0x374C, _0x6E19 in ipairs({"trebucbd.ttf","trebuc.ttf","arial.ttf"}) do
if doesFileExist(_0x6A3E .."\\".. _0x6E19) then _0x1D80 = _0x6A3E .."\\".. _0x6E19 break end
end
end
end
if not _0x1D80 then return end
local _0xB954 = _0xAAB1.GetIO()
local _0xC867 = _0xB954.Fonts:AddFontFromFileTTF(_0x1D80, 28, nil, _0xB954.Fonts:GetGlyphRangesCyrillic())
if _0xC867 ~= nil thenif not pcall(_0x19D1.Init, 28) then pcall(_0x19D1.Init) end
_0xB954.FontDefault = _0xC867
_0xB954.FontGlobalScale = 0.5
end
end)
_0x076F("apply_theme", apply_theme)
_0x076F("load_data", _0x9060)
end)local _0x24C4 = { on = false, _0xE62A = 0, _0x813B = 0, _0x8E44 = 0, _0x86ED = 0 }
local function _0xFD46()local _0x9E14, _0x4257 = _0xAAB1.GetWindowPos(), _0xAAB1.GetWindowSize()
local _0x4335, _0x952C = _0x9E14.x + _0x4257.x, _0x9E14.y + _0x4257.y_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(_0x4257.x - 28, _0x4257.y - 28 + _0xAAB1.GetScrollY()))
_0xAAB1.InvisibleButton("##resize_grip", _0xAAB1.ImVec2(20, 20))
local _0xF201 = _0xAAB1.GetMousePos()
local _0x56EC = _0xF201.x >= _0x4335 - 34 and _0xF201.x <= _0x4335 + 4 and _0xF201.y >= _0x952C - 34 and _0xF201.y <= _0x952C + 4
if not _0x24C4.on and _0x56EC and _0xAAB1.IsMouseClicked(0) then
_0x24C4.on = true
_0x24C4.mx, _0x24C4.my, _0x24C4.w, _0x24C4.h = _0xF201.x, _0xF201.y, _0x4C9D.w, _0x4C9D.h
end
if _0x24C4.on then
if _0xAAB1.IsMouseDown(0) then
local _0x17E0, _0xFBEC = getScreenResolution()
_0x4C9D.req = {
_0x8E44 = _0x43DE(_0x24C4.w + _0xF201.x - _0x24C4.mx, 700, math.max(700, _0x17E0 - 20)),
_0x86ED = _0x43DE(_0x24C4.h + _0xF201.y - _0x24C4.my, 400, math.max(400, _0xFBEC - 20)),
}
else
_0x24C4.on = false
end
end
local _0x86C5 = _0x3CC0.accent
local _0x1C8E = (_0x56EC or _0x24C4.on) and 0.95 or 0.55
_0xAAB1.GetWindowDrawList():AddTriangleFilled(
_0xAAB1.ImVec2(_0x4335 - 6, _0x952C - 6), _0xAAB1.ImVec2(_0x4335 - 6, _0x952C - 22), _0xAAB1.ImVec2(_0x4335 - 22, _0x952C - 6),
_0x82F6(_0x86C5[1], _0x86C5[2], _0x86C5[3], _0x1C8E))
endlocal function _0x0394(wsz)
if wsz.x < 700 or wsz.y < 400 then
wsz = _0xAAB1.ImVec2(math.max(700, wsz.x), math.max(400, wsz.y))
_0xAAB1.SetWindowSize(wsz, _0xAAB1.Cond.Always)
end
_0x4C9D.w, _0x4C9D.h = wsz.x, wsz.y
_0x4C9D.tab_h = _0x43DE(math.floor((_0x4C9D.h - 161) / 8) - 5, 26, 42)
_0x4C9D.block_y = 5 + 8 * (_0x4C9D.tab_h + 5) + 6
local _0x8E44, _0x86ED = math.floor(wsz.x + 0.5), math.floor(wsz.y + 0.5)
if _0x8E44 ~= _0x3CC0.win_w or _0x86ED ~= _0x3CC0.win_h then
_0x3CC0.win_w, _0x3CC0.win_h = _0x8E44, _0x86ED
_0xEC9A()
end
endfunction _0xD3A9.draw_splash(_0xE35E)
if not _0xD3A9.splash_t then return end
local _0x6A7C = _0xAAB1.ImVec2
local _0x00C2 = _0xAAB1.GetTime() - _0xD3A9.splash_t
local _0x6164 = 2.0
if _0x00C2 >= _0x6164 then
_0xD3A9.splash_t = nil
return
end
_0xAAB1.SetCursorPos(_0x6A7C(0, 0))
if _0xAAB1.InvisibleButton("##splash_block", _0x6A7C(_0x4C9D.w, _0x4C9D.h)) then
_0xD3A9.splash_t = nil
return
end
local _0x1C8E = (_0x00C2 < 1.35) and 1 or _0x43DE(1 - (_0x00C2 - 1.35) / (_0x6164 - 1.35), 0, 1)
local _0x86C5 = _0x3CC0.accent
local _0xFCBC = _0xAAB1.GetWindowDrawList()
local _0x0DBB, _0x4326 = _0xE35E.x + _0x4C9D.w, _0xE35E.y + _0x4C9D.h
_0xFCBC:AddRectFilled(_0xE35E, _0x6A7C(_0x0DBB, _0x4326), _0x82F6(0.04, 0.035, 0.06, 0.98 * _0x1C8E), 12)
local _0x4335, _0x952C = (_0xE35E.x + _0x0DBB) / 2, (_0xE35E.y + _0x4326) / 2 - 24
for _0x4E41 = 5, 1, -1 do
_0xFCBC:AddCircleFilled(_0x6A7C(_0x4335, _0x952C), 40 + _0x4E41 * 26, _0x82F6(_0x86C5[1], _0x86C5[2], _0x86C5[3], 0.035 * _0x1C8E), 40)
end
if _0x3CC0.halloween then _0xD3A9.hw_safe(_0xD3A9.hw_pumpkin, _0xFCBC, _0x4335, _0x952C - 92, 30, _0x1C8E, true) end
local _0x5F3D = 1 + 0.12 * (1 - _0x43DE(_0x00C2 / 0.7, 0, 1)) ^ 2
local _0x6FF2 ="Arizona Prices"_0xAAB1.SetWindowFontScale(2.6 * _0x5F3D)
local _0x0F4A = _0xAAB1.CalcTextSize(_0x6FF2)
_0xFCBC:AddText(_0x6A7C(_0x4335 - _0x0F4A.x / 2 + 2, _0x952C - _0x0F4A.y / 2 + 2), _0x82F6(0, 0, 0, 0.6 * _0x1C8E), _0x6FF2)
_0xFCBC:AddText(_0x6A7C(_0x4335 - _0x0F4A.x / 2, _0x952C - _0x0F4A.y / 2), _0x82F6(1, 1, 1, _0x1C8E), _0x6FF2)
_0xAAB1.SetWindowFontScale(1.2)
local _0x9E6D ="Версия ".. _0x59FB .."  |  t.me/arizona_prices"local _0x4ECA = _0xAAB1.CalcTextSize(_0x9E6D)
_0xFCBC:AddText(_0x6A7C(_0x4335 - _0x4ECA.x / 2, _0x952C + _0x0F4A.y / 2 + 12), _0x82F6(0.75, 0.78, 0.9, _0x1C8E), _0x9E6D)
_0xAAB1.SetWindowFontScale(1.0)
local _0xAC10 = 240
local _0x037E, _0x47CC = _0x4335 - _0xAC10 / 2, _0x952C + _0x0F4A.y / 2 + 62
_0xFCBC:AddRectFilled(_0x6A7C(_0x037E, _0x47CC), _0x6A7C(_0x037E + _0xAC10, _0x47CC + 6), _0x82F6(1, 1, 1, 0.10 * _0x1C8E), 3)
_0xFCBC:AddRectFilled(_0x6A7C(_0x037E, _0x47CC), _0x6A7C(_0x037E + _0xAC10 * _0x43DE(_0x00C2 / (_0x6164 - 0.3), 0, 1), _0x47CC + 6), _0x82F6(_0x86C5[1], _0x86C5[2], _0x86C5[3], _0x1C8E), 3)
if _0x3CC0.halloween then
_0xAAB1.SetWindowFontScale(1.1)
local _0x7113 = _0xAAB1.CalcTextSize("Happy Halloween")
_0xFCBC:AddText(_0x6A7C(_0x4335 - _0x7113.x / 2, _0x47CC + 20), _0x82F6(1.0, 0.60, 0.15, _0x1C8E),"Happy Halloween")
_0xAAB1.SetWindowFontScale(1.0)
end
end
_0xAAB1.OnFrame(function() return _0xF7A7[0] or _0x602D[0] or _0xD3A9.alpha > 0 end,
_0x7DD2("menu", function(player)
_0xD3A9.tick()
if _0xF7A7[0] or _0xD3A9.alpha > 0 then
_0xD3A9.set_alpha(_0xD3A9.alpha)
local _0x17E0, _0xFBEC = getScreenResolution()
_0xAAB1.SetNextWindowPos(_0xAAB1.ImVec2(_0x17E0 / 2, _0xFBEC / 2), _0xAAB1.Cond.FirstUseEver, _0xAAB1.ImVec2(0.5, 0.5))
if _0x4C9D.force then
_0x4C9D.force = false
_0xAAB1.SetNextWindowSize(_0xAAB1.ImVec2(835, 500), _0xAAB1.Cond.Always)
elseif _0x4C9D.req then
_0xAAB1.SetNextWindowSize(_0xAAB1.ImVec2(_0x4C9D.req.w, _0x4C9D.req.h), _0xAAB1.Cond.Always)
_0x4C9D.req = nil
else
_0xAAB1.SetNextWindowSize(_0xAAB1.ImVec2(_0x3CC0.win_w, _0x3CC0.win_h), _0xAAB1.Cond.FirstUseEver)
end
pcall(_0xAAB1.SetNextWindowSizeConstraints, _0xAAB1.ImVec2(700, 400), _0xAAB1.ImVec2(math.max(700, _0x17E0 - 20), math.max(400, _0xFBEC - 20)))
if _0xAAB1.Begin(_0xACD5("Arizona Prices##main_window"), _0xF7A7[0] and _0xF7A7 or nil, bit.bor(_0xAAB1.WindowFlags.NoCollapse, _0xAAB1.WindowFlags.NoResize, _0xAAB1.WindowFlags.NoTitleBar, _0xAAB1.WindowFlags.NoScrollbar, _0xAAB1.WindowFlags.NoScrollWithMouse)) then
_0x0394(_0xAAB1.GetWindowSize())
local _0xE35E = _0xAAB1.GetWindowPos()
local _0xA5E4, _0xCDB8 = _0xE35E.x + _0x4C9D.w / 2, _0xE35E.y + _0x4C9D.h / 2
_0x547A.typing = _0xAAB1.GetIO().WantTextInput_0xE514(_0xE35E)
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(5, 5))
_0x207F(_0xB72A.CIRCLE_DOLLAR .. _0xACD5(" Arizona Prices"), 1,"Таблица цен предметов (клавиша 1)\nCtrl+F - быстрый поиск")
_0x207F(_0x4BFE("CALCULATOR","") .." Калькулятор", 2,"Калькулятор с историей (клавиша 2)")
_0x207F(_0x4BFE("CLOCK","") .." Отчет до PayDay", 3,"Таймер до PayDay на экране (клавиша 3)")
_0x207F(_0x4BFE("COMMENT_DOTS","") .." Фразы", 4,"Быстрые фразы в чат (клавиша 4)")
_0x207F(_0x4BFE("NOTE_STICKY","") .." Заметки", 8,"Ваши заметки (клавиша 5)")
_0x207F(_0x4BFE("GLOBE","") .." Время стран", 6,"Время в других странах (клавиша 6)")
_0x207F(_0x4BFE("CIRCLE_INFO","") .." О скрипте", 5,"Соцсети и разработчик (клавиша 7)")
_0x207F(_0x4BFE("GEAR","") .." Настройки", 7,"Тема, шрифт, прозрачность (клавиша 8)")
_0xD3A9.draw_bar(_0xE35E)
_0x2351()local _0x496C = _0x43DE((_0xAAB1.GetTime() - _0xD3A9.tab_t) / 0.30, 0, 1)
local _0x7C7B = 1 - (1 - _0x496C) ^ 3
local _0x0197 = (1 - _0x7C7B) * 30
_0xD3A9.base = _0xD3A9.alpha * _0x7C7B
_0xD3A9.set_alpha(_0xD3A9.base)
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(_0x2546 + _0x0197, 0))
local _0x932E = _0xAAB1.WindowFlags.AlwaysUseWindowPadding or 0
if not (_0x307A == 2 and (_0x4C9D.h < 495 or _0x4C9D.w < 830)) then
_0x932E = bit.bor(_0x932E, _0xAAB1.WindowFlags.NoScrollbar, _0xAAB1.WindowFlags.NoScrollWithMouse)
end
local _0xB410 = _0xAAB1.BeginChild("##content", _0xAAB1.ImVec2(_0x4C9D.w - _0x2546 - _0x0197, _0x4C9D.h), false, _0x932E)
if _0xB410 then
if _0x3CC0.bg_fx then pcall(_0xD3A9.draw_bg) end
if _0x3CC0.halloween then _0xD3A9.hw_safe(_0xD3A9.hw_bg) end
if _0x307A == 1 then
_0xAAB1.AlignTextToFramePadding()
_0xAAB1.SetCursorPosX(9)
local _0x4889 = _0xAAB1.GetCursorScreenPos()
_0xAAB1.Text(_0xB72A.CIRCLE_DOLLAR .. _0xACD5(' Arizona Prices'))
if _0xAAB1.IsItemHovered() then
local _0xA3FD, _0x6354 = _0xAAB1.GetItemRectMin(), _0xAAB1.GetItemRectMax()
_0xAAB1.GetWindowDrawList():AddLine(_0xAAB1.ImVec2(_0xA3FD.x, _0x6354.y), _0xAAB1.ImVec2(_0x6354.x, _0x6354.y), _0x82F6(_0x3CC0.accent[1], _0x3CC0.accent[2], _0x3CC0.accent[3], 1), 1.5)
_0xAAB1.SetTooltip("Открыть наш Telegram-канал @arizona_prices")
if _0xAAB1.IsMouseClicked(0) then _0x1810("https://t.me/arizona_prices") end
end
_0xAAB1.SameLine(140)
_0xAAB1.SetNextItemWidth(math.max(90, _0x4C9D.w - _0x2546 - 329))
if _0xD3A9.focus_search then
_0xAAB1.SetKeyboardFocusHere()
_0xD3A9.focus_search = false
end
_0xAAB1.InputTextWithHint("##search", _0xB72A.MAGNIFYING_GLASS .." Поиск", _0x7972, _0x90EB.sizeof(_0x7972))
_0xAAB1.SameLine()
_0xAAB1.SetNextItemWidth(150)
local _0xDDFF = {"По умолчанию","Сначала дорогие","Сначала дешёвые","По алфавиту"}
local _0x088F = _0xDDFF[_0xC4BB[0] + 1] or"Сортировка"if _0xAAB1.BeginCombo("##sort_combo", _0x088F) then
for _0x4E41, _0x6E19 in ipairs(_0xDDFF) do
local _0x44EC = _0xC4BB[0] == (_0x4E41 - 1)
if _0xAAB1.Selectable(_0x6E19, _0x44EC) then
_0xC4BB[0] = _0x4E41 - 1
end
if _0x44EC then
_0xAAB1.SetItemDefaultFocus()
end
end
_0xAAB1.EndCombo()
end
_0xAAB1.SameLine(_0x4C9D.w - _0x2546 - 29)
_0xAAB1.PushStyleColor(_0xAAB1.Col.Button, _0xAAB1.ImVec4(0, 0, 0, 0))
if _0xAAB1.Button(_0xB72A.CIRCLE_XMARK .."##close", _0xAAB1.ImVec2(24, 24)) then
_0xF7A7[0] = false
end
if _0xAAB1.IsItemHovered() then _0xAAB1.SetTooltip("Закрыть") end
_0xAAB1.PopStyleColor(1)
_0xAAB1.Spacing()
local _0x3BDE = _0x90EB.string(_0x7972)
if _0x3BDE ~= _0xD3A9.last_q or _0xC4BB[0] ~= _0xD3A9.last_sort then
_0xD3A9.last_q, _0xD3A9.last_sort = _0x3BDE, _0xC4BB[0]
_0xD3A9.table_t = _0xAAB1.GetTime()
end
if not _0xD3A9.hint_shown then
_0xD3A9.hint_shown = true
_0x3EA3("Подсказка: правая кнопка мыши по предмету - быстрые действия, звёздочка - избранное","info", 7)
end
if _0xAAB1.BeginChild("##table_child", _0xAAB1.ImVec2(-1, _0x4C9D.h - 79), true) then
local _0x9D16 = _0xAAB1.GetStyle()
local _0x4EB8 = _0xAAB1.GetCursorScreenPos().x
local _0x3DDC = _0xAAB1.GetCursorScreenPos().y - _0x9D16.WindowPadding.y
local _0xA9C5 = _0x9D16.ItemSpacing.y
local _0x965A = 110
local _0xC841, _0x9DFA, _0x1F81 = 140, 120, _0xAADF.on and 108 or 44
local _0x4F8D = math.max(110, math.floor(_0xAAB1.GetContentRegionAvail().x) - (_0x965A + _0xC841 + _0x9DFA + _0x1F81))
_0xAAB1.Columns(5,"item_table", false)
_0xAAB1.SetColumnWidth(0, _0x4F8D)
_0xAAB1.SetColumnWidth(1, _0x965A)
_0xAAB1.SetColumnWidth(2, _0xC841)
_0xAAB1.SetColumnWidth(3, _0x9DFA)
_0xAAB1.SetColumnWidth(4, _0x1F81)
do
local _0x2B19 = _0xAAB1.CalcTextSize("Предмет")
_0xAAB1.SetCursorPosX(_0xAAB1.GetCursorPosX() + math.max(0, (_0x4F8D - _0x2B19.x) * 0.5))
_0xAAB1.TextColored(_0xB079(1.3),"Предмет")
end
_0xAAB1.NextColumn()
do
local _0x2B19 = _0xAAB1.CalcTextSize("Ликвидность")
_0xAAB1.SetCursorPosX(_0xAAB1.GetCursorPosX() + math.max(0, (_0x965A - _0x2B19.x) * 0.5))
_0xAAB1.TextColored(_0xB079(1.3),"Ликвидность")
end
_0xAAB1.NextColumn()
do
local _0x2B19 = _0xAAB1.CalcTextSize("Скупочная цена")
_0xAAB1.SetCursorPosX(_0xAAB1.GetCursorPosX() + math.max(0, (_0xC841 - _0x2B19.x) * 0.5))
_0xAAB1.TextColored(_0xB079(1.3),"Скупочная цена")
end
_0xAAB1.NextColumn()
do
local _0x2B19 = _0xAAB1.CalcTextSize("Продажа")
_0xAAB1.SetCursorPosX(_0xAAB1.GetCursorPosX() + math.max(0, (_0x9DFA - _0x2B19.x) * 0.5))
_0xAAB1.TextColored(_0xB079(1.3),"Продажа")
end
_0xAAB1.NextColumn()
do
local _0x2B19 = _0xAAB1.CalcTextSize("Действия")
_0xAAB1.SetCursorPosX(_0xAAB1.GetCursorPosX() + math.max(0, (_0x1F81 - _0x2B19.x) * 0.5))
_0xAAB1.TextColored(_0xB079(1.3),"Действия")
end
_0xAAB1.NextColumn()
_0xAAB1.Separator()
local _0x2AC2 = _0xAAB1.GetCursorScreenPos().y - _0xA9C5 - 1.0
local _0x6848 = {}
local _0xE213 = _0xF8EB(_0x90EB.string(_0x7972))
for _0x4E41, _0x1545 in ipairs(_0x1217) do
local _0x8AD3 = _0xF8EB(_0x1545.item or"")
if _0xE213 ==""or _0x8AD3:find(_0xE213, 1, true) then
table.insert(_0x6848, _0x4E41)
end
end
if _0xC4BB[0] == 1 then
table.sort(_0x6848, function(_0x1C8E, _0x527F) return tonumber(_0x1217[_0x1C8E].sell or 0) > tonumber(_0x1217[_0x527F].sell or 0) end)
elseif _0xC4BB[0] == 2 then
table.sort(_0x6848, function(_0x1C8E, _0x527F) return tonumber(_0x1217[_0x1C8E].sell or 0) < tonumber(_0x1217[_0x527F].sell or 0) end)
elseif _0xC4BB[0] == 3 then
table.sort(_0x6848, function(_0x1C8E, _0x527F) local _0xAC13 = (_0x1217[_0x1C8E].item or""):lower() local _0xF99B = (_0x1217[_0x527F].item or""):lower() return _0xAC13 < _0xF99B end)
end
if next(_0xED9C.favs) thenlocal _0x8BA4, _0x5E5F = {}, {}
for _0x374C, ix in ipairs(_0x6848) do
if _0x1217[ix] and _0xED9C.favs[_0x1217[ix].item] then
_0x8BA4[#_0x8BA4 + 1] = ix
else
_0x5E5F[#_0x5E5F + 1] = ix
end
end
for _0x374C, ix in ipairs(_0x5E5F) do _0x8BA4[#_0x8BA4 + 1] = ix end
_0x6848 = _0x8BA4
end
local _0x773C = _0xAAB1.GetTime()
for ri, _0xCA44 in ipairs(_0x6848) do
local _0x3EBB = _0x1217[_0xCA44]
if _0x3EBB then
local _0xC6D4 = _0xAAB1.GetCursorPosY()
local _0x022D = _0x43DE((_0x773C - _0xD3A9.table_t - math.min(ri, 14) * 0.03) / 0.22, 0, 1)
_0xD3A9.set_alpha(_0xD3A9.base * _0x022D)
do
local _0x7376 = _0xAAB1.GetCursorScreenPos()
local _0x7C5B = _0x4EB8 + _0x4F8D + _0x965A + _0xC841 + _0x9DFA + _0x1F81
local _0xA3FD, _0x6354 = _0xAAB1.ImVec2(_0x4EB8, _0x7376.y - 2), _0xAAB1.ImVec2(_0x7C5B, _0x7376.y + 27)
local _0x60A9 = _0xAAB1.IsMouseHoveringRect(_0xA3FD, _0x6354)
if _0x60A9 and _0xAAB1.IsWindowHovered() and _0xAAB1.IsMouseClicked(1) then
_0x134E = _0x3EBB.item
_0xD3A9.ctx_open = true
end
if _0x60A9 and _0xAAB1.IsWindowHovered() and _0xAAB1.IsMouseClicked(0) then
_0x134E = _0x3EBB.item
end
if _0x134E ~= nil and _0x3EBB.item == _0x134E then
_0xAAB1.GetWindowDrawList():AddRectFilled(_0xA3FD, _0x6354, _0x82F6(_0x3CC0.accent[1], _0x3CC0.accent[2], _0x3CC0.accent[3], 0.30), 6)
elseif _0x60A9 then
_0xAAB1.GetWindowDrawList():AddRectFilled(_0xA3FD, _0x6354, _0x82F6(_0x3CC0.accent[1], _0x3CC0.accent[2], _0x3CC0.accent[3], 0.14), 6)
elseif ri % 2 == 0 then
_0xAAB1.GetWindowDrawList():AddRectFilled(_0xA3FD, _0x6354, _0x82F6(1, 1, 1, 0.025), 6)
end
end
local _0xD6AD = _0x3EBB.item or""local _0x2B19 = _0xAAB1.CalcTextSize(_0xD6AD)
_0xAAB1.SetCursorPosY(_0xC6D4 + math.max(0, (24 - _0x2B19.y) * 0.5))
local _0xE8F2 = _0xAAB1.CalcTextSize(_0xB72A.CIRCLE_QUESTION).x
local _0x6EFA = _0x4F8D - _0xE8F2 - 12
if _0x2B19.x > _0x6EFA then
local _0xD101 = _0xD6AD
while #_0xD101 > 3 and _0xAAB1.CalcTextSize(_0xD101 .."...").x > _0x6EFA do
local _0xA422 = #_0xD101
local _0x731B = _0xA422
while _0x731B > 0 and _0xD101:byte(_0x731B) >= 128 and _0xD101:byte(_0x731B) < 192 do
_0x731B = _0x731B - 1
end
_0xD101 = _0xD101:sub(1, _0x731B - 1)
end
_0xD101 = _0xD101 .."..."_0xAAB1.Text(_0xD101)
if _0xAAB1.IsItemHovered() then _0xAAB1.SetTooltip((_0xD6AD:gsub("%%","%%%%"))) end
_0xAAB1.SameLine(_0x4F8D - _0xE8F2 - 6)
_0xAAB1.Text(_0xB72A.CIRCLE_QUESTION)
if _0xAAB1.IsItemHovered() then _0xAAB1.SetTooltip((_0xD6AD:gsub("%%","%%%%"))) end
else
_0xAAB1.SetCursorPosX(_0xAAB1.GetCursorPosX() + math.max(0, (_0x4F8D - _0x2B19.x) * 0.5))
_0xAAB1.TextUnformatted(_0xD6AD)
end
_0xAAB1.NextColumn()
do
local _0x000B = _0x3EBB.liq
local _0xD6C6 = _0x000B or"-"local _0xD79F = _0xD3A9.liq_color(_0x000B)
if _0xAADF.on then_0xAAB1.SetCursorPosY(_0xC6D4)
_0xAAB1.PushStyleColor(_0xAAB1.Col.Text, _0xD79F)
if _0xAAB1.Button(_0xD6C6 .."##liq_".. _0xCA44, _0xAAB1.ImVec2(_0x965A - 14, 24)) then
_0x3EBB.liq = _0xD3A9.liq_next(_0x000B)
_0x64DF()
end
_0xAAB1.PopStyleColor(1)
else
local _0x2B19 = _0xAAB1.CalcTextSize(_0xD6C6)
_0xAAB1.SetCursorPosY(_0xC6D4 + math.max(0, (24 - _0x2B19.y) * 0.5))
_0xAAB1.SetCursorPosX(_0xAAB1.GetCursorPosX() + math.max(0, (_0x965A - _0x2B19.x) * 0.5))
_0xAAB1.TextColored(_0xD79F, _0xD6C6)
end
end
_0xAAB1.NextColumn()
do
local _0x2B19 = _0xAAB1.CalcTextSize(_0x3882(_0x3EBB.buy))
_0xAAB1.SetCursorPosY(_0xC6D4 + math.max(0, (24 - _0x2B19.y) * 0.5))
_0xAAB1.SetCursorPosX(_0xAAB1.GetCursorPosX() + math.max(0, (_0xC841 - _0x2B19.x) * 0.5))
_0xAAB1.TextColored(_0xAAB1.ImVec4(0.55, 0.92, 0.65, 1.0), _0x3882(_0x3EBB.buy))
end
_0xAAB1.NextColumn()
do
local _0x3E9D = tonumber(_0x3EBB.sell) or 0
local _0x6878 = _0x3882(_0x3EBB.sell)
local _0x2B19 = _0xAAB1.CalcTextSize(_0x6878)
_0xAAB1.SetCursorPosY(_0xC6D4 + math.max(0, (24 - _0x2B19.y) * 0.5))
_0xAAB1.SetCursorPosX(_0xAAB1.GetCursorPosX() + math.max(0, (_0x9DFA - _0x2B19.x - 20) * 0.5))
_0xAAB1.TextColored(_0xAAB1.ImVec4(1.0, 0.85, 0.45, 1.0), _0x6878)
local _0xE8F2 = _0xAAB1.CalcTextSize(_0xB72A.BADGE_PERCENT).x
_0xAAB1.SameLine(_0x9DFA - _0xE8F2 - 6)
_0xAAB1.Text(_0xB72A.BADGE_PERCENT)
if _0xAAB1.IsItemHovered() then
_0xAAB1.SetTooltip("1%% - ".. _0x3882(math.floor(_0x3E9D * 0.99 + 0.5)) .."\n".."3%% - ".. _0x3882(math.floor(_0x3E9D * 0.97 + 0.5)) .."\n".."4%% - ".. _0x3882(math.floor(_0x3E9D * 0.96 + 0.5)) .."\n".."5%% - ".. _0x3882(math.floor(_0x3E9D * 0.95 + 0.5)))
end
end
_0xAAB1.NextColumn()
local _0x869B = _0xAADF.on and (28 * 3 + 10) or 28
_0xAAB1.SetCursorPosY(_0xC6D4)
_0xAAB1.SetCursorPosX(_0xAAB1.GetCursorPosX() + math.max(0, (_0x1F81 - _0x869B) * 0.5))
local _0x8476 = _0xED9C.favs[_0x3EBB.item] == true
_0xAAB1.PushStyleColor(_0xAAB1.Col.Text, _0x8476 and _0xAAB1.ImVec4(1.0, 0.82, 0.25, 1.0) or _0xAAB1.ImVec4(0.50, 0.52, 0.58, 1.0))
if _0xAAB1.Button(_0x4BFE("STAR","*") .."##fav_".. _0xCA44, _0xAAB1.ImVec2(28, 24)) then
_0xD3A9.toggle_fav(_0x3EBB.item)
end
_0xAAB1.PopStyleColor(1)
if _0xAAB1.IsItemHovered() then _0xAAB1.SetTooltip(_0x8476 and"Убрать из избранного"or"В избранное") end
if _0xAADF.on then
_0xAAB1.SameLine()
if _0xAAB1.Button(_0xB72A.PEN_LINE .."##edit_".. _0xCA44, _0xAAB1.ImVec2(28, 24)) then
_0x906A(_0xCA44)
end
_0xAAB1.SameLine()
if _0xAAB1.Button(_0xB72A.TRASH_CAN .."##del_".. _0xCA44, _0xAAB1.ImVec2(28, 24)) then
_0x12C4 = _0xCA44
_0xDEBC = true
end
end
_0xAAB1.NextColumn()
_0xAAB1.Separator()
_0x2AC2 = _0xAAB1.GetCursorScreenPos().y - _0xA9C5 - 1.0
end
end
_0xAAB1.Columns(1)
_0xD3A9.set_alpha(_0xD3A9.base)
if _0xD3A9.ctx_open then
_0xAAB1.OpenPopup("##row_ctx")
_0xD3A9.ctx_open = false
end
if _0xAAB1.BeginPopup("##row_ctx") then
local _0x3D8A
for _0x374C, _0x1545 in ipairs(_0x1217) do
if _0x1545.item == _0x134E then _0x3D8A = _0x1545; break end
end
if _0x3D8A then
local _0xC3CF = _0x3D8A.item ..": скупка ".. _0x3882(_0x3D8A.buy) .." / продажа ".. _0x3882(_0x3D8A.sell)
_0xAAB1.TextColored(_0xB079(1.3), _0x3D8A.item)
_0xAAB1.Separator()
if _0xAAB1.Selectable(_0x4BFE("COMMENT_DOTS","") .."  Вставить в строку чата##ctx_chat") then
_0x0EA0(function()
sampSetChatInputEnabled(true)
sampSetChatInputText(_0xACD5:decode(_0xC3CF))
end)
end
if _0xAAB1.Selectable(_0x4BFE("COPY","") .."  Скопировать в буфер##ctx_copy") then
_0xAAB1.SetClipboardText(_0xC3CF)
_0x3EA3("Скопировано: ".. _0xC3CF,"ok", 4)
end
local _0x4185 = _0xED9C.favs[_0x3D8A.item] == true
if _0xAAB1.Selectable(_0x4BFE("STAR","*") .. (_0x4185 and"  Убрать из избранного"or"  В избранное") .."##ctx_fav") then
_0xD3A9.toggle_fav(_0x3D8A.item)
end
else
_0xAAB1.Text("Предмет не найден")
end
_0xAAB1.EndPopup()
end
if _0x2AC2 > _0x3DDC then
local _0xD71F = _0xAAB1.GetWindowDrawList()
local _0xEABC = _0xAAB1.GetColorU32(_0xAAB1.Col.Separator)
local _0x6BF7 = _0x4EB8
local _0xA2BC = {_0x4F8D, _0x965A, _0xC841, _0x9DFA}
for _0x4E41 = 1, 4 do
_0x6BF7 = _0x6BF7 + _0xA2BC[_0x4E41]
_0xD71F:AddLine(_0xAAB1.ImVec2(_0x6BF7, _0x3DDC), _0xAAB1.ImVec2(_0x6BF7, _0x2AC2), _0xEABC, 1.0)
end
end
_0xAAB1.EndChild()
end
local _0x028C = _0xAAB1.GetContentRegionAvail().x - 95
if _0xAADF.on then
if _0xAAB1.Button(_0xB72A.CIRCLE_PLUS .." Добавить предмет", _0xAAB1.ImVec2(_0x028C, 30)) then
_0xEE8F()
end
else
if _0xAAB1.Button(_0x4BFE("PAPER_PLANE","") .." Актуальные цены - в нашем ТГК @arizona_prices##open_tg", _0xAAB1.ImVec2(_0x028C, 30)) then
_0x1810("https://t.me/arizona_prices")
end
end
_0xAAB1.SameLine()
if _0xAAB1.Button(_0xB72A.TRIANGLE_EXCLAMATION .."##report_prices", _0xAAB1.ImVec2(30, 30)) then
if _0x134E and _0x134E ~=""then
_0xAAB1.SetClipboardText("Привет. Заметил что цена предмета \"".. _0x134E .."\" изменилась, прошу обновить")
_0x1810("https://t.me/xi_vivide")
_0x3EA3("Сообщение скопировано - вставьте его в чат (Ctrl+V)","ok", 6)
else
_0x3EA3("Сначала нажмите на предмет в таблице, цена которого устарела","warn", 5)
end
end
if _0xAAB1.IsItemHovered() then _0xAAB1.SetTooltip("Сообщить об устаревших ценах\n(сначала нажмите на предмет в таблице)") end
_0xAAB1.SameLine()
if _0xAAB1.Button(_0xB72A.BUG .."##report_bug", _0xAAB1.ImVec2(30, 30)) then
_0x8081()
end
if _0xAAB1.IsItemHovered() then _0xAAB1.SetTooltip("Сообщить о баге (скопирует данные для разработчика)") end
if _0x149C then
_0xAAB1.OpenPopup(_0x03B9 and _0x88DA or _0x312F)
_0x149C = false
end
if _0x602D[0] then
local _0x32EB = _0x03B9 and _0x88DA or _0x312F
_0xAAB1.SetNextWindowPos(_0xAAB1.ImVec2(_0xA5E4, _0xCDB8), _0xAAB1.Cond.Always, _0xAAB1.ImVec2(0.5, 0.5))
_0xAAB1.SetNextWindowSize(_0xAAB1.ImVec2(300, 171), _0xAAB1.Cond.Always)
if _0xAAB1.BeginPopupModal(_0x32EB, _0x602D, bit.bor(_0xAAB1.WindowFlags.NoCollapse, _0xAAB1.WindowFlags.NoResize)) then
local _0xF5BB = _0xB72A.LAYER_GROUP .." Предмет"local _0x613F = _0xB72A.HANDS_HOLDING_DOLLAR .." Скупочная цена"local _0x2DE3 = _0xB72A.HAND_HOLDING_DOLLAR .." Продажа"if _0xBB1A then
local _0x6442 = os.clock() - _0xF928
if _0x6442 >= 1.2 then
_0xBB1A = false
else
local _0x96F5 = (_0x6442 % 0.4) < 0.2
if _0x3E98 and _0x96F5 then _0xF5BB =""end
if _0xF7A3 and _0x96F5 then _0x613F =""end
if _0x169C and _0x96F5 then _0x2DE3 =""end
end
end
if _0xAAB1.BeginChild("##modal", _0xAAB1.ImVec2(-1, 102), true) then
_0xAAB1.SetNextItemWidth(-1)
_0xAAB1.InputTextWithHint("##modal_item", _0xF5BB, _0x2279, _0x90EB.sizeof(_0x2279))
_0xAAB1.Separator()
_0xAAB1.SetNextItemWidth(-1)
_0xAAB1.InputTextWithHint("##modal_buy", _0x613F, _0xE998, _0x90EB.sizeof(_0xE998), _0xAAB1.InputTextFlags.CharsDecimal)
_0xAAB1.Separator()
_0xAAB1.SetNextItemWidth(-1)
_0xAAB1.InputTextWithHint("##modal_sell", _0x2DE3, _0x15D8, _0x90EB.sizeof(_0x15D8), _0xAAB1.InputTextFlags.CharsDecimal)
_0xAAB1.EndChild()
end
if _0x03B9 then
if _0xAAB1.Button(_0xB72A.FLOPPY_DISK .." Сохранить", _0xAAB1.ImVec2(142, 30)) then
local _0x2063 = _0x90EB.string(_0x2279)
local _0x5E99 = _0x90EB.string(_0xE998)
local _0x526B = _0x90EB.string(_0x15D8)
_0x3E98 = (_0x2063 =="")
_0xF7A3 = (_0x5E99 =="")
_0x169C = (_0x526B =="")
if _0x3E98 or _0xF7A3 or _0x169C then
_0xBB1A = true
_0xF928 = os.clock()
else
local _0x6E19 = _0x2063
local _0x2FFC = tonumber(_0x5E99)
local _0xE824 = tonumber(_0x526B)
if _0x2FFC and _0xE824 and _0x94C4 and _0x1217[_0x94C4] then
_0x1217[_0x94C4] = {_0x3EBB = _0x6E19, _0x2FFC = _0x2FFC, _0xE824 = _0xE824, _0x000B = _0x1217[_0x94C4].liq}
_0x64DF()
_0x2EFC()
end
end
end
_0xAAB1.SameLine()
if _0xAAB1.Button(_0xB72A.CIRCLE_XMARK .." Отменить", _0xAAB1.ImVec2(142, 30)) then
_0x2EFC()
end
else
if _0xAAB1.Button(_0xB72A.CIRCLE_PLUS .." Добавить", _0xAAB1.ImVec2(-1, 30)) then
local _0x2063 = _0x90EB.string(_0x2279)
local _0x5E99 = _0x90EB.string(_0xE998)
local _0x526B = _0x90EB.string(_0x15D8)
_0x3E98 = (_0x2063 =="")
_0xF7A3 = (_0x5E99 =="")
_0x169C = (_0x526B =="")
if _0x3E98 or _0xF7A3 or _0x169C then
_0xBB1A = true
_0xF928 = os.clock()
else
local _0x6E19 = _0x2063
local _0x2FFC = tonumber(_0x5E99)
local _0xE824 = tonumber(_0x526B)
if _0x2FFC and _0xE824 then
table.insert(_0x1217, {_0x3EBB = _0x6E19, _0x2FFC = _0x2FFC, _0xE824 = _0xE824})
_0x64DF()
_0x2EFC()
end
end
end
end
_0xAAB1.EndPopup()
end
end
if _0xDEBC then
_0xAAB1.OpenPopup(_0xB72A.TRASH_CAN ..' Подтверждение удаления##delete_modal')
_0xDEBC = false
end
_0xAAB1.SetNextWindowPos(_0xAAB1.ImVec2(_0xA5E4, _0xCDB8), _0xAAB1.Cond.Always, _0xAAB1.ImVec2(0.5, 0.5))
_0xAAB1.SetNextWindowSize(_0xAAB1.ImVec2(415, 88), _0xAAB1.Cond.Always)
if _0xAAB1.BeginPopupModal(_0xB72A.TRASH_CAN ..' Подтверждение удаления##delete_modal', nil, bit.bor(_0xAAB1.WindowFlags.NoCollapse, _0xAAB1.WindowFlags.NoResize)) then
_0xAAB1.TextWrapped(_0xB72A.CIRCLE_QUESTION ..' Вы действительно хотите удалить этот предмет из справочника?')
_0xAAB1.Spacing()
if _0xAAB1.Button(_0xB72A.TRASH_CAN ..' Да, удалить', _0xAAB1.ImVec2(200, 30)) then
if _0x12C4 and _0x1217[_0x12C4] then
table.remove(_0x1217, _0x12C4)
_0x64DF()
end
_0x12C4 = nil
_0xAAB1.CloseCurrentPopup()
end
_0xAAB1.SameLine()
if _0xAAB1.Button(_0xB72A.CIRCLE_XMARK ..' Отменить', _0xAAB1.ImVec2(200, 30)) then
_0x12C4 = nil
_0xAAB1.CloseCurrentPopup()
end
_0xAAB1.EndPopup()
end
elseif _0x307A == 2 then
_0x92BA()
else
_0xA7A2(_0x307A)
end
end
if _0xB410 then pcall(_0xFD46) end
_0xAAB1.EndChild()
_0xD3A9.set_alpha(_0xD3A9.alpha)
_0xD3A9.draw_splash(_0xE35E)
_0x8386(_0xE35E.x, _0xE35E.y, _0xE35E.x + _0x4C9D.w, _0xE35E.y + _0x4C9D.h)
_0xAAB1.End()
else
_0xAAB1.End()
end
_0xD3A9.set_alpha(1)
end
end, function() _0xF7A7[0] = false; _0x602D[0] = false; _0x547A.binding = false; _0xD3A9.alpha = 0; _0xD3A9.set_alpha(1) end)
)_0xAAB1.OnFrame(function() return _0x6AA2[0] end, _0x7DD2("outdated", function()
local _0x17E0, _0xFBEC = getScreenResolution()
_0xAAB1.SetNextWindowPos(_0xAAB1.ImVec2(_0x17E0 / 2, _0xFBEC / 2), _0xAAB1.Cond.Always, _0xAAB1.ImVec2(0.5, 0.5))
_0xAAB1.SetNextWindowSize(_0xAAB1.ImVec2(580, 290), _0xAAB1.Cond.Always)
_0xAAB1.SetNextWindowFocus()
local _0x8D1B = bit.bor(_0xAAB1.WindowFlags.NoTitleBar, _0xAAB1.WindowFlags.NoResize, _0xAAB1.WindowFlags.NoMove,
_0xAAB1.WindowFlags.NoCollapse, _0xAAB1.WindowFlags.NoScrollbar, _0xAAB1.WindowFlags.NoSavedSettings)_0xAAB1.PushStyleColor(_0xAAB1.Col.WindowBg, _0xAAB1.ImVec4(0.075, 0.07, 0.095, 1.0))
_0xAAB1.Begin("##outdated_window", nil, _0x8D1B)
local _0x721A = _0xAAB1.GetWindowPos()
_0xAAB1.GetWindowDrawList():AddRectFilled(_0x721A, _0xAAB1.ImVec2(_0x721A.x + 580, _0x721A.y + 5), _0xAAB1.ColorConvertFloat4ToU32(_0xAAB1.ImVec4(1.00, 0.75, 0.15, 1.00)))
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(24, 28))
_0xAAB1.SetWindowFontScale(1.9)
_0xAAB1.TextColored(_0xAAB1.ImVec4(1.00, 0.80, 0.20, 1.00), _0x4BFE("TRIANGLE_EXCLAMATION","") .." Внимание!")
_0xAAB1.SetWindowFontScale(1.0)
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(24, 90))
_0xAAB1.SetWindowFontScale(1.3)
_0xAAB1.PushTextWrapPos(556)
_0xAAB1.TextWrapped("У вас старая версия скрипта. Обновите для комфортного использования.")
_0xAAB1.PopTextWrapPos()
_0xAAB1.SetWindowFontScale(1.0)
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(24, 160))
_0xAAB1.TextDisabled("Ваша версия: ".. _0x59FB .."    Новая версия: ".. _0x52F7.version)
if _0x52F7.status ~=""then
_0xAAB1.SetCursorPosX(24)
_0xAAB1.TextDisabled(_0x52F7.status)
end
_0xAAB1.SetCursorPos(_0xAAB1.ImVec2(24, 290 - 24 - 44))
local _0xE1B5 = (580 - 48 - 10) / 2
_0xAAB1.PushStyleColor(_0xAAB1.Col.Button, _0xB079(1.0))
_0xAAB1.PushStyleColor(_0xAAB1.Col.ButtonHovered, _0xB079(1.15))
_0xAAB1.PushStyleColor(_0xAAB1.Col.ButtonActive, _0xB079(0.85))
if _0x52F7.busy then
_0xAAB1.Button("Скачивание...##outdated_busy", _0xAAB1.ImVec2(_0xE1B5, 44))
elseif _0xAAB1.Button(_0x4BFE("DOWNLOAD","") .." Обновить##outdated_update", _0xAAB1.ImVec2(_0xE1B5, 44)) then
_0x2DFB()
end
_0xAAB1.PopStyleColor(3)
_0xAAB1.SameLine()
if _0xAAB1.Button(_0xB72A.CIRCLE_XMARK .." Закрыть##outdated_close", _0xAAB1.ImVec2(_0xE1B5, 44)) then
_0x6AA2[0] = false
end
_0xAAB1.End()
_0xAAB1.PopStyleColor(1)
end, function() _0x6AA2[0] = false end))
function main()
while not isSampAvailable() do wait(0) end
_0x076F("load_data", _0x9060)
sampAddChatMessage(_0xACD5:decode("{33AAFF}[Arizona Prices V2.0] {FFFFFF}Скрипт успешно загружен! Для активации - {33AAFF}/prices{FFFFFF}. ТГК - {33AAFF}@arizona_prices"), -1)
sampRegisterChatCommand('prices', _0x7EF9)
sampRegisterChatCommand('pradmin', function(arg)
arg = tostring(arg or""):gsub("%s","")
if arg =="off"then
_0xAADF.disable()
sampAddChatMessage(_0xACD5:decode("{33AAFF}[Arizona Prices] {FFFFFF}Режим разработчика выключен"), -1)
elseif arg ~=""and _0xAADF.enable(arg) then
sampAddChatMessage(_0xACD5:decode("{33AAFF}[Arizona Prices] {55FF55}Режим разработчика включён{FFFFFF}. Правка цен и ликвидности открыта"), -1)
else
sampAddChatMessage(_0xACD5:decode("{33AAFF}[Arizona Prices] {FF5555}Неверный код"), -1)
end
end)
addEventHandler('onWindowMessage', function(msg, wparam, lparam)
_0x076F("hotkey", _0xA589, msg, wparam, lparam)
end)
local _0x8DB9 = os.time() + 5
while true do
wait(100)
if _0x27CF then
local _0xEE69 = _0x27CF
_0x27CF = nil
pcall(function() _0xE3D9.ShellExecuteA(nil,"open", _0xEE69, nil, nil, 1) end)
end
while #_0x9041 > 0 do
_0x076F("action", table.remove(_0x9041, 1))
end
if not _0xF7A7[0] and _0x547A.binding then _0x547A.binding = false end
_0x076F("updates", _0xF41A)
if #_0x294A > 0 then
local _0xB322 = table.remove(_0x294A, 1)
_0x076F("notice", _0x3EA3, _0xB322.text, _0xB322.kind)
end
_0x076F("save_ui", _0x26A7)
if os.time() >= _0x8DB9 then
_0x8DB9 = os.time() + _0x5F5C
_0x076F("start_checks", _0x8A6A)
end
if _0xA34D then
_0xA34D = false
wait(700)
thisScript():reload()
end
end
end
function onScriptTerminate(scr, quit)
if scr == thisScript() then
pcall(_0x26A7, true)
end
end