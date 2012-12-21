
/* libs */
import structs/ArrayList

import dye/[core, math]

use yaml
import yaml/[Emitter, Document]

use deadlogger
import deadlogger/[Log, Logger]

/* internal */
use gnaar
import gnaar/[utils, ui, objects]

LevelSaver: class {

    logger := static Log getLogger("level-saver")

    name: String
    level: GnUI

    init: func (=name, =level) {
        emit()
    }

    emit: func {
        doc := Document new()
        map := MappingNode new()
        doc insert(map)

        layerMap := MappingNode new()
        for (layer in level layers) {
            layerMap put(layer name, emitLayer(layer))
        }
        map put("layers", layerMap)

        emitter := YAMLEmitter new()
        path := "assets/levels/%s.yml" format(name)
        emitter setOutputFile(path)

        emitter streamStart()
        doc emit(emitter)
        emitter streamEnd()

        emitter flush()
        emitter delete()
        logger info("Saved level %s" format(path))
    }

    emitLayer: func (layer: EditorLayer) -> SequenceNode {
        seq := SequenceNode new()

        layer eachObject(|object|
            objMap := emitObject(object)
            if (objMap) {
                seq add(objMap)
            }
        )

        seq
    }

    emitObject: func (object: EditorObject) -> MappingNode {
        map := MappingNode new()
        map put("family", object family toScalar())
        map put("name", object name toScalar())
        map put("pos", object pos toSeq())
        object emit(map)
        map
    }

}
