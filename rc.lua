-- Standard awesome library
poxis = require("posix")
awful = require("awful")
wibox = require("wibox")
require("awful.autofocus")
awful.rules = require("awful.rules")
-- Theme handling library
beautiful = require("beautiful")
-- Notification library
naughty = require("naughty")
vicious = require("vicious")
--require("teardrop")
--require("scratchpad")
local menubar = require("menubar")

-- Load Debian menu entries
require("debian.menu")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("~/.config/awesome/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "urxvt -pe tabbed"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"


-- Autostart
local autostart_dir = string.format('/home/nicolas/.config/awesome/autostart', awful.util.getdir('config'))
local autostart_stat = posix.stat(autostart_dir)
if autostart_stat and autostart_stat.type == 'directory' then
        local files = posix.dir(autostart_dir)
        if files then
                for _, file in pairs(files) do
                        local full_file = string.format('%s/%s', autostart_dir, file)
                        local file_stat = posix.stat(full_file)
                        if file_stat and (file_stat.type == 'regular' or file_stat.type == 'link') then
                                local command = full_file
                                if file_stat.type == 'link' then
                                        local readlink_output = awful.util.pread(string.format('readlink %s', full_file))
                                        command = readlink_output:gsub('%s*$', '')
                                end
                                local basename = command:gsub('^.*/', '')
                                if command then
                                        awful.util.spawn_with_shell(string.format('pgrep -u $USER -f "%s$" >/dev/null || ("%s" &)', basename, command))
                                end
                        end
                end
        end
end


-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile.right,
    awful.layout.suit.max,
    awful.layout.suit.magnifier,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.top,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.

 tags = {
   names  = { "1-web",    "2-shell",  "3-java",   "4-webdev", "5-misc",   "6-mail",   "7-zik",    8,          9 },
   layout = { layouts[2], layouts[2], layouts[2], layouts[2], layouts[2], layouts[2], layouts[4], layouts[2], layouts[2]}
}
for s = 1, screen.count() do
     -- Each screen has its own tag table.
     tags[s] = awful.tag(tags.names, s, tags.layout)
end
-- }}}


-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock()

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 5, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 4, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({
                                                      theme = { width = 250 }
                                                  })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))


