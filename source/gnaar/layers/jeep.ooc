
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

use yaml
import yaml/[Parser, Document]

/* internal */
import gnaar/[ui, loader, saver, dialogs, objects, utils]

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

    grid := SparseGrid new()

    init: func (.ui, .name) {
        super(ui, name)

        addFactory(JeepFactory new(this))
    }

    insert: func {
        ui push(InputDialog new(ui, "Enter jeep name", |name|
            spawn("jeep", name, ui handPos())
        ))
    }

    add: func (object: EditorObject) -> EditorObject {
        match (object) {
            case jo: JeepObject =>
                object layer = this
                group add(object group)
                grid put(jo row, jo col, jo)
                object
            case =>
                logger warn("Can not add %s to %s" format(object class name, This name))
                null
        }
    }

    remove: func (object: EditorObject) {
        match (object) {
            case jo: JeepObject =>
                object layer = null
                group remove(object group)
                grid remove(jo row, jo col)
                object
            case =>
                logger warn("Can not add %s to %s" format(object class name, This name))
                null
        }
    }

    update: func {
        // nothing to do here
    }

    destroy: func {
        eachObject(|object| object destroy())
        ui layerGroup remove(group)
        ui layers remove(this)
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
        cols remove(col)
        obj
    }

}

JeepObject: class extends EditorObject {

    side := 32

    def: JeepDefinition

    sprite: GlGridSprite

    col: Int { get { pos x / side } }
    row: Int { get { pos y / side } }

    init: func (=def, initPos: Vec2) {
        super("jeep", def name, initPos)

        path := def images get(0)
        sprite = GlGridSprite new(path, 4, 4)
        group add(sprite)
    }

    contains?: func (hand: Vec2) -> Bool {
        contains?(sprite size, hand)
    }

    snap!: func (gridSize: Int) {
        snap!(sprite size, gridSize)
    }

    clone: func -> This {
        c := new(def, pos)
        c pos set!(pos)
        c
    }

}

