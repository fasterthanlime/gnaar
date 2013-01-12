
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

// our stuff

main: func (args: ArrayList<String>) {
    config := ZombieConfig new("config/deckedit.conf")
    config handleCommandLine(args)

    app := App new(config)
    app run()
}

App: class {

    dye: DyeContext
    running := true

    deck: Deck

    init: func (config: ZombieConfig) {
        dye = DyeContext new(1920, 1080, "Deck Editor [Gnaar]", false, 1280, 720)
        dye setClearColor(Color white())

        file := config["file"]
        if (!file) {
            "Usage: deck-editor file=FILE" println()
            running = false
        }
        deck = Deck new(file)
        deck group pos set!(dye center)
        dye add(deck group)

        setupEvents()
    }

    setupEvents: func {
        dye input onKeyPress(Keys ESC, ||
            running = false
        )
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

