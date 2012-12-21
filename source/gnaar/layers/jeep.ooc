
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

    init: func (.ui, .name) {
        super(ui, name)

        addFactory(JeepFactory new(this))
    }

    insert: func {
        ui push(InputDialog new(ui, "Enter jeep name", |name|
            spawn("jeep", name, ui handPos())
        ))
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

JeepObject: class extends ImageObject {

    def: JeepDefinition

    init: func (=def, initPos: Vec2) {
        super("jeep", def name, def images get(0))
    }

    clone: func -> This {
        c := new(def, pos)
        c pos set!(pos)
        c
    }

}

