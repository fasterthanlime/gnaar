
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

    init: func (config: ZombieConfig) {
        dye = DyeContext new(1920, 1080, "Deck Editor [Gnaar]", false, 1280, 720)
        dye setClearColor(Color white())

        setupEvents()
    }

    setupEvents: func {
        dye input onKeyPress(Keys ESC, ||
            running = false
        )
    }

    run: func {
        while (running) {
            SDL delay(10)

            dye input _poll()
            dye render()
        }

        dye quit()
    }

}

