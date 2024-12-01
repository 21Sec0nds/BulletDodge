-- Retro Gadgets
-- Joystick input
local joy = gdt.Stick0
-- Video chip for rendering
local vid = gdt.VideoChip0

-- Player (ball) position
local ballX = vid.Width / 2 - 1
local ballY = vid.Height - 4

-- Enemy (top triangle) position and speed
local enemyX = vid.Width / 2 - 1
local enemyY = 3
local enemySpeed = 0.3 -- Speed at which the enemy moves horizontally

-- Bullets list and their speed
local bullets = {}
local bulletSpeed = 0.5
local shootTimer = 0
local shootInterval = 2 -- Time between enemy shots (in seconds)

local font = gdt.ROM.System.SpriteSheets["StandardFont"]
-- Game state flags
local isGameOver = false
local isGameWon = false

-- LED Strip
local ledStrip = gdt.LedStrip0
local maxLeds = #ledStrip.States

-- Audio Chip
local audioChip = gdt.AudioChip0
local winSound = gdt.ROM.User.AudioSamples["win"]
local loseSound = gdt.ROM.User.AudioSamples["lose"]

-- Colors for convenience
local colorWhite = color.white
local colorBlack = color.black

-- Update function runs every tick
function update()
    if isGameOver then
        -- If the game is over, display "Game Over!" message
        vid.Clear(vid, colorBlack)
        vid:DrawText(vec2(10, 10), font, "Game Over!", colorWhite, colorBlack)
        return
    end

    if isGameWon then
        -- If the game is won, display "You Win!" message and play the sound
        vid.Clear(vid, colorBlack)
        vid:DrawText(vec2(10, 10), font, "You Win!", colorWhite, colorBlack)
        if not audioChip:IsPlaying(1) then
            audioChip:Play(winSound, 1)
        end
        return
    end

    -- Clear screen for the new frame
    vid.Clear(vid, colorBlack)

    -- Player movement
    local x = joy.X
    ballX = ballX + x / 100
    if ballX < 0 then
        ballX = 0
    elseif ballX > vid.Width - 1 then
        ballX = vid.Width - 1
    end

    -- Shooting logic: enemy fires bullets at intervals
    shootTimer = shootTimer + 1 / 60
    if shootTimer >= shootInterval then
        shootTimer = 0
        -- Add a new bullet starting from the enemy position
        table.insert(bullets, {x = enemyX, y = enemyY})
        -- Increase bullet speed and reduce interval over time
        bulletSpeed = bulletSpeed + 0.06
        shootInterval = math.max(0.6, shootInterval - 0.1)

        -- Calculate active LEDs based on bullet speed
        local activeLeds = math.min(math.floor(bulletSpeed), maxLeds)

        -- Light up the LEDs corresponding to the current level
        for i = 1, maxLeds do
            if i <= activeLeds then
                ledStrip.States[i] = true
                ledStrip.Colors[i] = color.red
            else
                ledStrip.States[i] = false
            end
        end

        -- Check if all LEDs are active
        if activeLeds >= maxLeds then
            isGameWon = true
        end
    end

    -- Update bullets and check for collisions
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        bullet.y = bullet.y + bulletSpeed
        -- Remove bullet if it goes off-screen
        if bullet.y > vid.Height then
            table.remove(bullets, i)
        -- Check collision with player
        elseif math.abs(bullet.x - ballX) < 2 and math.abs(bullet.y - ballY) < 2 then
            -- Game over if a bullet hits the player
            if not audioChip:IsPlaying(2) then
                audioChip:Play(loseSound, 2)
            end
            isGameOver = true
            return
        end
    end

    -- Move the enemy horizontally
    enemyX = enemyX + enemySpeed

    -- Reverse direction when hitting the screen boundaries
    if enemyX < 0 or enemyX > vid.Width - 1 then
        enemySpeed = -enemySpeed
    end

    -- Draw player (ball)
    vid:DrawCircle(vec2(ballX, ballY), 3, colorWhite)

    -- Draw enemy (top triangle)
    vid:DrawTriangle(
        vec2(enemyX, enemyY),
        vec2(enemyX - 5, enemyY + 10),
        vec2(enemyX + 5, enemyY + 10),
        colorWhite
    )

    -- Draw bullets
    for _, bullet in ipairs(bullets) do
        if bullet.x >= 0 and bullet.x < vid.Width and bullet.y >= 0 and bullet.y < vid.Height then
            vid:DrawCircle(vec2(bullet.x, bullet.y), 2, colorWhite)
        end
    end
end
