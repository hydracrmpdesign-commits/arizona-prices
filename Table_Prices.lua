local ffi = require('ffi')
local encoding = require('encoding')
encoding.default = 'CP1251'
local u8 = encoding.UTF8

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

local function load_data()
    local data = safe_read_json(datadir)
    if data then
        local clean = {}
        for _, v in ipairs(data) do
            if type(v) == "table" then
                clean[#clean + 1] = { item = tostring(v.item or ""), buy = tonumber(v.buy) or 0, sell = tonumber(v.sell) or 0 }
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
    accent = {0.18, 0.45, 0.85}, opacity = 1.0, overlay_scale = 1.0, open_key = 0, toasts = true, toast_corner = 3,
    border_mode = 1, border_speed = 1.0, shadow = true, font = "seguisb",
    win_w = 835, win_h = 500,
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
    return imgui.ColorConvertFloat4ToU32(imgui.ImVec4(r, g, b, a))
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
local LAYOUT = { w = 835, h = 500, tab_h = 42, block_y = 340, force = false } -- текущие размеры главного окна
local current_tab = 1 -- 1 = Arizona Prices, 2 = Калькулятор, 3 = Отчет до PayDay, 4 = Фразы, 5 = О скрипте, 6 = Время стран

local calc_expr = ""
local calc_prev = ""
local calc_error = nil
local calc_fresh = false

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
        local icon = ic(kind.icon, "")
        local ts = imgui.CalcTextSize(t.text)
        local w = math.min(760, ts.x + 74)
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
        local isz = imgui.CalcTextSize(icon)
        local p0, p1 = imgui.ImVec2(x, y), imgui.ImVec2(x + w, y + H)
        dl:AddRectFilled(p0, p1, col32(0.07, 0.075, 0.09, 0.96 * alpha), 10)
        pcall(function()
            dl:AddRect(p0, p1, col32(c[1], c[2], c[3], 0.60 * alpha), 10, 0, 1.5)
            dl:AddCircleFilled(imgui.ImVec2(x + 25, y + H / 2), 14, col32(c[1], c[2], c[3], 0.18 * alpha), 24)
        end)
        dl:AddText(imgui.ImVec2(x + 25 - isz.x / 2, y + (H - isz.y) / 2), col32(c[1], c[2], c[3], alpha), icon)
        dl:AddText(imgui.ImVec2(x + 50, ty), col32(1, 1, 1, alpha), t.text)
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
    calc_prev = calc_format_expr(calc_expr) .. " ="
    calc_expr = calc_raw_number(res)
    calc_fresh = true
end
-- CALC_LOGIC_END

local function draw_sidebar_bg(wpos)
    local dl = imgui.GetWindowDrawList()
    local col = imgui.ColorConvertFloat4ToU32(dark(0.088, 1.0))
    dl:AddRectFilled(wpos, imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y + LAYOUT.h), col, 12)
    dl:AddRectFilled(imgui.ImVec2(wpos.x + 14, wpos.y), imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y + LAYOUT.h), col)
    dl:AddLine(imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y + 8), imgui.ImVec2(wpos.x + SIDEBAR_W - 1, wpos.y + LAYOUT.h - 8), imgui.GetColorU32(imgui.Col.Separator), 1.0)
end

local function sidebar_tab(label, id)
    local active = (current_tab == id)
    if active then
        imgui.PushStyleColor(imgui.Col.Button, blend(0.115, 0.28))
    end
    imgui.SetWindowFontScale(1.15)
    if imgui.Button(label .. "##tab" .. id, imgui.ImVec2(SIDEBAR_W - 10, LAYOUT.tab_h)) then
        current_tab = id
    end
    imgui.SetWindowFontScale(1.0)
    if active then
        imgui.PopStyleColor(1)
        local rmin, rmax = imgui.GetItemRectMin(), imgui.GetItemRectMax()
        local mid = (rmin.y + rmax.y) / 2
        imgui.GetWindowDrawList():AddRectFilled(imgui.ImVec2(rmin.x + 2, mid - 13), imgui.ImVec2(rmin.x + 5, mid + 13), imgui.ColorConvertFloat4ToU32(accent_vec(1.15)), 2)
    end
end

