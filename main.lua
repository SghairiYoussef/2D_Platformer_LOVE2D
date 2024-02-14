button = require 'Button'
local grid

jumpCount = 0
storyProgress = 1
fallDistance = 0

state =
{
    Start = true,
    Pause = false,
    Running = false,
    Closing = false
}

buttons =
{
    start_state = {}
}

--Saving System (RW FROM FILE)

function saveGame()
    local data = "storyProgress = " .. storyProgress
    local success, message = love.filesystem.write("data/saves/savefile.txt", data)
    if success then
        love.graphics.printf("Saved Successfully!", love.graphics.newFont(16), 10, love.graphics.getHeight() - 350, love.graphics.getWidth())
    else
        love.graphics.printf("Save Unsuccessfull" .. message, love.graphics.newFont(16), 10, love.graphics.getHeight() - 350, love.graphics.getWidth())
    end
end

function loadGame()
    if love.filesystem.getInfo("data/savefile.txt") then
        local data = love.filesystem.read("data/saves/savefile.txt")
        storyProgress = tointeger(data:match("storyProgress = (%d+)"))
    end
end

--Start&Quit Game

function startGame()
    state["Running"] = true
    state["Start"] = false
    state["Pause"] = false
    state["Closing"] = false
end

function exit_game()
    state["Closing"] = true
    state["Start"] = false
    state["Pause"] = false
    love.event.quit()
end

--Mouse Detection for Menu Functionalities
function love.mousepressed(x, y, button, istouch, presses)
    if not state["Running"] then
        if button == 1 then
            if state["Start"] or state["Pause"] then
                for index in pairs(buttons.start_state) do
                    buttons.start_state[index]:checkPressed(x, y, 10)
                end
            end
        end
    end
end


--Love Functions
function love.load()
    if state["Running"] == true then
        love.mouse.setVisible(false)
    end

    --Physcis
    wf = require 'lib/windfield'
    world = wf.newWorld(0, 500)
    world: addCollisionClass('Player')
    world: addCollisionClass('Walls')
    world: addCollisionClass('Environment')

    ground = world:newRectangleCollider(0,630,1200,1200)
    ground:setType('static')
    ground:setCollisionClass('Environment')
    groundY = 570

    left_Wall = world:newRectangleCollider(-30, 30, 30, 675)
    left_Wall:setType('static')
    left_Wall:setCollisionClass('Walls')

    right_Wall = world:newRectangleCollider(1200, 30, 30, 675)
    right_Wall:setType('static')
    right_Wall:setCollisionClass('Walls')

    player = {}
    player.x = 20
    player.y = 400
    player.speed = 300
    player.health = 80
    player.maxHealth = 100
    player.collider = world:newRectangleCollider(player.x, player.y , 30, 80)
    player.collider:setCollisionClass('Player')
    player.collider:setFixedRotation (true)

    --animations & graphics
    anim8 = require 'lib/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest")

    player.spriteSheet = love.graphics.newImage('Sprites/shinobi/shinobi/walk.png')

    SPRITE_WIDTH, SPRITE_HEIGHT = player.spriteSheet:getWidth(), player.spriteSheet:getHeight()
    QUAD_WIDTH, QUAD_HEIGHT = SPRITE_WIDTH / 8, SPRITE_HEIGHT

    grid = anim8.newGrid(QUAD_WIDTH, QUAD_HEIGHT, SPRITE_WIDTH, SPRITE_HEIGHT)

    player.animation = {
        direction = "right",
        idle = true,
        animation = anim8.newAnimation(grid('1-8', 1), 0.1),
        isRunning = false,
        isJumping = false,
        jumpSpeed = 200,
        jumpHeight = 300,
        speed = 150,
        isFalling = false
    }



    background = love.graphics.newImage("Sprites/SUMMER BG/PNG/summer 3/Summer3.png")
    FRAME_WIDTH = background:getWidth()
    FRAME_HEIGHT = background:getHeight()

    --camera
    camera = require 'lib/camera'
    cam = camera()


    ---Menu
    buttons.start_state.play_game = button("Play", startGame, nil, 120, 40)
    buttons.start_state.save = button("Save", saveGame, nil, 120, 40)
    buttons.start_state.exit_game = button("Exit", exit_game, nil, 120, 40)

end

