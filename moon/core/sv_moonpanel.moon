--@include moonpanel/core/sh_moonpanel.txt

getters = (cls, getters) ->
  cls.__base.__index = (key) =>
    if getter = getters[key]
      getter @
    else
      cls.__base[key]

setters = (cls, setters) ->
  cls.__base.__newindex = (key, val) =>
    if setter = setters[key]
      setter @, val
    else
      rawset @, key, val

TileShared = require "moonpanel/core/sh_moonpanel.txt"

COLOR_BG = Color 80, 77, 255, 255
COLOR_UNTRACED = Color 40, 22, 186
COLOR_TRACED = Color 255, 255, 255, 255
COLOR_VIGNETTE = Color 0, 0, 0, 92

DEFAULT_SCREEN_TO_INNER_RATIO = (630-250) / 630
DEFAULT_SCREEN_TO_BAR_WIDTH_RATIO = 0.08
MINIMUM_BARWIDTH = 10
MAXIMUM_BARWIDTH = 24

DEFAULT_RESOLUTIONS = [
    [1]: {
        innerScreen
    }
    [2]: {
        innerScreen
    }
    [3]: {
        innerScreen
    }
    [1]: {
        innerScreen
    }
]

DEFAULTEST_RESOLUTION

return class Tile extends TileShared
    __internal: {}
    getters @,
        isPowered: =>
            return @__internal.isPowered
    
    setters @,
        isPowered: (value) =>
            @__internal.isPowered = true
            net.start "UpdatePowered"
            net.writeInt value and 1 or 0, 2
            net.send!

    setup: (@tileData) =>
        printTable @tileData

        -- Init coloures
        @tileData.colors            or= {}
        @tileData.colors.background or= COLOR_BG
        @tileData.colors.untraced   or= COLOR_UNTRACED
        @tileData.colors.traced     or= COLOR_TRACED
        @tileData.colors.vignette   or= COLOR_VIGNETTE

        -- Init tile defaults
        @tileData.tile        or= {}
        @tileData.tile.width  or= 2
        @tileData.tile.height or= 2

        width  = @tileData.tile.width
        height = @tileData.tile.height

        screenWidth = 1024 -- why? because for some reason RT contexts are 1024.
        -- it's also good to keep in mind that tileData.dimensions.screenWidth
        -- should only be used for rendering in RT context.

        -- Calculate dimensions
        innerZoneLength = math.ceil screenWidth * DEFAULT_SCREEN_TO_INNER_RATIO
        
        maxDim    = math.max width, height
        barWidth  = math.floor math.max MINIMUM_BARWIDTH, (innerZoneLength * DEFAULT_SCREEN_TO_BAR_WIDTH_RATIO)
        barWidth  = math.min barWidth, MAXIMUM_BARWIDTH

        barLength = math.floor (innerZoneLength - (barWidth * (maxDim + 1))) / maxDim

        tileData.dimensions = {
            offsetH: math.ceil (screenWidth - (barWidth * (width + 1)) - (barLength * width)) / 2
            offsetV: math.ceil (screenWidth - (barWidth * (height + 1)) - (barLength * height)) / 2

            innerZoneLength: innerZoneLength
            barWidth: barWidth
            barLength: barLength
            width: width
            height: height

            screenWidth: screenWidth
            screenHeight: screenWidth
        }

        data = fastlz.compress json.encode @tileData

        net.start "ClearTileData"
        net.send!

        sendData = () ->
            net.start "UpdateTileData"
            net.writeInt #data, 32
            net.writeData data, #data
            net.send!
            @isPowered = true

        -- Starfall bug
        if @firstExecution
            @firstExecution = false
            timer.simple 2, sendData
        else
            sendData!

    new: () =>
        @firstExecution = true
        super!