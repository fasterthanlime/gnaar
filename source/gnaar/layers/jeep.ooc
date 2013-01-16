
/* libs */
use dye
import dye/[core, input, sprite, font, math, primitives]

use yaml
import yaml/[Document]

import math, math/Random
import structs/[ArrayList, Stack, HashMap, List]

use deadlogger
import deadlogger/[Log, Logger]

use yaml
import yaml/[Parser, Document]

/* internal */
import gnaar/[editor, ui, loader, saver, dialogs, objects, utils]

JeepFactory: class extends ObjectFactory {

    init: func (.layer) {
        super(layer, "jeep")
    }

    spawn: func (name: String, pos: Vec2) -> GnObject {
        def := JeepDefinition load(name)
        if (def) {
            layer add(JeepObject new(def, pos))
        } else {
            logger warn("Jeep not found: %s" format(name))
        }
    }

}

JeepLayer: class extends EditorLayer {

    gridSize := 64

    current := vec2i(0, 0)

    grid := SparseGrid new()
    currentName := "<none>"

    init: func (.editor, .name) {
        super(editor, name)

        addFactory(JeepFactory new(this))
    }

    insert: func {
        editor frame push(InputDialog new(editor frame, "Enter jeep name", |name|
            currentName = name
        ))
    }

    insertAt: func (pos: Vec2, posi: Vec2i) {
        item := grid get(posi x, posi y)
        if (!item) {
            spawn("jeep", currentName, pos)
        } else if (item def name != currentName) {
            remove(item)
            spawn("jeep", currentName, pos)
        }
    }

    removeAt: func (pos: Vec2, posi: Vec2i) {
        item := grid get(posi x, posi y)
        if (item) {
            remove(item)
        }
    }

    click: func {
        if (currentName == "<none>") {
            insert()
        }

        pos := editor handPos() snap(vec2(gridSize, gridSize), gridSize)
        posi := pos getColRow(gridSize)

        if (editor input isPressed(Keys SHIFT)) {
            removeAt(pos, posi)
        } else {
            insertAt(pos, posi)
        }
    }

    dragStart: func (handStart: Vec2) {
        pos := editor handPos() snap(vec2(gridSize, gridSize), gridSize)
        current = pos getColRow(gridSize)

        block := grid get(current x, current y)
        if (block) {
            currentName = block def name
        }

        drag(vec2(0, 0))
    }

    drag: func (delta: Vec2) {
        pos := editor handPos() snap(vec2(gridSize, gridSize), gridSize)
        posi := pos getColRow(gridSize)

        if (posi equals(current)) return

        if (editor input isPressed(Keys SHIFT)) {
            removeAt(pos, posi)
        } else {
            insertAt(pos, posi)
        }

        current set!(posi)
    }

    dragEnd: func {
    }

    notifyNeighbors: func (col, row: Int) {
        grid notify(col - 1, row)
        grid notify(col + 1, row)
        grid notify(col, row - 1)
        grid notify(col, row + 1)
    }

    add: func (object: EditorObject) -> EditorObject {
        match (object) {
            case jo: JeepObject =>
                object layer = this
                group add(object group)
                grid put(jo col, jo row, jo)
                notifyNeighbors(jo col, jo row)
                grid notify(jo col, jo row)

                object
            case =>
                logger warn("Can not add %s to %s" format(object class name, This name))
                null
        }
    }

    remove: func (object: EditorObject) {
        match (object) {
            case jo: JeepObject =>
                grid remove(jo col, jo row)
                notifyNeighbors(jo col, jo row)
                group remove(object group)
                object layer = null

                object
            case =>
                logger warn("Can not remove %s from %s" format(object class name, This name))
                null
        }
    }

    update: func {
        // nothing to do here
    }

    destroy: func {
        eachObject(|object| object destroy())
        editor layerGroup remove(group)
        editor layers remove(this)
    }

    eachObject: func (f: Func (EditorObject)) {
        grid rows each(|rowNum, row|
            g := f
            row cols each(|colNum, obj|
                f(obj)
            )
        )
    }

}

