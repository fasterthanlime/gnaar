
// libs
import dye/[core, input, sprite, font, math, primitives]

import math
import structs/[ArrayList, Stack, List]

use deadlogger
import deadlogger/[Log, Logger]

use sdl
import sdl/[Core]

// internal
import gnaar/[utils, objects, dialogs, loader, saver]

GnUI: class extends LevelBase {

    prevMousePos := vec2(0, 0)

    fontPath := static "assets/ttf/font.ttf"
    logger := static Log getLogger("editor-ui")

    dye: DyeContext
    input: Input

    running := true

    /* dragging */
    dragging := false
    dragStart := false
    dragThreshold := 2.0
    dragPath := vec(0, 0)

    /* Camera */
    camPos := vec2(0, 0)
    draggingCam := false
    camNudge := 128.0
    
    /* Dye groups */
    group: GlGroup
    worldGroup: GlGroup
        layerGroup: GlGroup
    hudGroup: GlGroup
    dialogGroup: GlGroup
    
    /* Dialogs */
    dialogStack := Stack<Dialog> new()

    /* Layers */
    layers := ArrayList<EditorLayer> new()
    activeLayer: EditorLayer

    factory: LayerFactory

    /* HUD */
    camPosText: GlText
    mousePosText: GlText
    activeLayerText: GlText

    /* Constructor */
    init: func (=dye, globalInput: Input, =factory) {
        dye setClearColor(Color white())
        dye setShowCursor(true)
        SDL enableUnicode(true)
        SDL enableKeyRepeat(SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL)

        group = GlGroup new()
        dye add(group)

        worldGroup = GlGroup new()
        group add(worldGroup)

        {
            layerGroup = GlGroup new()
            worldGroup add(layerGroup)
        }

        hudGroup = GlGroup new()
        group add(hudGroup)

        dialogGroup = GlGroup new()
        group add(dialogGroup)

        input = globalInput sub()

        initEvents()
        prevMousePos set!(input getMousePos())

        initHud()
        initLayers()
    }

    reset: func {
        clearLayers()
        initLayers()
    }

    clearLayers: func {
        while (!layers empty?()) {
            layers get(0) destroy()
        }
    }

    initLayers: func {
        if (layers empty?())

        factory spawnLayers(this)

        setActiveLayer(0)
    }

    initHud: func {
        camPosText = GlText new(fontPath, "camera pos")
        camPosText color set!(Color black())
        hudGroup add(camPosText)

        mousePosText = GlText new(fontPath, "camera pos")
        mousePosText color set!(Color black())
        mousePosText pos add!(300, 0)
        hudGroup add(mousePosText)

        activeLayerText = GlText new(fontPath, "active layer: <unknown>")
        activeLayerText color set!(Color black())
        activeLayerText pos set!(30, dye height - 30)
        hudGroup add(activeLayerText)
    }

    updateHud: func {
        camPosText value = "camera pos: %s" format(camPos _)
        mousePosText value = "mouse pos: %s" format(handPos() _)
    }

    handPos: func -> Vec2 {
        toWorld(input getMousePos())
    }

    openDialog: func {
    }

    push: func (dialog: Dialog) {
        dialogStack push(dialog)
    }

    pop: func (dialog: Dialog) {
        if (root?) return
        dialogStack pop()
    }

    root?: Bool { get { dialogStack empty?() } }

    update: func {
        updateMouse()

        for (layer in layers) {
            layer update()
        }
        updateCamera()
        updateHud()

        if (!root?) {
            dialog := dialogStack peek()
            dialog update()
        }
    }

    updateCamera: func {
        worldGroup pos set!(screenSize() mul(0.5) add(camPos mul(-1.0)))
    }

    updateMouse: func {
        mousePos := input getMousePos()
        delta := mousePos sub(prevMousePos)
        
        if (draggingCam) {
            camPos sub!(delta)
        }

        if (dragging && activeLayer) {
            activeLayer drag(delta)
        }

        if (dragStart) {
            dragPath add!(delta)

            if (dragPath norm() >= dragThreshold) {
                // Yup, it's a drag
                dragStart = false
                dragging = true

                if (activeLayer) {
                    activeLayer dragStart(handPos() sub(dragPath))
                    activeLayer drag(dragPath)
                }
            }
        }

        prevMousePos set!(mousePos)
    }

    setActiveLayer: func (index: Int) {
        if (index < 0 || index >= layers size) {
            logger warn("No such layer: %d" format(index))
            return
        }

        if (activeLayer) {
            activeLayer clearSelection()
        }
        activeLayer = getLayer(index)
        activeLayerText value = "active layer: %s" format(activeLayer name)
    }

    initEvents: func {
        input onKeyPress(|kev|
            if (!root?) return

            match (kev code) {
                case Keys ESC =>
                    running = false
                case Keys F1 =>
                    push(InputDialog new(this, "Enter level path to load", |name|
                        loader := LevelLoader new(name, this)
                        if (!loader success) {
                            push(AlertDialog new(this, "Could not load level %s" format(name)))
                        }
                    ))
                case Keys F2 =>
                    push(InputDialog new(this, "Enter level path to save", |name|
                        LevelSaver new(name, this)
                    ))
                case Keys KP0 =>
                    camPos set!(0, 0)
                case Keys KP4 =>
                    camPos sub!(camNudge, 0)
                case Keys KP6 =>
                    camPos add!(camNudge, 0)
                case Keys KP2 =>
                    camPos add!(0, camNudge)
                case Keys KP8 => 
                    camPos sub!(0, camNudge)
                case Keys I =>
                    if (activeLayer) {
                        activeLayer insert()
                    }
                case Keys BACKSPACE || Keys DEL =>
                    if (activeLayer) activeLayer deleteSelected()
                case Keys _1 =>
                    setActiveLayer(0)
                case Keys _2 =>
                    setActiveLayer(1)
                case Keys _3 =>
                    setActiveLayer(2)
                case Keys _4 =>
                    setActiveLayer(3)
                case Keys _5 =>
                    setActiveLayer(4)
                case Keys _6 =>
                    setActiveLayer(5)
                case Keys _7 =>
                    setActiveLayer(6)
                case Keys _8 =>
                    setActiveLayer(7)
                case Keys _9 =>
                    setActiveLayer(8)
                case Keys _0 =>
                    setActiveLayer(9)
                case Keys LEFT =>
                    if (activeLayer) {
                        activeLayer left()
                    }
                case Keys RIGHT =>
                    if (activeLayer) {
                        activeLayer right()
                    }
                case Keys UP =>
                    if (activeLayer) {
                        activeLayer up()
                    }
                case Keys DOWN =>
                    if (activeLayer) {
                        activeLayer down()
                    }
            }
        )

        input onMousePress(Buttons LEFT, ||
            dragStart = true
            dragPath = vec2(0, 0)
            dragging = false
        )

        input onMouseRelease(Buttons LEFT, ||
            dragStart = false
            if (dragging) {
                dragging = false
                if (activeLayer) {
                    activeLayer dragEnd()
                }
            } else {
                if (activeLayer) {
                    activeLayer click()
                }
            }
        )

        input onMousePress(Buttons MIDDLE, ||
            draggingCam = true
        )

        input onMouseRelease(Buttons MIDDLE, ||
            draggingCam = false
        )
    }

    screenSize: func -> Vec2 {
        vec2(dye width, dye height)
    }
    
    addLayer: func (layer: EditorLayer) {
        layers add(layer)
    }

    getLayer: func (index: Int) -> EditorLayer {
        layers get(index)
    }

    getLayerByName: func (name: String) -> EditorLayer {
        for (layer in layers) {
            if (layer name == name) {
                return layer
            }
        }
        null
    }

    /* Coordinate */

    toWorld: func (mouseCoords: Vec2) -> Vec2 {
        mouseCoords sub(screenSize() mul(0.5)) add(camPos)
    }
}

                
