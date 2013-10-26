
// third-party stuff
use dye
import dye/[sprite, anim]

use yaml
import yaml/[Document]

// our stuff
import gnaar/[objects, utils, yaml]

/**
 * A deck is a set of animations you can play in any order,
 * repeat, etc.
 */

Deck: class extends GnObject {

    group: GlAnimSet { get set }
    path: String

    init: func (=path) {
        group = GlAnimSet new()

        doc := parseYaml(path)
        if (!doc) {
            Exception new("AnimSet definition not found: %s" format(path)) throw()
        }

        map := doc toMap() 
        map each(|k, v|
            group put(k, loadAnim(k, v))
        )
        play("idle") // default, do what you want cause a pirate is free.
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
            raise("Missing source for animation %s in file %s")
        }
        "Loaded anim from %s, %d rows, %d frames, %d frameDuration" printfln(
            source, numRows, numFrames, frameDuration)

        grid := GlGridSprite new(source, numFrames, numRows)
        anim := GlAnim new(grid)
        anim frameDuration = frameDuration
        anim
    }

    play: func (name: String) {
        group play(name)
    }

    update: func -> Bool {
        group update()

        true
    }

    currentFrame: func -> Int {
        group currentFrame()
    }

    frameOffset: func (offset: Int) {
        group frameOffset(offset)
    }

}

