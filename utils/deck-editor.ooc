
// third-party libs
use dye
import dye/[core, input, math, text]

use gnaar
import gnaar/[deck]

use zombieconfig

use sdl2
import sdl2/Core

// sdk
import structs/ArrayList
import io/File

// our stuff

main: func (cmd: ArrayList<String>) {
    config := ZombieConfig new("config/deckedit.conf", |base|
        base("home", ".")
        base("font", "assets/ttf/font.ttf")
    )
    args := config handleCommandLine(cmd)

    app := App new(config, args)
    app run()
}

App: class {

    dye: DyeContext
    running := true

    paused := false

    group: GlGroup
    deck: Deck

    frameLabel: GlText

    file, anim: String

    config: ZombieConfig
    home, font: String

    init: func (=config, args: ArrayList<String>) {
        home = config["home"]
        font = config["font"]

        dye = DyeContext new(1280, 720, "Deck Editor [Gnaar]", false, 1280, 720)
        dye setClearColor(Color white())

        group = GlGroup new()
        group pos set!(dye center)
        dye add(group)

        frameLabel = GlText new(font, "Frame: ?", 28)
        frameLabel color set!(0, 0, 0)
        frameLabel pos set!(30, 30)
        dye add(frameLabel)

        if (args empty?()) {
            "Usage: deck-editor FILE [ANIM]" println()
            dye quit()
            exit(1)
        }

        fileName := args get(0)
        if (!fileName endsWith?(".yml")) {
            fileName = fileName + ".yml"
        }

        file = File new(home, fileName) path

        if (args size >= 2) {
            anim = args get(1)
        }

        reload()

        setupEvents()
    }

    setupEvents: func {
        dye input onKeyPress(|kp|
            match (kp scancode) {
                case Keys ESC =>
                    running = false
                case Keys F5 =>
                    reload()
                case Keys SPACE =>
                    paused = !paused
                case Keys LEFT =>
                    deck frameOffset(-1)
                case Keys RIGHT =>
                    deck frameOffset(1)
            }
        )
    }

    reload: func {
        if (deck) {
            group remove(deck group)
            deck = null
        }

        deck = Deck new(file)
        if (anim) {
            deck play(anim)
        }
        group add(deck group)
    }

    run: func {
        while (running) {
            SDL delay(16)
            if (!paused) {
                deck update()
            }
            frameLabel value = "Frame: %d" format(deck currentFrame())

            dye input _poll()
            dye render()
        }

        dye quit()
    }

}