local function draw_calculator()
    -- Шапка
    imgui.AlignTextToFramePadding()
    imgui.SetCursorPosX(9)
    imgui.Text(ic("CALCULATOR", "") .. " Калькулятор")
    imgui.SameLine(LAYOUT.w - SIDEBAR_W - 29)
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))
    if imgui.Button(FA.CIRCLE_XMARK .. "##close_calc", imgui.ImVec2(24, 24)) then
        main_window[0] = false
    end
    imgui.PopStyleColor(1)
    imgui.Spacing()

    local calc_w, btn_w, btn_h = 355, 85, 54
    local x0 = (LAYOUT.w - SIDEBAR_W - calc_w) / 2

    -- Экран калькулятора
    imgui.SetCursorPosX(x0)
    if imgui.BeginChild("##calc_display", imgui.ImVec2(calc_w, 92), true) then
        local avail = imgui.GetContentRegionAvail().x

        local prev_text = calc_prev ~= "" and calc_prev or " "
        local pw = imgui.CalcTextSize(prev_text).x
        imgui.SetCursorPosX(math.max(5, 5 + avail - pw))
        imgui.TextColored(imgui.ImVec4(0.60, 0.60, 0.65, 1.00), prev_text)

        local shown, color
        if calc_error then
            shown = calc_error
            color = imgui.ImVec4(1.00, 0.35, 0.35, 1.00)
        else
            shown = (calc_expr == "") and "0" or calc_format_expr(calc_expr)
            color = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
        end

        local scale = 1.7
        imgui.SetWindowFontScale(scale)
        while scale > 0.8 and imgui.CalcTextSize(shown).x > avail do
            scale = scale - 0.1
            imgui.SetWindowFontScale(scale)
        end
        local tw = imgui.CalcTextSize(shown).x
        imgui.SetCursorPosX(math.max(5, 5 + avail - tw))
        imgui.TextColored(color, shown)
        imgui.SetWindowFontScale(1.0)
    end
    imgui.EndChild()

    -- Кнопки
    local rows = {
        { {"C", calc_clear, 3}, {ic("DELETE_LEFT", "<"), calc_back, 1}, {ic("PERCENT", "%"), calc_percent, 1}, {ic("DIVIDE", "/"), function() calc_op("/") end, 1} },
        { {"7", function() calc_digit("7") end, 0}, {"8", function() calc_digit("8") end, 0}, {"9", function() calc_digit("9") end, 0}, {ic("XMARK", "x"), function() calc_op("*") end, 1} },
        { {"4", function() calc_digit("4") end, 0}, {"5", function() calc_digit("5") end, 0}, {"6", function() calc_digit("6") end, 0}, {ic("MINUS", "-"), function() calc_op("-") end, 1} },
        { {"1", function() calc_digit("1") end, 0}, {"2", function() calc_digit("2") end, 0}, {"3", function() calc_digit("3") end, 0}, {ic("PLUS", "+"), function() calc_op("+") end, 1} },
        { {"0", function() calc_digit("0") end, 0}, {"000", function() calc_digit("000") end, 0}, {",", calc_dot, 0}, {ic("EQUALS", "="), calc_equals, 2} },
    }

    imgui.SetWindowFontScale(1.25)
    for r, row in ipairs(rows) do
        imgui.SetCursorPosX(x0)
        for c, b in ipairs(row) do
            if c > 1 then imgui.SameLine() end
            local style = b[3]
            local pushed = false
            if style == 1 then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.17, 0.17, 0.19, 1.00))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.21, 0.21, 0.23, 1.00))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.25, 0.25, 0.27, 1.00))
                pushed = true
            elseif style == 2 then
                imgui.PushStyleColor(imgui.Col.Button, accent_vec(1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, accent_vec(1.15))
                imgui.PushStyleColor(imgui.Col.ButtonActive, accent_vec(0.85))
                pushed = true
            elseif style == 3 then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.55, 0.18, 0.18, 1.00))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.65, 0.22, 0.22, 1.00))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.45, 0.15, 0.15, 1.00))
                pushed = true
            end
            if imgui.Button(b[1] .. "##cb" .. r .. "_" .. c, imgui.ImVec2(btn_w, btn_h)) then
                b[2]()
            end
            if pushed then imgui.PopStyleColor(3) end
        end
    end
    imgui.SetWindowFontScale(1.0)
end

-- ===================== Новые разделы: PayDay, фразы, о скрипте =====================
local settings_path = getWorkingDirectory() .. "\\config\\arizona_prices_settings.json"
local settings = { ui = UI_CFG, payday = { enabled = false, x = 20, y = 300 }, phrases = {}, clock = { enabled = false, country = "Узбекистан", x = 20, y = 340 } }

local function load_settings()
    local data = safe_read_json(settings_path)
    if not data then return end
    if type(data.payday) == "table" then
        settings.payday.enabled = (data.payday.enabled == true)
        settings.payday.x = tonumber(data.payday.x) or 20
        settings.payday.y = tonumber(data.payday.y) or 300
    end
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

local payday_on = imgui.new.bool(settings.payday.enabled)
local payday_edit = false
local payday_pos = { x = settings.payday.x, y = settings.payday.y }
local phrase_buf = imgui.new.char[256]()

local function minutes_to_payday()
    local m = tonumber(os.date("%M")) or 0
    if m < 30 then return 30 - m end
    return 60 - m
end

local function payday_text()
    local d = os.date("*t")
    local left = 1800 - ((d.min % 30) * 60 + d.sec)
    return "До PayDay: " .. math.floor(left / 60) .. " мин " .. string.format("%02d", left % 60) .. " сек"
end

local function minutes_word(n)
    local n10, n100 = n % 10, n % 100
    if n100 >= 11 and n100 <= 14 then return "минут" end
    if n10 == 1 then return "минута" end
    if n10 >= 2 and n10 <= 4 then return "минуты" end
    return "минут"
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
    imgui.PopStyleColor(1)
    imgui.Spacing()
end