JeepDefinition: class {

    name: String
    images := ArrayList<String> new()

    logger := static Log getLogger(This name)

    init: func (=name) {
    }

    cache := static HashMap<String, JeepDefinition> new()

    load: static func (name: String) -> JeepDefinition {
        if (cache contains?(name)) {
            return cache get(name)
        }

        path := "assets/jeeps/%s.yml" format(name)
        doc := parseYaml(path)
        if (!doc) {
            logger warn("File not found: %s" format(path))
            return null
        }

        map := doc toMap()
        
        def := This new(name)
        images := map get("images") toList()
        for (image in images) {
            def images add(image toString())
        }
        cache put(name, def)
        def
    }

}

SparseGrid: class {
    
    rows := HashMap<Int, Row> new()

    put: func (col, row: Int, obj: JeepObject) -> JeepObject {
        getRow(row) put(col, obj)
    }

    remove: func (col, row: Int) -> JeepObject {
        getRow(row) remove(col)
    }

    notify: func (col, row: Int) {
        obj := get(col, row)
        if (obj) {
            obj notify(this)
        }
    }

    get: func (col, row: Int) -> JeepObject {
        getRow(row) get(col)
    }

    getRow: func (row: Int) -> Row {
        if (rows contains?(row)) {
            rows get(row)
        } else {
            obj := Row new()
            rows put(row, obj)
            obj
        }
    }

}

Row: class {

    cols := HashMap<Int, JeepObject> new()

    init: func {
    }

    put: func (col: Int, obj: JeepObject) -> JeepObject {
        cols put(col, obj)
        obj
    }

    get: func (col: Int) -> JeepObject {
        cols get(col)
    }

    remove: func (col: Int) -> JeepObject {
        obj := cols get(col)
        if (obj) {
            cols remove(col)
            obj
        }
        obj
    }

}

JeepObject: class extends EditorObject {

    side := 64

    def: JeepDefinition

    sprite: GlGridSprite

    posi: Vec2i

    col: Int { get { posi x } }
    row: Int { get { posi y } }

    top    := false
    bottom := false
    left   := false
    right  := false

    init: func (=def, initPos: Vec2) {
        super("jeep", def name, initPos)

        path := Random choice(def images)
        sprite = GlGridSprite new(path, 4, 4)
        group add(sprite)

        updatePos()
    }

    updatePos: func {
        snap!(vec2(side, side), side)
        updatePosi()
        group pos set!(pos)
    }

    updatePosi: func {
        posi = pos getColRow(side)
    }

    notify: func (grid: SparseGrid) {
        top    = (grid get(posi x, posi y - 1) != null)
        bottom = (grid get(posi x, posi y + 1) != null)
        left   = (grid get(posi x - 1, posi y) != null)
        right  = (grid get(posi x + 1, posi y) != null)

        sprite x = leftRightToX(left, right)
        sprite y = topBottomToY(top, bottom)
    }
    
    leftRightToX: static func (left, right: Bool) -> Int {
        if (left) {
            if (right) {
                2
            } else {
                3
            }
        } else {
            if (right) {
                1
            } else {
                0
            }
        }
    }

    topBottomToY: static func (top, bottom: Bool) -> Int {
        if (top) {
            if (bottom) {
                2
            } else {
                3
            }
        } else {
            if (bottom) {
                1
            } else {
                0
            }
        }
    }

    contains?: func (hand: Vec2) -> Bool {
        false
    }

    snap!: func (gridSize: Int) {
        // fuck off
    }

    clone: func -> This {
        new(def, pos)
    }

    load: func (map: HashMap<String, DocumentNode>) {
        if (map get("top")) { // old format won't have this
            top    = map get("top") toBool()
            bottom = map get("bottom") toBool()
            left   = map get("left") toBool()
            right  = map get("right") toBool()
        }
    }

    emit: func (map: MappingNode) {
        map put("top", top toScalar())
        map put("bottom", bottom toScalar())
        map put("left", left toScalar())
        map put("right", right toScalar())
    }

}

