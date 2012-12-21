
/* libs */
import dye/[core, input, sprite, font, math, primitives]

use sdl
import sdl/[Core]

use yaml
import yaml/[Document]

import math
import structs/[ArrayList, Stack, HashMap, List]

use deadlogger
import deadlogger/[Log, Logger]

/* internal */
import gnaar/[ui, loader, saver, dialogs]

InvalidInputException: class extends Exception {
    
    init: super func

}

LevelBase: abstract class {

    reset: abstract func
    getLayer: abstract func (index: Int) -> LayerBase
    getLayerByName: abstract func (name: String) -> LayerBase

}

LayerBase: abstract class {

    level: LevelBase
    name: String

    init: func (=level, =name) {
        "Created layer %s" printfln(name)
    }

    spawn: abstract func (family: String, name: String, pos: Vec2) -> GnObject

}

LayerFactory: abstract class {

    spawnLayers: abstract func (ui: GnUI)

}

ObjectFactory: abstract class {

    layer: EditorLayer
    family: String

    logger := static Log getLogger(This name)

    init: func (=layer, =family)

    spawn: abstract func (name: String, pos: Vec2) -> GnObject

}

EditorLayer: class extends LayerBase {

    moving := false

    logger: Logger
    factories := HashMap<String, ObjectFactory> new()
    objects := ArrayList<EditorObject> new()
    ui: GnUI

    selectedObjects := ArrayList<EditorObject> new()

    group: GlGroup

    name: String

    init: func (=ui, =name) {
        group = GlGroup new()
        ui layerGroup add(group)
        logger = Log getLogger("layer: %s" format(name))
    }

    add: func (object: EditorObject) -> EditorObject {
        object layer = this
        objects add(object)
        group add(object group)
        object
    }

    remove: func (object: EditorObject) {
        object layer = null
        objects remove(object)
        group remove(object group)
    }

    insert: func

    update: func {
        for (o in objects) {
            o update()
        }
    }

    deleteSelected: func {
        while (!selectedObjects empty?()) {
            o := selectedObjects get(0)
            deselect(o)
            o remove()
        }
    }

    click: func {
        // Shift = multi-selection
        if (!ui input isPressed(Keys SHIFT)) {
            clearSelection()
        }

        singleSelect()
    }

    singleSelect: func {
        o := singlePick()
        if (o) {
            if (ui input isPressed(Keys SHIFT)) {
                toggleSelect(o)
            } else {
                select(o)
            }
        }
    }

    singlePick: func -> EditorObject {
        handPos := ui handPos()

        for (o in objects) {
            if (o contains?(handPos)) {
                return o
            }
        }

        null
    }

    toggleSelect: func (o: EditorObject) {
        if (selectedObjects contains?(o)) {
            deselect(o)
        } else {
            select(o)
        }
    }

    select: func (o: EditorObject) {
        if (!selectedObjects contains?(o)) {
            o outlineGroup visible = true
            selectedObjects add(o)
        }
    }

    deselect: func (o: EditorObject) {
        if (selectedObjects contains?(o)) {
            o outlineGroup visible = false
            selectedObjects remove(o)
        }
    }

    clearSelection: func {
        while (!selectedObjects empty?()) {
            deselect(selectedObjects get(0))
        }
    }

    drag: func (delta: Vec2) {
        if (!moving) return

        for (o in selectedObjects) {
            ourDelta := delta
            if(ui input isPressed(Keys X)) {
                ourDelta y = 0
            } else if (ui input isPressed(Keys Y)) {
                ourDelta x = 0
            }

            o pos add!(delta)
        }
    }

    dragStart: func (handStart: Vec2) {
        inSelection := false
        moving = false

        for (o in selectedObjects) {
            if (o contains?(handStart)) {
                inSelection = true
                break
            }
        }

        if (inSelection) {
            moving = true // all good
        } else {
            o := singlePick()
            if (o) {
                clearSelection()
                select(o)
                moving = true
            }
        }

        if (moving && ui input isPressed(Keys D)) {
            old := ArrayList<EditorObject> new()
            old addAll(selectedObjects)
            clearSelection()

            for (o in old) {
                c := o clone()
                add(c)
                select(c)
            }
        }
    }

    dragEnd: func {
        moving = false

        // CTRL = precise dragging
        if (!ui input isPressed(Keys CTRL)) {
            for (o in selectedObjects) {
                o snap!(ui gridSize)
            }
        }
    }

    destroy: func {
        while (!objects empty?()) {
            objects get(0) destroy()
        }
        ui layerGroup remove(group)
        ui layers remove(this)
    }

    spawn: func (family: String, name: String, pos: Vec2) -> GnObject {
        factory := getFactory(family)
        if (factory) {
            factory spawn(name, pos)
        } else {
            null
        }
    }

    addFactory: func (factory: ObjectFactory) {
        factories put(factory family, factory)
    }

    getFactory: func (family: String) -> ObjectFactory {
        if (!factories contains?(family)) {
            logger warn("No such factory: %s (for layer %s)" format(family, name))
            return null
        }

        factories get(family)
    }

}

GnObject: abstract class {

    load: func (map: HashMap<String, DocumentNode>) {
        // by default, no property besides family or name
    }

    emit: func (map: MappingNode) {
        // by default, no property besides family or name
    }

}

EditorObject: abstract class extends GnObject {

    pos := vec2(0, 0)

    layer: EditorLayer

    group: GlGroup
    outlineGroup: GlGroup

    family, name: String

    init: func (=family, =name) {
        group = GlGroup new()
        outlineGroup = GlGroup new()
        outlineGroup visible = false
        group add(outlineGroup)
    }

    remove: func {
        destroy()
    }

    destroy: func {
        layer remove(this)
    }
    
    contains?: func (hand: Vec2) -> Bool {
        false
    }

    clone: func -> This {
        // By default objects aren't clonable - they'll just return themselves
        this
    }

    contains?: func ~rect (size, hand: Vec2) -> Bool {
        left  :=  pos x - size x * 0.5
        right :=  pos x + size x * 0.5
        top    := pos y - size y * 0.5
        bottom := pos y + size y * 0.5

        if (hand x < left) return false
        if (hand x > right) return false
        if (hand y < top) return false
        if (hand y > bottom) return false

        true
    }

    update: func {
        group pos set!(pos)
    }

    snap!: func (gridSize: Int) {
        pos snap!(gridSize)
    }
    
    snap!: func ~rect (size: Vec2, gridSize: Int) {
        halfSize := vec2(size x * 0.5, - size y * 0.5)
        pos set!(pos sub(halfSize) snap(gridSize) add(halfSize))
    }

}

ImageObject: abstract class extends EditorObject {

    OUTLINE_COLOR := static Color new(0, 160, 160)

    sprite: GlSprite

    init: func (=name, initPos: Vec2, path: String) {
        super("prop", name)

        sprite = GlSprite new(path)
        group add(sprite)

        rect := GlRectangle new()
        rect size set!(sprite size)
        rect color = OUTLINE_COLOR
        rect filled = false
        rect lineWidth = 2.0
        outlineGroup add(rect)

        pos set!(initPos)
    }

    contains?: func (hand: Vec2) -> Bool {
        contains?(sprite size, hand)
    }

    snap!: func (gridSize: Int) {
        snap!(sprite size, gridSize)
    }

}

