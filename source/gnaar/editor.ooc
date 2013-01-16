
// libs
use dye
import dye/[core, input, sprite, font, math, primitives]

import math
import structs/[ArrayList, Stack, List]

use deadlogger
import deadlogger/[Log, Logger]

use sdl2
import sdl2/[Core, Event]

// internal
import gnaar/[ui, events]
import gnaar/[utils, objects, dialogs, loader, saver]

Editor: class extends LevelBase {

    logger := static Log getLogger(This name)

    /* Camera */
    camPos := vec2(0, 0)
    draggingCam := false
    camNudge := 128.0

    /* Groups */
    group: GlGroup
    worldGroup: GlGroup
    layerGroup: GlGroup

    /* Layers */
    layers := ArrayList<EditorLayer> new()
    activeLayer: EditorLayer
    factory: LayerFactory

    /* Interface */
    frame: Frame
    input: Input
    listener: EditorEventListener

    camPosText: Label
    mousePosText: Label
    activeLayerText: Label

    running := true

    init: func (dye: DyeContext, =factory) {
        frame = Frame new(dye)
        frame padding set!(10, 10)
        input = frame input

        listener = EditorEventListener new(this)
        frame queue subscribe(listener)

        group = GlGroup new()
        dye add(group)

        worldGroup = GlGroup new()
        group add(worldGroup)

        {
            layerGroup = GlGroup new()
            worldGroup add(layerGroup)
        }

        group add(frame)
        initHud()
        initEvents()
    }

    initHud: func {
        camPosText = Label new("camera pos")
        frame add(camPosText)

        mousePosText = Label new("camera pos")
        frame add(mousePosText)

        activeLayerText = Label new("active layer: <unknown>")
        frame add(activeLayerText)
    }

    handPos: func -> Vec2 {
        toWorld(input getMousePos())
    }

    closeEditor: func {
        // TODO: ask if dirty level should be saved
        running = false
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
        activeLayerText setValue("active layer: %s", activeLayer name)
    }

    update: func {
        frame update()

        for (layer in layers) {
            layer update()
        }

        updateCamera()
        updateHud()
    }

    updateHud: func {
        camPosText setValue("camera pos: %s", camPos _)
        mousePosText setValue("mouse pos: %s", handPos() _)
    }

    updateCamera: func {
        if (draggingCam) {
            camPos sub!(frame delta)
        }
        worldGroup pos set!(center() sub(camPos))
    }

    /* Coordinate */

    toWorld: func (mouseCoords: Vec2) -> Vec2 {
        mouseCoords sub(center()) add(camPos)
    }

    center: func -> Vec2 {
        frame size mul(0.5)
    }

    /* Event handling */

    initEvents: func {
        input onExit(||
            closeEditor()
        )

        input onKeyPress(|kev|
            if (!frame root?) return

            match (kev scancode) {
                case Keys ESC =>
                    closeEditor()
                case Keys F1 =>
                    frame push(InputDialog new(frame, "Enter level path to load", |name|
                        loader := LevelLoader new(name, this)
                        if (!loader success) {
                            frame push(AlertDialog new(frame, "Could not load level %s" format(name)))
                        }
                    ))
                case Keys F2 =>
                    frame push(InputDialog new(frame, "Enter level path to save", |name|
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

        input onMousePress(Buttons MIDDLE, ||
            draggingCam = true
        )

        input onMouseRelease(Buttons MIDDLE, ||
            draggingCam = false
        )
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

}

EditorEventListener: class extends EventListener {

    editor: Editor

    init: func (=editor)

    onEvent: func (e: GEvent) {
        match e {
            case dragStart: DragStartEvent =>
                if (editor activeLayer) {
                    handPos := editor toWorld(dragStart pos)
                    editor activeLayer dragStart(handPos)
                }

            case drag: DragEvent =>
                if (editor activeLayer) {
                    editor activeLayer drag(drag delta)
                }
                
            case dragStop: DragStopEvent =>
                if (editor activeLayer) {
                    editor activeLayer dragEnd()
                }

            case click: ClickEvent =>
                if (click button == Buttons LEFT && editor activeLayer) {
                    editor activeLayer click()
                }

        }
    }

}

