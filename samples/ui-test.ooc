
use dye
import dye/[core, loop, primitives]

use gnaar
import gnaar/[ui]

use deadlogger
import deadlogger/[Log, Logger, Formatter, Handler, Filter, Level]

main: func {
    console := StdoutHandler new()
    console setFormatter(NiceFormatter new())
    Log root attachHandler(console)

    dye := DyeContext new(800, 600, "gnaar ui demo")

    quit := func {
        dye quit()
        exit(0)
    }

    dye input onExit(||
        quit()
    )

    scene := dye currentScene

    // frame is green
    frame := Frame new(scene)
    frame setBackgroundColor(Color new(35, 120, 35))

    // panel1 is red
    panel1 := Panel new()
    //panel1 setPositionFlavor(PositionFlavor CENTER)
    panel1 setRelativeWidth(50)
    panel1 setRelativeHeight(50)
    panel1 setDisplayFlavor(DisplayFlavor INLINE)
    panel1 setBackgroundColor(Color new(120, 35, 35))
    frame add(panel1)

    loop := FixedLoop new(dye, 3)

    loop run(||
        // not much to do, heh.

        "size    = %s | %s" printfln(
            frame  backgroundColorRect size _,
            panel1 backgroundColorRect size _
        )

        "position = %s | %s" printfln(
            frame  backgroundColorRect pos _,
            panel1 backgroundColorRect pos _
        )
    )
}

