
// third-party libs
use dye
import dye/[core, input, math]

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
    )
    args := config handleCommandLine(cmd)

    app := App new(config, args)
    app run()
}

App: class {

    dye: DyeContext
    running := true

    group: GlGroup
    deck: Deck

    file, anim: String
    home: String

    init: func (config: ZombieConfig, args: ArrayList<String>) {
        dye = DyeContext new(1280, 720, "Deck Editor [Gnaar]", false, 1280, 720)
        dye setClearColor(Color white())

        group = GlGroup new()
        group pos set!(dye center)
        dye add(group)

        home = config["home"]

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
            deck update()

            dye input _poll()
            dye render()
        }

        dye quit()
    }

}

