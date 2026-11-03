local ffi = require('ffi')
local encoding = require('encoding')
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local SCRIPT_VERSION = "4.4" -- Метка для старых версий

-- Проверка библиотек: если чего-то не хватает, скрипт не вылетает с непонятной ошибкой,
-- а пишет в чат, что именно нужно установить
local ok_imgui, imgui = pcall(require, 'mimgui')
local ok_fa, fa = pcall(require, 'fAwesome6')
if not ok_imgui or not ok_fa then
    local missing = {}
    if not ok_imgui then missing[#missing + 1] = "mimgui" end
    if not ok_fa then missing[#missing + 1] = "fAwesome6" end
    function main()
        while not isSampAvailable() do wait(100) end
        sampAddChatMessage(u8:decode("{FF5555}[Arizona Prices] {FFFFFF}Не найдены библиотеки: {FFCC33}" .. table.concat(missing, ", ") .. "{FFFFFF}. Положите их в папку {FFCC33}moonloader\\lib{FFFFFF} и перезапустите игру."), -1)
        sampAddChatMessage(u8:decode("{FF5555}[Arizona Prices] {FFFFFF}Где скачать, смотрите в нашем ТГК: {33AAFF}@arizona_prices"), -1)
        thisScript():unload()
    end
    return
end

-- иконки: если в вашей версии fAwesome6 такой иконки нет, будет пустое место, а не вылет скрипта
local FA = setmetatable({}, { __index = function(_, k) return fa[k] or "" end })

ffi.cdef[[
    int ShellExecuteA(void* hwnd, const char* op, const char* file, const char* params, const char* dir, int show);
]]
local shell32 = ffi.load('shell32')
local pending_url = nil
-- ссылка открывается не прямо из кадра отрисовки (это могло ронять игру), а из основного потока
local function open_url(url)
    pending_url = url
end

local main_window = imgui.new.bool(false) 
local modal_window = imgui.new.bool(false) 
local MODAL_ID_ADD = FA.CIRCLE_PLUS .. " Добавить предмет###item_modal"
local MODAL_ID_EDIT = FA.PEN_LINE .. " Редактировать предмет###item_modal"

local buf_search = imgui.new.char[256]() 
local buf_item = imgui.new.char[256]() 
local buf_buy = imgui.new.char[64]() 
local buf_sell = imgui.new.char[64]()

local current_sort = imgui.new.int(0) 
local is_editing = false 
local edit_index = nil 
local pending_modal_open = false 
local pending_delete_open = false 
local pending_delete_index = nil
local selected_item_name = nil -- строка таблицы, на которую нажали (для «Сообщить об устаревших ценах»)
local is_blinking = false 
local blink_start_time = 0

local empty_item_field = false 
local empty_buy_field = false 
local empty_sell_field = false 
local items_list = {} 
local datadir = getWorkingDirectory() .. "\\config\\item_prices.json"

-- ===================== Защита данных и журнал ошибок =====================
local pending_notices = {}
local function queue_notice(text, kind)
    pending_notices[#pending_notices + 1] = { text = text, kind = kind }
end

local err_log = {}
local function tb(e)
    return debug.traceback(tostring(e), 2)
end

local function log_error(where, err)
    local text = tostring(err)
    err_log[#err_log + 1] = os.date("%H:%M:%S") .. " [" .. tostring(where) .. "] " .. (text:sub(1, 300):gsub("%s+", " "))
    if #err_log > 8 then table.remove(err_log, 1) end
    pcall(function()
        print("[Arizona Prices] " .. tostring(where) .. ": " .. text)
        local dir = getWorkingDirectory() .. "\\config"
        if not doesDirectoryExist(dir) then createDirectory(dir) end
        local path = dir .. "\\arizona_prices_errors.log"
        local f = io.open(path, "ab")
        if f then
            if (f:seek("end") or 0) > 200000 then
                f:close()
                f = io.open(path, "wb")
            end
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " [" .. tostring(where) .. "] " .. text .. "\n\n")
                f:close()
            end
        end
    end)
end

-- вызов функции без риска уронить скрипт: ошибка попадает в журнал
local function safe_call(where, fn, ...)
    local args = { ... }
    local ok, err = xpcall(function() return fn(unpack(args)) end, tb)
    if not ok then log_error(where, err) end
    return ok
end

-- действия, которые нельзя выполнять прямо из кадра отрисовки (скачивание, отправка в чат):
-- кадр только кладёт их в очередь, выполняет основной поток
local ui_actions = {}
local function defer(fn)
    ui_actions[#ui_actions + 1] = fn
end

-- обёртка для окон: ошибка внутри окна не роняет скрипт, а попадает в журнал
local function guard_frame(name, fn, on_fail)
    return function(...)
        local args = { ... }
        local n = select("#", ...)
        local ok, err = xpcall(function() return fn(unpack(args, 1, n)) end, tb)
        if not ok then
            log_error("frame:" .. name, err)
            queue_notice("Ошибка в окне (" .. name .. "). Откройте Настройки и нажмите «Сообщить об ошибке»", "err")
            if on_fail then pcall(on_fail) end
        end
    end
end

local function read_file_raw(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local c = f:read("*a")
    f:close()
    return c
end

local function write_file_raw(path, content)
    local f = io.open(path, "wb")
    if not f then return false end
    local ok = f:write(content)
    f:close()
    return ok ~= nil and ok ~= false
end

local function json_ok(str)
    if type(str) ~= "string" or str == "" then return false end
    local ok, d = pcall(decodeJson, str)
    return ok and type(d) == "table"
end

-- безопасная запись: сначала во временный файл, проверка, копия старой версии (.bak), потом замена
local function safe_write(path, content)
    if type(content) ~= "string" or content == "" then return false end
    local tmp = path .. ".tmp"
    if not write_file_raw(tmp, content) then os.remove(tmp); return false end
    if read_file_raw(tmp) ~= content then os.remove(tmp); return false end
    local old = read_file_raw(path)
    if old and json_ok(old) then write_file_raw(path .. ".bak", old) end
    os.remove(path)
    if not os.rename(tmp, path) then
        local ok = write_file_raw(path, content)
        os.remove(tmp)
        return ok
    end
    return true
end

-- безопасное чтение: если файл повреждён, берём резервную копию
local function safe_read_json(path)
    local c = read_file_raw(path)
    if json_ok(c) then return decodeJson(c) end
    local b = read_file_raw(path .. ".bak")
    if json_ok(b) then
        if c and c ~= "" then
            queue_notice("Файл данных был повреждён - восстановили из резервной копии", "warn")
            write_file_raw(path .. ".broken", c)
        end
        write_file_raw(path, b)
        return decodeJson(b)
    end
    if c and c ~= "" then
        write_file_raw(path .. ".broken", c)
        queue_notice("Файл данных повреждён и копии нет - начинаем с чистого листа", "err")
    end
    return nil
end

-- ===================== Режим разработчика (правка цен и ликвидности только у владельца) =====================
-- Остальные игроки видят цены только на чтение: их список всегда приводится к списку из нашего канала.
local ADM = {
    on = false,
    HASH = 888940931,
    LIQ = { ["Ликвид"] = true, ["Средне"] = true, ["Неликвид"] = true },
    path = getWorkingDirectory() .. "\\config\\arizona_prices_admin.json",
}

function ADM.hash(code)
    local s = "arzp|" .. tostring(code):lower()
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    return h
end

function ADM.valid_liq(v)
    if type(v) == "string" and ADM.LIQ[v] then return v end
    return nil
end

function ADM.enable(code)
    if ADM.hash(code) ~= ADM.HASH then return false end
    ADM.on = true
    local dir = getWorkingDirectory() .. "\\config"
    if not doesDirectoryExist(dir) then createDirectory(dir) end
    write_file_raw(ADM.path, encodeJson({ hash = ADM.HASH }))
    return true
end

function ADM.disable()
    ADM.on = false
    os.remove(ADM.path)
end

do
    local d = safe_read_json(ADM.path)
    if type(d) == "table" and tonumber(d.hash) == ADM.HASH then ADM.on = true end
end

local function load_data()
    local data = safe_read_json(datadir)
    if data then
        local clean = {}
        for _, v in ipairs(data) do
            if type(v) == "table" then
                clean[#clean + 1] = { item = tostring(v.item or ""), buy = tonumber(v.buy) or 0, sell = tonumber(v.sell) or 0, liq = ADM.valid_liq(v.liq) }
            end
        end
        items_list = clean
    elseif not doesFileExist(datadir) then
        items_list = {}
    end
end

local function save_data()
    local dir = getWorkingDirectory() .. "\\config"
    if not doesDirectoryExist(dir) then
        createDirectory(dir)
    end
    local ok, json = pcall(encodeJson, items_list)
    if ok and type(json) == "string" and json ~= "" then
        if not safe_write(datadir, json) then
            queue_notice("Не удалось сохранить список предметов", "err")
        end
    end
end

local function format_price(amount)
    local num = tonumber(amount)
    if not num then return tostring(amount) end
    local sign = num < 0 and "-" or ""
    num = math.abs(num)
    local s = (num == math.floor(num)) and string.format("%.0f", num) or tostring(num)
    local int, frac = s:match("^(%d+)(.*)$")
    if not int then return sign .. s end
    int = int:reverse():gsub("(%d%d%d)", "%1."):reverse()
    if int:sub(1, 1) == "." then int = int:sub(2) end
    return sign .. int .. frac
end

local function lower_cp1251(str) 
    local dec_ok, dec = pcall(function() return u8:decode(tostring(str or "")) end)
    str = dec_ok and dec or tostring(str or "")
    return (str:gsub(".", function(char) 
        local byte = char:byte() 
        if byte >= 192 and byte <= 223 then 
            return string.char(byte + 32) 
        elseif byte == 168 then 
            return string.char(184) 
        end 
        return char:lower() 
    end)) 
end

local function close_modal() 
    modal_window[0] = false 
    imgui.CloseCurrentPopup() 
end

local function open_add_modal() 
    is_editing = false 
    edit_index = nil 
    imgui.StrCopy(buf_item, "") 
    imgui.StrCopy(buf_buy, "") 
    imgui.StrCopy(buf_sell, "") 
    modal_window[0] = true 
    pending_modal_open = true 
end

local function open_edit_modal(index) 
    local item = items_list[index] 
    if not item then return end 
    is_editing = true 
    edit_index = index
    imgui.StrCopy(buf_item, item.item or "") 
    imgui.StrCopy(buf_buy, tostring(item.buy or 0)) 
    imgui.StrCopy(buf_sell, tostring(item.sell or 0)) 
    modal_window[0] = true 
    pending_modal_open = true
end

-- ===================== Внешний вид (настраивается во вкладке «Настройки») =====================
local UI_CFG = {
    accent = {0.98, 0.55, 0.12}, opacity = 1.0, overlay_scale = 1.0, open_key = 0, toasts = true, toast_corner = 3,
    halloween = true, -- Хэллоуин: фиолетовый фон, тыквы, летучие мыши, паутина
    border_mode = 1, border_speed = 1.0, shadow = true, font = "seguisb",
    win_w = 835, win_h = 500, bg_fx = true, splash = true,
}

-- Все эффекты интерфейса (плавное открытие, анимации вкладок и таблицы, фон, заставка) лежат в одной таблице UIFX
local UIFX = {
    alpha = 0,        -- текущая прозрачность окна (плавно растёт при открытии, падает при закрытии)
    m = 1,            -- множитель прозрачности для ручного рисования (см. col32)
    base = 1,         -- прозрачность содержимого вкладки
    tab_t = -10,      -- момент смены вкладки
    table_t = -10,    -- момент начала каскадной анимации строк таблицы
    was_open = false,
    splashed = false, -- заставка уже показана в этой игровой сессии
    TAB_ORDER = { 1, 2, 5, 7 }, -- порядок вкладок слева (цифры 1-4 на клавиатуре)
}

-- шрифты берём из системной папки Windows (там есть кириллица), ничего скачивать не нужно
local FONT_LIST = {
    { key = "seguisb",     name = "Segoe UI Semibold", file = "seguisb.ttf" },
    { key = "segoeui",     name = "Segoe UI",          file = "segoeui.ttf" },
    { key = "bahnschrift", name = "Bahnschrift",       file = "bahnschrift.ttf" },
    { key = "corbel",      name = "Corbel",            file = "corbel.ttf" },
    { key = "candara",     name = "Candara",           file = "candara.ttf" },
    { key = "calibri",     name = "Calibri",           file = "calibri.ttf" },
    { key = "verdana",     name = "Verdana",           file = "verdana.ttf" },
    { key = "tahoma",      name = "Tahoma",            file = "tahoma.ttf" },
}
local FONT_AVAILABLE = { { key = "default", name = "Системный (Trebuchet)" } }
pcall(function()
    local dir = getFolderPath(0x14)
    for _, f in ipairs(FONT_LIST) do
        local path = dir .. "\\" .. f.file
        if doesFileExist(path) then
            FONT_AVAILABLE[#FONT_AVAILABLE + 1] = { key = f.key, name = f.name, path = path }
        end
    end
end)

local function clamp(x, lo, hi)
    return math.max(lo, math.min(hi, x))
end

local function accent_vec(mult, alpha)
    local a = UI_CFG.accent
    local m = mult or 1.0
    return imgui.ImVec4(math.min(1, a[1] * m), math.min(1, a[2] * m), math.min(1, a[3] * m), alpha or 1.0)
end

-- ===================== Оформление: цвета, рамка с переливами, тень =====================
local function col32(r, g, b, a)
    return imgui.ColorConvertFloat4ToU32(imgui.ImVec4(r, g, b, a * UIFX.m))
end

local function hsv_to_rgb(h, s, v)
    h = h % 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v
    end
    return v, p, q
end

local function rgb_to_hsv(r, g, b)
    local mx, mn = math.max(r, g, b), math.min(r, g, b)
    local d = mx - mn
    local h = 0
    if d > 0 then
        if mx == r then h = ((g - b) / d) % 6
        elseif mx == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
        h = h / 6
    end
    return h, (mx == 0) and 0 or d / mx, mx
end

-- тёмный цвет с лёгким оттенком акцента
local function dark(l, a)
    local ac = UI_CFG.accent
    if UI_CFG.halloween then
        return imgui.ImVec4(math.min(1, l + 0.022), math.min(1, l + 0.002), math.min(1, l + 0.058), a or 1.0)
    end
    return imgui.ImVec4(math.min(1, l + ac[1] * 0.04), math.min(1, l + ac[2] * 0.04), math.min(1, l + ac[3] * 0.06), a or 1.0)
end

-- тёмный цвет, подмешанный к акценту (k от 0 до 1)
local function blend(l, k, a)
    local ac = UI_CFG.accent
    local d = dark(l)
    return imgui.ImVec4(d.x + (ac[1] - d.x) * k, d.y + (ac[2] - d.y) * k, d.z + (ac[3] - d.z) * k, a or 1.0)
end

-- список для рисования поверх окон; если нет, берём запасной
local function fg_list(fallback)
    if imgui.GetForegroundDrawList then
        local ok, dl = pcall(imgui.GetForegroundDrawList)
        if ok and dl ~= nil then return dl end
    end
    return fallback()
end

local function rounded_path(x0, y0, x1, y1, r)
    local xs, ys = {}, {}
    local function add(x, y) xs[#xs + 1] = x; ys[#ys + 1] = y end
    local function line(ax, ay, bx, by)
        local len = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
        local n = math.max(1, math.floor(len / 14))
        for i = 0, n - 1 do
            local t = i / n
            add(ax + (bx - ax) * t, ay + (by - ay) * t)
        end
    end
    local function arc(cx, cy, a0)
        for i = 0, 5 do
            local a = a0 + (math.pi / 2) * (i / 5)
            add(cx + math.cos(a) * r, cy + math.sin(a) * r)
        end
    end
    line(x0 + r, y0, x1 - r, y0)
    arc(x1 - r, y0 + r, -math.pi / 2)
    line(x1, y0 + r, x1, y1 - r)
    arc(x1 - r, y1 - r, 0)
    line(x1 - r, y1, x0 + r, y1)
    arc(x0 + r, y1 - r, math.pi / 2)
    line(x0, y1 - r, x0, y0 + r)
    arc(x0 + r, y0 + r, math.pi)
    return xs, ys
end

-- рамка: 1 = переливы цвета акцента, 2 = радуга, 3 = статичная
local function draw_border(x0, y0, x1, y1)
    local xs, ys = rounded_path(x0 + 1, y0 + 1, x1 - 1, y1 - 1, 12)
    local n = #xs
    local pts = {}
    for i = 1, n do pts[i] = imgui.ImVec2(xs[i], ys[i]) end
    local dl = fg_list(imgui.GetWindowDrawList)
    local ac = UI_CFG.accent
    local mode = UI_CFG.border_mode
    local t = os.clock() * UI_CFG.border_speed
    local lr, lg, lb = 1, 1, 1
    if mode == 1 then
        local h, sat = rgb_to_hsv(ac[1], ac[2], ac[3])
        lr, lg, lb = hsv_to_rgb(h + 0.08, math.max(0.35, sat * 0.75), 1.0)
    end
    for i = 1, n do
        local j = i % n + 1
        local f = (i - 1) / n
        local r, g, b
        if mode == 1 then
            local w = 0.5 + 0.5 * math.sin((f * 2 - t * 0.6) * math.pi * 2)
            local dr, dg, db = ac[1] * 0.55, ac[2] * 0.55, ac[3] * 0.55
            r, g, b = dr + (lr - dr) * w, dg + (lg - dg) * w, db + (lb - db) * w
        elseif mode == 2 then
            r, g, b = hsv_to_rgb(f - t * 0.3, 0.75, 1.0)
        else
            r, g, b = ac[1], ac[2], ac[3]
        end
        dl:AddLine(pts[i], pts[j], col32(r, g, b, 0.16), 5.0)
        dl:AddLine(pts[i], pts[j], col32(r, g, b, 0.95), 2.0)
    end
end

-- тень и рамка главного окна; при любой ошибке эффекты просто отключаются
local border_broken = false
local function draw_window_fx(x0, y0, x1, y1)
    if border_broken then return end
    local ok, err = pcall(function()
        if UI_CFG.shadow then
            local bl = imgui.GetBackgroundDrawList()
            for i = 1, 6 do
                local e = i * 3
                bl:AddRectFilled(imgui.ImVec2(x0 - e, y0 - e + 5), imgui.ImVec2(x1 + e, y1 + e + 5), col32(0, 0, 0, 0.045), 12 + e)
            end
        end
        if UI_CFG.border_mode ~= 0 then draw_border(x0, y0, x1, y1) end
    end)
    if not ok then
        border_broken = true
        log_error("window_fx", err)
    end
    if UI_CFG.halloween then UIFX.hw_safe(UIFX.hw_front, x0, y0, x1, y1) end
end

function apply_theme()
    local style = imgui.GetStyle()
    local clr = style.Colors
    local ac = UI_CFG.accent
    local function sets(name, v) pcall(function() style[name] = v end) end
    local function setc(name, v)
        local idx = imgui.Col[name]
        if idx ~= nil then clr[idx] = v end
    end
    -- размеры (отступы не меняем: вёрстка окон рассчитана на них)
    sets("WindowPadding", imgui.ImVec2(5, 5))
    sets("FramePadding", imgui.ImVec2(5, 5))
    sets("ItemSpacing", imgui.ImVec2(5, 5))
    sets("ItemInnerSpacing", imgui.ImVec2(2, 2))
    sets("WindowTitleAlign", imgui.ImVec2(0.5, 0.5))
    sets("ScrollbarSize", 10)
    sets("WindowBorderSize", 0)
    sets("PopupBorderSize", 0)
    sets("ChildBorderSize", 1)
    sets("FrameBorderSize", 0)
    -- скругления
    sets("WindowRounding", 12)
    sets("ChildRounding", 8)
    sets("FrameRounding", 6)
    sets("PopupRounding", 10)
    sets("ScrollbarRounding", 8)
    sets("GrabRounding", 6)
    sets("TabRounding", 6)
    -- цвета
    setc("Text", imgui.ImVec4(0.93, 0.94, 0.97, 1.00))
    setc("TextDisabled", imgui.ImVec4(0.52, 0.55, 0.62, 1.00))
    setc("WindowBg", dark(0.058, UI_CFG.opacity))
    setc("ChildBg", dark(0.080, 0.50))
    setc("PopupBg", dark(0.085, 0.98))
    setc("Border", imgui.ImVec4(ac[1], ac[2], ac[3], 0.20))
    setc("TitleBg", dark(0.058))
    setc("TitleBgActive", dark(0.058))
    setc("TitleBgCollapsed", dark(0.058))
    setc("FrameBg", dark(0.105))
    setc("FrameBgHovered", blend(0.105, 0.14))
    setc("FrameBgActive", blend(0.105, 0.22))
    setc("Button", dark(0.115))
    setc("ButtonHovered", blend(0.115, 0.30))
    setc("ButtonActive", blend(0.115, 0.50))
    setc("Header", blend(0.115, 0.22))
    setc("HeaderHovered", blend(0.115, 0.34))
    setc("HeaderActive", blend(0.115, 0.48))
    setc("ScrollbarBg", imgui.ImVec4(0, 0, 0, 0))
    setc("ScrollbarGrab", blend(0.12, 0.30))
    setc("ScrollbarGrabHovered", blend(0.12, 0.50))
    setc("ScrollbarGrabActive", blend(0.12, 0.75))
    setc("Separator", imgui.ImVec4(1, 1, 1, 0.07))
    setc("ModalWindowDimBg", imgui.ImVec4(0, 0, 0, 0.65))
    setc("CheckMark", accent_vec(1.15))
    setc("SliderGrab", accent_vec(1.0))
    setc("SliderGrabActive", accent_vec(1.25))
    setc("PlotHistogram", accent_vec(1.0))
    setc("TextSelectedBg", imgui.ImVec4(ac[1], ac[2], ac[3], 0.35))
    setc("ResizeGrip", imgui.ImVec4(ac[1], ac[2], ac[3], 0.45))
    setc("ResizeGripHovered", imgui.ImVec4(ac[1], ac[2], ac[3], 0.75))
    setc("ResizeGripActive", imgui.ImVec4(ac[1], ac[2], ac[3], 1.00))
end

-- ===================== Левая панель и калькулятор =====================
local SIDEBAR_W = 200
local LAYOUT = { w = 835, h = 500, tab_h = 46, block_y = 266, force = false } -- текущие размеры главного окна
local current_tab = 1 -- 1 = Arizona Prices, 2 = Калькулятор, 5 = О скрипте, 7 = Настройки

local calc_expr = ""
local calc_prev = ""
local calc_error = nil
local calc_fresh = false
local CALCFX = { hover = {}, press = {}, ripple = {}, hist = {}, hist_open = false, pop_t = -10, grown = false }

local function ic(name, fallback)
    return fa[name] or fallback
end

-- ===================== Всплывающие уведомления =====================
local toasts = {}
local TOAST_KINDS = {
    info = { icon = "CIRCLE_INFO",          color = nil },
    ok   = { icon = "CIRCLE_CHECK",         color = {0.30, 0.78, 0.45} },
    warn = { icon = "TRIANGLE_EXCLAMATION", color = {1.00, 0.75, 0.20} },
    err  = { icon = "CIRCLE_XMARK",         color = {0.92, 0.32, 0.32} },
}

local toast_broken = false

local function toast(text, kind, dur)
    if UI_CFG.toasts == false or toast_broken then return false end
    toasts[#toasts + 1] = { text = tostring(text), kind = TOAST_KINDS[kind] and kind or "info", t0 = os.clock(), dur = dur or 3.5 }
    if #toasts > 5 then table.remove(toasts, 1) end
    return true
end

-- уведомление: всплывающая карточка, а если они выключены - обычное сообщение в чат
local function notify(text, kind, dur)
    if not toast(text, kind, dur) then
        if sampAddChatMessage then
            pcall(sampAddChatMessage, u8:decode("{33AAFF}[Arizona Prices] {FFFFFF}" .. tostring(text)), -1)
        end
    end
end

-- карточки рисуются прямо на экране (без отдельных окон ImGui), поэтому ломать стек окон им нечем
local function draw_toasts()
    local now = os.clock()
    for i = #toasts, 1, -1 do
        if now - toasts[i].t0 > toasts[i].dur then table.remove(toasts, i) end
    end
    if #toasts == 0 then return end
    local dl = fg_list(imgui.GetBackgroundDrawList)
    local sw, sh = getScreenResolution()
    local corner = UI_CFG.toast_corner or 3 -- 0 слева сверху, 1 справа сверху, 2 слева снизу, 3 справа снизу
    local right = (corner == 1 or corner == 3)
    local bottom = (corner == 2 or corner == 3)
    local H, GAP, MARGIN = 46, 8, 20
    for i, t in ipairs(toasts) do
        local kind = TOAST_KINDS[t.kind] or TOAST_KINDS.info
        local ts = imgui.CalcTextSize(t.text)
        local w = math.min(760, ts.x + 84)
        local age = now - t.t0
        local pr = math.min(1, age / 0.25)
        local ease = 1 - (1 - pr) ^ 3
        local alpha = math.max(0, math.min(1, (t.dur - age) / 0.4))
        local off = (1 - ease) * (w + MARGIN + 10)
        local slot = #toasts - i
        local x = right and (sw - MARGIN - w + off) or (MARGIN - off)
        local y = bottom and (sh - MARGIN - 80 - H - slot * (H + GAP)) or (MARGIN + slot * (H + GAP))
        local c = kind.color or UI_CFG.accent
        local ty = y + (H - ts.y) / 2
        local p0, p1 = imgui.ImVec2(x, y), imgui.ImVec2(x + w, y + H)
        local cx, cy = x + 28, y + H / 2
        dl:AddRectFilled(p0, p1, col32(0.07, 0.075, 0.09, 0.96 * alpha), 10)
        pcall(function()
            dl:AddRect(p0, p1, col32(c[1], c[2], c[3], 0.60 * alpha), 10, 0, 1.5)
            dl:AddCircleFilled(imgui.ImVec2(cx, cy), 17, col32(c[1], c[2], c[3], 0.20 * alpha), 28)
        end)
        -- значок рисуем линиями, поэтому его размер не зависит от шрифта
        local icol = col32(c[1], c[2], c[3], alpha)
        local function seg(ax, ay, bx, by)
            dl:AddLine(imgui.ImVec2(cx + ax, cy + ay), imgui.ImVec2(cx + bx, cy + by), icol, 3.0)
        end
        if t.kind == "ok" then
            seg(-7, 0.5, -2.5, 5.5)
            seg(-2.5, 5.5, 7.5, -5.5)
            dl:AddCircleFilled(imgui.ImVec2(cx - 2.5, cy + 5.5), 1.5, icol, 12)
        elseif t.kind == "err" then
            seg(-6, -6, 6, 6)
            seg(-6, 6, 6, -6)
        elseif t.kind == "warn" then
            seg(0, -8, 0, 2)
            dl:AddCircleFilled(imgui.ImVec2(cx, cy + 7), 2.0, icol, 12)
        else
            dl:AddCircleFilled(imgui.ImVec2(cx, cy - 7), 2.0, icol, 12)
            seg(0, -2.5, 0, 8)
        end
        dl:AddText(imgui.ImVec2(x + 56, ty), col32(1, 1, 1, alpha), t.text)
    end
end

local toast_frame
toast_frame = imgui.OnFrame(
    function()
        toast_frame.HideCursor = true
        return #toasts > 0
    end,
    function()
        local ok, err = xpcall(draw_toasts, tb)
        if not ok then
            toast_broken = true
            toasts = {}
            log_error("toast", err)
            queue_notice("Карточки уведомлений отключены из-за ошибки, сообщения будут в чате", "warn")
        end
    end
)

-- CALC_LOGIC_BEGIN
local function group_digits(s)
    if s == "" then return "0" end
    local r = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
    if r:sub(1, 1) == "." then r = r:sub(2) end
    return r
end

local function calc_format_expr(expr)
    local out = expr:gsub("[%d%.]+", function(num)
        local ip, dp = num:match("^(%d*)%.(%d*)$")
        if ip then
            return group_digits(ip) .. "," .. dp
        end
        return group_digits(num)
    end)
    out = out:gsub("%*", " x "):gsub("/", " / "):gsub("%+", " + "):gsub("%-", " - ")
    out = out:gsub("^%s+", ""):gsub("%s+$", "")
    out = out:gsub("^%- ", "-")
    return out
end

local function calc_raw_number(x)
    if x >= 0 then
        x = math.floor(x * 100 + 0.5) / 100
    else
        x = -math.floor(-x * 100 + 0.5) / 100
    end
    local s = string.format("%.2f", x)
    s = s:gsub("0+$", ""):gsub("%.$", "")
    if s == "-0" or s == "" then s = "0" end
    return s
end

local function calc_eval(expr)
    local tokens = {}
    local i, n = 1, #expr
    while i <= n do
        local c = expr:sub(i, i)
        if c:match("[%d%.]") then
            local num = expr:match("^[%d%.]+", i)
            i = i + #num
            local v = tonumber(num)
            if not v then return nil, "Ошибка" end
            local pct = false
            if expr:sub(i, i) == "%" then
                pct = true
                i = i + 1
            end
            tokens[#tokens + 1] = {num = v, pct = pct}
        elseif c:match("[%+%-%*/]") then
            tokens[#tokens + 1] = {op = c}
            i = i + 1
        else
            return nil, "Ошибка"
        end
    end

    if tokens[#tokens] and tokens[#tokens].op then tokens[#tokens] = nil end

    local idx, sign = 1, 1
    if tokens[1] and tokens[1].op == "-" then
        sign = -1
        idx = 2
    end
    if idx > #tokens then return nil, "Ошибка" end

    local total, cur_op, first = 0, "+", true
    while idx <= #tokens do
        local tk = tokens[idx]
        if not tk.num then return nil, "Ошибка" end
        local term = tk.pct and (tk.num / 100) or tk.num
        local single = true
        idx = idx + 1

        while tokens[idx] and (tokens[idx].op == "*" or tokens[idx].op == "/") do
            local nx = tokens[idx + 1]
            if not nx or not nx.num then return nil, "Ошибка" end
            local val = nx.pct and (nx.num / 100) or nx.num
            if tokens[idx].op == "*" then
                term = term * val
            else
                if val == 0 then return nil, "Деление на ноль" end
                term = term / val
            end
            single = false
            idx = idx + 2
        end

        if first then
            term = term * sign
            total = term
            first = false
        else
            if single and tk.pct then term = total * tk.num / 100 end
            if cur_op == "+" then total = total + term else total = total - term end
        end

        local nxt = tokens[idx]
        if nxt then
            if nxt.op ~= "+" and nxt.op ~= "-" then return nil, "Ошибка" end
            cur_op = nxt.op
            idx = idx + 1
        end
    end
    return total
end

local function calc_reset_if_fresh()
    if calc_fresh then
        calc_expr = ""
        calc_prev = ""
        calc_fresh = false
    end
end

local function calc_digit(d)
    calc_error = nil
    calc_reset_if_fresh()
    if #calc_expr > 45 then return end
    if calc_expr:sub(-1) == "%" then return end
    local last = calc_expr:match("[%d%.]*$")
    if d == "000" then
        if last == "" or last == "0" then return end
        calc_expr = calc_expr .. "000"
        return
    end
    if last == "0" then
        if d == "0" then return end
        calc_expr = calc_expr:sub(1, -2) .. d
    else
        calc_expr = calc_expr .. d
    end
end

local function calc_dot()
    calc_error = nil
    calc_reset_if_fresh()
    if #calc_expr > 45 then return end
    if calc_expr:sub(-1) == "%" then return end
    local last = calc_expr:match("[%d%.]*$")
    if last:find(".", 1, true) then return end
    if last == "" then
        calc_expr = calc_expr .. "0."
    else
        calc_expr = calc_expr .. "."
    end
end

local function calc_op(op)
    calc_error = nil
    if calc_fresh then
        calc_fresh = false
        calc_prev = ""
    end
    if calc_expr == "" then
        if op == "-" then calc_expr = "-" end
        return
    end
    local lastc = calc_expr:sub(-1)
    if lastc:match("[%+%-%*/]") then
        if #calc_expr == 1 then return end
        calc_expr = calc_expr:sub(1, -2) .. op
    else
        if lastc == "." then calc_expr = calc_expr:sub(1, -2) end
        calc_expr = calc_expr .. op
    end
end

local function calc_percent()
    calc_error = nil
    if calc_fresh then
        calc_fresh = false
        calc_prev = ""
    end
    if calc_expr:sub(-1):match("%d") then
        calc_expr = calc_expr .. "%"
    end
end

local function calc_back()
    calc_error = nil
    if calc_fresh then
        calc_fresh = false
        calc_prev = ""
    end
    calc_expr = calc_expr:sub(1, -2)
end

local function calc_clear()
    calc_expr = ""
    calc_prev = ""
    calc_error = nil
    calc_fresh = false
end

local function calc_equals()
    if calc_expr == "" or calc_fresh then return end
    local res, err = calc_eval(calc_expr)
    if not res then
        calc_error = err or "Ошибка"
        return
    end
    local shown_expr = calc_format_expr(calc_expr)
    calc_prev = shown_expr .. " ="
    calc_expr = calc_raw_number(res)
    calc_fresh = true
    CALCFX.pop_t = imgui.GetTime()
    CALCFX.hist[#CALCFX.hist + 1] = { expr = shown_expr, res = calc_format_expr(calc_expr), raw = calc_expr }
    if #CALCFX.hist > 15 then table.remove(CALCFX.hist, 1) end
end
-- CALC_LOGIC_END

local function draw_sidebar_bg(wpos)
    local dl = imgui.GetWindowDrawList()
    local col = imgui.ColorConvertFloat4ToU32(dark(0.088, UIFX.m))
    dl:AddRectFilled(wpos, imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y + LAYOUT.h), col, 12)
    dl:AddRectFilled(imgui.ImVec2(wpos.x + 14, wpos.y), imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y + LAYOUT.h), col)
    dl:AddLine(imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y + 8), imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y + LAYOUT.h - 8), imgui.GetColorU32(imgui.Col.Separator), 1.0)
    if UI_CFG.halloween then UIFX.hw_safe(UIFX.hw_web, dl, wpos.x + 7, wpos.y + LAYOUT.h - 7, 84, 1, -1, 0.18) end
end

-- ===================== Эффекты интерфейса =====================
-- Устанавливает прозрачность всего, что рисуется дальше (и стандартных виджетов, и ручного рисования)
-- цвет и следующее значение ликвидности (клик по значению у разработчика переключает по кругу)
function UIFX.liq_color(l)
    if l == "Ликвид" then return imgui.ImVec4(0.45, 0.95, 0.55, 1) end
    if l == "Средне" then return imgui.ImVec4(1.00, 0.85, 0.40, 1) end
    if l == "Неликвид" then return imgui.ImVec4(1.00, 0.45, 0.45, 1) end
    return imgui.ImVec4(0.50, 0.52, 0.58, 1)
end

function UIFX.liq_next(l)
    if l == nil then return "Ликвид" end
    if l == "Ликвид" then return "Средне" end
    if l == "Средне" then return "Неликвид" end
    return nil
end

function UIFX.set_alpha(a)
    a = clamp(a, 0, 1)
    UIFX.m = a
    pcall(function() imgui.GetStyle().Alpha = a end)
end

-- Переключение вкладки с запуском анимации
function UIFX.go_tab(id)
    if id ~= current_tab then
        current_tab = id
        local now = imgui.GetTime()
        UIFX.tab_t, UIFX.table_t = now, now
    end
end

-- Вызывается в начале каждого кадра меню: плавное появление и исчезновение окна, заставка, горячие клавиши
function UIFX.tick()
    local dt = imgui.GetIO().DeltaTime
    local open = main_window[0]
    local target = open and 1 or 0
    UIFX.alpha = UIFX.alpha + (target - UIFX.alpha) * math.min(1, dt * (open and 11 or 15))
    if not open and UIFX.alpha < 0.03 then UIFX.alpha = 0 end
    if open and UIFX.alpha > 0.99 then UIFX.alpha = 1 end
    if open and not UIFX.was_open then
        local now = imgui.GetTime()
        UIFX.table_t, UIFX.tab_t = now, now
        if UI_CFG.splash and not UIFX.splashed then
            UIFX.splash_t = now
            UIFX.splashed = true
        end
    end
    UIFX.was_open = open
    if UIFX.pending_tab then
        UIFX.go_tab(UIFX.pending_tab)
        UIFX.pending_tab = nil
    end
end

-- Бегущая полоска слева у активной вкладки: плавно «переезжает» на новую
function UIFX.draw_bar(wpos)
    if not UIFX.bar_ty then return end
    local dt = imgui.GetIO().DeltaTime
    if not UIFX.bar_cur then UIFX.bar_cur = UIFX.bar_ty end
    UIFX.bar_cur = UIFX.bar_cur + (UIFX.bar_ty - UIFX.bar_cur) * math.min(1, dt * 16)
    local ac = UI_CFG.accent
    local x, y = wpos.x + UIFX.bar_x, wpos.y + UIFX.bar_cur
    imgui.GetWindowDrawList():AddRectFilled(imgui.ImVec2(x, y - 13), imgui.ImVec2(x + 3, y + 13),
        col32(math.min(1, ac[1] * 1.15), math.min(1, ac[2] * 1.15), math.min(1, ac[3] * 1.15), 1), 2)
end

-- Анимированный фон вкладки: медленные цветные пятна и поднимающиеся искры (рисуется под содержимым)
function UIFX.draw_bg()
    local p, s = imgui.GetWindowPos(), imgui.GetWindowSize()
    local dl = imgui.GetWindowDrawList()
    local t, ac = imgui.GetTime(), UI_CFG.accent
    for i = 1, 3 do
        local cx = p.x + s.x * (0.5 + 0.38 * math.sin(t * 0.11 * i + i * 2.1))
        local cy = p.y + s.y * (0.5 + 0.38 * math.cos(t * 0.09 * i + i * 1.3))
        for r = 4, 1, -1 do
            dl:AddCircleFilled(imgui.ImVec2(cx, cy), r * 55, col32(ac[1], ac[2], ac[3], 0.014), 32)
        end
    end
    for i = 1, 26 do
        local sp = 10 + (i * 7) % 17
        local x = p.x + ((i * 137) % 100) / 100 * s.x + math.sin(t * 0.5 + i) * 12
        local y = p.y + s.y - ((t * sp + i * 61) % (s.y + 20)) + 10
        local tw = 0.5 + 0.5 * math.sin(t * 1.5 + i * 1.7)
        dl:AddCircleFilled(imgui.ImVec2(x, y), 1.2 + (i % 3) * 0.7,
            col32(ac[1] * 0.5 + 0.5, ac[2] * 0.5 + 0.5, ac[3] * 0.5 + 0.5, 0.05 + 0.14 * tw), 8)
    end
end

-- ===================== Хэллоуин =====================
-- Всё рисуется простыми фигурами (круги, треугольники, линии). При любой ошибке украшения сами отключаются.
function UIFX.hw_safe(fn, ...)
    if UIFX.hw_broken then return end
    local ok, err = pcall(fn, ...)
    if not ok then
        UIFX.hw_broken = true
        pcall(log_error, "halloween", err)
    end
end

-- закрашенный треугольник (вершины переставляются, чтобы обход всегда был по часовой)
function UIFX.hw_tri(dl, col, ax, ay, bx, by, cx, cy)
    local V = imgui.ImVec2
    if (bx - ax) * (cy - ay) - (by - ay) * (cx - ax) < 0 then
        bx, by, cx, cy = cx, cy, bx, by
    end
    dl:AddTriangleFilled(V(ax, ay), V(bx, by), V(cx, cy), col)
end

-- тыква: cx, cy - центр, r - размер, k - прозрачность, hat - ведьмина шляпа
function UIFX.hw_pumpkin(dl, cx, cy, r, k, hat)
    local V = imgui.ImVec2
    local t = imgui.GetTime()
    local fl = 0.85 + 0.15 * math.sin(t * 7 + cx * 0.05) * math.sin(t * 3.1 + cy * 0.1) -- мерцание свечи внутри
    for i = 3, 1, -1 do
        dl:AddCircleFilled(V(cx, cy), r * (1.0 + i * 0.45), col32(1.0, 0.45, 0.05, 0.04 * k * fl), 28)
    end
    local top = cy - r * 0.78
    local side = col32(0.80, 0.33, 0.03, k)
    local body = col32(1.00, 0.52, 0.08, k)
    dl:AddCircleFilled(V(cx - r * 0.45, cy + r * 0.03), r * 0.62, side, 22)
    dl:AddCircleFilled(V(cx + r * 0.45, cy + r * 0.03), r * 0.62, side, 22)
    dl:AddCircleFilled(V(cx, cy), r * 0.78, body, 28)
    dl:AddCircleFilled(V(cx - r * 0.38, cy - r * 0.38), r * 0.13, col32(1.0, 0.82, 0.55, 0.35 * k), 12)
    -- лицо светится изнутри
    local fc = col32(1.0, 0.88, 0.30, k * fl)
    UIFX.hw_tri(dl, fc, cx - r * 0.55, cy - r * 0.02, cx - r * 0.18, cy - r * 0.02, cx - r * 0.36, cy - r * 0.34)
    UIFX.hw_tri(dl, fc, cx + r * 0.18, cy - r * 0.02, cx + r * 0.55, cy - r * 0.02, cx + r * 0.36, cy - r * 0.34)
    UIFX.hw_tri(dl, fc, cx - r * 0.08, cy + r * 0.14, cx + r * 0.08, cy + r * 0.14, cx, cy + r * 0.03)
    dl:AddRectFilled(V(cx - r * 0.58, cy + r * 0.26), V(cx + r * 0.58, cy + r * 0.48), fc, r * 0.06)
    for j = -2, 2, 2 do
        local x = cx + j * r * 0.22
        UIFX.hw_tri(dl, body, x - r * 0.09, cy + r * 0.26, x + r * 0.09, cy + r * 0.26, x, cy + r * 0.37)
    end
    for j = -1, 1, 2 do
        local x = cx + j * r * 0.22
        UIFX.hw_tri(dl, body, x - r * 0.09, cy + r * 0.48, x + r * 0.09, cy + r * 0.48, x, cy + r * 0.37)
    end
    if hat then
        local hc = col32(0.22, 0.10, 0.38, k)
        local hb = top + r * 0.12
        UIFX.hw_tri(dl, hc, cx - r * 0.55, hb - r * 0.05, cx + r * 0.55, hb - r * 0.05, cx + r * 0.22, hb - r * 1.35)
        dl:AddRectFilled(V(cx - r * 0.44, hb - r * 0.30), V(cx + r * 0.44, hb - r * 0.10), body, 2)
        dl:AddRectFilled(V(cx - r * 0.95, hb - r * 0.10), V(cx + r * 0.95, hb + r * 0.08), hc, r * 0.08)
    else
        local sc = col32(0.30, 0.45, 0.10, k)
        UIFX.hw_tri(dl, sc, cx - r * 0.10, top + r * 0.08, cx + r * 0.14, top + r * 0.08, cx + r * 0.20, top - r * 0.28)
        UIFX.hw_tri(dl, sc, cx - r * 0.10, top + r * 0.08, cx + r * 0.20, top - r * 0.28, cx - r * 0.02, top - r * 0.30)
    end
end

-- летучая мышь: x, y - центр, s - размер, fl - взмах крыльев (-1..1), k - прозрачность
function UIFX.hw_bat(dl, x, y, s, fl, k)
    local V = imgui.ImVec2
    local c = col32(0.36, 0.23, 0.52, 0.90 * k)
    local f = fl * s * 0.55
    for d = -1, 1, 2 do
        UIFX.hw_tri(dl, c, x, y - s * 0.15, x + d * s * 1.35, y - s * 0.45 + f, x + d * s * 0.85, y + s * 0.05)
        UIFX.hw_tri(dl, c, x, y - s * 0.15, x + d * s * 0.85, y + s * 0.05, x + d * s * 0.45, y + s * 0.32)
        UIFX.hw_tri(dl, c, x, y - s * 0.05, x + d * s * 0.45, y + s * 0.32, x, y + s * 0.22)
    end
    dl:AddCircleFilled(V(x, y + s * 0.02), s * 0.30, c, 12)
    UIFX.hw_tri(dl, c, x - s * 0.26, y - s * 0.12, x - s * 0.06, y - s * 0.22, x - s * 0.24, y - s * 0.52)
    UIFX.hw_tri(dl, c, x + s * 0.06, y - s * 0.22, x + s * 0.26, y - s * 0.12, x + s * 0.24, y - s * 0.52)
    local eye = col32(1.0, 0.40, 0.10, k)
    dl:AddCircleFilled(V(x - s * 0.11, y), s * 0.05, eye, 6)
    dl:AddCircleFilled(V(x + s * 0.11, y), s * 0.05, eye, 6)
end

-- паутина в углу: cx, cy - угол, size - размер, dx/dy - куда расходится (±1), a - прозрачность
function UIFX.hw_web(dl, cx, cy, size, dx, dy, a)
    local V = imgui.ImVec2
    local col = col32(0.85, 0.85, 1.0, a)
    local n = 5
    for k = 0, n do
        local ang = (k / n) * (math.pi / 2)
        dl:AddLine(V(cx, cy), V(cx + dx * math.cos(ang) * size, cy + dy * math.sin(ang) * size), col, 1.0)
    end
    for j = 1, 4 do
        local rr = size * j / 4
        for k = 0, n - 1 do
            local a1, a2, am = (k / n) * (math.pi / 2), ((k + 1) / n) * (math.pi / 2), ((k + 0.5) / n) * (math.pi / 2)
            local x1, y1 = cx + dx * math.cos(a1) * rr, cy + dy * math.sin(a1) * rr
            local x2, y2 = cx + dx * math.cos(a2) * rr, cy + dy * math.sin(a2) * rr
            local xm, ym = cx + dx * math.cos(am) * rr * 0.86, cy + dy * math.sin(am) * rr * 0.86
            dl:AddLine(V(x1, y1), V(xm, ym), col, 1.0)
            dl:AddLine(V(xm, ym), V(x2, y2), col, 1.0)
        end
    end
end

-- фон вкладки: луна, фиолетовое свечение, летучие мыши, паутина (рисуется под содержимым, внутри ##content)
function UIFX.hw_bg()
    local p, s = imgui.GetWindowPos(), imgui.GetWindowSize()
    local dl = imgui.GetWindowDrawList()
    local V = imgui.ImVec2
    local t = imgui.GetTime()
    local mx, my = p.x + s.x - 78, p.y + 70
    for i = 5, 1, -1 do
        dl:AddCircleFilled(V(mx, my), 40 + i * 14, col32(1.0, 0.82, 0.45, 0.012), 40)
    end
    dl:AddCircleFilled(V(mx, my), 40, col32(1.0, 0.90, 0.62, 0.15), 40)
    dl:AddCircleFilled(V(mx - 12, my - 8), 9, col32(0.9, 0.7, 0.4, 0.08), 16)
    dl:AddCircleFilled(V(mx + 14, my + 10), 6, col32(0.9, 0.7, 0.4, 0.08), 16)
    dl:AddCircleFilled(V(mx + 6, my - 20), 5, col32(0.9, 0.7, 0.4, 0.08), 16)
    local gx, gy = p.x + s.x * (0.30 + 0.20 * math.sin(t * 0.13)), p.y + s.y * (0.65 + 0.15 * math.cos(t * 0.10))
    for r = 4, 1, -1 do
        dl:AddCircleFilled(V(gx, gy), r * 60, col32(0.55, 0.20, 0.85, 0.016), 36)
    end
    for i = 1, 4 do
        local span = s.x + 140
        local bx = p.x - 70 + ((t * (22 + i * 6) + i * 173) % span)
        local by = p.y + s.y * (0.12 + 0.17 * i) + math.sin(t * 0.8 + i * 2.0) * 16
        UIFX.hw_bat(dl, bx, by, 10 + (i % 3) * 4, math.sin(t * 9 + i * 1.7), 0.85)
    end
    UIFX.hw_web(dl, p.x + s.x - 6, p.y + 6, 80, -1, 1, 0.20)
    UIFX.hw_web(dl, p.x + s.x - 6, p.y + s.y - 6, 100, -1, -1, 0.17)
end

-- тыквы сидят на верхней рамке окна (рисуются поверх, как и сама рамка)
function UIFX.hw_front(x0, y0, x1, y1)
    local dl = fg_list(imgui.GetWindowDrawList)
    UIFX.hw_pumpkin(dl, x1 - 135, y0 + 3 - 22 * 0.78, 22, 1, true)
    UIFX.hw_pumpkin(dl, x1 - 66, y0 + 3 - 16 * 0.78, 16, 1, false)
    UIFX.hw_pumpkin(dl, x0 + 80, y0 + 3 - 19 * 0.78, 19, 1, false)
end

local function sidebar_tab(label, id, tip)
    local active = (current_tab == id)
    local ac = UI_CFG.accent
    if active then
        imgui.PushStyleColor(imgui.Col.Button, blend(0.115, 0.28))
    end
    imgui.SetWindowFontScale(1.15)
    local clicked = imgui.Button(label .. "##tab" .. id, imgui.ImVec2(SIDEBAR_W - 10, LAYOUT.tab_h))
    local hovered = imgui.IsItemHovered()
    imgui.SetWindowFontScale(1.0)
    if clicked then UIFX.go_tab(id) end
    if hovered and tip then imgui.SetTooltip(tip) end
    if active then
        imgui.PopStyleColor(1)
        local rmin, rmax = imgui.GetItemRectMin(), imgui.GetItemRectMax()
        local wp = imgui.GetWindowPos()
        UIFX.bar_ty = (rmin.y + rmax.y) / 2 - wp.y
        UIFX.bar_x = rmin.x + 2 - wp.x
        -- мягкое свечение вокруг активной вкладки
        local dl = imgui.GetWindowDrawList()
        for i = 3, 1, -1 do
            dl:AddRect(imgui.ImVec2(rmin.x - i * 1.5, rmin.y - i * 1.5), imgui.ImVec2(rmax.x + i * 1.5, rmax.y + i * 1.5),
                col32(ac[1], ac[2], ac[3], 0.07 * (4 - i)), 8 + i, 15, 1.2)
        end
    end
end

-- ===================== Калькулятор: крупный экран, анимации, история =====================
-- Все вспомогательные функции лежат внутри таблицы CALCFX (так не расходуются локальные переменные скрипта)
function CALCFX.step(tbl, key, target, speed, dt)
    local v = tbl[key] or 0
    v = v + (target - v) * math.min(1, dt * speed)
    tbl[key] = v
    return v
end

-- Рисует одну кнопку калькулятора: плавная подсветка, свечение, "волна" от клика, нажатие вдавливает кнопку
function CALCFX.button(id, label, kind, w, h, action)
    local dl = imgui.GetWindowDrawList()
    local p = imgui.GetCursorScreenPos()
    local now = imgui.GetTime()
    local dt = imgui.GetIO().DeltaTime

    local clicked = imgui.InvisibleButton("##cb" .. id, imgui.ImVec2(w, h))
    local hovered, held = imgui.IsItemHovered(), imgui.IsItemActive()
    if clicked then
        local m = imgui.GetMousePos()
        CALCFX.ripple[id] = { t = now, x = m.x, y = m.y }
        action()
    end

    local hv = CALCFX.step(CALCFX.hover, id, hovered and 1 or 0, 14, dt)
    local pr = CALCFX.step(CALCFX.press, id, held and 1 or 0, 24, dt)

    -- базовый цвет по типу кнопки: 0 цифра, 1 действие, 2 "=", 3 сброс
    local br, bg, bb
    if kind == 2 then
        local a = UI_CFG.accent
        br, bg, bb = a[1], a[2], a[3]
    elseif kind == 3 then
        br, bg, bb = 0.55, 0.18, 0.20
    elseif kind == 1 then
        br, bg, bb = 0.20, 0.20, 0.23
    else
        br, bg, bb = 0.145, 0.145, 0.165
    end
    local lift = 0.07 * hv - 0.05 * pr
    local r, g, b = clamp(br + lift, 0, 1), clamp(bg + lift, 0, 1), clamp(bb + lift, 0, 1)

    local pad = 2.5 * pr -- при нажатии кнопка чуть уменьшается
    local x1, y1 = p.x + pad, p.y + pad
    local x2, y2 = p.x + w - pad, p.y + h - pad
    local round = 11

    -- мягкое свечение вокруг кнопки при наведении (у "=" пульсирует всегда)
    local ac = UI_CFG.accent
    local glow = hv
    if kind == 2 then glow = math.max(hv, 0.35 + 0.25 * math.sin(now * 3.0)) end
    if glow > 0.02 then
        for i = 3, 1, -1 do
            dl:AddRect(imgui.ImVec2(x1 - i * 1.6, y1 - i * 1.6), imgui.ImVec2(x2 + i * 1.6, y2 + i * 1.6),
                col32(ac[1], ac[2], ac[3], 0.10 * glow * (4 - i) / 3), round + i, 15, 1.4)
        end
    end

    dl:AddRectFilled(imgui.ImVec2(x1, y1), imgui.ImVec2(x2, y2), col32(r, g, b, 1), round)
    -- блик сверху
    dl:AddRectFilled(imgui.ImVec2(x1 + 2, y1 + 2), imgui.ImVec2(x2 - 2, y1 + (y2 - y1) * 0.45), col32(1, 1, 1, 0.045 + 0.03 * hv), round - 2)
    -- рамка
    local ba = 0.10 + 0.75 * hv
    dl:AddRect(imgui.ImVec2(x1, y1), imgui.ImVec2(x2, y2), col32(ac[1], ac[2], ac[3], ba), round, 15, 1.2)

    -- волна от места клика
    local rp = CALCFX.ripple[id]
    if rp then
        local k = (now - rp.t) / 0.5
        if k >= 1 then
            CALCFX.ripple[id] = nil
        else
            dl:PushClipRect(imgui.ImVec2(x1, y1), imgui.ImVec2(x2, y2), true)
            dl:AddCircleFilled(imgui.ImVec2(rp.x, rp.y), k * math.max(w, h) * 1.1, col32(1, 1, 1, 0.30 * (1 - k)), 32)
            dl:PopClipRect()
        end
    end

    -- подпись по центру
    local ts = imgui.CalcTextSize(label)
    dl:AddText(imgui.ImVec2(p.x + (w - ts.x) / 2, p.y + (h - ts.y) / 2 + pr), col32(1, 1, 1, 0.95), label)
end

-- Крупный экран: прошлое выражение сверху, результат крупно, при "=" цифры "выпрыгивают"
function CALCFX.display(w, h)
    local now = imgui.GetTime()
    local ac = UI_CFG.accent
    local p = imgui.GetCursorScreenPos()
    local dl = imgui.GetWindowDrawList()

    local flash = clamp(1 - (now - CALCFX.pop_t) / 0.6, 0, 1)
    dl:AddRectFilled(p, imgui.ImVec2(p.x + w, p.y + h), col32(0.075, 0.075, 0.09, 1), 14)
    dl:AddRectFilled(p, imgui.ImVec2(p.x + w, p.y + h), col32(ac[1], ac[2], ac[3], 0.05 + 0.10 * flash), 14)
    dl:AddRect(p, imgui.ImVec2(p.x + w, p.y + h), col32(ac[1], ac[2], ac[3], 0.35 + 0.55 * flash), 14, 15, 1.5)

    local fs = clamp(h / 100 * 1.9, 1.7, 3.2)
    local shown, color
    if calc_error then
        shown, color = calc_error, { 1.0, 0.38, 0.38 }
    else
        shown, color = (calc_expr == "") and "0" or calc_format_expr(calc_expr), { 1, 1, 1 }
    end

    -- предыдущее выражение (мелко, справа сверху)
    imgui.SetWindowFontScale(1.1)
    local prev = calc_prev ~= "" and calc_prev or ""
    local ps = imgui.CalcTextSize(prev)
    dl:AddText(imgui.ImVec2(p.x + w - 16 - ps.x, p.y + 10), col32(0.62, 0.62, 0.68, 1), prev)

    -- основной текст: подбираем размер, чтобы влез, плюс "прыжок" после "="
    local pop = 1 + 0.16 * flash * flash
    local scale = fs
    imgui.SetWindowFontScale(scale)
    while scale > 0.9 and imgui.CalcTextSize(shown).x > (w - 36) / pop do
        scale = scale - 0.1
        imgui.SetWindowFontScale(scale)
    end
    local ts = imgui.CalcTextSize(shown)
    local s2 = scale * pop
    imgui.SetWindowFontScale(s2)
    ts = imgui.CalcTextSize(shown)
    local tx = p.x + w - 18 - ts.x
    local ty = p.y + h - 12 - ts.y + 4 * (1 - flash)
    dl:AddText(imgui.ImVec2(tx + 1.5, ty + 1.5), col32(0, 0, 0, 0.5), shown)
    dl:AddText(imgui.ImVec2(tx, ty), col32(color[1], color[2], color[3], 1), shown)
    imgui.SetWindowFontScale(1.0)

    imgui.Dummy(imgui.ImVec2(w, h))
end

-- Панель истории: клик по записи подставляет результат обратно в калькулятор
function CALCFX.history(w, h)
    local ac = UI_CFG.accent
    if imgui.BeginChild("##calc_hist", imgui.ImVec2(w, h), true) then
        imgui.TextColored(accent_vec(1.2), ic("CLOCK_ROTATE_LEFT", "") .. " История")
        imgui.Separator()
        if #CALCFX.hist == 0 then
            imgui.TextColored(imgui.ImVec4(0.55, 0.55, 0.6, 1), "Пока пусто")
        else
            for i = #CALCFX.hist, 1, -1 do
                local e = CALCFX.hist[i]
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, accent_vec(1.0, 0.25))
                imgui.PushStyleColor(imgui.Col.ButtonActive, accent_vec(1.0, 0.4))
                if imgui.Button(e.res .. "##h" .. i, imgui.ImVec2(-1, 34)) then
                    calc_expr, calc_prev, calc_error, calc_fresh = e.raw, "", nil, false
                end
                imgui.PopStyleColor(3)
                imgui.TextColored(imgui.ImVec4(0.55, 0.55, 0.6, 1), e.expr)
                imgui.Spacing()
            end
        end
        if #CALCFX.hist > 0 then
            if imgui.Button("Очистить##hclr", imgui.ImVec2(-1, 28)) then CALCFX.hist = {} end
        end
    end
    imgui.EndChild()
end

local function draw_calculator()
    local sw, sh = getScreenResolution()
    -- при первом заходе во вкладку растягиваем окно, чтобы калькулятору хватило места
    if not CALCFX.grown then
        CALCFX.grown = true
        if LAYOUT.w < 960 or LAYOUT.h < 640 then
            LAYOUT.req = { w = math.min(math.max(LAYOUT.w, 980), sw - 40), h = math.min(math.max(LAYOUT.h, 660), sh - 40) }
        end
    end

    -- Шапка
    imgui.AlignTextToFramePadding()
    imgui.SetCursorPosX(9)
    imgui.Text(ic("CALCULATOR", "") .. " Калькулятор")
    imgui.SameLine(LAYOUT.w - SIDEBAR_W - 76)
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))
    if imgui.Button(ic("CLOCK_ROTATE_LEFT", "H") .. "##calc_hist_btn", imgui.ImVec2(30, 24)) then
        CALCFX.hist_open = not CALCFX.hist_open
    end
    imgui.SameLine(LAYOUT.w - SIDEBAR_W - 29)
    if imgui.Button(FA.CIRCLE_XMARK .. "##close_calc", imgui.ImVec2(24, 24)) then
        main_window[0] = false
    end
    if imgui.IsItemHovered() then imgui.SetTooltip("Закрыть") end
    imgui.PopStyleColor(1)
    imgui.Spacing()

    local avail = imgui.GetContentRegionAvail()
    local gap = 9
    local hist_w = CALCFX.hist_open and 200 or 0
    local area_w = avail.x - hist_w - (hist_w > 0 and 12 or 0) - 16
    local cw = clamp(area_w, 300, 720)
    local disp_h = clamp(avail.y * 0.25, 92, 160)
    local btn_h = clamp((avail.y - disp_h - 6 * gap - 6) / 5, 40, 110)
    local btn_w = (cw - 3 * gap) / 4
    local x0 = 8 + math.max(0, (area_w - cw) / 2)
    local y0 = imgui.GetCursorPosY()

    imgui.SetCursorPos(imgui.ImVec2(x0, y0))
    CALCFX.display(cw, disp_h)

    local function d(n) return function() calc_digit(n) end end
    local function o(n) return function() calc_op(n) end end
    local rows = {
        { {"C", calc_clear, 3}, {ic("DELETE_LEFT", "<"), calc_back, 1}, {ic("PERCENT", "%"), calc_percent, 1}, {ic("DIVIDE", "/"), o("/"), 1} },
        { {"7", d("7"), 0}, {"8", d("8"), 0}, {"9", d("9"), 0}, {ic("XMARK", "x"), o("*"), 1} },
        { {"4", d("4"), 0}, {"5", d("5"), 0}, {"6", d("6"), 0}, {ic("MINUS", "-"), o("-"), 1} },
        { {"1", d("1"), 0}, {"2", d("2"), 0}, {"3", d("3"), 0}, {ic("PLUS", "+"), o("+"), 1} },
        { {"0", d("0"), 0}, {"000", d("000"), 0}, {",", calc_dot, 0}, {ic("EQUALS", "="), calc_equals, 2} },
    }

    imgui.SetWindowFontScale(clamp(btn_h / 54 * 1.25, 1.2, 2.0))
    for r, row in ipairs(rows) do
        imgui.SetCursorPos(imgui.ImVec2(x0, y0 + disp_h + gap + (r - 1) * (btn_h + gap)))
        for c, b in ipairs(row) do
            if c > 1 then imgui.SameLine(0, gap) end
            CALCFX.button(r .. "_" .. c, b[1], b[3], btn_w, btn_h, b[2])
        end
    end
    imgui.SetWindowFontScale(1.0)

    if hist_w > 0 then
        imgui.SetCursorPos(imgui.ImVec2(x0 + cw + 12 + math.max(0, (area_w - cw) / 2) * 0, y0))
        CALCFX.history(hist_w, disp_h + 5 * (btn_h + gap))
    end
end

-- ===================== Новые разделы: фразы, о скрипте =====================
local settings_path = getWorkingDirectory() .. "\\config\\arizona_prices_settings.json"
local settings = { ui = UI_CFG, favs = {}, notes = "", phrases = {}, clock = { enabled = false, country = "Узбекистан", x = 20, y = 340 } }

local function load_settings()
    local data = safe_read_json(settings_path)
    if not data then return end
    if type(data.phrases) == "table" then
        local ph = {}
        for _, v in ipairs(data.phrases) do
            if type(v) == "string" and v ~= "" then ph[#ph + 1] = v end
        end
        settings.phrases = ph
    end
    if type(data.clock) == "table" then
        settings.clock.enabled = (data.clock.enabled == true)
        if type(data.clock.country) == "string" then settings.clock.country = data.clock.country end
        settings.clock.x = tonumber(data.clock.x) or 20
        settings.clock.y = tonumber(data.clock.y) or 340
    end
    if type(data.favs) == "table" then
        local f = {}
        for k, v in pairs(data.favs) do
            if type(k) == "string" and v == true then f[k] = true end
        end
        settings.favs = f
    end
    if type(data.notes) == "string" then settings.notes = data.notes:sub(1, 8000) end
    if type(data.ui) == "table" then
        local u = data.ui
        if type(u.accent) == "table" and tonumber(u.accent[1]) and tonumber(u.accent[2]) and tonumber(u.accent[3]) then
            UI_CFG.accent = { clamp(tonumber(u.accent[1]), 0, 1), clamp(tonumber(u.accent[2]), 0, 1), clamp(tonumber(u.accent[3]), 0, 1) }
        end
        UI_CFG.opacity = clamp(tonumber(u.opacity) or 1.0, 0.3, 1.0)
        UI_CFG.overlay_scale = clamp(tonumber(u.overlay_scale) or 1.0, 0.7, 2.0)
        UI_CFG.open_key = math.max(0, math.floor(tonumber(u.open_key) or 0))
        UI_CFG.toasts = (u.toasts ~= false)
        UI_CFG.toast_corner = clamp(math.floor(tonumber(u.toast_corner) or 3), 0, 3)
        UI_CFG.border_mode = clamp(math.floor(tonumber(u.border_mode) or 1), 0, 3)
        UI_CFG.border_speed = clamp(tonumber(u.border_speed) or 1.0, 0.2, 3.0)
        UI_CFG.shadow = (u.shadow ~= false)
        UI_CFG.bg_fx = (u.bg_fx ~= false)
        UI_CFG.splash = (u.splash ~= false)
        if u.halloween == nil then
            UI_CFG.halloween = true
            UI_CFG.accent = { 0.98, 0.55, 0.12 }
        else
            UI_CFG.halloween = (u.halloween == true)
        end
        if type(u.font) == "string" then UI_CFG.font = u.font end
        UI_CFG.win_w = clamp(math.floor(tonumber(u.win_w) or 835), 700, 2400)
        UI_CFG.win_h = clamp(math.floor(tonumber(u.win_h) or 500), 400, 1400)
    end
end

local function save_settings()
    local dir = getWorkingDirectory() .. "\\config"
    if not doesDirectoryExist(dir) then
        createDirectory(dir)
    end
    local ok, json = pcall(encodeJson, settings)
    if ok and type(json) == "string" and json ~= "" then
        safe_write(settings_path, json)
    end
end

safe_call("load_settings", load_settings)

-- избранные предметы

function UIFX.toggle_fav(name)
    if settings.favs[name] then settings.favs[name] = nil else settings.favs[name] = true end
    save_settings()
end

local function section_header(icon, title)
    imgui.AlignTextToFramePadding()
    imgui.SetCursorPosX(9)
    imgui.Text(icon .. " " .. title)
    imgui.SameLine(LAYOUT.w - SIDEBAR_W - 29)
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))
    if imgui.Button(FA.CIRCLE_XMARK .. "##close_section", imgui.ImVec2(24, 24)) then
        main_window[0] = false
    end
    if imgui.IsItemHovered() then imgui.SetTooltip("Закрыть") end
    imgui.PopStyleColor(1)
    imgui.Spacing()
end


local about_links = {
    { icon = "GLOBE", title = "Сайт скрипта", sub = "Гайд по установке и ссылки", url = "https://hydracrmpdesign-commits.github.io/arizona-prices/", color = {0.96, 0.62, 0.15} },
    { icon = "PAPER_PLANE", logo = "tg", title = "Telegram-канал",              sub = "Актуальные цены и новости",    url = "https://t.me/arizona_prices",                 color = {0.16, 0.62, 0.86} },
    { icon = "COMMENTS",    logo = "ds", title = "Discord-канал",               sub = "Общение и обновления",         url = "https://discord.gg/z4UmCnRwd",                color = {0.35, 0.40, 0.95} },
    { icon = "MUSIC",       logo = "tt", title = "TikTok-канал",                sub = "Видео и обзоры",               url = "https://www.tiktok.com/@cosmychesky_jetpack", color = {0.86, 0.15, 0.40} },
    { icon = "USER",        logo = "ds", title = "Discord разработчика",        sub = "Нажми, чтобы скопировать ник", copy = "vasyablackwoode", color = {0.35, 0.40, 0.95} },
    { icon = "PAPER_PLANE", logo = "tg", title = "ЛС Разработчика",             sub = "Баги, идеи, предложения",      url = "https://t.me/arzprices_ceo",                      color = {0.16, 0.62, 0.86} },
    { icon = "PAPER_PLANE", logo = "tg", title = "ЛС Разработчика 2",           sub = "Кодер",                        url = "https://t.me/obrezik",                        color = {0.16, 0.62, 0.86} },
}

-- ===================== Вкладка "О скрипте" =====================
UIFX.about = { hv = {} }

-- светлая версия цвета (k: 0 = белый, 1 = сам цвет) сразу в формате col32
function UIFX.alc(c, k, a)
    return col32(c[1] * k + (1 - k), c[2] * k + (1 - k), c[3] * k + (1 - k), a)
end

function UIFX.about_body()
    local V = imgui.ImVec2
    local now = imgui.GetTime()
    local dt = imgui.GetIO().DeltaTime
    local ac = UI_CFG.accent
    local dl = imgui.GetWindowDrawList()
    local avail = imgui.GetContentRegionAvail().x
    local p = imgui.GetCursorScreenPos()
    local appear = clamp((now - UIFX.table_t) / 0.9, 0, 1)
    local ae = 1 - (1 - appear) ^ 3

    -- ---------- шапка ----------
    local hh = 150
    local x0, y0, x1, y1 = p.x, p.y, p.x + avail, p.y + hh
    local bg = dark(0.055)
    dl:AddRectFilled(V(x0, y0), V(x1, y1), col32(bg.x, bg.y, bg.z, 1), 14)
    for i = 0, 7 do
        local k = i / 8
        dl:AddRectFilled(V(x0, y0), V(x1, y0 + hh * (1 - k)), col32(ac[1], ac[2], ac[3], 0.040), 14)
    end
    dl:PushClipRect(V(x0, y0), V(x1, y1), true)
    for i = 1, 3 do
        local ox = avail * (0.25 + 0.25 * i) + math.sin(now * (0.5 + i * 0.17) + i) * 40
        local oy = y0 + hh * 0.5 + math.cos(now * (0.4 + i * 0.13) + i * 2) * 26
        for r = 6, 1, -1 do
            dl:AddCircleFilled(V(x0 + ox, oy), 18 * r * 0.9, col32(ac[1], ac[2], ac[3], 0.018), 32)
        end
    end
    dl:PopClipRect()
    dl:AddRect(V(x0, y0), V(x1, y1), col32(ac[1], ac[2], ac[3], 0.55), 14, 0, 1.4)

    -- значок
    local ls = 96
    local lx, ly = x0 + 24, y0 + (hh - ls) / 2 - 2 * math.sin(now * 1.6)
    for k = 4, 1, -1 do
        dl:AddRectFilled(V(lx - k * 3, ly - k * 3), V(lx + ls + k * 3, ly + ls + k * 3), col32(ac[1], ac[2], ac[3], 0.05), 22 + k * 3)
    end
    local logo = UIFX.logo_tex and UIFX.logo_tex() or nil
    if logo then
        UIFX.photo(dl, logo, V(lx, ly), V(lx + ls, ly + ls), 0, col32(1, 1, 1, 1), ls / 2)
        dl:AddCircle(V(lx + ls / 2, ly + ls / 2), ls / 2, col32(ac[1], ac[2], ac[3], 0.9), 48, 1.6)
    else
        -- запасной вариант, если картинка не загрузилась: старый значок с долларом
        dl:AddRectFilled(V(lx, ly), V(lx + ls, ly + ls), col32(ac[1], ac[2], ac[3], 1), 20)
        UIFX.grad(dl, lx + 3, ly + 3, lx + ls - 3, ly + ls * 0.55, 0.35, 0.0, 1, 1, 1)
        imgui.SetWindowFontScale(2.6)
        local gi = ic("CIRCLE_DOLLAR", "$")
        local gs = imgui.CalcTextSize(gi)
        dl:AddText(V(lx + (ls - gs.x) / 2, ly + (ls - gs.y) / 2), col32(0.06, 0.05, 0.04, 1), gi)
    end

    -- название
    local tx = lx + ls + 22
    imgui.SetWindowFontScale(2.0)
    local ts = imgui.CalcTextSize("ARIZONA PRICES")
    local ty = y0 + 26
    dl:AddText(V(tx + 2, ty + 2), col32(0, 0, 0, 0.55), "ARIZONA PRICES")
    dl:AddText(V(tx, ty), col32(1, 1, 1, 1), "ARIZONA PRICES")
    imgui.SetWindowFontScale(1.1)
    dl:AddText(V(tx, ty + ts.y + 4), UIFX.alc(ac, 0.55, 0.95), "Актуальные цены на аксессуары и скины")
    imgui.SetWindowFontScale(1.0)

    -- плашки: версия и автообновление
    local by = y1 - 38
    local vtxt = "v" .. SCRIPT_VERSION
    local vs = imgui.CalcTextSize(vtxt)
    dl:AddRectFilled(V(tx, by), V(tx + vs.x + 22, by + 24), col32(ac[1], ac[2], ac[3], 0.22), 12)
    dl:AddRect(V(tx, by), V(tx + vs.x + 22, by + 24), col32(ac[1], ac[2], ac[3], 0.9), 12, 0, 1.2)
    dl:AddText(V(tx + 11, by + (24 - vs.y) / 2), UIFX.alc(ac, 0.4, 1), vtxt)
    local on = UIFX.get_auto and UIFX.get_auto() or false
    local stxt = on and "Автообновление цен включено" or "Автообновление цен выключено"
    local ss = imgui.CalcTextSize(stxt)
    local sx = tx + vs.x + 22 + 10
    local sc = on and { 0.30, 0.85, 0.45 } or { 0.90, 0.45, 0.35 }
    dl:AddRectFilled(V(sx, by), V(sx + ss.x + 36, by + 24), col32(sc[1], sc[2], sc[3], 0.14), 12)
    local pulse = 0.55 + 0.45 * math.sin(now * 3)
    dl:AddCircleFilled(V(sx + 14, by + 12), 6, col32(sc[1], sc[2], sc[3], 0.25 * pulse), 16)
    dl:AddCircleFilled(V(sx + 14, by + 12), 3.5, col32(sc[1], sc[2], sc[3], 1), 16)
    dl:AddText(V(sx + 26, by + (24 - ss.y) / 2), UIFX.alc(sc, 0.5, 1), stxt)
    imgui.Dummy(V(avail, hh + 12))

    -- ---------- цифры ----------
    local nitems = #items_list
    local stats = {
        { label = "Предметов в базе",      value = nitems,              icon = "LIST" },
        { label = "Ссылок и контактов",    value = #about_links,        icon = "LINK" },
    }
    local gap = 10
    local cw = math.floor((avail - gap * (#stats - 1)) / #stats)
    local ch = 62
    for i, st in ipairs(stats) do
        if i > 1 then imgui.SameLine(0, gap) end
        local q = imgui.GetCursorScreenPos()
        imgui.Dummy(V(cw, ch))
        local ra = clamp((now - UIFX.table_t - 0.10 - (i - 1) * 0.07) / 0.35, 0, 1)
        local re = 1 - (1 - ra) ^ 3
        UIFX.set_alpha(UIFX.base * re)
        local cb = dark(0.085)
        local qy = q.y + (1 - re) * 12
        dl:AddRectFilled(V(q.x, qy), V(q.x + cw, qy + ch), col32(cb.x, cb.y, cb.z, 1), 12)
        dl:AddRect(V(q.x, qy), V(q.x + cw, qy + ch), col32(ac[1], ac[2], ac[3], 0.28), 12, 0, 1.0)
        dl:AddRectFilled(V(q.x + 12, qy + 14), V(q.x + 15, qy + ch - 14), col32(ac[1], ac[2], ac[3], 1), 2)
        imgui.SetWindowFontScale(1.55)
        local num = tostring(math.floor(st.value * re + 0.5))
        dl:AddText(V(q.x + 26, qy + 7), UIFX.alc(ac, 0.55, 1), num)
        imgui.SetWindowFontScale(1.0)
        dl:AddText(V(q.x + 26, qy + ch - 24), col32(1, 1, 1, 0.55), st.label)
        local gl = ic(st.icon, "")
        local gls = imgui.CalcTextSize(gl)
        dl:AddText(V(q.x + cw - gls.x - 16, qy + (ch - gls.y) / 2), col32(ac[1], ac[2], ac[3], 0.55), gl)
    end
    UIFX.set_alpha(UIFX.base)
    imgui.Dummy(V(0, 8))

    -- ---------- заголовок раздела ----------
    local hp = imgui.GetCursorScreenPos()
    imgui.SetWindowFontScale(1.15)
    dl:AddText(V(hp.x + 4, hp.y), col32(1, 1, 1, 0.92), "Мы в соцсетях и связь с разработчиком")
    local hs = imgui.CalcTextSize("Мы в соцсетях и связь с разработчиком")
    imgui.SetWindowFontScale(1.0)
    dl:AddRectFilled(V(hp.x + 4, hp.y + hs.y + 3), V(hp.x + 4 + 46, hp.y + hs.y + 5), col32(ac[1], ac[2], ac[3], 1), 1)
    dl:AddRectFilled(V(hp.x + 56, hp.y + hs.y + 3.5), V(hp.x + avail, hp.y + hs.y + 4.5), col32(1, 1, 1, 0.08), 1)
    imgui.Dummy(V(avail, hs.y + 14))

    -- ---------- карточки ссылок ----------
    local cols = (avail >= 500) and 2 or 1
    local lw = math.floor((avail - gap * (cols - 1)) / cols)
    local lh = 66
    for i, l in ipairs(about_links) do
        if (i - 1) % cols ~= 0 then imgui.SameLine(0, gap) end
        local q = imgui.GetCursorScreenPos()
        local clicked = imgui.InvisibleButton("##about_link" .. i, V(lw, lh + gap - 2))
        local hv = imgui.IsItemHovered() and 1 or 0
        if hv == 1 then pcall(function() imgui.SetMouseCursor(imgui.MouseCursor.Hand) end) end
        local cur = UIFX.about.hv[i] or 0
        cur = cur + (hv - cur) * math.min(1, dt * 14)
        UIFX.about.hv[i] = cur
        if clicked then
            if l.url then
                open_url(l.url)
            elseif l.copy then
                imgui.SetClipboardText(l.copy)
                notify("Ник скопирован: " .. l.copy, "ok")
            end
        end
        local ra = clamp((now - UIFX.table_t - 0.25 - (i - 1) * 0.06) / 0.30, 0, 1)
        local re = 1 - (1 - ra) ^ 3
        UIFX.set_alpha(UIFX.base * re)
        local c = l.color
        local cx0, cy0 = q.x, q.y + (1 - re) * 14 - cur * 2
        local cx1, cy1 = cx0 + lw, cy0 + lh
        if cur > 0.02 then
            for k = 4, 1, -1 do
                dl:AddRectFilled(V(cx0 - k * 2, cy0 - k * 2), V(cx1 + k * 2, cy1 + k * 2 + 2), col32(c[1], c[2], c[3], 0.05 * cur), 14 + k * 2)
            end
        end
        local cb = dark(0.085 + 0.02 * cur)
        dl:AddRectFilled(V(cx0, cy0), V(cx1, cy1), col32(cb.x, cb.y, cb.z, 1), 12)
        dl:AddRectFilled(V(cx0, cy0), V(cx1, cy1), col32(c[1], c[2], c[3], 0.04 + 0.14 * cur), 12)
        dl:AddRect(V(cx0, cy0), V(cx1, cy1), col32(c[1], c[2], c[3], 0.25 + 0.65 * cur), 12, 0, 1.0 + 0.6 * cur)
        -- иконка в цветном круге
        local cr = 25
        local ccx, ccy = cx0 + 16 + cr, cy0 + lh / 2
        local ltex = l.logo and UIFX.icon_tex and UIFX.icon_tex(l.logo) or nil
        dl:AddCircleFilled(V(ccx, ccy), cr + 3 + 3 * cur, col32(c[1], c[2], c[3], 0.20 + 0.12 * cur), 40)
        if ltex then
            -- официальный логотип занимает весь кружок
            UIFX.photo(dl, ltex, V(ccx - cr, ccy - cr), V(ccx + cr, ccy + cr), 0, col32(1, 1, 1, 1), cr)
        else
            dl:AddCircleFilled(V(ccx, ccy), cr - 3, col32(c[1], c[2], c[3], 1), 32)
            imgui.SetWindowFontScale(1.2)
            local gl = ic(l.icon, "")
            local gls = imgui.CalcTextSize(gl)
            dl:AddText(V(ccx - gls.x / 2, ccy - gls.y / 2), 0xFFFFFFFF, gl)
            imgui.SetWindowFontScale(1.0)
        end
        -- текст
        local tx2 = ccx + cr + 16
        imgui.SetWindowFontScale(1.1)
        dl:AddText(V(tx2, cy0 + 13), col32(1, 1, 1, 0.97), l.title)
        imgui.SetWindowFontScale(1.0)
        dl:AddText(V(tx2, cy0 + 37), col32(1, 1, 1, 0.50), l.sub or "")
        -- стрелка справа
        local ar = ic(l.copy and "COPY" or "ARROW_UP_RIGHT_FROM_SQUARE", ">")
        local ars = imgui.CalcTextSize(ar)
        dl:AddText(V(cx1 - ars.x - 18 + cur * 2, cy0 + (lh - ars.y) / 2), col32(c[1], c[2], c[3], 0.45 + 0.55 * cur), ar)
    end
    UIFX.set_alpha(UIFX.base)

    -- ---------- подпись ----------
    imgui.Dummy(V(0, 6))
    local fp = imgui.GetCursorScreenPos()
    local msg = "Спасибо, что пользуешься скриптом!  Нашёл ошибку или есть идея - пиши разработчику."
    local ms = imgui.CalcTextSize(msg)
    dl:AddText(V(fp.x + math.max(0, (avail - ms.x) / 2), fp.y), col32(1, 1, 1, 0.45), msg)
    imgui.Dummy(V(avail, ms.y + 14))
end

local function draw_about_tab()
    section_header(ic("CIRCLE_INFO", ""), "О скрипте")
    if imgui.BeginChild("##about_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then
        local ok, err = pcall(UIFX.about_body)
        if not ok then
            UIFX.set_alpha(UIFX.base)
            imgui.SetWindowFontScale(1.0)
            log_error("about_tab", err)
            imgui.TextWrapped("Вкладка временно недоступна. Подробности в файле arizona_prices_errors.log")
        end
    end
    imgui.EndChild()
end


-- ===================== Автообновление (скрипт и цены) =====================
-- (версия задана в начале файла: SCRIPT_VERSION)
local UPDATE_BASE = "https://raw.githubusercontent.com/hydracrmpdesign-commits/arizona-prices/main/"
local CHECK_EVERY = 1800 -- проверять обновления раз в 30 минут
local cfg_dir = getWorkingDirectory() .. "\\config\\"
local cache_dir = cfg_dir .. "arizona_prices_cache\\"  -- картинки интерфейса: их можно удалить, скрипт пересоздаст
local function ensure_cache()
    if not doesDirectoryExist(cache_dir) then createDirectory(cache_dir) end
end
local state_path = cfg_dir .. "arizona_prices_state.json"
local state = { prices_sig = "", auto_prices = true }
function UIFX.get_auto() return state.auto_prices ~= false end
local update_info = { available = false, version = "", busy = false, status = "" }
local dl_done = {}
local need_reload = false
local manual_check = false
local busy_since = 0

local ok_moon, moon = pcall(require, 'moonloader')
local dlstatus = ok_moon and moon.download_status or nil

local function read_file(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local c = f:read("*a")
    f:close()
    return c
end

local function write_file(path, content)
    local f = io.open(path, "wb")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

local function load_state()
    local c = read_file(state_path)
    if c then
        local ok, d = pcall(decodeJson, c)
        if ok and type(d) == "table" then
            if type(d.prices_sig) == "string" then state.prices_sig = d.prices_sig end
            if d.auto_prices == false then state.auto_prices = false end
        end
    end
end

local function save_state()
    if not doesDirectoryExist(cfg_dir) then createDirectory(cfg_dir) end
    safe_write(state_path, encodeJson(state))
end

safe_call("load_state", load_state)

local auto_prices_cb = imgui.new.bool(state.auto_prices)

local function version_newer(remote, current)
    local a, b = {}, {}
    for n in tostring(remote):gmatch("%d+") do a[#a + 1] = tonumber(n) end
    for n in tostring(current):gmatch("%d+") do b[#b + 1] = tonumber(n) end
    for i = 1, math.max(#a, #b) do
        local x, y = a[i] or 0, b[i] or 0
        if x ~= y then return x > y end
    end
    return false
end

local function signature(s)
    local sum = 0
    for i = 1, #s do sum = (sum * 31 + s:byte(i)) % 4294967291 end
    return #s .. ":" .. sum
end

-- скачивание: сам колбэк только ставит флаг, всю работу делает основной поток
local function fetch(name, dest, flag)
    os.remove(dest)
    if not dlstatus or not downloadUrlToFile then
        update_info.status = "Загрузка недоступна"
        return false
    end
    local url = UPDATE_BASE .. name .. "?t=" .. os.time()
    local ok = pcall(downloadUrlToFile, url, dest, function(id, status, p1, p2)
        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
            dl_done[flag] = true
        end
    end)
    return ok
end

-- удаляет картинки, которые старые версии клали прямо в config, и временные файлы обновления
local junk_cleared = false
local function clear_junk()
    local names = { "arizona_logo.jpg", "arizona_prices_update.lua", "arizona_prices_remote_version.txt", "arizona_prices_remote.json" }
    for key in pairs(UIFX.ICONS or {}) do names[#names + 1] = "arizona_icon_" .. key .. ".png" end
    for _, n in ipairs(names) do os.remove(cfg_dir .. n) end
end

local function start_checks()
    if not doesDirectoryExist(cfg_dir) then createDirectory(cfg_dir) end
    if not junk_cleared then junk_cleared = true; pcall(clear_junk) end
    fetch("version.txt", cfg_dir .. "arizona_prices_remote_version.txt", "version")
    if state.auto_prices then
        fetch("item_prices.json", cfg_dir .. "arizona_prices_remote.json", "prices")
    end
end

local function handle_version()
    local path = cfg_dir .. "arizona_prices_remote_version.txt"
    local c = read_file(path)
    os.remove(path)
    local v = c and c:match("%d[%d%.]*")
    if v and version_newer(v, SCRIPT_VERSION) then
        if not update_info.available then
            notify("Вышла новая версия " .. v .. "! Откройте /prices и нажмите «Обновить»", "info", 8)
        end
        update_info.available = true
        update_info.version = v
        update_info.status = ""
    elseif manual_check then
        update_info.status = v and "У вас последняя версия" or "Не удалось проверить"
    end
    manual_check = false
end

local function handle_script()
    local dest = cfg_dir .. "arizona_prices_update.lua"
    local c = read_file(dest)
    update_info.busy = false
    if not c or #c < 2000 then
        update_info.status = "Ошибка загрузки"
        return
    end
    if not loadstring(c) then
        update_info.status = "Файл повреждён"
        return
    end
    local cur = thisScript().path
    local old = read_file(cur)
    if old then write_file(cfg_dir .. "Table_Prices.lua.bak", old) end
    if write_file(cur, c) then
        os.remove(dest)
        update_info.status = "Готово, перезапуск..."
        need_reload = true
    else
        update_info.status = "Не удалось записать файл"
    end
end

local function handle_prices()
    local path = cfg_dir .. "arizona_prices_remote.json"
    local c = read_file(path)
    os.remove(path)
    if not c or #c < 2 then return end
    local sig = signature(c)
    local ok, remote = pcall(decodeJson, c)
    if not ok or type(remote) ~= "table" then return end

    -- обычный игрок: список всегда ТОЧНО равен списку из канала (так нельзя подкрутить цены у себя и обмануть другого)
    if not ADM.on then
        local fresh = {}
        for _, r in ipairs(remote) do
            local buy = type(r) == "table" and tonumber(r.buy) or nil
            local sell = type(r) == "table" and tonumber(r.sell) or nil
            if buy and sell and type(r.item) == "string" then
                fresh[#fresh + 1] = { item = r.item, buy = buy, sell = sell, liq = ADM.valid_liq(r.liq) }
            end
        end
        if #fresh == 0 then return end
        local same = false
        local okc, a1, a2 = pcall(function() return encodeJson(fresh), encodeJson(items_list) end)
        if okc and a1 == a2 then same = true end
        if not same then
            items_list = fresh
            save_data()
            if sig ~= state.prices_sig then notify("Цены обновлены из канала", "ok", 5) end
        end
        state.prices_sig = sig
        save_state()
        return
    end

    -- разработчик: свои правки не затираем, только подтягиваем новые предметы и цены
    if sig == state.prices_sig then return end
    local index = {}
    for i, it in ipairs(items_list) do
        if it.item then index[it.item] = i end
    end
    local added, changed = 0, 0
    for _, r in ipairs(remote) do
        local buy = type(r) == "table" and tonumber(r.buy) or nil
        local sell = type(r) == "table" and tonumber(r.sell) or nil
        if buy and sell and type(r.item) == "string" then
            local i = index[r.item]
            if i then
                local l = items_list[i]
                if tonumber(l.buy) ~= buy or tonumber(l.sell) ~= sell then
                    l.buy, l.sell = buy, sell
                    changed = changed + 1
                end
            else
                items_list[#items_list + 1] = { item = r.item, buy = buy, sell = sell, liq = ADM.valid_liq(r.liq) }
                index[r.item] = #items_list
                added = added + 1
            end
        end
    end
    state.prices_sig = sig
    save_state()
    if added + changed > 0 then
        save_data()
        notify("Цены обновлены: новых " .. added .. ", изменено " .. changed, "ok", 5)
    end
end

local function process_updates()
    if dl_done.version then dl_done.version = nil; pcall(handle_version) end
    if dl_done.script then dl_done.script = nil; pcall(handle_script) end
    if dl_done.prices then dl_done.prices = nil; pcall(handle_prices) end
    if update_info.busy and os.time() - busy_since > 40 then
        update_info.busy = false
        update_info.status = "Не удалось скачать"
    end
end

local outdated_popup = imgui.new.bool(false)

local function start_update()
    update_info.busy = true
    update_info.status = ""
    busy_since = os.time()
    if not fetch("Table_Prices.lua", cfg_dir .. "arizona_prices_update.lua", "script") then
        update_info.busy = false
        if update_info.status == "" then update_info.status = "Ошибка загрузки" end
    end
end

local function request_update()
    update_info.busy = true
    update_info.status = ""
    busy_since = os.time()
    defer(start_update)
end

local function draw_update_block()
    imgui.SetCursorPos(imgui.ImVec2(5, LAYOUT.block_y))
    imgui.TextDisabled("Версия " .. SCRIPT_VERSION)
    imgui.SetCursorPosX(5)
    if update_info.available then
        imgui.TextColored(imgui.ImVec4(0.45, 1.00, 0.55, 1.00), "Вышла версия " .. update_info.version)
        imgui.SetCursorPosX(5)
        if update_info.busy then
            imgui.TextDisabled("Скачивание...")
        elseif imgui.Button(ic("DOWNLOAD", "") .. " Обновить##do_update", imgui.ImVec2(SIDEBAR_W - 10, 32)) then
            request_update()
        end
    else
        if imgui.Button(ic("ARROWS_ROTATE", "") .. " Проверить##check_update", imgui.ImVec2(SIDEBAR_W - 10, 28)) then
            manual_check = true
            update_info.status = "Проверка..."
            defer(start_checks)
        end
    end
    if update_info.status ~= "" then
        imgui.SetCursorPosX(5)
        imgui.TextDisabled(update_info.status)
    end
    imgui.SetCursorPosX(5)
    if imgui.Checkbox(" Автообновление цен##auto_prices", auto_prices_cb) then
        state.auto_prices = auto_prices_cb[0]
        save_state()
        if state.auto_prices then defer(start_checks) end
    end
end

-- ===================== Настройки, отчёт об ошибке, горячая клавиша =====================
local hk = { binding = false, typing = false }
local vkeys_ok, vkeys = pcall(require, 'vkeys')

local function key_name(code)
    if not code or code == 0 then return "Не задана" end
    if vkeys_ok and vkeys.id_to_name then
        local n = vkeys.id_to_name(code)
        if n then return n end
    end
    return "VK " .. tostring(code)
end

local sui = {
    accent = imgui.new.float[3](UI_CFG.accent[1], UI_CFG.accent[2], UI_CFG.accent[3]),
    opacity = imgui.new.float(UI_CFG.opacity),
    scale = imgui.new.float(UI_CFG.overlay_scale),
    toasts = imgui.new.bool(UI_CFG.toasts),
    border_speed = imgui.new.float(UI_CFG.border_speed),
    shadow = imgui.new.bool(UI_CFG.shadow),
    bg_fx = imgui.new.bool(UI_CFG.bg_fx),
    splash = imgui.new.bool(UI_CFG.splash),
    halloween = imgui.new.bool(UI_CFG.halloween),
    font_pending = false,
}

local ui_dirty_at = nil
local function mark_ui_dirty()
    ui_dirty_at = os.clock()
end

local function flush_ui_save(force)
    if ui_dirty_at and (force or os.clock() - ui_dirty_at > 0.8) then
        ui_dirty_at = nil
        save_settings()
    end
end

-- ===================== Окно авторизации (код из телеграм-канала) =====================
-- ВАЖНО: чтобы сменить код, поменяй ACCESS_CODE и выложи новую версию скрипта.
-- Все данные окна лежат в одной таблице AUTH, чтобы не тратить локальные переменные.
local AUTH = {
    ACCESS_CODE = "PRICES2026",
    path = getWorkingDirectory() .. "\\config\\arizona_prices_auth.json",
    open = imgui.new.bool(false),
    nick = imgui.new.char[48](),
    code = imgui.new.char[48](),
    error = "",
    ok = false,
    DELAY = 10, -- сколько секунд идёт «Загрузка» после ввода кода
}

-- уже входил с этим кодом раньше?
do
    local d = safe_read_json(AUTH.path)
    if type(d) == "table" and tostring(d.code or ""):lower() == AUTH.ACCESS_CODE:lower() then
        AUTH.ok = true
    end
end

-- Значки рисуются линиями, а не символами шрифта: у некоторых игроков шрифт иконок не грузится и вместо них был "?"
function AUTH.icon(kind, cx, cy, sz, r, g, b, a)
    local dl = imgui.GetWindowDrawList()
    local c = col32(r, g, b, a)
    local th = math.max(2, sz * 0.14)
    local function P(x, y) return imgui.ImVec2(cx + x * sz, cy + y * sz) end
    if kind == "check" then
        dl:AddLine(P(-0.5, 0.02), P(-0.14, 0.38), c, th)
        dl:AddLine(P(-0.14, 0.38), P(0.52, -0.38), c, th)
    elseif kind == "cross" then
        dl:AddLine(P(-0.38, -0.38), P(0.38, 0.38), c, th)
        dl:AddLine(P(0.38, -0.38), P(-0.38, 0.38), c, th)
    elseif kind == "login" then
        dl:AddLine(P(-0.5, 0), P(0.45, 0), c, th)
        dl:AddLine(P(0.05, -0.42), P(0.5, 0), c, th)
        dl:AddLine(P(0.05, 0.42), P(0.5, 0), c, th)
    elseif kind == "lock" then
        dl:AddRectFilled(P(-0.42, -0.02), P(0.42, 0.5), c, sz * 0.1)
        local px, py
        for i = 0, 10 do
            local ang = math.pi + i / 10 * math.pi
            local x, y = math.cos(ang) * 0.28, -0.02 + math.sin(ang) * 0.34
            if px then dl:AddLine(P(px, py), P(x, y), c, th) end
            px, py = x, y
        end
    end
end

-- кнопка: слева значок, справа текст (место под значок занимают пробелы)
function AUTH.button(kind, text, id, w, h)
    local isz = 16
    local spw = math.max(imgui.CalcTextSize(" ").x, 1)
    local label = string.rep(" ", math.ceil((isz + 8) / spw)) .. text
    local clicked = imgui.Button(label .. "##" .. id, imgui.ImVec2(w, h))
    local mn, mx = imgui.GetItemRectMin(), imgui.GetItemRectMax()
    local x0 = (mn.x + mx.x) / 2 - imgui.CalcTextSize(label).x / 2
    AUTH.icon(kind, x0 + isz / 2, (mn.y + mx.y) / 2, isz, 1, 1, 1, 0.95)
    return clicked
end

function AUTH.try_login()
    local nick = ffi.string(AUTH.nick):gsub("^%s+", ""):gsub("%s+$", "")
    local code = ffi.string(AUTH.code):gsub("%s", "")
    if nick == "" then AUTH.error = "Введите ваш никнейм"; return end
    if code == "" then AUTH.error = "Введите код из телеграм-канала"; return end
    if AUTH.loading then return end
    AUTH.error = ""
    AUTH.loading = { t = imgui.GetTime(), nick = nick, code = code, valid = (code:lower() == AUTH.ACCESS_CODE:lower()) }
end

-- фаза 2 (через AUTH.DELAY секунд): проверяем код и открываем меню
function AUTH.finish()
    local nick, code = AUTH.loading.nick, AUTH.loading.code
    AUTH.loading = nil
    if code:lower() ~= AUTH.ACCESS_CODE:lower() then
        AUTH.error = "Неверный код. Получите актуальный код в телеграм-канале"
        return
    end
    AUTH.ok = true
    AUTH.error = ""
    AUTH.open[0] = false
    local dir = getWorkingDirectory() .. "\\config"
    if not doesDirectoryExist(dir) then createDirectory(dir) end
    write_file_raw(AUTH.path, encodeJson({ nick = nick, code = code }))
    notify("Доступ открыт. Добро пожаловать, " .. nick .. "!", "ok", 5)
    main_window[0] = true
end

imgui.OnFrame(function() return AUTH.open[0] end, guard_frame("auth", function()
    local sw, sh = getScreenResolution()
    local W, H = 560, 380
    imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(W, H), imgui.Cond.Always)
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.075, 0.07, 0.095, 1.0))
    imgui.Begin("##auth_window", nil, bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoResize,
        imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoSavedSettings))
    local p = imgui.GetWindowPos()
    local ac = UI_CFG.accent
    imgui.GetWindowDrawList():AddRectFilled(p, imgui.ImVec2(p.x + W, p.y + 5), col32(ac[1], ac[2], ac[3], 1))

    imgui.SetCursorPos(imgui.ImVec2(26, 24))
    imgui.SetWindowFontScale(1.7)
    local tv = accent_vec(1.2)
    AUTH.icon("lock", p.x + 26 + 14, p.y + 24 + imgui.GetTextLineHeight() / 2 - 2, 26, tv.x, tv.y, tv.z, 1)
    imgui.SetCursorPos(imgui.ImVec2(26 + 38, 24))
    imgui.TextColored(tv, "Авторизация")
    imgui.SetWindowFontScale(1.15)
    imgui.SetCursorPos(imgui.ImVec2(26, 76))
    imgui.PushTextWrapPos(W - 26)
    imgui.TextWrapped("Вы попали в окно авторизации. Введите свой никнейм и код. Код можно получить в телеграм-канале.")
    imgui.PopTextWrapPos()

    if AUTH.loading then
        -- экран «Загрузка...»: крутящийся индикатор, меняющиеся статусы и полоска прогресса
        local now = imgui.GetTime()
        local k = clamp((now - AUTH.loading.t) / AUTH.DELAY, 0, 1)
        local dl = imgui.GetWindowDrawList()
        local cx, cy = p.x + W / 2, p.y + 165
        for i = 0, 11 do
            local ang = i / 12 * math.pi * 2 - now * 6
            local fade = ((i / 12) - (now * 1.5) % 1) % 1
            dl:AddCircleFilled(imgui.ImVec2(cx + math.cos(ang) * 34, cy + math.sin(ang) * 34), 5.5,
                col32(ac[1], ac[2], ac[3], 0.15 + 0.85 * (1 - fade)), 12)
        end
        -- последний этап зависит от результата: верный код - "Доступ разрешён", неверный - "Неверный код"
        local steps = { "Подключение к серверу...", "Проверка кода...", "Верификация никнейма...", "Подготовка данных..." }
        local good = AUTH.loading.valid
        local st, stcol = nil, imgui.ImVec4(0.65, 0.65, 0.72, 1)
        if k >= 0.88 then
            if good then st, stcol = "Доступ разрешён", imgui.ImVec4(0.30, 0.85, 0.45, 1)
            else st, stcol = "Неверный код", imgui.ImVec4(1.0, 0.4, 0.4, 1) end
        else
            st = steps[math.min(#steps, 1 + math.floor(k / 0.88 * #steps))]
        end
        imgui.SetCursorPos(imgui.ImVec2(0, 232))
        imgui.SetWindowFontScale(1.6)
        local dots = string.rep(".", math.floor(now * 3) % 4)
        local title = "Загрузка" .. dots
        imgui.SetCursorPosX((W - imgui.CalcTextSize("Загрузка...").x) / 2)
        imgui.Text(title)
        imgui.SetWindowFontScale(1.1)
        imgui.SetCursorPosX((W - imgui.CalcTextSize(st).x) / 2)
        imgui.TextColored(stcol, st)
        imgui.SetCursorPos(imgui.ImVec2(60, H - 46))
        imgui.PushStyleColor(imgui.Col.PlotHistogram, (k >= 0.88 and not good) and imgui.ImVec4(1.0, 0.4, 0.4, 1) or accent_vec(1.1))
        imgui.ProgressBar(k, imgui.ImVec2(W - 120, 10), "")
        imgui.PopStyleColor(1)
        imgui.SetWindowFontScale(1.0)
        imgui.End()
        imgui.PopStyleColor(1)
        if k >= 1 then AUTH.finish() end
        return
    end

    imgui.SetCursorPos(imgui.ImVec2(26, 150))
    imgui.SetNextItemWidth(W - 52)
    imgui.InputTextWithHint("##auth_nick", "Ваш никнейм", AUTH.nick, ffi.sizeof(AUTH.nick))
    imgui.SetCursorPosX(26)
    imgui.SetNextItemWidth(W - 52)
    local enter = imgui.InputTextWithHint("##auth_code", "Код из телеграм-канала", AUTH.code, ffi.sizeof(AUTH.code), imgui.InputTextFlags.EnterReturnsTrue)
    if enter then AUTH.try_login() end

    imgui.SetCursorPosX(26)
    if AUTH.error ~= "" then
        imgui.TextColored(imgui.ImVec4(1.0, 0.4, 0.4, 1.0), AUTH.error)
    else
        imgui.Text(" ")
    end

    imgui.SetCursorPos(imgui.ImVec2(26, H - 26 - 46))
    local bw = (W - 52 - 20) / 3
    imgui.PushStyleColor(imgui.Col.Button, accent_vec(1.0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, accent_vec(1.15))
    imgui.PushStyleColor(imgui.Col.ButtonActive, accent_vec(0.85))
    if AUTH.button("login", "Войти", "auth_go", bw, 46) then AUTH.try_login() end
    imgui.PopStyleColor(3)
    imgui.SameLine()
    if AUTH.button("check", "Получить код", "auth_tg", bw + 40, 46) then
        open_url("https://t.me/arizona_prices")
    end
    imgui.SameLine()
    if AUTH.button("cross", "Закрыть", "auth_close", bw - 40, 46) then AUTH.open[0] = false end
    imgui.SetWindowFontScale(1.0)
    imgui.End()
    imgui.PopStyleColor(1)
end, function() AUTH.open[0] = false; AUTH.loading = nil end))

local function toggle_menu()
    if not AUTH.ok then
        -- нет доступа: показываем окно авторизации вместо меню
        main_window[0] = false
        AUTH.loading = nil
        AUTH.open[0] = not AUTH.open[0]
        if AUTH.open[0] and ffi.string(AUTH.nick) == "" then
            local okn, id = pcall(function() local _, i = sampGetPlayerIdByCharHandle(PLAYER_PED); return sampGetPlayerNickname(i) end)
            if okn and id then imgui.StrCopy(AUTH.nick, id) end
        end
        return
    end
    main_window[0] = not main_window[0]
    if main_window[0] and update_info.available then
        outdated_popup[0] = true
    end
end

local function on_window_message(msg, wparam, lparam)
    if msg ~= 0x100 and msg ~= 0x104 then return end
    local is_repeat = bit.band(lparam, 0x40000000) ~= 0

    if hk.binding then
        consumeWindowMessage(true, true)
        if is_repeat then return end
        hk.binding = false
        if wparam == 0x08 then
            UI_CFG.open_key = 0
            mark_ui_dirty()
            notify("Горячая клавиша убрана", "info")
        elseif wparam ~= 0x1B then
            UI_CFG.open_key = wparam
            mark_ui_dirty()
            notify("Клавиша открытия меню: " .. key_name(wparam), "ok")
        end
        return
    end

    if is_repeat then return end

    -- горячие клавиши внутри открытого меню: цифры 1-4 переключают вкладки, Ctrl+F - поиск по таблице
    if main_window[0] and UIFX.alpha > 0.5 and not hk.typing then
        local okc, busy = pcall(function() return sampIsChatInputActive() or sampIsDialogActive() end)
        if not (okc and busy) then
            if wparam >= 0x31 and wparam <= 0x34 then
                UIFX.pending_tab = UIFX.TAB_ORDER[wparam - 0x30]
                consumeWindowMessage(true, true)
                return
            elseif wparam == 0x46 then
                local okk, ctrl = pcall(isKeyDown, 0x11)
                if okk and ctrl then
                    UIFX.pending_tab = 1
                    UIFX.focus_search = true
                    consumeWindowMessage(true, true)
                    return
                end
            end
        end
    end

    local key = UI_CFG.open_key
    if key and key ~= 0 and wparam == key then
        local okc, busy = pcall(function() return sampIsChatInputActive() or sampIsDialogActive() end)
        if okc and busy then return end
        if main_window[0] and hk.typing then return end
        toggle_menu()
    end
end

local function build_report()
    local lines = {}
    local function add(t) lines[#lines + 1] = t end
    add("Arizona Prices - отчёт об ошибке")
    add("Версия скрипта: " .. SCRIPT_VERSION)
    add("Журнал ошибок: moonloader\\config\\arizona_prices_errors.log")
    add("Дата: " .. os.date("%Y-%m-%d %H:%M:%S"))
    local okv, mv = pcall(function() return getMoonloaderVersion() end)
    add("MoonLoader: " .. (okv and tostring(mv) or "?"))
    add("Lua: " .. tostring(_VERSION) .. (jit and (" / " .. tostring(jit.version)) or ""))
    local okr, rw, rh = pcall(getScreenResolution)
    add("Экран: " .. (okr and (tostring(rw) .. "x" .. tostring(rh)) or "?"))
    add("Предметов в списке: " .. #items_list)
    add("Автообновление цен: " .. tostring(state.auto_prices))
    add("Загрузка файлов: " .. ((downloadUrlToFile and dlstatus) and "доступна" or "недоступна"))
    add("Уведомления: " .. tostring(UI_CFG.toasts) .. ", горячая клавиша: " .. key_name(UI_CFG.open_key))
    if #err_log > 0 then
        add("Последние ошибки:")
        for _, e in ipairs(err_log) do add("  " .. e) end
    else
        add("Ошибок в журнале нет")
    end
    add("")
    add("Что вы делали перед ошибкой:")
    return table.concat(lines, "\n")
end

local function send_bug_report()
    local ok, text = pcall(build_report)
    local body = ok and text or ("Arizona Prices " .. SCRIPT_VERSION)
    imgui.SetClipboardText("Привет. Заметил о баге:\n\n\n" .. body)
    open_url("https://t.me/arzprices_ceo")
    notify("Сообщение скопировано - допишите, что случилось, и отправьте (Ctrl+V)", "ok", 6)
end

local THEMES = {
    { name = "Океан",   c = {0.18, 0.45, 0.85} }, { name = "Изумруд", c = {0.20, 0.70, 0.45} },
    { name = "Аметист", c = {0.60, 0.35, 0.90} }, { name = "Рубин",   c = {0.90, 0.30, 0.35} },
    { name = "Янтарь",  c = {0.95, 0.60, 0.15} }, { name = "Бирюза",  c = {0.15, 0.72, 0.78} },
    { name = "Сакура",  c = {0.90, 0.40, 0.70} }, { name = "Неон",    c = {0.55, 1.00, 0.20} },
}
local BORDER_MODES = { "Выключена", "Переливы цвета", "Радуга", "Статичная" }

local CORNERS = {
    { name = "Справа снизу", v = 3 }, { name = "Справа сверху", v = 1 },
    { name = "Слева снизу", v = 2 }, { name = "Слева сверху", v = 0 },
}

local function sub_title(icon_name, text)
    imgui.Spacing()
    imgui.TextColored(accent_vec(1.2), ic(icon_name, "") .. " " .. text)
    imgui.Separator()
    imgui.Spacing()
end

local function draw_settings_tab()
    section_header(ic("GEAR", ""), "Настройки")
    if imgui.BeginChild("##settings_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then
        sub_title("PALETTE", "Темы оформления")
        for i, th in ipairs(THEMES) do
            local c = th.c
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(c[1] * 0.55, c[2] * 0.55, c[3] * 0.55, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(c[1] * 0.80, c[2] * 0.80, c[3] * 0.80, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(c[1], c[2], c[3], 1.0))
            if imgui.Button(th.name .. "##theme" .. i, imgui.ImVec2(110, 30)) then
                UI_CFG.accent = { c[1], c[2], c[3] }
                sui.accent[0], sui.accent[1], sui.accent[2] = c[1], c[2], c[3]
                apply_theme()
                mark_ui_dirty()
            end
            imgui.PopStyleColor(3)
            if i % 4 ~= 0 and i < #THEMES then imgui.SameLine() end
        end
        imgui.Spacing()
        if imgui.ColorEdit3("Свой цвет##accent_custom", sui.accent, imgui.ColorEditFlags.NoInputs) then
            UI_CFG.accent = { sui.accent[0], sui.accent[1], sui.accent[2] }
            apply_theme()
            mark_ui_dirty()
        end
        imgui.SetNextItemWidth(260)
        if imgui.SliderFloat("Прозрачность окна##opacity", sui.opacity, 0.3, 1.0, "%.2f") then
            UI_CFG.opacity = sui.opacity[0]
            apply_theme()
            mark_ui_dirty()
        end

        sub_title("WAND_MAGIC_SPARKLES", "Рамка и эффекты")
        imgui.SetNextItemWidth(220)
        if imgui.BeginCombo("Рамка окна##border_mode", BORDER_MODES[UI_CFG.border_mode + 1] or BORDER_MODES[2]) then
            for i, name in ipairs(BORDER_MODES) do
                if imgui.Selectable(name .. "##bm" .. i, UI_CFG.border_mode == i - 1) then
                    UI_CFG.border_mode = i - 1
                    mark_ui_dirty()
                end
            end
            imgui.EndCombo()
        end
        if UI_CFG.border_mode == 1 or UI_CFG.border_mode == 2 then
            imgui.SetNextItemWidth(260)
            if imgui.SliderFloat("Скорость переливов##border_speed", sui.border_speed, 0.2, 3.0, "%.1f") then
                UI_CFG.border_speed = sui.border_speed[0]
                mark_ui_dirty()
            end
        end
        if imgui.Checkbox("Тень под окном##shadow", sui.shadow) then
            UI_CFG.shadow = sui.shadow[0]
            mark_ui_dirty()
        end
        if imgui.Checkbox("Анимированный фон##bgfx", sui.bg_fx) then
            UI_CFG.bg_fx = sui.bg_fx[0]
            mark_ui_dirty()
        end
        if imgui.Checkbox("Заставка при первом открытии меню##splash", sui.splash) then
            UI_CFG.splash = sui.splash[0]
            mark_ui_dirty()
        end
        if imgui.Checkbox("Хэллоуин: тыквы, летучие мыши, паутина##halloween", sui.halloween) then
            UI_CFG.halloween = sui.halloween[0]
            local c = UI_CFG.halloween and { 0.98, 0.55, 0.12 } or { 0.18, 0.45, 0.85 }
            UI_CFG.accent = c
            sui.accent[0], sui.accent[1], sui.accent[2] = c[1], c[2], c[3]
            apply_theme()
            mark_ui_dirty()
        end

        sub_title("FONT", "Шрифт")
        local font_name = FONT_AVAILABLE[1].name
        for _, f in ipairs(FONT_AVAILABLE) do
            if f.key == UI_CFG.font then font_name = f.name end
        end
        imgui.SetNextItemWidth(260)
        if imgui.BeginCombo("Шрифт интерфейса##font", font_name) then
            for _, f in ipairs(FONT_AVAILABLE) do
                if imgui.Selectable(f.name .. "##font_" .. f.key, UI_CFG.font == f.key) then
                    UI_CFG.font = f.key
                    sui.font_pending = true
                    mark_ui_dirty()
                end
            end
            imgui.EndCombo()
        end
        if sui.font_pending then
            if imgui.Button(ic("ARROWS_ROTATE", "") .. " Применить шрифт (перезапуск скрипта)##apply_font", imgui.ImVec2(360, 28)) then
                defer(function()
                    flush_ui_save(true)
                    thisScript():reload()
                end)
            end
        else
            imgui.TextDisabled("Шрифт меняется после перезапуска скрипта. Берётся из папки Fonts в Windows.")
        end

        imgui.Spacing()
        if imgui.Button(ic("ROTATE_LEFT", "") .. " Сбросить внешний вид##reset_look", imgui.ImVec2(230, 28)) then
            UI_CFG.accent = UI_CFG.halloween and { 0.98, 0.55, 0.12 } or { 0.18, 0.45, 0.85 }
            UI_CFG.opacity = 1.0
            UI_CFG.overlay_scale = 1.0
            UI_CFG.border_mode = 1
            UI_CFG.border_speed = 1.0
            UI_CFG.shadow = true
            if UI_CFG.font ~= "seguisb" then
                UI_CFG.font = "seguisb"
                sui.font_pending = true
            end
            sui.accent[0], sui.accent[1], sui.accent[2] = UI_CFG.accent[1], UI_CFG.accent[2], UI_CFG.accent[3]
            sui.opacity[0] = 1.0
            sui.scale[0] = 1.0
            sui.border_speed[0] = 1.0
            sui.shadow[0] = true
            apply_theme()
            mark_ui_dirty()
        end
        imgui.SameLine()
        if imgui.Button(ic("EXPAND", "") .. " Сбросить размер окна##reset_size", imgui.ImVec2(230, 28)) then
            LAYOUT.force = true
        end

        sub_title("KEYBOARD", "Управление")
        imgui.AlignTextToFramePadding()
        imgui.Text("Клавиша открытия меню:")
        imgui.SameLine()
        local bind_label = hk.binding and "Нажмите клавишу..." or key_name(UI_CFG.open_key)
        if imgui.Button(bind_label .. "##bind_open_key", imgui.ImVec2(190, 26)) then
            hk.binding = not hk.binding
        end
        imgui.TextDisabled("Esc - отмена, Backspace - убрать клавишу. Команды /prices и /pr работают всегда.")

        sub_title("BELL", "Уведомления")
        if imgui.Checkbox("Всплывающие карточки вместо сообщений в чате", sui.toasts) then
            UI_CFG.toasts = sui.toasts[0]
            mark_ui_dirty()
        end
        local corner_name = CORNERS[1].name
        for _, c in ipairs(CORNERS) do
            if c.v == UI_CFG.toast_corner then corner_name = c.name end
        end
        imgui.SetNextItemWidth(220)
        if imgui.BeginCombo("Угол экрана##toast_corner", corner_name) then
            for _, c in ipairs(CORNERS) do
                if imgui.Selectable(c.name, c.v == UI_CFG.toast_corner) then
                    UI_CFG.toast_corner = c.v
                    mark_ui_dirty()
                end
            end
            imgui.EndCombo()
        end
        if imgui.Button(ic("BELL", "") .. " Показать пример##toast_test", imgui.ImVec2(230, 28)) then
            notify("Так выглядят уведомления", "ok")
        end

        sub_title("BUG", "Поддержка")
        if imgui.Button(ic("BUG", "") .. " Сообщить об ошибке##report_error", imgui.ImVec2(230, 30)) then
            send_bug_report()
        end
        imgui.TextDisabled("Скопирует версию скрипта и данные для диагностики и откроет Telegram разработчика.")
        if #err_log > 0 then
            imgui.TextColored(imgui.ImVec4(1.0, 0.55, 0.40, 1.0), "Записей в журнале ошибок: " .. #err_log)
        end
    end
    imgui.EndChild()
end

function UIFX.b64(s)
    local idx, chars = {}, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    for i = 1, #chars do idx[chars:byte(i)] = i - 1 end
    local out, n, acc, bits = {}, 0, 0, 0
    for i = 1, #s do
        local v = idx[s:byte(i)]
        if v then
            acc = acc * 64 + v
            bits = bits + 6
            if bits >= 8 then
                bits = bits - 8
                local div = 2 ^ bits
                local byte = math.floor(acc / div)
                acc = acc - byte * div
                n = n + 1
                out[n] = string.char(byte)
            end
        end
    end
    return table.concat(out)
end

-- логотип скрипта (шапка вкладки "О скрипте"): грузим один раз, при неудаче рисуем старый значок
UIFX.LOGO = [[
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
qHW0gZhQqkDev//Z
]]
function UIFX.logo_tex()
    if UIFX.logo ~= nil or UIFX.logo_failed then return UIFX.logo end
    local ok, tex = pcall(function()
        ensure_cache()
        local path = cache_dir .. "logo.jpg"
        local need = math.floor(#(UIFX.LOGO:gsub("[^%w%+/]", "")) * 6 / 8)
        local have = 0
        local f = io.open(path, "rb")
        if f then have = f:seek("end") or 0; f:close() end
        if have < need - 2 or have > need + 2 then
            if not write_file(path, UIFX.b64(UIFX.LOGO)) then error("write failed") end
        end
        return imgui.CreateTextureFromFile(path)
    end)
    if ok and tex then UIFX.logo = tex else UIFX.logo_failed = true end
    return UIFX.logo
end

-- логотипы Telegram / Discord / TikTok для вкладки "О скрипте" (PNG, грузим при первом показе)
UIFX.ICONS = {
    tg = [[
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
jVNN4/8DbPSg6vMcCXIAAAAASUVORK5CYII=
]],
    ds = [[
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
]],
    tt = [[
iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAfiElEQVR42u2deZxcZZnvv8/7nlNrd3VC9hASwhLDKpsBlIEREIxcVEREWQSZcdyuI8rgjOMdFe+dcUc/frxe7oijXlSQ
RS4jirKD0UuCBBUTwiIQCZCks3RVV1V31Tnnfe4f51R3pbPQnXRXVyd9Pp+imu5U9znv7/es7/M8rzDxLgFM8h4O/eGMGTM6qtVwgYhb7JweKiILgQOA6aBzQLz4a7whHw2BTaAhyCvx
17yoqs8bI8+omjW5nLe2u7u7vIN78gAFXPI+oRZzIoEOEDX/oFAoHOycHKeqS1Q5VoRDQWaDpCR5Oh2AREe0LNt+Xuug61V5RoTHRWSFMbqyVCr9eciHbfI+IcjQ7gQwyatJ0mflc7m+
U4CzRDgd5AgR8QcgHkS7GQDZyfvQS3fyPkBAkcGPqmoAukqV+4G7q9XsMthQGaIZXPKaJMAILtukUgEyuVznG0XkfOBMEbOgSTIbWkGHaIrRfjYdQiyJ71OaNIVbC9yrqrdVq70PAP1N
RJah2muSADsGfkByOzo6DlO1lwIXiMghTRLekKrGwo7Xc2gTUQ1gGhpCVZ8FbhGJbiiXy08O0STRJAG2B35gUfL5wpuAD4KcIyLpHYBu2lRzuaFkUNUa6M+B6yqV0j07e+Z9lQCmaeHo
6Og6X5UrQU4RGZD2sM1BfzUyeDERAHSZCN8ol4u37ej59yUCJPYzdu5iiZfPisgbEvXZMANmAkUquzITLvYfxSTP9xvQa5o0gtfkx+z1BBhQffn81KMgukbEnJcsTDTEkdvbLgeoiNjE
abwd7Gcrla1PjJdZsOMg9RGQzee7Pgv6fRFzZJPE271A4oeTz0iIYA4HvSKVyqSDoPYIUG8xJi1b7MZDk8sVzgb5mjFyRGLjo1Y/dBtdEWBFBOd0FehV1WrpV0PXbKJrgIZ9S+dyU74i
Iv/TGJmpquFeru6HKxgKRMbIbJBLfD/TFQT9Dyb+kTfWJJAWgB8m8fz3RWRJou7Zx4HfmX+AiBhVXSESXZ7kDzx2sOfR7hpgIOGRzxcuBvNTETk4kfq93c7vyZoJEIrIAapySSqVfjEI
an8YS2EZCwI01Jrm811fFDHXApnEDHiTOA9r/SIgK2Le4fvpbBDU7hmytm1LgCSVOyeXy9kfGSN/N2nr98w3EJFTPS99RBDs93MoN6IEHU21M6rxfT6fn6nq3WKMnBrvluFP4rlHVyAi
vnP6sEh4QaVS2Tia+QIZTfBzudxs8O9NQrxJ8EefBKsgOLNara4fLRLIKIN/nzFyeKL2J+396F6hiHjO6WoIzhgtEphJ8CfM5alqaIwcDv598ZrveRJN9pA8rqOjY7pz9qFJ8FuvCYyJ
TiuXy5vYg6yh2TPizMs6Z2+fBH98NIFz9naYl90TYba7CX6i+rnJGPPmSYdvXMLEwBhZ6Hn9i4Og9hMGK5PHnAAeEObzhS8ZY94/YcEXAWvBmFd/WdtcWtwul41JYI70/VQuCGp3sxt7
B7Kb4L9HxPx4IoOvtRoEtWEsgaI4JJVDUql2JEIgIr6qu6hSKd3ICPcOZIRqx3V2di5yzjwGZJmIFTsiaBjgLVyIt3AhhMFgA8B22DskncbO3Z/ar5cR/vnPkEqDa6sq70bFUZ8x7vje
3t6nR+IUeiMgigAp5+QmEeloqt6ZWJe1aLmH/MUX0vXp/4YLyuB5O3lkBecwNseWT3yC2tefwGQySHtV+UvMa+lwTm4CTkrCQxmOTzBcAlggzOUKXxUxx+4NHr/W66iL0HJlJwRoBF0h
2uljZ83AiCAIzinGtBX3raqGIubYXK7wpWq19PHhmgJvuODn812ng1y514R7Ilhj6RHhw6ksl/jpnWZVxFjchz5McO7bMH6KT151NXf9/E46Oruoh2G79H95CQmuzOe7flapFO9nGJlC
bxjqRYGMKteJDFTq7hVXo1VnhggHmVcJiApdcHgXAAsWH0r9ZyFbXEBawU8Wpk3CQ1XlOuBo4hrDXZoCM4xf6LLZrk8bI4eCRuxl27oCBInHVGewmH+7lyphvY5zjnfOX8xnCofwhWmH
cZCfo6auXZwhAxoZI4dms12fZrBJZbc0QMPrf41z/GNSyrVXFm82ihV22X0igrEeGMNfHXM8fzXzKOjq4k/VrTxZL5EzlrA9QkSrqs4Y/rGzs/OHrxYVmFdT/1EkX0m6b5V9vZQrcfzc
a+bTV0gT1vqYZdPtyGcVET+K5CuvhpvZheMX5fNdfy1izk1CPsu+fsX9apgZU/EWH4TXH3BCdspgNN5eUUEkYs7N57v+ml3sGppdJBdElS/JZPnmtlcUa1J7zilQr3FMZgpZ4xG24SyI
hK9f2pUjaHYi/S6bnfJWY2TJpPQPXZ14yeQtp8ABMznYeRzk56mpw9B2uYHIGFmSzU55a+ID2OEQQGP26D8zwebdtEysogiZ0kl40ZtJVQLO6pxFqBGmPbWlJlju0FCZHUi/xrZflmjc
uzUp/dutmgGnyCVvgUMP4B3ShbEerv3ExaqqisiSxBfYDs8dagBVvTKx/W4S7Z0bV1vowH3qMk6WDk7OTKWiIbb9AiWXzFq48tU0gAGiQqFwiIgsnZT+YfgCUYSeeSL2U3/L56PpqDXx
98W0oxZYWigUDkkiArMzAhBFcoWIpBjcUZq8drq0Fhs5og+8ndM//Qk+VO+i1NuDX6vFRSSNgpPxDaWEuMEkFUVyxVDcmzOBEZBW1fckuE928gzTHzDO4a66iK+mDaseuJOHVj1G11NP
EQDYFJJOxzuOiQM5DkUlRhVibLmGOOu9DQGSGr/CaSLmQFA3SYDhy5eIQZ0j+1/fzW1vO4OLqPCbhx8mddc9mD+tJnxhLWGxByVC0nnE91tNAgPqRMyBuVzhtGq1dHcDc2+Ib3NhPNiK
SQKMWBEYnCrTDpjB/2UG37n4QH508SW82LsV++JLdK5eg9m4gcq3ryd87nnU9+N6hNbxwIkgwIXA3c12X4Bo3jyyIG9W1clGzt0lQSI9WVX+PnLcGzq+le3kvxy2mOnvPA/98EfZOm0/
Sn29VPr7iaKWBlkmxlbeHGMd+3hew/vfurVwCsjcSfW/pxFiXBvgrNCJ4R3AO1TZGAQsp87Ky97Lk9Om8fTav7DuxXVUymWMMa3IuCU7gjI3xrp0T5LRiD0+VZY27n0Sxj13uxs93FGi
e2f6Kc71U3z2ivdx009vZeVjKzjuhOOp9lXwrdeqcMslSmpp41ZNU7h3pupkH/9YEME0kSGMIoIgAKDTxC5Y0YWEaCtIYBKMz2yYfgNoV1fXgSJyWGMbYBK6sSODZy2+9VDg32ccyep5
p3Hn7OOZbdPUVZGxXX4BRUQO6+rqOhDQJPnDCSLiTSZ/WkuIqSbFYakCSzvmMM2kCMZeCzSSQl4UccJAssc5PTH5BxNr909ksHXL87Z/2THKZKuOSnOIQ4k0JHRBq0zAAMYNzBt5gGOb
GNLuAXf8UoVaHa3XiCvVdQd0N0g2n/i6o0w8kbg4xMhup3rjbpvB/7ZQ+Qxg7s2aNStfLvctSqZ2tq8DmEizVipoVEOwmDlz8A+cj7dgAXbhgUg6jagDY9BiifCZZ6k/soKoUh0kzZ7K
jgCbemD9JjjykOS4igixE2bfzKgqIiyaNWtW3qtUKgvAzmxriQe0VERxpI5+LZlzlpI+eQn+UUdg587BpjIYvNjLRtHkPU1A+cjXweo1eIUCGu7hvEXVWNq3FNEL/wn+5u3Ihy6AbDpO
nUZRO2z+DFcRzKxUKgu8KLKLjSEFbZj+9Ty03AtOySw9m/wVl5F50+mYrukYQqj3U6vXKfX1EamSFWGKCClgihiMCJ3z5rHu+RcoV6ukfH/PVK0mKqC3ArUAvnkTpV8uo3DZ2zDvOpvQ
t/EUTOcSbSG0YZmQJFinosgu9kR0kYhBtY36nhN17YqbSZ2whK5//RyZM9+IGB+p9uKK3fQIODHMNZbT0ymOtR4nGo8DjCGD0JEkvut33M6GDRt46qmnuezSy+mtVtnjtEvoiFC8Gfux
/MlV/Nvlt/Ct772NI959Hiw9iXD/GduOQ42ajhlqlGeO72qriCDiFnmqHNRutl77+wGl6/PX0HnlR5HOTqS3CKoUjSHlWd5sU7zVS/EG6zFjFwUY6XSa+fPnM3vOHMpWKAc1QMmNhhsV
RqRyWR5M1zjl4Zu58pFf84n/fSKdrz8eTjuG6PjFsGA2xu6kXHScTYUqB3nGyIK2Uvm9vZiZ09nvu9eRfcu5uMpWTKmHqjU4hNOtz0f8DCdbvymcGvTPhp4Lp87FWbhyhe9MP5JXvC08
sWkd94jBjYIYqnN4agjTHp9jAz9aczdXPLOSd982lwNnzoGD5sLhC4kOPxCduR8yaxpmvy4kn4EgHFcSGCMLPNDp8QbgOIeAnocWe/CPOoJpt96Ev2gRrmcj1vPYbAyHi+Xz6RynJsA3
nymzy/YmEUSErPW5sDAPZDqh6+JoY4lGKfaOUIwqXVheoManwhe5ttzN0vqLvHvDdE5d8Ufyxo9zEykP8mk05eEqfWg2FW8Lt9gPSM4wmu6BzBj3FLC1aLkX/8gjmP6LO7D7z8H1bMb4
PltVOc9L8cV0nqki7Mms+cAFSFRniwtGfcE1IUIaIScevWGd/1N/iRvMKxya7uC16QKvo4uTTReLyzmmi4f1fEhayzxa2mEsic6c4amSGldTJAJBHenoYL8bvoudtz/0bEV8n6Iqn0vn
+KCfSSRtz6pULYIRGdPKXQVCVTyEgvFR4Pn+Mk/3lbiFF7FimeNlmOtlmG1SzLIpphifza6OjyRBbMt8gJQnwrRxzQKKoEGdaT/6HqljjsP1bBoA/9/SOa7wMwNlrBOpRLmhEQDSYsiK
RSRuM+8Oa7wU9iXH4sX/JmM8Uq2bM5CMlWGax3hO+/A8XHEznR/7GLnz3okrdmMS8L+QzvE+P8PeMI5kgAwJur4IKbw4o5zAEamOR2Tojd/aGkH7+/AXHkLhn6/G9ZXwrGWzKh9NZfYa
8HdGiG3gHsecwPhl/sSgtSqdn74aO3Mupl6jV4TjrcenUrnRP0pMZIKkaPcFAhiDViukjjmO3IUX4Co9OM/DA76Yzg1k0WSPxWxQ7VLtR/trYAxbojolF2Ex+3z3q2EMT6TaJQHCGvm/
ex+mYwo2DOlR5XI/zdHGY7cHEUVusPFCmjJtqnH+vr8OxhCqjloOYIJfoVFlc0stkQjUatgZs8mc/SaoV6hZw4HG8DE/u3tjyJzGINukOKSxV9/XP7iDN7VzgBDjed58G7khqLLZExls
E2qZ9Pf3kX7jaXgLD0TKZcoi/I2XYorIyG1/5AaGNrDscfShlbD6OdhSwtVquGwGpk+BBXNwVkDdqKSA94ZLhLoH2g3mgMG9zhbE/USkTnodIiki58h5Hufa1MinUDXAf+Fl9PPfgQce
BeeIPIuxFmt9rAJPvwTLnoCOLHhpcrLPNz0natF1eyCbknb31ohFFCGpLOlT34BxAWURTjSWo5NKWTNS8B/4HXrVtbC1hHZ1oIAnHqhjVa3IY/UiL0Y1AOwWx2tyU/HqvaN/AN8EI0CM
uWzynNO11krLdA5hiN1vP7yDD4awRl2E1ycbPMM+WdIl4P/2D+gH/gdYi5vSgQ0VxPDj3rVcX/oLy2tFqi7Y9rNFn3Rvkf14+z7fAOGcrvVEeK6VRkejKN7fz2VwkSPdRIBh0bDh1G3u
QT/5TRDBpX1sBL0a8cGNv+fHvesAQ95Yumxq249bL54MGkXtkIcZbx/gOU9Vnk6KgaRFtEPyOUw2S+gcU8VwUFL3NyyJdLG3r9f+CNa+jJs+BRM5tkQhb3llOcv7ttLlpVCN06/bTe9M
/t9OnYImoWCjoGQfigxEVVGVp4210RrigQGtM4uqiCoBMF2E6cMFIAGf9Zvh58ugqwPCCIfwvo2/Z3nfVqZ66YE4f6caBJCpUxJfCDL7Voaw4WrVrY3WmHw+vxZ047jYIOJjR4btkzdO
nn90FfSUCD2DNT439a7jPyuvMMVLU1c3bE20b5sA3ZjP59eaDRs2VFR5WmIpaE1nsEicqwGmJdI/kj+sjz2JOsViqLk6X+l5Hl88opHUtbp9NgZwIoIqT2/YsKHSMLuPt0wYRCAIIIx2
f3MmCOMaduPxq0o3f6gVyYoddoJHsEihY+Bx97F+eG3G3MTJOVk+sDZj7QD6PtH6DYQbu/F8j02JyjYjJJEmaaOH+rcg6PC5pArWx86dg2qIEaFj30oMSzPmBsBafpccBWPHXAtYD1cs
Eb30CsbzCXenyXIAbaXkRjCm2Ri0r4p/1OGkXvtaXF8fvrFMHT574rfunkENphNO+q2qhtbyuwYBpFgsvqCqTzaGhYwtAQQN+6k9thJPfHqco5TYbh2u8po/O7bhMsJ9A2vRsEbH338I
0zkFwhBkBNon+fu6YXPS7CETzYFUEFT1yWKx+ALJhJCG1N/bkhExCiKW/vsfwmrIVmHADOgwJBhAzlwS7+6Fbvhnp6dSuJ5NZM9eSv6Si9FyD3VrmSGGQ5PzgsywlCfw/Mto8nW3q6Pq
JkpW0SUY39vQBgOxvwh3tWREjHNIJkf9t8txTz1FJZPmmSgcJgEkDt8W7g+nL4FShenp7Kubi1QKt7Wb1JFHMfX6b6Muwir0qnJB0y6kDEOD4Bz8/ilIx6eIbo7qE0kDGFVEhLsa4jhw
lszUqaVloC+zB0eRD9sJS6WItnbTf/vPUD/P/fX+Ef8O85F3QUeWU20nxlrU2MHxrNaCFw+N0CCIwT/hdUz76c3YOXOwtX4qRlhkLB8ebg1CI2x8cQO88PIAAVbVe1vhPo9W2sWAvhxj
HX+voQHsunX0gf5SRMbeDDiHeGnKN99GqtLDo0YIVIdnz5NR7WbRArjm/ZwSpNnfefSVNkOpFLeRl4q44hZccTN29iy6/vvnmXnvL/AWzsdUegmsRVGuTecpJDpRhnHPAHr/o1AsY7xY
G6wN+2NfoP2dARdjq7+MsY5NvzdEsH4CXNESM5DLU/v9SqL/dT3P/cNV/KFW4/h0hmEdTWYNEkVE7zidznXdXP19j48fVqBz01YCMagR7Nw5pE85mczZb8KbMx+t9mD6+ijb2OW5Np3n
ROsNvwClMWXkvhWob7EIPVE/K2slUiPIQYy3+k8w3s6taXydyuUKa1oyL1gEwgCvawrpFQ9xwdx5fMumiESG7dlr5FBrcL/5I5fMm8ovF8xmqgvxxeBJ3JXjamXC/hp1a6ghHGksX07n
OWEk4Efx1BH+9Ax6/tWEmRSeeNzWu453rV9Jp/GJ2psADsSouheq1dJi4r2f7UbCWKAmIje25LAIVUhnCDa8jP7TZ/iF57E6qMcHFg2XQ9Ygqtg3HM11M6bzmVrAIdV+vHKZUnEz5eJm
wiCky/dZYn2+mcnzi1xhZOAPRk/ojXdDLUCMQRB+VtkY7yjKRFD/ICI3ArXmR2++dQO4QqFwSBTJKsBvSXbQWqTUg/eD63n7e9/Hf4QhzvNGFN+rU8QMsvYl53gpCS2nJruN05pQGpFq
c4n0P/kcet4/4HwPI4busJ+j1v2aUhTiSVvnAxq3FlirR5RKpWebHX0zxEu0pVLpWVW9S+LdoWjsuenQXB730au448F7uc/zsGE0oj8sRgYmcRrgAGM4yXqcZD1eYyzTZPDnIyo7a7Tu
OYd+5joII9QIIpavFZ9nY9hP2rR9b0EkIqKqdyXgb6NkzQ6ts8g3Eq927PMbquD5uGqVvsvez7/85XnKnsWE4YhskDTpNZeAHbHt8Ag7UnUWhXHxyQ/uhEeewHVkMQp/qfdyfelFssYf
2Q7k+Dl/iMg3dvT4QwGOAKlUig+q6oqWaYEoQnN5/JdfYcXZ5/D+3z+OeB4a7Z5r1UhvNub07pYNC6O4dXLlGvjyD2BKJy6KMOLzr1ufZUtUa2U3755K/4pKpfgggwemb+P47Wj91POy
3cbwnpFqzT3RBJpOk1m/kcduvpngoIM488gjiaJoYMpHy64wihNJz61Dr7gG+mtEnsE3Pg9U1nP15jVkjT8RQj8VEeOcfCQM+59iB1VfdieWz4Rh/1Oel15qjBwARK0kQbZW594f/5Ba
GHHWmWckP9LWkKAB/urnYvA39eCyaazC5qjOW9Y/StlFeDIhbL91Tlf09RWv3lmG1+5Ci7pUKvMsyOUt0wINElhLNp3lvnvvZuPGTSxduhRrDVEYYswY3UZjW9oa+O0f0Ss+B8UyLpeB
yGHEcvGGlSzv76HDeu0e9zdiVyPCJUFQe4Gd1HzuSqQaB0n9pzHjcIK4CJ61FIubOeOMs/iP736H+Qvmx+NXGsWho+WENn5fFKHX3QrfuhmEOORziojlvRtWckPvOrpMqi0Pit6x9Luf
Vaultzaw3BnIu3KsyWRSK1XlA00aoGXG2DlHLtfBk0+u5uaf3MKS/HQWHncMoU1GLDfO3BmpaWiADvEOoxF4fA36sa/BTb+CXIbQGjwMdeDyjSv5Ye9LEwX8xg2G1up59Xp9y5DvD5sA
Cth6vd7teZmUMXJay3yBoSTI5ukpl7n1jluZ/8gzvLZzBnLwPELPYhrgRy7OXmty69ocx2vysyQgbIAuAmtfQb96A1zz7/BKN25KB6qKZ3zWhlXOW/8od1Y20GUnBPhN0s8XKpXSLUPj
/pGYgMbPkz2Crj+KyCHJKra8/sGIIbTQV+rl0sxsvnzqOcw+5ww4awnRovkYGcHI9U1bYfkq9I4HYfmf0GIZ15kDI3gam8obyy/zyU2rWRf202X97RtM2jTlCyKq+my1WjyawZy/7i4B
BnyBfL7rdJD7QMdtdI8AxlhKGrAgMHwuu4D3zHsN6UUHwTGHEC1eEE/jnD0Nk/IBicfHv7wJ1r6M/mVDHNo98Sy6flPcIZnP4Hk+jRKf5X1b+JctT3FPtZu0WNJiJoLDNxDDxCfB6RmV
SvH+Xdn+kRCABPAwlyt83RhzZVJAOm7zmzwR+lDqOI60eS5LzeSi1EzmelnwPcikQDQ+AVMV7euHIIzVmbWYbCYu6BALUUQxrPHb2la+X1rHHZX11FQpGA+HTqSav1BEPOfcN6rV0scb
mA1HqIYtfIDN5wuPiJhjWx4V7PCGhIpGRKLM8bOckt2P16W6eL3fxRGpDqYYPy57bEwNIfYF+sOAV8Ia/69/K3dWN/JI/1aeD/oApcN4GGQiSf2A3Vd1j1cqpZPYNgs+KgQYyA10dnYu
cs48RtzVtduZ1lHzDZLjVuo4+l283WPFcoCXYZaXYarxmGPT9KtjaxQQoKwL+9kY1dia1POlxJAWm+RJJ1zHUKOCq88Yd3xvb+/TjKCsb6TgeUCYzxfeI2J+rKoBg9vG43o1NEJjGmdN
HQHaNI1zcI64J4Ivgk+jLU0ncn9gICK+qruoUindOFzVP5wwcCdeJl4Q1P7o+6mciDkVCGiTKa7apPc8EdJiySSv9MDL4IkgyPB05MQA/8uVSunrIwV/d5M6jZ3VMJcr3GqMOb+dNME+
dAUi4jvnbqtWS+9MwI9Gymmzm4IWAaZaLVzqnC4TEZ/xmDe4715hDL4uq1YLlyY4jhj83SVAU1pxXZ8x0XnO6erk5NFJErQs3NPVxkTnwbq+bTEZuTrfkyvZMMrNBv8+Y+Tw8c4R7Cvg
Q3BGtVpdP5xkz1hogIH4E7DxjQRnTGqCiQX+aBBgRyRYlZAgmMRsVB0+zzldNZrgjxYBtiGBSHi6c/pw4hhOkmDUvH19WCQ8fTTB3508wKs5hjYIgnIQ7Hez5wWLjJGjEnMwOZ95N6Ot
BPxbqtXcBUGwpWc0wR9tAjRu2kC5HgS1W3w/nRWRUxmsRjWTuA5boxoRMar6pWq1+AEoB4xB57YdI+YKYIKgdo/vp54FOUNEsok2mCTBMJw9oAj6t0mGz+xJqDeWYeCrXR4QdnR0HKZq
vy8iS1R1T47+25svB5BI/QqR6PJyufwku5HeHW8NMPShvHq9vjEIajd4XiYvIq9PGk4mfYNtbb2Nq3n4erVavKRer68fa/BbQYAGCQwQBkH/r3w/9Ygqxxojsyd9g0FbH4d4+t5qtfjt
pjUZ864s20KWSxwl1J4Jgtr3fD+twIlJuNjcwrevqHuNpZ4a8MVqtfjeIKitacKkJRuVrd7G1eRv1oOg9kAqlbsD3GwRc/iQPkTZi4F3ImLjnj13O9iLKpWemxJVb1sh9a10Anf1d23D
vuXzhTeBfFZE3gCQOIqN6uOJToZGmYKIxIORVfU3oNdUKqV7mpzliHEoTxjvxTXNHnBHR9f5qlwJckp8pInSFDqaiSjtgJcMZwZ0mQjfKJeLt+3o+cdLEtvh2kb1xRqBD4KcIyLphAiu
yaE0bQ66SZw7VLUG+nPguiaJZzzUfTsToHlRBiq1kvzBpcAFcVPKgFZoXujxDCW1ScUPgJ7c57PALSLRDUk831hv0w7AtysBmonQPK8wk8t1vlFEzgfOFDEL4kUecJajpihirHoYtdmD
H/RjpOmAUrcWuFdVb6tWex8A+ptUvbQT8O1OgGYfYcjxtrPyuVzfKcBZIpwOckQSStKkIZqBan5OeZXn1p28DxCreUZBXAupq1S5H7i7Ws0ugw2Vpt/nNWmrtrwmiofdLNnbSFGhUDjY
OTlOVZeocqwIh4LMBkk1Hx08stA6OWJ2m89rHXS9Ks+I8LiIrDBGV5ZKpT/vJLSeEEXHEzHEkiaVul2adMaMGR3VarhAxC12Tg8VkYXAAcB00Dlx7xzT2b5sLQQ2xb2P8kr8NS+q6vPG
yDOqZk0u563t7u4u7+CePLatSp8w1/8Hbd0SOMegg3gAAAAASUVORK5CYII=
]],
}
UIFX.icon_cache = {}
function UIFX.icon_tex(key)
    local e = UIFX.icon_cache[key]
    if e == nil then e = {}; UIFX.icon_cache[key] = e end
    if e.tex ~= nil or e.failed then return e.tex end
    local data = UIFX.ICONS[key]
    if not data then e.failed = true; return nil end
    local ok, tex = pcall(function()
        ensure_cache()
        local path = cache_dir .. "icon_" .. key .. ".png"
        local need = math.floor(#(data:gsub("[^%w%+/]", "")) * 6 / 8)
        local have = 0
        local f = io.open(path, "rb")
        if f then have = f:seek("end") or 0; f:close() end
        if have < need - 2 or have > need + 2 then
            if not write_file(path, UIFX.b64(data)) then error("write failed") end
        end
        return imgui.CreateTextureFromFile(path)
    end)
    if ok and tex then e.tex = tex else e.failed = true end
    return e.tex
end

-- фото со скруглёнными углами и приближением (zoom 0..1); если не получится, рисуем обычное
function UIFX.photo(dl, tex, p0, p1, zoom, col, rounding)
    local z = (zoom or 0) * 0.05
    local uv0, uv1 = imgui.ImVec2(z, z), imgui.ImVec2(1 - z, 1 - z)
    if UIFX.round_mode ~= 2 then
        if pcall(dl.AddImageRounded, dl, tex, p0, p1, uv0, uv1, col, rounding or 8, 0) then
            UIFX.round_mode = 1
            return
        end
        UIFX.round_mode = 2
    end
    pcall(dl.AddImage, dl, tex, p0, p1, uv0, uv1, col)
end

-- вертикальный градиент цвета (r,g,b) от прозрачности a0 (сверху) до a1 (снизу)
function UIFX.grad(dl, x0, y0, x1, y1, a0, a1, r, g, b)
    if UIFX.grad_mode ~= 2 then
        local c0, c1 = col32(r, g, b, a0), col32(r, g, b, a1)
        if pcall(dl.AddRectFilledMultiColor, dl, imgui.ImVec2(x0, y0), imgui.ImVec2(x1, y1), c0, c0, c1, c1) then
            UIFX.grad_mode = 1
            return
        end
        UIFX.grad_mode = 2
    end
    local n = 8
    for i = 0, n - 1 do
        local t = (i + 0.5) / n
        dl:AddRectFilled(imgui.ImVec2(x0, y0 + (y1 - y0) * i / n), imgui.ImVec2(x1, y0 + (y1 - y0) * (i + 1) / n + 1),
            col32(r, g, b, a0 + (a1 - a0) * t), 0)
    end
end

local function draw_extra_tab(id)
    if id == 5 then
        draw_about_tab()
    elseif id == 7 then
        draw_settings_tab()
    end
end


-- Подключение иконок к шрифту. В разных версиях fAwesome6 по-разному: где-то есть fa.Init(),
-- где-то только данные шрифта (fa.get_font_data_base85) - тогда подключаем вручную.
local fa_keep = {}
local fa_diag_done = false
local function fa_merge(font_size)
    if type(fa.Init) == "function" then
        if font_size and pcall(fa.Init, font_size) then return true end
        if pcall(fa.Init) then return true end
    end
    local data
    if type(fa.get_font_data_base85) == "function" then
        local ok, d = pcall(fa.get_font_data_base85, "solid")
        if ok and type(d) == "string" and #d > 100 then data = d end
        if not data then
            ok, d = pcall(fa.get_font_data_base85)
            if ok and type(d) == "string" and #d > 100 then data = d end
        end
    end
    if not data then
        if not fa_diag_done then
            fa_diag_done = true
            local names = {}
            for k, v in pairs(fa) do
                if type(k) == "string" and not k:match("^[A-Z0-9_]+$") then
                    names[#names + 1] = k .. ":" .. type(v)
                end
            end
            table.sort(names)
            log_error("fa_diag", "нет способа подключить иконки; поля fAwesome6: " .. table.concat(names, ", "))
        end
        return false
    end
    local mn = tonumber(fa.min_range) or 0xE000
    local mx = tonumber(fa.max_range) or 0xF8FF
    local cfg = imgui.ImFontConfig()
    cfg.MergeMode = true
    cfg.PixelSnapH = true
    local ranges = imgui.new.ImWchar[3](mn, mx, 0)
    fa_keep[#fa_keep + 1] = { cfg, ranges } -- держим в памяти до сборки атласа шрифтов
    local f = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(data, font_size or 14, cfg, ranges)
    return f ~= nil
end

imgui.OnInitialize(function()
    -- иконки сначала в стандартный шрифт (его создаёт mimgui), потом ещё раз в свой шрифт ниже
    safe_call("fa_init", function() fa_merge(nil) end)
    -- шрифт рисуем в 2 раза крупнее и уменьшаем масштабом: так крупные надписи (SetWindowFontScale) остаются чёткими,
    -- а обычный текст выглядит как раньше
    safe_call("custom_font", function()
        local path
        for _, f in ipairs(FONT_AVAILABLE) do
            if f.key == UI_CFG.font and f.path then path = f.path end
        end
        if not path then
            -- "Системный": берём тот же Trebuchet, который mimgui использует по умолчанию
            local ok, dir = pcall(getFolderPath, 0x14)
            if ok and dir then
                for _, name in ipairs({ "trebucbd.ttf", "trebuc.ttf", "arial.ttf" }) do
                    if doesFileExist(dir .. "\\" .. name) then path = dir .. "\\" .. name break end
                end
            end
        end
        if not path then return end
        local io_ = imgui.GetIO()
        local font = io_.Fonts:AddFontFromFileTTF(path, 28, nil, io_.Fonts:GetGlyphRangesCyrillic())
        if font ~= nil then
            -- иконки в тот же крупный размер (если версия fAwesome6 не принимает размер, берётся обычный)
            fa_merge(28)
            io_.FontDefault = font
            io_.FontGlobalScale = 0.5
        end
    end)
    safe_call("apply_theme", apply_theme)
    safe_call("load_data", load_data)
end)

-- свой уголок изменения размера: окно тянется по смещению мыши, форма курсора не меняется
local grip = { on = false, mx = 0, my = 0, w = 0, h = 0 }
local function draw_resize_grip()
    -- угол окна считаем по рабочей области (окно содержимого стоит в правом нижнем углу)
    local wp, ws = imgui.GetWindowPos(), imgui.GetWindowSize()
    local cx, cy = wp.x + ws.x, wp.y + ws.y
    -- невидимая кнопка не даёт окну "уехать" при перетаскивании за угол
    imgui.SetCursorPos(imgui.ImVec2(ws.x - 28, ws.y - 28 + imgui.GetScrollY()))
    imgui.InvisibleButton("##resize_grip", imgui.ImVec2(20, 20))
    local mp = imgui.GetMousePos()
    local hov = mp.x >= cx - 34 and mp.x <= cx + 4 and mp.y >= cy - 34 and mp.y <= cy + 4
    if not grip.on and hov and imgui.IsMouseClicked(0) then
        grip.on = true
        grip.mx, grip.my, grip.w, grip.h = mp.x, mp.y, LAYOUT.w, LAYOUT.h
    end
    if grip.on then
        if imgui.IsMouseDown(0) then
            local sw, sh = getScreenResolution()
            LAYOUT.req = {
                w = clamp(grip.w + mp.x - grip.mx, 700, math.max(700, sw - 20)),
                h = clamp(grip.h + mp.y - grip.my, 400, math.max(400, sh - 20)),
            }
        else
            grip.on = false
        end
    end
    local ac = UI_CFG.accent
    local a = (hov or grip.on) and 0.95 or 0.55
    imgui.GetWindowDrawList():AddTriangleFilled(
        imgui.ImVec2(cx - 6, cy - 6), imgui.ImVec2(cx - 6, cy - 22), imgui.ImVec2(cx - 22, cy - 6),
        col32(ac[1], ac[2], ac[3], a))
end

-- размеры окна: запоминаем в настройках, пересчитываем высоту вкладок левой панели
local function layout_update(wsz)
    if wsz.x < 700 or wsz.y < 400 then
        wsz = imgui.ImVec2(math.max(700, wsz.x), math.max(400, wsz.y))
        imgui.SetWindowSize(wsz, imgui.Cond.Always)
    end
    LAYOUT.w, LAYOUT.h = wsz.x, wsz.y
    LAYOUT.tab_h = clamp(math.floor((LAYOUT.h - 161) / 5) - 5, 26, 46)
    LAYOUT.block_y = 5 + 5 * (LAYOUT.tab_h + 5) + 6
    local w, h = math.floor(wsz.x + 0.5), math.floor(wsz.y + 0.5)
    if w ~= UI_CFG.win_w or h ~= UI_CFG.win_h then
        UI_CFG.win_w, UI_CFG.win_h = w, h
        mark_ui_dirty()
    end
end

-- Заставка при первом открытии меню: логотип, версия и полоска загрузки (клик по ней закрывает)
function UIFX.draw_splash(wpos)
    if not UIFX.splash_t then return end
    local V = imgui.ImVec2
    local el = imgui.GetTime() - UIFX.splash_t
    local dur = 2.0
    if el >= dur then
        UIFX.splash_t = nil
        return
    end
    imgui.SetCursorPos(V(0, 0))
    if imgui.InvisibleButton("##splash_block", V(LAYOUT.w, LAYOUT.h)) then
        UIFX.splash_t = nil
        return
    end
    local a = (el < 1.35) and 1 or clamp(1 - (el - 1.35) / (dur - 1.35), 0, 1)
    local ac = UI_CFG.accent
    local dl = imgui.GetWindowDrawList()
    local x1, y1 = wpos.x + LAYOUT.w, wpos.y + LAYOUT.h
    dl:AddRectFilled(wpos, V(x1, y1), col32(0.04, 0.035, 0.06, 0.98 * a), 12)
    local cx, cy = (wpos.x + x1) / 2, (wpos.y + y1) / 2 - 24
    for i = 5, 1, -1 do
        dl:AddCircleFilled(V(cx, cy), 40 + i * 26, col32(ac[1], ac[2], ac[3], 0.035 * a), 40)
    end
    if UI_CFG.halloween then UIFX.hw_safe(UIFX.hw_pumpkin, dl, cx, cy - 92, 30, a, true) end
    local grow = 1 + 0.12 * (1 - clamp(el / 0.7, 0, 1)) ^ 2
    local title = "Arizona Prices"
    imgui.SetWindowFontScale(2.6 * grow)
    local ts = imgui.CalcTextSize(title)
    dl:AddText(V(cx - ts.x / 2 + 2, cy - ts.y / 2 + 2), col32(0, 0, 0, 0.6 * a), title)
    dl:AddText(V(cx - ts.x / 2, cy - ts.y / 2), col32(1, 1, 1, a), title)
    imgui.SetWindowFontScale(1.2)
    local sub = "Версия " .. SCRIPT_VERSION .. "  |  t.me/arizona_prices"
    local ss = imgui.CalcTextSize(sub)
    dl:AddText(V(cx - ss.x / 2, cy + ts.y / 2 + 12), col32(0.75, 0.78, 0.9, a), sub)
    imgui.SetWindowFontScale(1.0)
    local bw = 240
    local bx, by = cx - bw / 2, cy + ts.y / 2 + 62
    dl:AddRectFilled(V(bx, by), V(bx + bw, by + 6), col32(1, 1, 1, 0.10 * a), 3)
    dl:AddRectFilled(V(bx, by), V(bx + bw * clamp(el / (dur - 0.3), 0, 1), by + 6), col32(ac[1], ac[2], ac[3], a), 3)
    if UI_CFG.halloween then
        imgui.SetWindowFontScale(1.1)
        local hs = imgui.CalcTextSize("Happy Halloween")
        dl:AddText(V(cx - hs.x / 2, by + 20), col32(1.0, 0.60, 0.15, a), "Happy Halloween")
        imgui.SetWindowFontScale(1.0)
    end
end

imgui.OnFrame(function() return main_window[0] or modal_window[0] or UIFX.alpha > 0 end,
    guard_frame("menu", function(player)
        UIFX.tick()
        if main_window[0] or UIFX.alpha > 0 then
        UIFX.set_alpha(UIFX.alpha)
            local sw, sh = getScreenResolution()
            imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5)) 
            if LAYOUT.force then
                LAYOUT.force = false
                imgui.SetNextWindowSize(imgui.ImVec2(835, 500), imgui.Cond.Always)
            elseif LAYOUT.req then
                imgui.SetNextWindowSize(imgui.ImVec2(LAYOUT.req.w, LAYOUT.req.h), imgui.Cond.Always)
                LAYOUT.req = nil
            else
                imgui.SetNextWindowSize(imgui.ImVec2(UI_CFG.win_w, UI_CFG.win_h), imgui.Cond.FirstUseEver)
            end
            pcall(imgui.SetNextWindowSizeConstraints, imgui.ImVec2(700, 400), imgui.ImVec2(math.max(700, sw - 20), math.max(400, sh - 20)))
            if imgui.Begin(u8("Arizona Prices##main_window"), main_window[0] and main_window or nil, bit.bor(imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoScrollWithMouse)) then
                layout_update(imgui.GetWindowSize())
                local wpos = imgui.GetWindowPos()
                local win_cx, win_cy = wpos.x + LAYOUT.w / 2, wpos.y + LAYOUT.h / 2
                hk.typing = imgui.GetIO().WantTextInput

                -- Левая панель с вкладками
                draw_sidebar_bg(wpos)
                imgui.SetCursorPos(imgui.ImVec2(5, 5))
                sidebar_tab(FA.CIRCLE_DOLLAR .. u8(" Arizona Prices"), 1, "Таблица цен предметов (клавиша 1)\nCtrl+F - быстрый поиск")
                sidebar_tab(ic("CALCULATOR", "") .. " Калькулятор", 2, "Калькулятор с историей (клавиша 2)")
                sidebar_tab(ic("CIRCLE_INFO", "") .. " О скрипте", 5, "Соцсети и разработчик (клавиша 3)")
                sidebar_tab(ic("GEAR", "") .. " Настройки", 7, "Тема, шрифт, прозрачность (клавиша 4)")
                UIFX.draw_bar(wpos)
                draw_update_block()

                -- Правая часть (содержимое выбранной вкладки)
                local tk = clamp((imgui.GetTime() - UIFX.tab_t) / 0.30, 0, 1)
                local te = 1 - (1 - tk) ^ 3
                local slide = (1 - te) * 30
                UIFX.base = UIFX.alpha * te
                UIFX.set_alpha(UIFX.base)
                imgui.SetCursorPos(imgui.ImVec2(SIDEBAR_W + slide, 0))
                local content_flags = imgui.WindowFlags.AlwaysUseWindowPadding or 0
                if not (current_tab == 2 and (LAYOUT.h < 495 or LAYOUT.w < 830)) then
                    content_flags = bit.bor(content_flags, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoScrollWithMouse)
                end
                local content_visible = imgui.BeginChild("##content", imgui.ImVec2(LAYOUT.w - SIDEBAR_W - slide, LAYOUT.h), false, content_flags)
                if content_visible then
                if UI_CFG.bg_fx then pcall(UIFX.draw_bg) end
                if UI_CFG.halloween then UIFX.hw_safe(UIFX.hw_bg) end
                if current_tab == 1 then
                imgui.AlignTextToFramePadding() 
                imgui.SetCursorPosX(9) 
                local hdr_pos = imgui.GetCursorScreenPos()
                imgui.Text(FA.CIRCLE_DOLLAR .. u8(' Arizona Prices'))
                if imgui.IsItemHovered() then
                    local r0, r1 = imgui.GetItemRectMin(), imgui.GetItemRectMax()
                    imgui.GetWindowDrawList():AddLine(imgui.ImVec2(r0.x, r1.y), imgui.ImVec2(r1.x, r1.y), col32(UI_CFG.accent[1], UI_CFG.accent[2], UI_CFG.accent[3], 1), 1.5)
                    imgui.SetTooltip("Открыть наш Telegram-канал @arizona_prices")
                    if imgui.IsMouseClicked(0) then open_url("https://t.me/arizona_prices") end
                end
                imgui.SameLine(140) 
                imgui.SetNextItemWidth(math.max(90, LAYOUT.w - SIDEBAR_W - 329)) 
                if UIFX.focus_search then
                    imgui.SetKeyboardFocusHere()
                    UIFX.focus_search = false
                end
                imgui.InputTextWithHint("##search", FA.MAGNIFYING_GLASS .. " Поиск", buf_search, ffi.sizeof(buf_search))
                imgui.SameLine() 
                imgui.SetNextItemWidth(150)
                
                local sort_items = {"По умолчанию", "Сначала дорогие", "Сначала дешёвые", "По алфавиту", "Коллекционные", "Прочее"}
                local sort_preview = sort_items[current_sort[0] + 1] or "Сортировка"
                if imgui.BeginCombo("##sort_combo", sort_preview) then
                    for i, name in ipairs(sort_items) do 
                        local is_selected = current_sort[0] == (i - 1) 
                        if imgui.Selectable(name, is_selected) then 
                            current_sort[0] = i - 1 
                        end 
                        if is_selected then 
                            imgui.SetItemDefaultFocus() 
                        end 
                    end 
                    imgui.EndCombo()
                end
                
                imgui.SameLine(LAYOUT.w - SIDEBAR_W - 29) 
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0)) 
                if imgui.Button(FA.CIRCLE_XMARK .. "##close", imgui.ImVec2(24, 24)) then 
                    main_window[0] = false 
                end 
                if imgui.IsItemHovered() then imgui.SetTooltip("Закрыть") end
                imgui.PopStyleColor(1) 
                imgui.Spacing()

                local q_now = ffi.string(buf_search)
                if q_now ~= UIFX.last_q or current_sort[0] ~= UIFX.last_sort then
                    UIFX.last_q, UIFX.last_sort = q_now, current_sort[0]
                    UIFX.table_t = imgui.GetTime()
                end
                if not UIFX.hint_shown then
                    UIFX.hint_shown = true
                    notify("Подсказка: правая кнопка мыши по предмету - быстрые действия, звёздочка - избранное", "info", 7)
                end
                if imgui.BeginChild("##table_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then 
                    local table_style = imgui.GetStyle() 
                    local table_start_x = imgui.GetCursorScreenPos().x
                    local table_top_y = imgui.GetCursorScreenPos().y - table_style.WindowPadding.y 
                    local separator_spacing = table_style.ItemSpacing.y 
                    local col_wl = 110
                    local col_w1, col_w2, col_w3 = 140, 120, ADM.on and 108 or 44
                    local col_w0 = math.max(110, math.floor(imgui.GetContentRegionAvail().x) - (col_wl + col_w1 + col_w2 + col_w3))
                    
                    imgui.Columns(5, "item_table", false) 
                    imgui.SetColumnWidth(0, col_w0) 
                    imgui.SetColumnWidth(1, col_wl) 
                    imgui.SetColumnWidth(2, col_w1) 
                    imgui.SetColumnWidth(3, col_w2) 
                    imgui.SetColumnWidth(4, col_w3)

                    do 
                        local sz = imgui.CalcTextSize("Предмет")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w0 - sz.x) * 0.5)) 
                        imgui.TextColored(accent_vec(1.3), "Предмет")
                    end 
                    imgui.NextColumn()

                    do
                        local sz = imgui.CalcTextSize("Ликвидность")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_wl - sz.x) * 0.5))
                        imgui.TextColored(accent_vec(1.3), "Ликвидность")
                    end
                    imgui.NextColumn()
                    do 
                        local sz = imgui.CalcTextSize("Скупочная цена")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w1 - sz.x) * 0.5)) 
                        imgui.TextColored(accent_vec(1.3), "Скупочная цена")
                    end 
                    imgui.NextColumn()

                    do 
                        local sz = imgui.CalcTextSize("Продажа")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w2 - sz.x) * 0.5)) 
                        imgui.TextColored(accent_vec(1.3), "Продажа")
                    end 
                    imgui.NextColumn()

                    do 
                        local sz = imgui.CalcTextSize("Действия")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w3 - sz.x) * 0.5)) 
                        imgui.TextColored(accent_vec(1.3), "Действия")
                    end 
                    imgui.NextColumn() 
                    imgui.Separator()

                    local table_bottom_y = imgui.GetCursorScreenPos().y - separator_spacing - 1.0 
                    local display_indices = {} 
                    local search_query = lower_cp1251(ffi.string(buf_search))

                    -- фильтры "Коллекционные" / "Прочее" (пункты 4 и 5 в списке сортировки)
                    local flt = current_sort[0]
                    local coll_marks = { u8:decode("легендарн"), u8:decode("хлам"), u8:decode("редк") }
                    local prof_mark = u8:decode("проф.")
                    local function is_collectible(name)
                        -- метка стоит в скобках: "Нимб лича (Легендарный)", "(Хлам/Редкий)"
                        for grp in name:gmatch("%((.-)%)") do
                            for _, m in ipairs(coll_marks) do
                                if grp:find(m, 1, true) then return true end
                            end
                        end
                        for grp in name:gmatch("%[(.-)%]") do
                            for _, m in ipairs(coll_marks) do
                                if grp:find(m, 1, true) then return true end
                            end
                        end
                        return false
                    end
                    local function is_other(name)
                        return name:gsub("^%s+", ""):sub(1, #prof_mark) == prof_mark
                    end

                    for i, v in ipairs(items_list) do 
                        local item_name = lower_cp1251(v.item or "") 
                        if search_query == "" or item_name:find(search_query, 1, true) then 
                            if flt == 4 then
                                if is_collectible(item_name) then table.insert(display_indices, i) end
                            elseif flt == 5 then
                                if is_other(item_name) then table.insert(display_indices, i) end
                            else
                                table.insert(display_indices, i) 
                            end
                        end 
                    end

                    if current_sort[0] == 1 then 
                        table.sort(display_indices, function(a, b) return tonumber(items_list[a].sell or 0) > tonumber(items_list[b].sell or 0) end)
                    elseif current_sort[0] == 2 then 
                        table.sort(display_indices, function(a, b) return tonumber(items_list[a].sell or 0) < tonumber(items_list[b].sell or 0) end)
                    elseif current_sort[0] == 3 then 
                        table.sort(display_indices, function(a, b) local name_a = (items_list[a].item or ""):lower() local name_b = (items_list[b].item or ""):lower() return name_a < name_b end)
                    end

                    if next(settings.favs) then
                        -- избранные поднимаем наверх (порядок внутри групп сохраняется)
                        local favs_first, rest = {}, {}
                        for _, ix in ipairs(display_indices) do
                            if items_list[ix] and settings.favs[items_list[ix].item] then
                                favs_first[#favs_first + 1] = ix
                            else
                                rest[#rest + 1] = ix
                            end
                        end
                        for _, ix in ipairs(rest) do favs_first[#favs_first + 1] = ix end
                        display_indices = favs_first
                    end
                    local row_now = imgui.GetTime()
                    for ri, idx in ipairs(display_indices) do 
                        local item = items_list[idx]
                        if item then 
                            local row_y = imgui.GetCursorPosY() 
                            local ra = clamp((row_now - UIFX.table_t - math.min(ri, 14) * 0.03) / 0.22, 0, 1)
                            UIFX.set_alpha(UIFX.base * ra)
                            do
                                local rp = imgui.GetCursorScreenPos()
                                local rx1 = table_start_x + col_w0 + col_wl + col_w1 + col_w2 + col_w3
                                local r0, r1 = imgui.ImVec2(table_start_x, rp.y - 2), imgui.ImVec2(rx1, rp.y + 27)
                                local row_hover = imgui.IsMouseHoveringRect(r0, r1)
                                if row_hover and imgui.IsWindowHovered() and imgui.IsMouseClicked(1) then
                                    selected_item_name = item.item
                                    UIFX.ctx_open = true
                                end
                                if row_hover and imgui.IsWindowHovered() and imgui.IsMouseClicked(0) then
                                    selected_item_name = item.item
                                end
                                if selected_item_name ~= nil and item.item == selected_item_name then
                                    imgui.GetWindowDrawList():AddRectFilled(r0, r1, col32(UI_CFG.accent[1], UI_CFG.accent[2], UI_CFG.accent[3], 0.30), 6)
                                elseif row_hover then
                                    imgui.GetWindowDrawList():AddRectFilled(r0, r1, col32(UI_CFG.accent[1], UI_CFG.accent[2], UI_CFG.accent[3], 0.14), 6)
                                elseif ri % 2 == 0 then
                                    imgui.GetWindowDrawList():AddRectFilled(r0, r1, col32(1, 1, 1, 0.025), 6)
                                end
                            end
                            local item_text = item.item or "" 
                            local sz = imgui.CalcTextSize(item_text)
                            imgui.SetCursorPosY(row_y + math.max(0, (24 - sz.y) * 0.5)) 
                            local icon_w = imgui.CalcTextSize(FA.CIRCLE_QUESTION).x 
                            local max_w = col_w0 - icon_w - 12

                            if sz.x > max_w then 
                                local truncated = item_text
                                while #truncated > 3 and imgui.CalcTextSize(truncated .. "...").x > max_w do
                                    local len = #truncated 
                                    local pos = len 
                                    while pos > 0 and truncated:byte(pos) >= 128 and truncated:byte(pos) < 192 do 
                                        pos = pos - 1 
                                    end 
                                    truncated = truncated:sub(1, pos - 1)
                                end
                                truncated = truncated .. "..." 
                                imgui.Text(truncated) 
                                if imgui.IsItemHovered() then imgui.SetTooltip((item_text:gsub("%%", "%%%%"))) end 
                                imgui.SameLine(col_w0 - icon_w - 6) 
                                imgui.Text(FA.CIRCLE_QUESTION) 
                                if imgui.IsItemHovered() then imgui.SetTooltip((item_text:gsub("%%", "%%%%"))) end
                            else 
                                imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w0 - sz.x) * 0.5)) 
                                imgui.TextUnformatted(item_text)
                            end

                            imgui.NextColumn()
                            do
                                local liq = item.liq
                                local txt = liq or "-"
                                local lc = UIFX.liq_color(liq)
                                if ADM.on then
                                    -- режим разработчика: клик по значению переключает ликвидность
                                    imgui.SetCursorPosY(row_y)
                                    imgui.PushStyleColor(imgui.Col.Text, lc)
                                    if imgui.Button(txt .. "##liq_" .. idx, imgui.ImVec2(col_wl - 14, 24)) then
                                        item.liq = UIFX.liq_next(liq)
                                        save_data()
                                    end
                                    imgui.PopStyleColor(1)
                                else
                                    local sz = imgui.CalcTextSize(txt)
                                    imgui.SetCursorPosY(row_y + math.max(0, (24 - sz.y) * 0.5))
                                    imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_wl - sz.x) * 0.5))
                                    imgui.TextColored(lc, txt)
                                end
                            end
                            imgui.NextColumn()
                            do 
                                local sz = imgui.CalcTextSize(format_price(item.buy))
                                imgui.SetCursorPosY(row_y + math.max(0, (24 - sz.y) * 0.5)) 
                                imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w1 - sz.x) * 0.5)) 
                                imgui.TextColored(imgui.ImVec4(0.55, 0.92, 0.65, 1.0), format_price(item.buy))
                            end

                            imgui.NextColumn()
                            do 
                                local sale_value = tonumber(item.sell) or 0 
                                local sale_text = format_price(item.sell) 
                                local sz = imgui.CalcTextSize(sale_text)
                                imgui.SetCursorPosY(row_y + math.max(0, (24 - sz.y) * 0.5)) 
                                imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w2 - sz.x - 20) * 0.5)) 
                                imgui.TextColored(imgui.ImVec4(1.0, 0.85, 0.45, 1.0), sale_text)
                                local icon_w = imgui.CalcTextSize(FA.BADGE_PERCENT).x 
                                imgui.SameLine(col_w2 - icon_w - 6) 
                                imgui.Text(FA.BADGE_PERCENT)
                                if imgui.IsItemHovered() then 
                                    imgui.SetTooltip("1%% - " .. format_price(math.floor(sale_value * 0.99 + 0.5)) .. "\n" .. "3%% - " .. format_price(math.floor(sale_value * 0.97 + 0.5)) .. "\n" .. "4%% - " .. format_price(math.floor(sale_value * 0.96 + 0.5)) .. "\n" .. "5%% - " .. format_price(math.floor(sale_value * 0.95 + 0.5))) 
                                end
                            end

                            imgui.NextColumn()
                            local buttons_total_width = ADM.on and (28 * 3 + 10) or 28
                            imgui.SetCursorPosY(row_y) 
                            imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w3 - buttons_total_width) * 0.5))
                            
                            local is_fav = settings.favs[item.item] == true
                            imgui.PushStyleColor(imgui.Col.Text, is_fav and imgui.ImVec4(1.0, 0.82, 0.25, 1.0) or imgui.ImVec4(0.50, 0.52, 0.58, 1.0))
                            if imgui.Button(ic("STAR", "*") .. "##fav_" .. idx, imgui.ImVec2(28, 24)) then
                                UIFX.toggle_fav(item.item)
                            end
                            imgui.PopStyleColor(1)
                            if imgui.IsItemHovered() then imgui.SetTooltip(is_fav and "Убрать из избранного" or "В избранное") end
                            if ADM.on then
                            imgui.SameLine()
                            if imgui.Button(FA.PEN_LINE .. "##edit_" .. idx, imgui.ImVec2(28, 24)) then 
                                open_edit_modal(idx) 
                            end 
                            imgui.SameLine()
                            
                            if imgui.Button(FA.TRASH_CAN .. "##del_" .. idx, imgui.ImVec2(28, 24)) then 
                                pending_delete_index = idx 
                                pending_delete_open = true 
                            end
                            end

                            imgui.NextColumn() 
                            imgui.Separator() 
                            table_bottom_y = imgui.GetCursorScreenPos().y - separator_spacing - 1.0
                        end
                    end
                    imgui.Columns(1)
                    UIFX.set_alpha(UIFX.base)
                    if UIFX.ctx_open then
                        imgui.OpenPopup("##row_ctx")
                        UIFX.ctx_open = false
                    end
                    if imgui.BeginPopup("##row_ctx") then
                        local cur
                        for _, v in ipairs(items_list) do
                            if v.item == selected_item_name then cur = v; break end
                        end
                        if cur then
                            local line = cur.item .. ": скупка " .. format_price(cur.buy) .. " / продажа " .. format_price(cur.sell)
                            imgui.TextColored(accent_vec(1.3), cur.item)
                            imgui.Separator()
                            if imgui.Selectable(ic("COMMENT_DOTS", "") .. "  Вставить в строку чата##ctx_chat") then
                                defer(function()
                                    sampSetChatInputEnabled(true)
                                    sampSetChatInputText(u8:decode(line))
                                end)
                            end
                            if imgui.Selectable(ic("COPY", "") .. "  Скопировать в буфер##ctx_copy") then
                                imgui.SetClipboardText(line)
                                notify("Скопировано: " .. line, "ok", 4)
                            end
                            local isf = settings.favs[cur.item] == true
                            if imgui.Selectable(ic("STAR", "*") .. (isf and "  Убрать из избранного" or "  В избранное") .. "##ctx_fav") then
                                UIFX.toggle_fav(cur.item)
                            end
                        else
                            imgui.Text("Предмет не найден")
                        end
                        imgui.EndPopup()
                    end

                    if table_bottom_y > table_top_y then 
                        local draw_list = imgui.GetWindowDrawList() 
                        local border_col = imgui.GetColorU32(imgui.Col.Separator) 
                        local x = table_start_x 
                        local column_widths = {col_w0, col_wl, col_w1, col_w2}
                        for i = 1, 4 do 
                            x = x + column_widths[i] 
                            draw_list:AddLine(imgui.ImVec2(x, table_top_y), imgui.ImVec2(x, table_bottom_y), border_col, 1.0) 
                        end
                    end
                    imgui.EndChild()
                end

                local add_w = imgui.GetContentRegionAvail().x - 95
                if ADM.on then
                    if imgui.Button(FA.CIRCLE_PLUS .. " Добавить предмет", imgui.ImVec2(add_w, 30)) then
                        open_add_modal()
                    end
                else
                    if imgui.Button(ic("PAPER_PLANE", "") .. " Актуальные цены - в нашем ТГК @arizona_prices##open_tg", imgui.ImVec2(add_w, 30)) then
                        open_url("https://t.me/arizona_prices")
                    end
                end

                imgui.SameLine()
                if imgui.Button(FA.TRIANGLE_EXCLAMATION .. "##report_prices", imgui.ImVec2(30, 30)) then
                    if selected_item_name and selected_item_name ~= "" then
                        imgui.SetClipboardText("Привет. Заметил что цена предмета \"" .. selected_item_name .. "\" изменилась, прошу обновить")
                        open_url("https://t.me/arzprices_ceo")
                        notify("Сообщение скопировано - вставьте его в чат (Ctrl+V)", "ok", 6)
                    else
                        notify("Сначала нажмите на предмет в таблице, цена которого устарела", "warn", 5)
                    end
                end
                if imgui.IsItemHovered() then imgui.SetTooltip("Сообщить об устаревших ценах\n(сначала нажмите на предмет в таблице)") end

                imgui.SameLine()
                if imgui.Button(FA.BUG .. "##report_bug", imgui.ImVec2(30, 30)) then
                    send_bug_report()
                end
                if imgui.IsItemHovered() then imgui.SetTooltip("Сообщить о баге (скопирует данные для разработчика)") end

                if pending_modal_open then 
                    imgui.OpenPopup(is_editing and MODAL_ID_EDIT or MODAL_ID_ADD) 
                    pending_modal_open = false 
                end

                if modal_window[0] then 
                    local popup_title = is_editing and MODAL_ID_EDIT or MODAL_ID_ADD
                    imgui.SetNextWindowPos(imgui.ImVec2(win_cx, win_cy), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5)) 
                    imgui.SetNextWindowSize(imgui.ImVec2(300, 171), imgui.Cond.Always)
                    if imgui.BeginPopupModal(popup_title, modal_window, bit.bor(imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoResize)) then
                        local hint_item = FA.LAYER_GROUP .. " Предмет"
                        local hint_buy = FA.HANDS_HOLDING_DOLLAR .. " Скупочная цена"
                        local hint_sell = FA.HAND_HOLDING_DOLLAR .. " Продажа"
                        
                        if is_blinking then 
                            local elapsed = os.clock() - blink_start_time
                            if elapsed >= 1.2 then 
                                is_blinking = false
                            else 
                                local hide = (elapsed % 0.4) < 0.2 
                                if empty_item_field and hide then hint_item = "" end 
                                if empty_buy_field and hide then hint_buy = "" end 
                                if empty_sell_field and hide then hint_sell = "" end
                            end
                        end

                        if imgui.BeginChild("##modal", imgui.ImVec2(-1, 102), true) then
                            imgui.SetNextItemWidth(-1) 
                            imgui.InputTextWithHint("##modal_item", hint_item, buf_item, ffi.sizeof(buf_item)) 
                            imgui.Separator()

                            imgui.SetNextItemWidth(-1) 
                            imgui.InputTextWithHint("##modal_buy", hint_buy, buf_buy, ffi.sizeof(buf_buy), imgui.InputTextFlags.CharsDecimal) 
                            imgui.Separator()

                            imgui.SetNextItemWidth(-1) 
                            imgui.InputTextWithHint("##modal_sell", hint_sell, buf_sell, ffi.sizeof(buf_sell), imgui.InputTextFlags.CharsDecimal) 
                            imgui.EndChild()
                        end

                        if is_editing then
                            if imgui.Button(FA.FLOPPY_DISK .. " Сохранить", imgui.ImVec2(142, 30)) then
                                local name_str = ffi.string(buf_item) 
                                local buy_str = ffi.string(buf_buy) 
                                local sell_str = ffi.string(buf_sell)
                                empty_item_field = (name_str == "") 
                                empty_buy_field = (buy_str == "") 
                                empty_sell_field = (sell_str == "")

                                if empty_item_field or empty_buy_field or empty_sell_field then 
                                    is_blinking = true 
                                    blink_start_time = os.clock()
                                else 
                                    local name = name_str 
                                    local buy = tonumber(buy_str) 
                                    local sell = tonumber(sell_str)
                                    if buy and sell and edit_index and items_list[edit_index] then 
                                        items_list[edit_index] = {item = name, buy = buy, sell = sell, liq = items_list[edit_index].liq} 
                                        save_data() 
                                        close_modal() 
                                    end
                                end
                            end
                            imgui.SameLine()
                            if imgui.Button(FA.CIRCLE_XMARK .. " Отменить", imgui.ImVec2(142, 30)) then
                                close_modal() 
                            end
                        else
                            if imgui.Button(FA.CIRCLE_PLUS .. " Добавить", imgui.ImVec2(-1, 30)) then
                                local name_str = ffi.string(buf_item) 
                                local buy_str = ffi.string(buf_buy) 
                                local sell_str = ffi.string(buf_sell)
                                empty_item_field = (name_str == "") 
                                empty_buy_field = (buy_str == "") 
                                empty_sell_field = (sell_str == "")

                                if empty_item_field or empty_buy_field or empty_sell_field then 
                                    is_blinking = true 
                                    blink_start_time = os.clock()
                                else 
                                    local name = name_str 
                                    local buy = tonumber(buy_str) 
                                    local sell = tonumber(sell_str)
                                    if buy and sell then 
                                        table.insert(items_list, {item = name, buy = buy, sell = sell}) 
                                        save_data() 
                                        close_modal() 
                                    end
                                end
                            end
                        end
                        imgui.EndPopup()
                    end
                end

                if pending_delete_open then 
                    imgui.OpenPopup(FA.TRASH_CAN .. ' Подтверждение удаления##delete_modal')
                    pending_delete_open = false 
                end

                imgui.SetNextWindowPos(imgui.ImVec2(win_cx, win_cy), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5)) 
                imgui.SetNextWindowSize(imgui.ImVec2(415, 88), imgui.Cond.Always)
                if imgui.BeginPopupModal(FA.TRASH_CAN .. ' Подтверждение удаления##delete_modal', nil, bit.bor(imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoResize)) then
                    imgui.TextWrapped(FA.CIRCLE_QUESTION .. ' Вы действительно хотите удалить этот предмет из справочника?')
                    imgui.Spacing()
                    if imgui.Button(FA.TRASH_CAN .. ' Да, удалить', imgui.ImVec2(200, 30)) then
                        if pending_delete_index and items_list[pending_delete_index] then 
                            table.remove(items_list, pending_delete_index) 
                            save_data() 
                        end 
                        pending_delete_index = nil 
                        imgui.CloseCurrentPopup()
                    end
                    imgui.SameLine()
                    if imgui.Button(FA.CIRCLE_XMARK .. ' Отменить', imgui.ImVec2(200, 30)) then
                        pending_delete_index = nil 
                        imgui.CloseCurrentPopup() 
                    end
                    imgui.EndPopup()
                end

                elseif current_tab == 2 then
                    draw_calculator()
                else
                    draw_extra_tab(current_tab)
                end
                end
                if content_visible then pcall(draw_resize_grip) end
                imgui.EndChild()
                UIFX.set_alpha(UIFX.alpha)
                UIFX.draw_splash(wpos)

                draw_window_fx(wpos.x, wpos.y, wpos.x + LAYOUT.w, wpos.y + LAYOUT.h)
                imgui.End()
            else
                imgui.End()
            end
            UIFX.set_alpha(1)
        end
    end, function() main_window[0] = false; modal_window[0] = false; hk.binding = false; UIFX.alpha = 0; UIFX.set_alpha(1) end)
)