local function draw_payday_tab()
    section_header(ic("CLOCK", ""), "Отчет до PayDay")
    if imgui.BeginChild("##payday_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then
        imgui.TextWrapped("На экране появится надпись «До PayDay: N мин N сек». PayDay выплачивается каждые 30 минут: в :00 и :30.")
        imgui.Spacing()
        if imgui.Checkbox(" Включить", payday_on) then
            settings.payday.enabled = payday_on[0]
            save_settings()
        end
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        imgui.Text("Положение надписи на экране:")
        imgui.Spacing()
        if not payday_edit then
            if imgui.Button(ic("UP_DOWN_LEFT_RIGHT", "") .. " Передвинуть надпись", imgui.ImVec2(260, 38)) then
                payday_edit = true
                payday_on[0] = true
            end
        else
            imgui.TextColored(imgui.ImVec4(0.45, 1.00, 0.55, 1.00), "Перетащи надпись мышкой, затем нажми «Сохранить».")
            if imgui.Button(FA.FLOPPY_DISK .. " Сохранить положение", imgui.ImVec2(260, 38)) then
                settings.payday.x = payday_pos.x
                settings.payday.y = payday_pos.y
                settings.payday.enabled = payday_on[0]
                save_settings()
                payday_edit = false
                notify("Положение надписи сохранено", "ok")
            end
        end
        imgui.Spacing()
        imgui.TextDisabled("Сейчас: " .. payday_text())
    end
    imgui.EndChild()
end

local function draw_phrases_tab()
    section_header(ic("COMMENT_DOTS", ""), "Фразы для автоотправки")
    imgui.SetNextItemWidth(imgui.GetContentRegionAvail().x - 125)
    local enter = imgui.InputTextWithHint("##phrase_input", "Введи фразу или команду (например /time)", phrase_buf, ffi.sizeof(phrase_buf), imgui.InputTextFlags.EnterReturnsTrue)
    imgui.SameLine()
    local add_clicked = imgui.Button(FA.CIRCLE_PLUS .. " Добавить##add_phrase", imgui.ImVec2(120, 0))
    if enter or add_clicked then
        local text = ffi.string(phrase_buf)
        if text:gsub("%s", "") ~= "" then
            table.insert(settings.phrases, text)
            save_settings()
            imgui.StrCopy(phrase_buf, "")
        end
    end
    imgui.Spacing()
    if imgui.BeginChild("##phrases_list", imgui.ImVec2(-1, -1), true) then
        if #settings.phrases == 0 then
            imgui.TextDisabled("Пока нет фраз. Добавь первую выше.")
        end
        local to_remove = nil
        for i, phrase in ipairs(settings.phrases) do
            if imgui.Button(FA.PAPER_PLANE .. "##send_phrase_" .. i, imgui.ImVec2(36, 28)) then
                local txt = phrase
                defer(function() sampSendChat(u8:decode(txt)) end)
            end
            if imgui.IsItemHovered() then imgui.SetTooltip("Отправить в чат") end
            imgui.SameLine()
            if imgui.Button(FA.TRASH_CAN .. "##del_phrase_" .. i, imgui.ImVec2(36, 28)) then
                to_remove = i
            end
            if imgui.IsItemHovered() then imgui.SetTooltip("Удалить фразу") end
            imgui.SameLine()
            imgui.AlignTextToFramePadding()
            imgui.Text(phrase)
        end
        if to_remove then
            table.remove(settings.phrases, to_remove)
            save_settings()
        end
    end
    imgui.EndChild()
end

local about_links = {
    { icon = "PAPER_PLANE", title = "Telegram-канал",              url = "https://t.me/arizona_prices",                 color = {0.16, 0.62, 0.86} },
    { icon = "COMMENTS",    title = "Discord-канал",               url = "https://discord.gg/z4UmCnRwd",                color = {0.35, 0.40, 0.95} },
    { icon = "MUSIC",       title = "TikTok-канал",                url = "https://www.tiktok.com/@cosmychesky_jetpack", color = {0.86, 0.15, 0.40} },
    { icon = "USER",        title = "Discord разработчика",        copy = "sawnoff_karabin07", color = {0.35, 0.40, 0.95} },
    { icon = "PAPER_PLANE", title = "ЛС разработчика в Telegram",  url = "https://t.me/xi_vivide",                      color = {0.16, 0.62, 0.86} },
    { icon = "PAPER_PLANE", title = "ЛС разработчика в Telegram 2", url = "https://t.me/obrezik",                        color = {0.16, 0.62, 0.86} },
}

local function draw_about_tab()
    section_header(ic("CIRCLE_INFO", ""), "О скрипте")
    if imgui.BeginChild("##about_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then
        imgui.TextColored(imgui.ImVec4(0.30, 0.65, 1.00, 1.00), "Arizona Prices V2.0")
        imgui.TextWrapped("Спасибо, что пользуешься скриптом! Заходи в наши соцсети: там актуальные цены, новости и обновления. Нашёл ошибку или есть идея - пиши разработчику в личные сообщения.")
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        for i, l in ipairs(about_links) do
            local c = l.color
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(c[1] * 0.55, c[2] * 0.55, c[3] * 0.55, 1.00))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(c[1] * 0.80, c[2] * 0.80, c[3] * 0.80, 1.00))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(c[1], c[2], c[3], 1.00))
            if imgui.Button("##about_" .. i, imgui.ImVec2(-1, 46)) then
                if l.url then
                    open_url(l.url)
                elseif l.copy then
                    imgui.SetClipboardText(l.copy)
                    notify("Ник скопирован: " .. l.copy, "ok")
                end
            end
            local rmin, rmax = imgui.GetItemRectMin(), imgui.GetItemRectMax()
            local dl = imgui.GetWindowDrawList()
            local cy = (rmin.y + rmax.y) / 2
            local ts = imgui.CalcTextSize(l.title)
            dl:AddText(imgui.ImVec2((rmin.x + rmax.x) / 2 - ts.x / 2, cy - ts.y / 2), 0xFFFFFFFF, l.title)
            local icon = ic(l.icon, "")
            local isz = imgui.CalcTextSize(icon)
            dl:AddText(imgui.ImVec2(rmin.x + 18, cy - isz.y / 2), 0xFFFFFFFF, icon)
            imgui.PopStyleColor(3)
        end
    end
    imgui.EndChild()
