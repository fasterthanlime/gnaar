
import gnaar/[objects]

import structs/ArrayList

import dye/[core, math]

use yaml
import yaml/[Parser, Document]

use deadlogger
import deadlogger/[Log, Logger]

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
        layer := level getLayer(key)
        
        list each(|o|
            parseObject(layer, o) 
        )
    }

    parseObject: func (l: LayerBase, d: DocumentNode) {
        map := d toMap()

        type := map get("type") toScalar()
        name := map get("name") toScalar()
        pos := map get("pos") toVec2()

        match type {
            case "prop" => l spawnProp(name, pos)
            case "item" => l spawnItem(name, pos)
            case "tile" => l spawnTile(name, pos)
        }
    }

}