-- ===================== Большое окно «старая версия» =====================
imgui.OnFrame(function() return outdated_popup[0] end, guard_frame("outdated", function()
    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(580, 290), imgui.Cond.Always)
    imgui.SetNextWindowFocus()
    local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoMove,
        imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoSavedSettings)
    -- полностью непрозрачный фон, независимо от настройки прозрачности меню
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.075, 0.07, 0.095, 1.0))
    imgui.Begin("##outdated_window", nil, flags)
    local p = imgui.GetWindowPos()
    imgui.GetWindowDrawList():AddRectFilled(p, imgui.ImVec2(p.x + 580, p.y + 5), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.00, 0.75, 0.15, 1.00)))

    imgui.SetCursorPos(imgui.ImVec2(24, 28))
    imgui.SetWindowFontScale(1.9)
    imgui.TextColored(imgui.ImVec4(1.00, 0.80, 0.20, 1.00), ic("TRIANGLE_EXCLAMATION", "") .. " Внимание!")
    imgui.SetWindowFontScale(1.0)

    imgui.SetCursorPos(imgui.ImVec2(24, 90))
    imgui.SetWindowFontScale(1.3)
    imgui.PushTextWrapPos(556)
    imgui.TextWrapped("У вас старая версия скрипта. Обновите для комфортного использования.")
    imgui.PopTextWrapPos()
    imgui.SetWindowFontScale(1.0)

    imgui.SetCursorPos(imgui.ImVec2(24, 160))
    imgui.TextDisabled("Ваша версия: " .. SCRIPT_VERSION .. "    Новая версия: " .. update_info.version)
    if update_info.status ~= "" then
        imgui.SetCursorPosX(24)
        imgui.TextDisabled(update_info.status)
    end

    imgui.SetCursorPos(imgui.ImVec2(24, 290 - 24 - 44))
    local half = (580 - 48 - 10) / 2
    imgui.PushStyleColor(imgui.Col.Button, accent_vec(1.0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, accent_vec(1.15))
    imgui.PushStyleColor(imgui.Col.ButtonActive, accent_vec(0.85))
    if update_info.busy then
        imgui.Button("Скачивание...##outdated_busy", imgui.ImVec2(half, 44))
    elseif imgui.Button(ic("DOWNLOAD", "") .. " Обновить##outdated_update", imgui.ImVec2(half, 44)) then
        request_update()
    end
    imgui.PopStyleColor(3)
    imgui.SameLine()
    if imgui.Button(FA.CIRCLE_XMARK .. " Закрыть##outdated_close", imgui.ImVec2(half, 44)) then
        outdated_popup[0] = false
    end
    imgui.End()
    imgui.PopStyleColor(1)
end, function() outdated_popup[0] = false end))

