
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
import gnaar/[ui, loader, saver, dialogs, objects, utils]

PropFactory: class extends ObjectFactory {

    init: func (.layer) {
        super(layer, "prop")
    }

    spawn: func (name: String, pos: Vec2) -> GnObject {
        layer add(PropObject new(name, pos))
    }

}

PropObject: class extends ImageObject {

    init: func (.name, initPos: Vec2) {
        super("prop", name, initPos, "assets/png/%s.png" format(name))
    }

    clone: func -> This {
        new(name, pos)
    }

}

PropLayer: class extends DragLayer {

    init: func (.ui, .name) {
        super(ui, name)

        addFactory(PropFactory new(this))
    }

    insert: func {
        ui push(InputDialog new(ui, "Enter prop name", |name|
            spawn("prop", name, ui handPos())
        ))
    }

}

