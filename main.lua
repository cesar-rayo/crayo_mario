require 'src/Dependencies'

function love.load()
    math.randomseed(os.time())

    -- load images
    tileSheet = love.graphics.newImage('graphics/tiles.png')
    quads = GenerateQuads(tileSheet, TILE_SIZE, TILE_SIZE)

    topperSheet = love.graphics.newImage('graphics/tile_tops.png')
    topperQuads = GenerateQuads(topperSheet, TILE_SIZE, TILE_SIZE)

    -- divide quad tables into tile sets
    tilesets = GenerateTileSets(quads, TILE_SETS_WIDE, TILE_SETS_TALL, TILE_SET_WIDTH, TILE_SET_HEIGHT)
    toppersets = GenerateTileSets(topperQuads, TOPPER_SETS_WIDE, TOPPER_SETS_TALL, TILE_SET_WIDTH, TILE_SET_HEIGHT)

    -- random tile set and topper set for the level
    tileset = math.random(#tilesets)
    topperset = math.random(#toppersets)

    characterSheet = love.graphics.newImage('graphics/character.png')
    characterQuads = GenerateQuads(characterSheet, CHARACTER_WIDTH, CHARACTER_HEIGHT)

    idleAnimation = Animation{
        frames = {1, 2},
        interval = 0.5
    }
    walkAnimation = Animation{
        frames = {10, 11},
        interval = 0.2
    }
    jumpAnimation = Animation{
        frames = {4},
        interval = 1
    }
    downAnimation = Animation{
        frames = {4},
        interval = 1
    }

    currentAnimation = idleAnimation

    characterX = VIRTUAL_WIDTH / 2 - (CHARACTER_WIDTH / 2)
    characterY = ((7 - 1) * TILE_SIZE) - CHARACTER_HEIGHT

    characterDY = 0

    direction = 'right'
    mapWidth = 20
    mapHeight = 20

    cameraScroll = 0
    backgroundR = math.random(255) / 1000
    backgroundG = math.random(255) / 1000
    backgroundB = math.random(255) / 1000

    tiles = generateLevel()

    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle('Crayo Mario')

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT,{
        fullscreen = false,
        resizable = true,
        vsync = true
    })
end

function love.resize(w, h)
    push:resize(w,h)
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    if key == 'space' and characterDY == 0 then
        characterDY = JUMP_VELOCITY
        currentAnimation = jumpAnimation
    end

    if key == 'r' then
        tileset = math.random(#tilesets)
        topperset = math.random(#toppersets)
    end
end

function love.update(dt)
    characterDY = characterDY + GRAVITY
    characterY = characterY + characterDY * dt
    
    if characterY > ((7 - 1) * TILE_SIZE) - CHARACTER_HEIGHT then
        characterY = ((7 - 1) * TILE_SIZE) - CHARACTER_HEIGHT
        characterDY = 0
    end
    
    currentAnimation:update(dt)

    if love.keyboard.isDown('left') then
        characterX = characterX - CHARACTER_MOVE_SPEED * dt

        if characterDY == 0 then
            currentAnimation = walkAnimation
        end

        direction = 'left'
    
    elseif love.keyboard.isDown('right') then
        characterX = characterX + CHARACTER_MOVE_SPEED * dt

        if characterDY == 0 then
            currentAnimation = walkAnimation
        end

        direction = 'right'
    elseif love.keyboard.isDown('down') then
        currentAnimation = downAnimation
    else
        currentAnimation = idleAnimation
    end

    -- set camera's left edge
    cameraScroll = characterX - (VIRTUAL_WIDTH / 2) + (CHARACTER_WIDTH / 2)
end

function love.draw()
    push:start()
        love.graphics.translate(-math.floor(cameraScroll), 0) -- translates X axis only
        love.graphics.clear(backgroundR, backgroundG, backgroundB, 255)

        for y = 1, mapWidth do
            for x = 1, mapHeight do
                local tile = tiles[y][x]
                love.graphics.draw(tileSheet, tilesets[tileset][tile.id],
                    (x-1) * TILE_SIZE, (y-1) * TILE_SIZE)

                if tile.topper then 
                    love.graphics.draw(topperSheet, toppersets[topperset][tile.id],
                        (x-1) * TILE_SIZE, (y-1) * TILE_SIZE)
                end
            end
        end

        -- draw character, this time getting the current frame from the animation
        -- we also check for our direction and scale by -1 on the X axis if we're facing left
        -- when we scale by -1, we have to set the origin to the center of the sprite as well for proper flipping
        love.graphics.draw(characterSheet, characterQuads[currentAnimation:getCurrentFrame()],

            -- X and Y we draw at need to be shifted by half our width and height because we're setting the origin
            -- to that amount for proper scaling, which reverse-shifts rendering
            math.floor(characterX) + CHARACTER_WIDTH / 2, math.floor(characterY) + CHARACTER_HEIGHT / 2,

            -- 0 rotation, then the X and Y scales
            0, direction == 'left' and -1 or 1,1,

            -- lastly, the origin offsets relative to 0,0 on the sprite (set here to the sprite's center)
            CHARACTER_WIDTH / 2, CHARACTER_HEIGHT / 2)

    push:finish()
end

function generateLevel()
    local tiles = {}

    for y=1, mapHeight do
        table.insert(tiles, {})

        for x=1, mapWidth do
            table.insert(tiles[y],{
                id = y < 7 and SKY or GROUND,
                topper = y == 7 and true or false
            })
        end
    end

    return tiles
end