function main()
    while not isSampAvailable() do wait(0) end
    safe_call("load_data", load_data)

    sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices] {FFFFFF}Скрипт успешно загружен! Для активации - {33AAFF}/prices{FFFFFF} или {33AAFF}/pr{FFFFFF}. ТГК - {33AAFF}@arizona_prices"), -1)

    sampRegisterChatCommand('prices', toggle_menu)
    sampRegisterChatCommand('pr', toggle_menu)
    sampRegisterChatCommand('pradmin', function(arg)
        arg = tostring(arg or ""):gsub("%s", "")
        if arg == "off" then
            ADM.disable()
            sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices] {FFFFFF}Режим разработчика выключен"), -1)
        elseif arg ~= "" and ADM.enable(arg) then
            sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices] {55FF55}Режим разработчика включён{FFFFFF}. Правка цен и ликвидности открыта"), -1)
        else
            sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices] {FF5555}Неверный код"), -1)
        end
    end)
    addEventHandler('onWindowMessage', function(msg, wparam, lparam)
        safe_call("hotkey", on_window_message, msg, wparam, lparam)
    end)

    local next_check = os.time() + 5
    while true do
        wait(100)
        if pending_url then
            local url = pending_url
            pending_url = nil
            pcall(function() shell32.ShellExecuteA(nil, "open", url, nil, nil, 1) end)
        end
        while #ui_actions > 0 do
            safe_call("action", table.remove(ui_actions, 1))
        end
        if not main_window[0] and hk.binding then hk.binding = false end
        safe_call("updates", process_updates)
        if #pending_notices > 0 then
            local n = table.remove(pending_notices, 1)
            safe_call("notice", notify, n.text, n.kind)
        end
        safe_call("save_ui", flush_ui_save)
        if os.time() >= next_check then
            next_check = os.time() + CHECK_EVERY
            safe_call("start_checks", start_checks)
        end
        if need_reload then
            need_reload = false
            wait(700)
            thisScript():reload()
        end
    end
end

function onScriptTerminate(scr, quit)
    if scr == thisScript() then
        pcall(flush_ui_save, true)
    end
end