end

-- ===================== Время стран =====================
local function days_from_civil(y, m, d)
    if m <= 2 then y = y - 1 end
    local era = math.floor(y / 400)
    local yoe = y - era * 400
    local mp = (m + 9) % 12
    local doy = math.floor((153 * mp + 2) / 5) + d - 1
    local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
    return era * 146097 + doe - 719468
end

local function utc_epoch(y, m, d, h)
    return days_from_civil(y, m, d) * 86400 + h * 3600
end

local function weekday_of(y, m, d) -- 0 = воскресенье
    return (days_from_civil(y, m, d) + 4) % 7
end

local function nth_sunday(y, m, n)
    local first = 1 + (7 - weekday_of(y, m, 1)) % 7
    return first + (n - 1) * 7
end

local function last_sunday(y, m)
    local dim = ({31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31})[m]
    return dim - weekday_of(y, m, dim)
end

local function is_dst(rule, std_offset, now)
    local y = tonumber(os.date("!%Y", now))
    if rule == "eu" then
        local s = utc_epoch(y, 3, last_sunday(y, 3), 1)
        local e = utc_epoch(y, 10, last_sunday(y, 10), 1)
        return now >= s and now < e
    elseif rule == "us" then
        local s = utc_epoch(y, 3, nth_sunday(y, 3, 2), 2) - std_offset * 3600
        local e = utc_epoch(y, 11, nth_sunday(y, 11, 1), 2) - (std_offset + 1) * 3600
        return now >= s and now < e
    end
    return false
end

local function local_pc_offset()
    local now = os.time()
    local l = os.date("*t", now)
    local u = os.date("!*t", now)
    u.isdst = l.isdst
    return os.difftime(os.time(l), os.time(u)) / 3600
end

local countries = {
    { name = "Азербайджан", off = 4 },
    { name = "Армения", off = 4 },
    { name = "Беларусь", off = 3 },
    { name = "Великобритания", off = 0, dst = "eu" },
    { name = "Германия", off = 1, dst = "eu" },
    { name = "Грузия", off = 4 },
    { name = "Индия", off = 5.5 },
    { name = "Казахстан", off = 5 },
    { name = "Китай", off = 8 },
    { name = "Кыргызстан", off = 6 },
    { name = "Москва (время Аризоны)", off = 3 },
    { name = "ОАЭ", off = 4 },
    { name = "Польша", off = 1, dst = "eu" },
    { name = "Россия, Владивосток", off = 10 },
    { name = "Россия, Екатеринбург", off = 5 },
    { name = "Россия, Новосибирск", off = 7 },
    { name = "США, Лос-Анджелес", off = -8, dst = "us" },
    { name = "США, Нью-Йорк", off = -5, dst = "us" },
    { name = "Таджикистан", off = 5 },
    { name = "Таиланд", off = 7 },
    { name = "Турция", off = 3 },
    { name = "Узбекистан", off = 5 },
    { name = "Украина", off = 2, dst = "eu" },
    { name = "Япония", off = 9 },
}

local selected_country = 1
for i, c in ipairs(countries) do
    if c.name == "Узбекистан" then selected_country = i end
end

local function country_time(c)
    local now = os.time()
    local off
    if c.pc then
        off = local_pc_offset()
    else
        off = c.off
        if c.dst and is_dst(c.dst, c.off, now) then off = off + 1 end
    end
    local shifted = now + off * 3600
    return os.date("!%H:%M:%S", shifted), os.date("!%d.%m.%Y", shifted)
end

local function shadow_text(color, text)
    local p = imgui.GetCursorScreenPos()
    imgui.GetWindowDrawList():AddText(imgui.ImVec2(p.x + 1, p.y + 1), 0xFF000000, text)
    imgui.TextColored(color, text)
end

local clock_edit = false
local clock_pos = { x = settings.clock.x, y = settings.clock.y }
local pending_clock_open = false
local pending_clock_index = nil
local CLOCK_MODAL_ID = "Время на экране###clock_modal"

local function find_country(name)
    for _, c in ipairs(countries) do
        if c.name == name then return c end
    end
    return countries[1]
end

