if not game:IsLoaded() then game.Loaded:Wait() end

local BASE = 'https://raw.githubusercontent.com/kimmingehu/Ouroboros/main/games/'
local games = {
    [825735094] = 'stealanegg.lua',
}

local scriptUrl = BASE .. games[game.PlaceId]
if scriptUrl then
    loadstring(game:HttpGet(scriptUrl))()
else
    print('Game not supported: ' .. tostring(game.PlaceId))
end
