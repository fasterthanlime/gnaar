
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
    ticks := 1
    path: String
    currentAnim: String

    playing: Bool { get {
        group playing
    } }

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

        grid := GlGridSprite new(source, numFrames, numRows)
        anim := GlAnim new(grid)
        anim frameDuration = frameDuration
        anim
    }

    play: func (name: String, looping := true) {
        currentAnim = name
        group play(name, looping)
    }

    update: func -> Bool {
        group update(ticks)

        true
    }

    currentFrame: func -> Int {
        group currentFrame()
    }

    frameOffset: func (offset: Int) {
        group frameOffset(offset)
    }

}

