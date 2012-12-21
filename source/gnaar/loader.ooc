
/* libs */
import structs/ArrayList

import dye/[core, math]

use yaml
import yaml/[Parser, Document]

use deadlogger
import deadlogger/[Log, Logger]

/* internal */
use gnaar
import gnaar/[objects, utils]

LevelLoader: class {

    logger := static Log getLogger("level-loader")

    name: String
    level: LevelBase

    init: func (=name, =level) {
        level reset()

        parse()
    }

    parse: func {
        parser := YAMLParser new()
        path := "assets/levels/%s.yml" format(name)
        logger info("Loading level %s" format(path))
        parser setInputFile(path)

        doc := Document new()
        parser parseAll(doc)

        dict := doc getRootNode() toMap()
        dict each(|k, v|
            match k {
                case "layers" =>
                    parseLayers(v)
            }
        )
    }

    parseLayers: func (d: DocumentNode) {
        map := d toMap()

        map each(|k, v|
            parseLayer(k, v)
        )
    }

    parseLayer: func (key: String, d: DocumentNode) {
        if (!d instanceOf?(SequenceNode)) {
            // empty layer
            return
        }

        list := d toList()
        layer := level getLayerByName(key)
        
        list each(|o|
            parseObject(layer, o) 
        )
    }

    parseObject: func (layer: LayerBase, node: DocumentNode) {
        map := node toMap()

        family := map get("family") toScalar()
        name := map get("name") toScalar()
        pos := map get("pos") toVec2()

        layer spawn(family, name, pos)
    }

}

