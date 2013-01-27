
// libs
use dye
import dye/[core, input, sprite, text, math, primitives]

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
    sidebar: Panel
    input: Input
    listener: EditorEventListener

    activeLayerText: Label

    running := true

    init: func (scene: Scene, =factory) {
        frame = Frame new(scene)
        input = frame input

        listener = EditorEventListener new(this)
        frame queue subscribe(listener)

        group = scene

        worldGroup = GlGroup new()
        group add(worldGroup)

        {
            layerGroup = GlGroup new()
            worldGroup add(layerGroup)
        }

        group add(frame)
        initHud()
        initEvents()

        reset()
    }

    initHud: func {
        sidebar = Panel new()
        sidebar setBackgroundColor(Color new(30, 30, 30))
        sidebar margin set!(10, 10)
        sidebar padding set!(10, 10)
        sidebar setWidth(400)
        sidebar setRelativeHeight(100)
        frame add(sidebar)

        activeLayerText = Label new("active layer: <unknown>")
        activeLayerText setDisplayFlavor(DisplayFlavor BLOCK)
        sidebar add(activeLayerText)
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
        frame givenSize mul(0.5)
    }

    /* Event handling */

    initEvents: func {
        input onExit(||
            closeEditor()
        )

        input onKeyPress(|kev|
            if (!frame root?) return

            match (kev scancode) {
                case KeyCode ESC =>
                    kev consume()
                    closeEditor()
                case KeyCode F1 =>
                    frame push(InputDialog new(frame, "Enter level path to load", |name|
                        loader := LevelLoader new(name, this)
                        if (!loader success) {
                            message := "Could not load level %s" format(name)
                            frame push(AlertDialog new(frame, message))
                        }
                    ))
                case KeyCode F2 =>
                    frame push(InputDialog new(frame, "Enter level path to save", |name|
                        LevelSaver new(name, this)
                    ))
                case KeyCode KP0 =>
                    camPos set!(0, 0)
                case KeyCode KP4 =>
                    camPos sub!(camNudge, 0)
                case KeyCode KP6 =>
                    camPos add!(camNudge, 0)
                case KeyCode KP2 =>
                    camPos add!(0, camNudge)
                case KeyCode KP8 => 
                    camPos sub!(0, camNudge)
                case KeyCode I =>
                    if (activeLayer) {
                        activeLayer insert()
                    }
                case KeyCode BACKSPACE || KeyCode DEL =>
                    if (activeLayer) activeLayer deleteSelected()
                case KeyCode _1 =>
                    setActiveLayer(0)
                case KeyCode _2 =>
                    setActiveLayer(1)
                case KeyCode _3 =>
                    setActiveLayer(2)
                case KeyCode _4 =>
                    setActiveLayer(3)
                case KeyCode _5 =>
                    setActiveLayer(4)
                case KeyCode _6 =>
                    setActiveLayer(5)
                case KeyCode _7 =>
                    setActiveLayer(6)
                case KeyCode _8 =>
                    setActiveLayer(7)
                case KeyCode _9 =>
                    setActiveLayer(8)
                case KeyCode _0 =>
                    setActiveLayer(9)
                case KeyCode LEFT =>
                    if (activeLayer) {
                        activeLayer left()
                    }
                case KeyCode RIGHT =>
                    if (activeLayer) {
                        activeLayer right()
                    }
                case KeyCode UP =>
                    if (activeLayer) {
                        activeLayer up()
                    }
                case KeyCode DOWN =>
                    if (activeLayer) {
                        activeLayer down()
                    }
            }
        )

        input onMousePress(MouseButton MIDDLE, |ev|
            draggingCam = true
        )

        input onMouseRelease(MouseButton MIDDLE, |ev|
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
                if (click button == MouseButton LEFT && editor activeLayer) {
                    editor activeLayer click()
                }

        }
    }

}