-- {{{ Wibox
--
-- {{{ Widgets configuration
--
-- {{{ Reusable separators
spacer    = wibox.widget.textbox()
separator = wibox.widget.imagebox()
spacer:set_text(" ")
separator:set_image(beautiful.widget_sep)
-- }}}

-- {{{ CPU usage and temperature
cpuicon = wibox.widget.imagebox()
cpuicon:set_image(beautiful.widget_cpu)
-- Initialize widgets
cpugraph  = awful.widget.graph()
tzswidget = wibox.widget.textbox()
cpufreq = wibox.widget.textbox()
-- Graph properties
cpugraph:set_width(40)
cpugraph:set_height(14)
cpugraph:set_background_color(beautiful.fg_off_widget)
cpugraph:set_color(beautiful.fg_end_widget)
cpugraph:set_color({ type = "linear", from = { 0, 0 }, to = { 0, 20 }, stops = { { 0, beautiful.fg_end_widget }, { 0.5, beautiful.fg_center_widget }, { 1, beautiful.fg_widget } }})

-- Register widgets
vicious.register(cpugraph,  vicious.widgets.cpu,     "$1")
vicious.register(tzswidget, vicious.widgets.thermal, "$1°", 10, "thermal_zone0")
vicious.register(cpufreq, vicious.widgets.cpuinf, "${cpu0 mhz}mhz - ", 2)
-- }}}

-- {{{ Battery state
baticon = wibox.widget.imagebox()
baticon:set_image(beautiful.widget_bat)
-- Initialize widget
batwidget = wibox.widget.textbox()
-- Register widget
vicious.register(batwidget, vicious.widgets.bat, "$1$2% - $3", 1, "BAT1")
-- }}}

-- {{{ Memory usage
memicon = wibox.widget.imagebox()
memicon:set_image(beautiful.widget_mem)
-- Initialize widget
memwidget = wibox.widget.textbox()
membar = awful.widget.progressbar()
-- Pogressbar properties
membar:set_width(10)
membar:set_height(12)
membar:set_vertical(true)
membar:set_background_color(beautiful.fg_off_widget)
membar:set_border_color(beautiful.border_widget)
membar:set_color(beautiful.fg_widget)
-- TODO membar:set_color({ type = "linear", from = { 0, 0 }, to = { 0, 20 }, stops = { { 0, beautiful.fg_end_widget }, { 0.5, beautiful.fg_center_widget }, { 1, beautiful.fg_widget } }})

--set_gradient_colors({ beautiful.fg_widget,
  -- beautiful.fg_center_widget, beautiful.fg_end_widget}) -- Register widget
vicious.register(memwidget, vicious.widgets.mem, "$1%", 13)
vicious.register(membar, vicious.widgets.mem, "$1", 13)
-- }}}

-- {{{ File system usage
fsicon = wibox.widget.imagebox()
fsicon:set_image(beautiful.widget_fs)
-- Initialize widgets
fs = {
  r = awful.widget.progressbar(),  h = awful.widget.progressbar(),
  s = awful.widget.progressbar(),  b = awful.widget.progressbar()
}
-- Progressbar properties
for _, w in pairs(fs) do
  w:set_width(5)
  w:set_height(12)
  w:set_vertical(true)
  w:set_background_color(beautiful.fg_off_widget)
  w:set_border_color(beautiful.border_widget)
  w:set_color(beautiful.fg_widget)
  -- TODO w:set_color({ type = "linear", from = { 0, 0 }, to = { 0, 20 }, stops = { { 0, beautiful.fg_end_widget }, { 0.5, beautiful.fg_center_widget }, { 1, beautiful.fg_widget } }})
  -- Register buttons
--  w:buttons(awful.util.table.join(
--    awful.button({ }, 1, function () exec("rox", false) end)
--  ))
end -- Enable caching
--vicious.enable_caching(vicious.widgets.fs)
-- Register widgets
vicious.register(fs.r, vicious.widgets.fs, "${/ used_p}",            599)
vicious.register(fs.h, vicious.widgets.fs, "${/home used_p}",        599)
-- }}}

-- {{{ Network usage
dnicon = wibox.widget.imagebox()
upicon = wibox.widget.imagebox()
dnicon:set_image(beautiful.widget_net)
upicon:set_image(beautiful.widget_netup)
-- Initialize widget
netwidget = wibox.widget.textbox()
-- Register widget
vicious.register(netwidget, vicious.widgets.net, '<span color="'
  .. beautiful.fg_netdn_widget ..'">${wlan0 down_kb}</span> <span color="'
  .. beautiful.fg_netup_widget ..'">${wlan0 up_kb}</span>', 3)
-- }}}


-- {{{ Volume level
volicon = wibox.widget.imagebox()
volicon:set_image(beautiful.widget_vol)
-- Initialize widgets
volbar    = awful.widget.progressbar()
volwidget = wibox.widget.textbox()
-- Progressbar properties
volbar:set_width(10)
volbar:set_height(12)
volbar:set_vertical(true)
volbar:set_background_color(beautiful.fg_off_widget)
volbar:set_border_color(beautiful.border_widget)
volbar:set_color(beautiful.fg_widget)
-- TODO volbar:set_color({ type = "linear", from = { 0, 0 }, to = { 0, 20 }, stops = { { 0, beautiful.fg_end_widget }, { 0.5, beautiful.fg_center_widget }, { 1, beautiful.fg_widget } }})
-- Enable caching
--vicious.enable_caching(vicious.widgets.volume)
-- Register widgets
vicious.register(volbar,    vicious.widgets.volume, "$1",  1, "Master")
vicious.register(volwidget, vicious.widgets.volume, "$1%", 1, "Master")
-- Register buttons
volbar:buttons(awful.util.table.join(
--   awful.button({ }, 1, function () exec("kmix") end),
   awful.button({ }, 2, function () exec("amixer -q sset Master toggle")   end),
   awful.button({ }, 4, function () exec("amixer -q sset PCM 2dB+", false) end),
   awful.button({ }, 5, function () exec("amixer -q sset PCM 2dB-", false) end)
)) -- Register assigned buttons
volwidget:buttons(volbar:buttons())
-- }}}

-- {{{ Date and time
dateicon = wibox.widget.imagebox()
dateicon:set_image(beautiful.widget_date)
-- Initialize widget
datewidget = wibox.widget.textbox()
-- Register widget
vicious.register(datewidget, vicious.widgets.date, "%d %b, %R", 61)
-- Register buttons
datewidget:buttons(awful.util.table.join(
  awful.button({ }, 1, function () exec("pylendar.py") end)
))
-- }}}


for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    mywibox[s] = awful.wibox({ position = "top", screen = s,
        fg = beautiful.fg_normal, height = 16,
        bg = beautiful.bg_normal, position = "top",
        border_color = beautiful.border_focus,
        border_width = beautiful.border_width
    }) 
   
    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])
    left_layout:add(separator)

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(separator)
    if screen.count() > 1 and s == 2 then right_layout:add(wibox.widget.systray()) end
    if screen.count() == 1 and s == 1 then right_layout:add(wibox.widget.systray()) end

    -- cpu widget
    right_layout:add(separator)
    right_layout:add(cpuicon)
    right_layout:add(cpugraph)
    right_layout:add(spacer)
    right_layout:add(cpufreq)
    right_layout:add(spacer)
    right_layout:add(tzswidget)

    -- memory widget
    right_layout:add(separator)
    right_layout:add(memicon)
    right_layout:add(memwidget)

    -- volume widget
    right_layout:add(separator)
    right_layout:add(volicon)
    right_layout:add(spacer)
    right_layout:add(volwidget)

    -- network widget
    right_layout:add(separator)
    right_layout:add(dnicon)
    right_layout:add(netwidget)
    right_layout:add(upicon)

    -- battery widget
    right_layout:add(separator)
    right_layout:add(baticon)
    right_layout:add(batwidget)

    -- date widget
    right_layout:add(separator)
    right_layout:add(dateicon)
    right_layout:add(datewidget)
    right_layout:add(spacer)

    -- Layout icon
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey, "Shift"   }, "Tab",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "Down",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "Up",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    --awful.key({ modkey,           }, "Tab",
    --    function ()
    --        awful.client.focus.history.previous()
    --        if client.focus then
    --            client.focus:raise()
    --        end
    --    end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),
awful.key({ modkey },            "x",     function ()
    awful.util.spawn("dmenu_run -b  -i -p 'Run command:' -nb '" .. 
 		beautiful.bg_normal .. "' -nf '" .. beautiful.fg_normal .. 
		"' -sb '" .. beautiful.bg_focus .. 
		"' -sf '" .. beautiful.fg_focus .. "'") 
	end),


    awful.key({ modkey }, "c",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(

   -- Brightness control
   awful.key({ }, "XF86MonBrightnessDown", function () awful.util.spawn("xbacklight -dec 15") end),
   awful.key({ }, "XF86MonBrightnessUp", function () awful.util.spawn("xbacklight -inc 15") end),

   -- Volume control
   awful.key({ }, "XF86AudioRaiseVolume", function () awful.util.spawn("amixer set Master 5%+", false) end),
   awful.key({ }, "XF86AudioLowerVolume", function () awful.util.spawn("amixer set Master 5%-", false) end),
   awful.key({ }, "XF86AudioMute", function () awful.util.spawn("amixer sset Master toggle", false) end),

    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "Spotify" },
      properties = { tag = tags[1][7]} },
    { rule = { instance = "Netbeans" },
      properties = { tag = tags[1][3], maximized_vertical = true, maximized_horizontal = true } },
    { rule = { instance = "plugin-container" },
      properties = { floating = true } }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    elseif not c.size_hints.user_position and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count change
        awful.placement.no_offscreen(c)
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)


-- Enable sloppy focus
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)


-- }}}