local function draw_time_tab()
    section_header(ic("GLOBE", ""), "Время стран")
    if imgui.BeginChild("##time_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then
        local sel = countries[selected_country]
        local tm, dt = country_time(sel)
        local width = imgui.GetWindowWidth()

        imgui.SetWindowFontScale(2.4)
        local ts = imgui.CalcTextSize(tm)
        imgui.SetCursorPosX(math.max(5, (width - ts.x) / 2))
        imgui.TextColored(imgui.ImVec4(1.00, 0.85, 0.30, 1.00), tm)
        imgui.SetWindowFontScale(1.0)

        local label = sel.name .. "  |  " .. dt
        local ls = imgui.CalcTextSize(label)
        imgui.SetCursorPosX(math.max(5, (width - ls.x) / 2))
        imgui.Text(label)
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        if settings.clock.enabled then
            imgui.AlignTextToFramePadding()
            imgui.Text("На экране: " .. settings.clock.country)
            imgui.SameLine()
            if not clock_edit then
                if imgui.Button("Передвинуть##clock_move") then clock_edit = true end
            else
                if imgui.Button(FA.FLOPPY_DISK .. " Сохранить положение##clock_save") then
                    settings.clock.x = clock_pos.x
                    settings.clock.y = clock_pos.y
                    save_settings()
                    clock_edit = false
                end
            end
            imgui.SameLine()
            if imgui.Button("Убрать с экрана##clock_hide") then
                settings.clock.enabled = false
                clock_edit = false
                save_settings()
            end
            if clock_edit then
                imgui.TextColored(imgui.ImVec4(0.45, 1.00, 0.55, 1.00), "Перетащи надпись мышкой, затем нажми «Сохранить положение».")
            end
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
        end

        if imgui.BeginChild("##time_list", imgui.ImVec2(-1, -1), false) then
            local bw = math.floor((imgui.GetContentRegionAvail().x - 10 - 16) / 3)
            for i, c in ipairs(countries) do
                if (i - 1) % 3 ~= 0 then imgui.SameLine() end
                local ctm = country_time(c)
                local active = (i == selected_country)
                if active then
                    imgui.PushStyleColor(imgui.Col.Button, accent_vec(1.0))
                end
                if imgui.Button(c.name .. "\n" .. ctm .. "###country_" .. i, imgui.ImVec2(bw, 44)) then
                    selected_country = i
                    pending_clock_index = i
                    pending_clock_open = true
                    local ntm, ndt = country_time(c)
                    local chat_msg = u8:decode("{33AAFF}[Arizona Prices] {FFFFFF}Время (" .. c.name .. "): {33AAFF}" .. ntm .. " {FFFFFF}(" .. ndt .. ")")
                    defer(function() sampAddChatMessage(chat_msg, -1) end)
                end
                if active then imgui.PopStyleColor(1) end
            end
        end
        imgui.EndChild()

        if pending_clock_open then
            imgui.OpenPopup(CLOCK_MODAL_ID)
            pending_clock_open = false
        end
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(400, 135), imgui.Cond.Always)
        if imgui.BeginPopupModal(CLOCK_MODAL_ID, nil, bit.bor(imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoResize)) then
            local pc = countries[pending_clock_index or selected_country]
            imgui.TextColored(imgui.ImVec4(1.00, 0.85, 0.30, 1.00), pc.name)
            imgui.TextWrapped("Показывать время этой страны на экране?")
            imgui.Spacing()
            local half = (imgui.GetContentRegionAvail().x - 5) / 2
            if imgui.Button(ic("CIRCLE_CHECK", "") .. " Да##clock_yes", imgui.ImVec2(half, 34)) then
                settings.clock.enabled = true
                settings.clock.country = pc.name
                save_settings()
                imgui.CloseCurrentPopup()
            end
            imgui.SameLine()
            if imgui.Button(FA.CIRCLE_XMARK .. " Нет##clock_no", imgui.ImVec2(half, 34)) then
                imgui.CloseCurrentPopup()
            end
            imgui.EndPopup()
        end
    end
    imgui.EndChild()
end

local clock_frame
clock_frame = imgui.OnFrame(
    function()
        clock_frame.HideCursor = not clock_edit
        return settings.clock.enabled
    end,
    guard_frame("clock", function()
        if clock_edit and not main_window[0] then clock_edit = false end
        local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.AlwaysAutoResize, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoSavedSettings)
        if not clock_edit then
            flags = bit.bor(flags, imgui.WindowFlags.NoMove, imgui.WindowFlags.NoInputs, imgui.WindowFlags.NoBackground)
            imgui.SetNextWindowPos(imgui.ImVec2(clock_pos.x, clock_pos.y), imgui.Cond.Always)
        end
        imgui.SetNextWindowBgAlpha(0.45)
        imgui.Begin("##clock_overlay", nil, flags)
        imgui.SetWindowFontScale(UI_CFG.overlay_scale)
        local c = find_country(settings.clock.country)
        shadow_text(imgui.ImVec4(0.55, 0.85, 1.00, 1.00), c.name .. ": " .. country_time(c))
        if clock_edit then
            local pos = imgui.GetWindowPos()
            clock_pos.x, clock_pos.y = pos.x, pos.y
        end
        imgui.End()
    end, function() settings.clock.enabled = false end)
)

-- ===================== Автообновление (скрипт и цены) =====================
local SCRIPT_VERSION = "1.7"
local UPDATE_BASE = "https://raw.githubusercontent.com/hydracrmpdesign-commits/arizona-prices/main/"
local CHECK_EVERY = 1800 -- проверять обновления раз в 30 минут
local cfg_dir = getWorkingDirectory() .. "\\config\\"
local state_path = cfg_dir .. "arizona_prices_state.json"
local state = { prices_sig = "", auto_prices = true }
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

