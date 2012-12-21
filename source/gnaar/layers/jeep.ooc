
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
import gnaar/[ui, loader, saver, dialogs, objects]

JeepFactory: class extends ObjectFactory {

    init: func (.layer) {
        super(layer, "jeep")
    }

    spawn: func (name: String, pos: Vec2) -> GnObject {
        layer add(JeepObject new(name, pos))
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

}

JeepObject: class extends ImageObject {

    init: func (=name, initPos: Vec2) {
        super("prop", name, "assets/png/%.png" format(name))
    }

    clone: func -> This {
        c := new(name, pos)
        c pos set!(pos)
        c
    }

    getFamily: func -> String {
        "jeep"
    }

}