function love.update(dt)
    local isMoving, isRunning = false, false
    local px, py = player.collider:getLinearVelocity()
    local vx = 0
    if love.keyboard.isDown('right')then
        player.animation.idle = false
        player.animation.direction = "right"
        if love.keyboard.isDown("lshift") then
            player.spriteSheet = love.graphics.newImage("Sprites/SHINOBI/shinobi/Run.png")
            isRunning = true
            vx = 2.5 * player.animation.speed
        else
            vx = player.animation.speed
            isRunning = false
            player.spriteSheet = love.graphics.newImage('Sprites/shinobi/shinobi/walk.png')
        end
        isMoving = true
    end
    if love.keyboard.isDown('left') then
        player.animation.idle = false
        player.animation.direction = "left"
        if love.keyboard.isDown("lshift") then
            player.spriteSheet = love.graphics.newImage("Sprites/SHINOBI/shinobi/Run.png")
            isRunning = true
            vx = -2.5 * player.animation.speed
        else
            vx = player.animation.speed * -1
            isRunning = false
            player.spriteSheet = love.graphics.newImage('Sprites/shinobi/shinobi/walk.png')
        end
        isMoving = true
    end

    if not isMoving then
        player.animation.idle = true
        isRunning = false
        player.spriteSheet = love.graphics.newImage('Sprites/shinobi/shinobi/walk.png')
        player.animation.animation:gotoFrame(4)
        player.animation.isJumping = false
    end

    player.collider:setLinearVelocity(vx, py)
    world:update(dt)
    player.x = player.collider:getX()-55
    player.y = player.collider:getY()-87

    if not player.animation.idle then
        player.animation.animation:update(dt)
    end

    if player.collider:enter("Environment") then
        jumpCount = 0
        player.isJumping = false
        local fallThreshold = 150
        if fallDistance > fallThreshold then
            local fallDamage = fallDistance * 0.02
            player.health = player.health - fallDamage
        end
        fallDistance = 0
    end

    if player.collider:enter("Walls") then
        jumpCount = 0
    end

    if player.isJumping == true then
        player.spriteSheet = love.graphics.newImage('Sprites/shinobi/shinobi/jump.png')
        if py<0 then
            fallDistance = math.abs(player.y - groundY)
        end
    end

    if player.health < 0 then
        state["Running"] = false
        state["Closing"] = true
    end

    ---camera
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    cam:lookAt(player.x, player.y)
    if cam.x < width/2 then
        cam.x = width/2
    end
    if cam.y < height/2 then
        cam.y = height/2
    end
    if cam.x > (width - width/2) then
        cam.x = width - width/2
    end
    if cam.y > (height - height/2) then
        cam.y = height - height/2
    end
end

function love.draw()
    world:draw()
    if state["Running"] == true then
        cam:attach()
        love.graphics.draw(background)
        love.graphics.rectangle("fill", 10, 10 , player.maxHealth * 2, 15)
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", 10, 10, player.health * 2 * player.maxHealth/100, 15)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("HP: " .. tonumber(player.health) .."/" .. player.maxHealth, love.graphics.newFont(16), 10 + player.maxHealth *2, 10, love.graphics.getWidth())
        if player.animation.direction == "right" then
            player.animation.animation:draw(player.spriteSheet, player.x, player.y)
        else
            player.animation.animation:draw(player.spriteSheet, player.x-18, player.y, 0, -1, 1, QUAD_WIDTH, 0)
        end
        cam:detach()
        bool = false
    elseif state["Start"] == true or state["Pause"] == true then
        buttons.start_state.play_game:draw(10, 20, 17, 10)
        buttons.start_state.save:draw(10, 70, 17, 10)
        buttons.start_state.exit_game:draw(10, 120, 17, 10)
    elseif state["Closing"] == true then
        buttons.start_state.play_game:draw(10, 20, 17, 10)
        love.graphics.printf("THANKS FOR PLAYING", love.graphics.newFont(16), 10, love.graphics.getHeight() - 350, love.graphics.getWidth())
    end
    love.graphics.printf("FPS: " .. love.timer.getFPS(), love.graphics.newFont(16), 10, love.graphics.getHeight() - 30, love.graphics.getWidth())

end

-- Jump Functionalities
function love.keypressed(key)
    if key == 'space'  and jumpCount<2 then
        player.collider:applyLinearImpulse(0, -1000)
        jumpCount = jumpCount + 1
        player.isJumping = true
    end

    if key == 'escape' then
        state["Pause"] = true
        state["Running"] = false
    end
end