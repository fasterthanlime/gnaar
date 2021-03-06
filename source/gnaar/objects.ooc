
// third-party stuff
use dye
import dye/[core, input, sprite, text, math, primitives]

use yaml
import yaml/[Document]

use deadlogger
import deadlogger/[Log, Logger]

// sdk stuff
import math
import structs/[ArrayList, Stack, HashMap, List]

/* our stuff */
import gnaar/[editor, loader, saver, dialogs, utils]

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
    }

    spawn: abstract func (family: String, name: String, pos: Vec2) -> GnObject

}

LayerFactory: abstract class {

    spawnLayers: abstract func (editor: Editor)

}

ObjectFactory: abstract class {

    layer: EditorLayer
    family: String

    logger := static Log getLogger(This name)

    init: func (=layer, =family)

    spawn: abstract func (name: String, pos: Vec2) -> GnObject

}

EditorLayer: abstract class extends LayerBase {

    factories := HashMap<String, ObjectFactory> new()

    group: GlGroup

    logger: Logger
    editor: Editor

    init: func (=editor, =name) {
        group = GlGroup new()
        editor layerGroup add(group)
        logger = Log getLogger("layer: %s" format(name))
    }

    add: abstract func (object: EditorObject) -> EditorObject

    remove: abstract func (object: EditorObject)

    update: abstract func

    click: func {

    }

    dragStart: func (handStart: Vec2) {

    }

    drag: func (delta: Vec2) {

    }

    dragEnd: func {

    }

    left: func {

    }

    right: func {

    }

    up: func {

    }

    down: func {

    }

    insert: func {

    }

    clearSelection: func {

    }

    deleteSelected: func {

    }

    destroy: abstract func {

    }

    eachObject: abstract func (f: Func(EditorObject))

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

DragLayer: class extends EditorLayer {

    moving := false
    objects := ArrayList<EditorObject> new()
    selectedObjects := ArrayList<EditorObject> new()

    gridSize := 64

    init: func (.editor, .name) {
        super(editor, name)
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

    update: func {
        for (o in objects) {
            o update()
        }
    }

    destroy: func {
        while (!objects empty?()) {
            objects get(0) destroy()
        }
        editor layerGroup remove(group)
        editor layers remove(this)
    }

    eachObject: func (f: Func(EditorObject)) {
        for (object in objects) {
            f(object)
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
        if (!editor input isPressed(KeyCode SHIFT)) {
            clearSelection()
        }

        singleSelect()
    }

    singleSelect: func {
        o := singlePick()
        if (o) {
            if (editor input isPressed(KeyCode SHIFT)) {
                toggleSelect(o)
            } else {
                select(o)
            }
        }
    }

    singlePick: func -> EditorObject {
        handPos := editor handPos()

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
            if(editor input isPressed(KeyCode X)) {
                ourDelta y = 0
            } else if (editor input isPressed(KeyCode Y)) {
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

        if (moving && editor input isPressed(KeyCode D)) {
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
        if (!editor input isPressed(KeyCode CTRL)) {
            for (o in selectedObjects) {
                o snap!(gridSize)
            }
        }
    }

}

GnObject: abstract class {

    load: func (map: HashMap<String, DocumentNode>) {
        // by default, no property besides family or name
    }

    emit: func (map: MappingNode) {
        // by default, no property besides family or name
    }

    destroy: func {
        // by default, nothing to do
    }

    preUpdate: func {
    }

    // return false to destroy
    update: func -> Bool {
        true
    }

}

EditorObject: abstract class extends GnObject {

    pos := vec2(0, 0)

    layer: EditorLayer

    group: GlGroup
    outlineGroup: GlGroup

    family, name: String

    init: func (=family, =name, initPos: Vec2) {
        group = GlGroup new()
        outlineGroup = GlGroup new()
        outlineGroup visible = false
        group add(outlineGroup)

        pos set!(initPos)
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
        BoundingBox contains?(pos, size, hand)
    }

    update: func {
        group pos set!(pos)
    }

    snap!: func (gridSize: Int) {
        pos snap!(gridSize)
    }
    
    snap!: func ~rect (size: Vec2, gridSize: Int) {
        pos set!(pos snap(size, gridSize))
    }

}

ImageObject: abstract class extends EditorObject {

    OUTLINE_COLOR := static Color new(0, 160, 160)

    sprite: GlSprite

    init: func (.family, .name, initPos: Vec2, path: String) {
        super(family, name, initPos)

        sprite = GlSprite new(path)
        group add(sprite)

        rect := GlRectangle new()
        rect size set!(sprite size)
        rect color = OUTLINE_COLOR
        rect filled = false
        rect lineWidth = 2.0
        outlineGroup add(rect)
    }

    contains?: func (hand: Vec2) -> Bool {
        contains?(sprite size, hand)
    }

    snap!: func (gridSize: Int) {
        snap!(sprite size, gridSize)
    }

}

