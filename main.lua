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
    sti = require 'lib/sti'

    gameMap = sti('Maps/Sheran_LVL1.lua')

    world = wf.newWorld(0, 500)
    world: addCollisionClass('Player')
    world: addCollisionClass('Walls')
    world: addCollisionClass('Environment')

    groundY = 570

    walls={}
    if gameMap.layers["Object Layer 1"] then
        for i,obj in pairs(gameMap.layers["Object Layer 1"].objects) do
            local wall = world:newRectangleCollider(obj.x, obj.y+30, obj.width, obj.height)
            wall:setType('static')
            wall:setCollisionClass('Walls')
            wall:setCollisionClass('Environment')
            table.insert(walls, wall)
        end
    end

    player = {}
    player.speed = 300
    player.health = 100
    player.maxHealth = 100
    player.stamina = 100
    player.collider = world:newRectangleCollider(20, 400, 10, 60)
    player.collider:setCollisionClass('Player')
    player.collider:setFixedRotation (true)

    --animations & graphics
    anim8 = require 'lib/anim8'

    love.graphics.setDefaultFilter("nearest", "nearest")

    Sky = love.graphics.newImage('Sprites/SUMMER BG/PNG/summer 1/1.png')
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
    local mapW = gameMap.width * gameMap.tilewidth
    local mapH = gameMap.height * gameMap.tileheight

    if love.keyboard.isDown('right')then
        player.animation.idle = false
        player.animation.direction = "right"
        if love.keyboard.isDown("lshift") and player.stamina > 0 then
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
        if love.keyboard.isDown("lshift") and player.stamina > 0 then
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

    if isRunning == true then
        player.stamina = player.stamina - 0.2
    elseif player.stamina < 100 then
        player.stamina = player.stamina + 0.1
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

    if not player.animation.idle then
        player.animation.animation:update(dt)
    end

    if player.collider:enter("Environment") then
        jumpCount = 0
        player.isJumping = false
        local fallThreshold = 250
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
            fallDistance = math.abs(player.collider:getY() - groundY)
        end
    end

    if player.health < 0 then
        state["Running"] = false
        state["Closing"] = true
    end

    ---camera
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    cam:lookAt(player.collider:getX(), player.collider:getY())
    if cam.x < width/2 then
        cam.x = width/2
    end
    if cam.y < height/2 then
        cam.y = height/2
    end
    if cam.x > (mapW - width/2) then
         cam.x = mapW - width/2
    end
    if cam.y > (mapH - height/2) then
        cam.y = mapH - height/2
    end
end

function love.draw()
    if state["Running"] == true then
        love.graphics.draw(Sky,0,0,0,2.5,2)
        cam:attach()
        gameMap:drawLayer(gameMap.layers["Mountains"])
        gameMap:drawLayer(gameMap.layers["BACKGROUND TREES"])
        gameMap:drawLayer(gameMap.layers["Tile Layer 1"])
        gameMap:drawLayer(gameMap.layers["Trees"])
        gameMap:drawLayer(gameMap.layers["Objects"])
        if player.animation.direction == "right" then
            player.animation.animation:draw(player.spriteSheet, player.collider:getX()-40, player.collider:getY()-100,0)
        else
            player.animation.animation:draw(player.spriteSheet, player.collider:getX()-53, player.collider:getY()-100, 0, -1, 1, QUAD_WIDTH, 0)
        end
        cam:detach()
        love.graphics.draw(love.graphics.newImage("Sprites/HUD/hp_bar.png"),80,25,0,player.health/100,1)
        love.graphics.draw(love.graphics.newImage("Sprites/HUD/mp_bar.png"),75,32,0,player.stamina/100,1)
        love.graphics.draw(love.graphics.newImage("Sprites/HUD/hud_bg_without_custom_meter.png"),0,0)
    elseif state["Start"] == true or state["Pause"] == true then
        buttons.start_state.play_game:draw(10, 20, 17, 10)
        buttons.start_state.save:draw(10, 70, 17, 10)
        buttons.start_state.exit_game:draw(10, 120, 17, 10)
    elseif state["Closing"] == true then
        buttons.start_state.play_game:draw(10, 20, 17, 10)
        love.graphics.printf("THANKS FOR PLAYING", love.graphics.newFont(16), 10, love.graphics.getHeight() - 350, love.graphics.getWidth())
    end
    love.graphics.printf("FPS: " .. love.timer.getFPS(), love.graphics.newFont(16), 10, love.graphics.getHeight() - 30, love.graphics.getWidth())
    
    --world:draw()
end

-- Jump Functionalities
function love.keypressed(key)
    if key == 'space'  and jumpCount<2 then
        player.collider:applyLinearImpulse(0, -150)
        jumpCount = jumpCount + 1
        player.isJumping = true
    end

    if key == 'escape' then
        state["Pause"] = true
        state["Running"] = false
    end
end