local function start_checks()
    if not doesDirectoryExist(cfg_dir) then createDirectory(cfg_dir) end
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
    if not loadstring(c) or not c:find("SCRIPT_VERSION", 1, true) then
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
    if sig == state.prices_sig then return end
    local ok, remote = pcall(decodeJson, c)
    if not ok or type(remote) ~= "table" then return end
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
                items_list[#items_list + 1] = { item = r.item, buy = buy, sell = sell }
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

local function toggle_menu()
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
    imgui.SetClipboardText(ok and text or ("Arizona Prices " .. SCRIPT_VERSION))
    open_url("https://t.me/obrezik")
    notify("Данные для разработчика скопированы - вставьте их в сообщение (Ctrl+V)", "ok", 6)
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

        sub_title("EXPAND", "Надписи на экране")
        imgui.SetNextItemWidth(260)
        if imgui.SliderFloat("Размер надписей на экране##overlay_scale", sui.scale, 0.7, 2.0, "%.1f") then
            UI_CFG.overlay_scale = sui.scale[0]
            mark_ui_dirty()
        end
        imgui.TextDisabled("Касается надписей PayDay и часов, которые показываются поверх игры.")
        imgui.Spacing()
        if imgui.Button(ic("ROTATE_LEFT", "") .. " Сбросить внешний вид##reset_look", imgui.ImVec2(230, 28)) then
            UI_CFG.accent = { 0.18, 0.45, 0.85 }
            UI_CFG.opacity = 1.0
            UI_CFG.overlay_scale = 1.0
            UI_CFG.border_mode = 1
            UI_CFG.border_speed = 1.0
            UI_CFG.shadow = true
            if UI_CFG.font ~= "seguisb" then
                UI_CFG.font = "seguisb"
                sui.font_pending = true
            end
            sui.accent[0], sui.accent[1], sui.accent[2] = 0.18, 0.45, 0.85
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
        imgui.TextDisabled("Esc - отмена, Backspace - убрать клавишу. Команда /prices работает всегда.")

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

local function draw_extra_tab(id)
    if id == 3 then
        draw_payday_tab()
    elseif id == 4 then
        draw_phrases_tab()
    elseif id == 5 then
        draw_about_tab()
    elseif id == 6 then
        draw_time_tab()
    elseif id == 7 then
        draw_settings_tab()
    end
end

local payday_frame
payday_frame = imgui.OnFrame(
    function()
        payday_frame.HideCursor = not payday_edit
        return payday_on[0]
    end,
    guard_frame("payday", function()
        if payday_edit and not main_window[0] then payday_edit = false end
        local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.AlwaysAutoResize, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoSavedSettings)
        if not payday_edit then
            flags = bit.bor(flags, imgui.WindowFlags.NoMove, imgui.WindowFlags.NoInputs, imgui.WindowFlags.NoBackground)
            imgui.SetNextWindowPos(imgui.ImVec2(payday_pos.x, payday_pos.y), imgui.Cond.Always)
        end
        imgui.SetNextWindowBgAlpha(0.45)
        imgui.Begin("##payday_overlay", nil, flags)
        imgui.SetWindowFontScale(UI_CFG.overlay_scale)
        shadow_text(imgui.ImVec4(1.00, 0.85, 0.30, 1.00), payday_text())
        if payday_edit then
            local pos = imgui.GetWindowPos()
            payday_pos.x, payday_pos.y = pos.x, pos.y
        end
        imgui.End()
    end, function() payday_on[0] = false end)
)

imgui.OnInitialize(function()
    -- иконки в стандартный шрифт (его создаёт mimgui)
    safe_call("fa_init", function() fa.Init() end)
    -- свой шрифт: добавляем с кириллицей, дублируем в него иконки и делаем основным
    safe_call("custom_font", function()
        local pick
        for _, f in ipairs(FONT_AVAILABLE) do
            if f.key == UI_CFG.font and f.path then pick = f end
        end
        if not pick then return end
        local io_ = imgui.GetIO()
        local font = io_.Fonts:AddFontFromFileTTF(pick.path, 14, nil, io_.Fonts:GetGlyphRangesCyrillic())
        if font ~= nil then
            fa.Init()
            io_.FontDefault = font
        end
    end)
    safe_call("apply_theme", apply_theme)
    safe_call("load_data", load_data)
end)

-- свой уголок изменения размера: окно тянется по смещению мыши, форма курсора не меняется
local grip = { on = false, mx = 0, my = 0, w = 0, h = 0 }
local function draw_resize_grip()
    local cw = LAYOUT.w - SIDEBAR_W
    imgui.SetCursorPos(imgui.ImVec2(cw - 28, LAYOUT.h - 28 + imgui.GetScrollY()))
    imgui.InvisibleButton("##resize_grip", imgui.ImVec2(20, 20))
    local hov = imgui.IsItemHovered()
    local rmax = imgui.GetItemRectMax()
    if imgui.IsItemActive() then
        local mp = imgui.GetMousePos()
        if not grip.on then
            grip.on = true
            grip.mx, grip.my, grip.w, grip.h = mp.x, mp.y, LAYOUT.w, LAYOUT.h
        end
        local sw, sh = getScreenResolution()
        LAYOUT.req = {
            w = clamp(grip.w + mp.x - grip.mx, 700, math.max(700, sw - 20)),
            h = clamp(grip.h + mp.y - grip.my, 400, math.max(400, sh - 20)),
        }
    else
        grip.on = false
    end
    local ac = UI_CFG.accent
    local a = (hov or grip.on) and 0.95 or 0.55
    imgui.GetWindowDrawList():AddTriangleFilled(
        imgui.ImVec2(rmax.x, rmax.y), imgui.ImVec2(rmax.x, rmax.y - 14), imgui.ImVec2(rmax.x - 14, rmax.y),
        col32(ac[1], ac[2], ac[3], a))
