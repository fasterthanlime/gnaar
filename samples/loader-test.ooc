
use dye
import dye/[core, primitives, app]

use gnaar
import gnaar/[ui, ui-loader]

main: func (argc: Int, argv: CString*) {
    path := match {
        case argc > 1 => argv[1] toString()
        case => "assets/layout.yml"
    }

    UITest new(path) run(1)
}

UITest: class extends App {

    frame: Frame

    path: String

    init: func (=path) {
        super("gnaar ui loader test")
    }

    setup: func {
        scene := dye currentScene

        // frame is green
        frame = Frame new(scene) 

        loader := UILoader new(UIFactory new())
        loader load(frame, path)
    }

    update: func {
        // nothang
    }

}

