
// third-party stuff
use dye
import dye/[sprite, anim]

use yaml
import yaml/[Document]

// our stuff
import gnaar/[objects, utils]

/**
 * A deck is a set of animations you can play in any order,
 * repeat, etc.
 */

Deck: class extends GnObject {

    group: GlAnimSet { get set }

    init: func (path: String) {
        group = GlAnimSet new()

        doc := parseYaml(path)
        if (!doc) {
            Exception new("AnimSet definition not found: %s" format(path)) throw()
        }

        map := doc toMap() 
        map each(|k, v|
            group put(k, loadAnim(k, v))
        )
        group play("idle") // default, do what you want cause a pirate is free.
    }

    loadAnim: func (name: String, node: DocumentNode) -> GlAnim {
        map := node toMap()

        source: String = null
        numRows := 1
        numFrames := 1
        frameDuration := 4

        map each(|k, v|
            match k {
                case "source"        => source        = v toScalar()
                case "numRows"       => numRows       = v toInt()
                case "numFrames"     => numFrames     = v toInt()
                case "frameDuration" => frameDuration = v toInt()
            }
        )

        if (!source) {
            Exception new("Missing source for animation")
        }
        grid := GlGridSprite new(source, numFrames, numRows)
        anim := GlAnim new(grid)
        anim frameDuration = frameDuration
        anim
    }

    update: func -> Bool {
        group update()

        true
    }

}