end

-- размеры окна: запоминаем в настройках, пересчитываем высоту вкладок левой панели
local function layout_update(wsz)
    if wsz.x < 700 or wsz.y < 400 then
        wsz = imgui.ImVec2(math.max(700, wsz.x), math.max(400, wsz.y))
        imgui.SetWindowSize(wsz, imgui.Cond.Always)
    end
    LAYOUT.w, LAYOUT.h = wsz.x, wsz.y
    LAYOUT.tab_h = clamp(math.floor((LAYOUT.h - 161) / 7) - 5, 28, 42)
    LAYOUT.block_y = 5 + 7 * (LAYOUT.tab_h + 5) + 6
    local w, h = math.floor(wsz.x + 0.5), math.floor(wsz.y + 0.5)
    if w ~= UI_CFG.win_w or h ~= UI_CFG.win_h then
        UI_CFG.win_w, UI_CFG.win_h = w, h
        mark_ui_dirty()
    end
end

imgui.OnFrame(function() return main_window[0] or modal_window[0] end,
    guard_frame("menu", function(player)
        if main_window[0] then 
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
            if imgui.Begin(u8("Arizona Prices##main_window"), main_window, bit.bor(imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoScrollWithMouse)) then
                layout_update(imgui.GetWindowSize())
                local wpos = imgui.GetWindowPos()
                local win_cx, win_cy = wpos.x + LAYOUT.w / 2, wpos.y + LAYOUT.h / 2
                hk.typing = imgui.GetIO().WantTextInput

                -- Левая панель с вкладками
                draw_sidebar_bg(wpos)
                imgui.SetCursorPos(imgui.ImVec2(5, 5))
                sidebar_tab(FA.CIRCLE_DOLLAR .. u8(" Arizona Prices"), 1)
                sidebar_tab(ic("CALCULATOR", "") .. " Калькулятор", 2)
                sidebar_tab(ic("CLOCK", "") .. " Отчет до PayDay", 3)
                sidebar_tab(ic("COMMENT_DOTS", "") .. " Фразы", 4)
                sidebar_tab(ic("GLOBE", "") .. " Время стран", 6)
                sidebar_tab(ic("CIRCLE_INFO", "") .. " О скрипте", 5)
                sidebar_tab(ic("GEAR", "") .. " Настройки", 7)
                draw_update_block()

                -- Правая часть (содержимое выбранной вкладки)
                imgui.SetCursorPos(imgui.ImVec2(SIDEBAR_W, 0))
                local content_flags = imgui.WindowFlags.AlwaysUseWindowPadding or 0
                if not (current_tab == 2 and (LAYOUT.h < 495 or LAYOUT.w < 830)) then
                    content_flags = bit.bor(content_flags, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoScrollWithMouse)
                end
                local content_visible = imgui.BeginChild("##content", imgui.ImVec2(LAYOUT.w - SIDEBAR_W, LAYOUT.h), false, content_flags)
                if content_visible then
                if current_tab == 1 then
                imgui.AlignTextToFramePadding() 
                imgui.SetCursorPosX(9) 
                imgui.Text(FA.CIRCLE_DOLLAR .. u8(' Arizona Prices'))
                imgui.SameLine(140) 
                imgui.SetNextItemWidth(math.max(90, LAYOUT.w - SIDEBAR_W - 329)) 
                imgui.InputTextWithHint("##search", FA.MAGNIFYING_GLASS .. " Поиск", buf_search, ffi.sizeof(buf_search))
                imgui.SameLine() 
                imgui.SetNextItemWidth(150)
                
                local sort_items = {"По умолчанию", "Сначала дорогие", "Сначала дешёвые", "По алфавиту"}
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
                imgui.PopStyleColor(1) 
                imgui.Spacing()

                if imgui.BeginChild("##table_child", imgui.ImVec2(-1, LAYOUT.h - 79), true) then 
                    local table_style = imgui.GetStyle() 
                    local table_start_x = imgui.GetCursorScreenPos().x
                    local table_top_y = imgui.GetCursorScreenPos().y - table_style.WindowPadding.y 
                    local separator_spacing = table_style.ItemSpacing.y 
                    local col_w0, col_w1, col_w2, col_w3 = math.max(110, math.floor(imgui.GetContentRegionAvail().x) - 340), 140, 120, 80
                    
                    imgui.Columns(4, "item_table", false) 
                    imgui.SetColumnWidth(0, col_w0) 
                    imgui.SetColumnWidth(1, col_w1) 
                    imgui.SetColumnWidth(2, col_w2) 
                    imgui.SetColumnWidth(3, col_w3)

                    do 
                        local sz = imgui.CalcTextSize("Предмет")
                        imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w0 - sz.x) * 0.5)) 
                        imgui.TextColored(accent_vec(1.3), "Предмет")
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

                    for i, v in ipairs(items_list) do 
                        local item_name = lower_cp1251(v.item or "") 
                        if search_query == "" or item_name:find(search_query, 1, true) then 
                            table.insert(display_indices, i) 
                        end 
                    end

                    if current_sort[0] == 1 then 
                        table.sort(display_indices, function(a, b) return tonumber(items_list[a].sell or 0) > tonumber(items_list[b].sell or 0) end)
                    elseif current_sort[0] == 2 then 
                        table.sort(display_indices, function(a, b) return tonumber(items_list[a].sell or 0) < tonumber(items_list[b].sell or 0) end)
                    elseif current_sort[0] == 3 then 
                        table.sort(display_indices, function(a, b) local name_a = (items_list[a].item or ""):lower() local name_b = (items_list[b].item or ""):lower() return name_a < name_b end)
                    end

                    for ri, idx in ipairs(display_indices) do 
                        local item = items_list[idx]
                        if item then 
                            local row_y = imgui.GetCursorPosY() 
                            do
                                local rp = imgui.GetCursorScreenPos()
                                local rx1 = table_start_x + col_w0 + col_w1 + col_w2 + col_w3
                                local r0, r1 = imgui.ImVec2(table_start_x, rp.y - 2), imgui.ImVec2(rx1, rp.y + 27)
                                if imgui.IsMouseHoveringRect(r0, r1) then
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
                                if imgui.IsItemHovered() then imgui.SetTooltip(item_text) end 
                                imgui.SameLine(col_w0 - icon_w - 6) 
                                imgui.Text(FA.CIRCLE_QUESTION) 
                                if imgui.IsItemHovered() then imgui.SetTooltip(item_text) end
                            else 
                                imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w0 - sz.x) * 0.5)) 
                                imgui.Text(item_text)
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
                            local buttons_total_width = 28 + 5 + 28 
                            imgui.SetCursorPosY(row_y) 
                            imgui.SetCursorPosX(imgui.GetCursorPosX() + math.max(0, (col_w3 - buttons_total_width) * 0.5))
                            
                            if imgui.Button(FA.PEN_LINE .. "##edit_" .. idx, imgui.ImVec2(28, 24)) then 
                                open_edit_modal(idx) 
                            end 
                            imgui.SameLine()
                            
                            if imgui.Button(FA.TRASH_CAN .. "##del_" .. idx, imgui.ImVec2(28, 24)) then 
                                pending_delete_index = idx 
                                pending_delete_open = true 
                            end

                            imgui.NextColumn() 
                            imgui.Separator() 
                            table_bottom_y = imgui.GetCursorScreenPos().y - separator_spacing - 1.0
                        end
                    end
                    imgui.Columns(1)

                    if table_bottom_y > table_top_y then 
                        local draw_list = imgui.GetWindowDrawList() 
                        local border_col = imgui.GetColorU32(imgui.Col.Separator) 
                        local x = table_start_x 
                        local column_widths = {col_w0, col_w1, col_w2}
                        for i = 1, 3 do 
                            x = x + column_widths[i] 
                            draw_list:AddLine(imgui.ImVec2(x, table_top_y), imgui.ImVec2(x, table_bottom_y), border_col, 1.0) 
                        end
                    end
                    imgui.EndChild()
                end

                local add_w = imgui.GetContentRegionAvail().x - 95
                if imgui.Button(FA.CIRCLE_PLUS .. " Добавить предмет", imgui.ImVec2(add_w, 30)) then
                    open_add_modal() 
                end

                imgui.SameLine()
                if imgui.Button(FA.TRIANGLE_EXCLAMATION .. "##report_prices", imgui.ImVec2(30, 30)) then
                    open_url("https://t.me/xi_vivide")
                end
                if imgui.IsItemHovered() then imgui.SetTooltip("Сообщить об устаревших ценах") end

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
                                        items_list[edit_index] = {item = name, buy = buy, sell = sell} 
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
                if content_visible then draw_resize_grip() end
                imgui.EndChild()

                draw_window_fx(wpos.x, wpos.y, wpos.x + LAYOUT.w, wpos.y + LAYOUT.h)
                imgui.End()
            else
                imgui.End()
            end
        end
    end, function() main_window[0] = false; modal_window[0] = false; hk.binding = false end)
)

-- ===================== Большое окно «старая версия» =====================
imgui.OnFrame(function() return outdated_popup[0] end, guard_frame("outdated", function()
    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(580, 290), imgui.Cond.Always)
    imgui.SetNextWindowFocus()
    local flags = bit.bor(imgui.WindowFlags.NoTitleBar, imgui.WindowFlags.NoResize, imgui.WindowFlags.NoMove,
        imgui.WindowFlags.NoCollapse, imgui.WindowFlags.NoScrollbar, imgui.WindowFlags.NoSavedSettings)
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
end, function() outdated_popup[0] = false end))

function main()
    while not isSampAvailable() do wait(0) end
    safe_call("load_data", load_data)

    sampAddChatMessage(u8:decode("{33AAFF}[Arizona Prices V2.0] {FFFFFF}Скрипт успешно загружен! Для активации - {33AAFF}/prices{FFFFFF}. ТГК - {33AAFF}@arizona_prices"), -1)

    sampRegisterChatCommand('prices', toggle_menu)
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
