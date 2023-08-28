local lgi = require 'lgi'
local gtk = lgi.require('Gtk', '3.0')
local gio = lgi.require('Gio')
local gdk = lgi.require('Gdk')

local app = gtk.Application { application_id = 'org.phicross.luaexample' }

local labelCycle = coroutine.create(function()

    -- setup a timing table with all timing information for an animation.
    local timing =
    {
        phaseCheckpoints_milliseconds=
        {
            1000.0,2000.0,3000.0,4000.0,
            5000.0,6000.0,7000.0
        }
    }
    while true do
        local phase_milliseconds = 0
        local currentCheckpoint = 1
        local checkpoints = timing.phaseCheckpoints_milliseconds
        local labelWidget
        local frameclock
        local timestamp_start_microseconds
        do
            local label,clock = coroutine.yield()   --named unused values for clarity
            timestamp_start_microseconds= clock:get_frame_time()
        end

        while phase_milliseconds < checkpoints[#checkpoints] do

            -- get a GTK label widget and a GDK frame clock from the whoever is resuming this loop.
            labelWidget, frameClock = coroutine.yield()
            --print 'next frame.'

            -- (compute progress for this frame in milliseconds)
            -- compute how many milliseconds have passed between last frame and the current one.
            do
                local timeElapsed_microseconds = (frameClock:get_frame_time() - timestamp_start_microseconds)
                phase_milliseconds = (timeElapsed_microseconds / 1000.0)
            end

            -- append 'XD' to the label whenever the next checkpoint has been crossed.
            if (phase_milliseconds > checkpoints[currentCheckpoint]) then
--                 print('label changed.')
--                 print (phase_milliseconds, 'milliseconds elapsed.')
                labelWidget.label = labelWidget.label .. 'XD'
            end

            -- skip through checkpoints if more than one was crossed
            -- (this compensates for when occasional hangs, freezes
            --  and slow computers making frames take unusually long)
            -- .. or the end of the cycle was found.
            while (phase_milliseconds > checkpoints[currentCheckpoint]) do
                    currentCheckpoint = currentCheckpoint + 1
                    if (currentCheckpoint > #checkpoints) then
                        break;
                    end
            end
        end
        labelWidget.label = 'smiley.'
        startTime = frameClock:get_frame_time()
        phase_milliseconds = 0.0
    end

end)
local success, message= coroutine.resume(labelCycle)
if not success then
    print(message)
end

function app:on_activate()
    window = gtk.Window
    {
        title = "intro app.",
        default_width = 400,
        default_height = 400,
        gtk.Box
        {
            id='column',
            orientation=gtk.Orientation.VERTICAL,
            gtk.Label
            {
                id = 'message',
                label = 'hello.'
            },
            gtk.Label
            {
                id = 'scratchpad',
                label = 'dynamic.'
            },
            gtk.Button
            {
                id = 'daButton',
                label = 'no press plz'
            }
        }
    }
    app:add_window(window)
    window:set_titlebar(nil)
    local scratcher = window.child.column.child.scratchpad
    print 'setting frame update callback.'
    scratcher:add_tick_callback(function(label, clock)
        local success, message = coroutine.resume(labelCycle, label, clock)
        if not success then
            print (message)
        else
--             print 'frame update.'
        end
        -- this boolean specifies wether a callback should be repeated.
        -- glib has an enum for this, but i don't have it on GIR.
        return true
    end)

    window:show_all()
    print 'app ready.'
end

app:run()
--gtk.main()


--[[

local lgi = require 'lgi'
local glib = lgi.Glib

local function dump(t)
    for k,v in pairs(t) do
        print (k, '=', v)
    end
end

]]

