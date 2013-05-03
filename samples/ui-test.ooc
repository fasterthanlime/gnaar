
use dye
import dye/[core, primitives, app]

use gnaar
import gnaar/[ui]

main: func (argc: Int, argv: CString*) {
    UITest new() run(1)
}

UITest: class extends App {

    frame: Frame
    panel1: Panel

    init: func {
        super("gnaar ui test")
    }

    setup: func {
        scene := dye currentScene

        // frame is green
        frame = Frame new(scene)
        frame setBackgroundColor(Color new(35, 120, 35))

        // panel1 is red
        panel1 = Panel new()
        panel1 setPositionFlavor(PositionFlavor CENTER)
        panel1 setRelativeWidth(50)
        panel1 setRelativeHeight(50)
        panel1 setDisplayFlavor(DisplayFlavor INLINE)
        panel1 setBackgroundColor(Color new(120, 35, 35))
        frame add(panel1)
    }

    displayInfo: func {
        "size    = %s | %s" printfln(
            frame  backgroundColorRect size _,
            panel1 backgroundColorRect size _
        )

        "position = %s | %s" printfln(
            frame  backgroundColorRect pos _,
            panel1 backgroundColorRect pos _
        )
    }

    update: func {
        displayInfo()
    }

}

