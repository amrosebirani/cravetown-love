function love.conf(t)
    t.title = "CraveTown"
    t.author = "Your Name"
    t.version = "11.4"

    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true
    t.window.vsync = 1

    t.modules.joystick = true
    t.modules.audio = true
    t.modules.keyboard = true
    t.modules.mouse = true
    t.modules.timer = true
    t.modules.event = true
    t.modules.image = true
    t.modules.graphics = true
    t.modules.sound = true
    t.modules.physics = true
    t.modules.thread = true
    t.modules.math = true
    t.modules.data = true
    t.modules.font = true
    t.modules.system = true
    t.modules.video = true
end