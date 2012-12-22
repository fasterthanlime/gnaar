
use dye
import dye/[core, input, sprite, font, primitives, math]

import gnaar/[ui, utils]

Dialog: class {

    ui: GnUI
    input: Input
    group: GlGroup
    color := Color new(15, 15, 15)

    init: func (=ui) {
        group = GlGroup new()
        input = ui input sub()
        ui dialogGroup add(group)
    }

    update: func {
    }

    destroy: func {
        ui dialogGroup remove(group)
        input nuke()
        ui pop(this)
    }

}

InputDialog: class extends Dialog {
    
    prompt: String
    text, promptText: GlText

    cb: Func (String)

    initialized := false

    init: func (=ui, =prompt, =cb) {
        super(ui)

        bgRect := GlRectangle new()
        bgRect size set!(300, 60)
        bgRect color = color
        group add(bgRect)

        rect := GlRectangle new()
        rect size set!(300, 60)
        rect filled = false
        rect color = color lighten(0.1)
        group add(rect)

        promptText = GlText new(GnUI fontPath, "> " + prompt)
        promptText color = color lighten(0.1)
        promptText pos set!(- rect size x / 2 + 10, -10)
        group add(promptText)

        text = GlText new(GnUI fontPath, "")
        text color = color lighten(0.03)
        text pos set!(- rect size x / 2 + 10, 15)
        group add(text)

        group center!(ui dye)
    }

    update: func {
        if (initialized) return

        cb := this cb // silly workaround..
        input onKeyPress(|kev|
            if (kev code == Keys ESC) {
                destroy()
            } if (kev code == Keys ENTER) {
                destroy()
                cb(text value)
            } else if (kev code == Keys BACKSPACE) {
                if (text value size > 0) {
                    text value = text value[0..-2]
                }
            } else if (isPrintable(kev unicode)) {
                text value = "%s%c" format(text value, kev unicode as Char)
            }
        )
        initialized = true
    }

}

AlertDialog: class extends Dialog {
    
    text: GlText

    cb: Func

    initialized := false

    init: func ~nocb (.ui, message: String) {
        init(ui, message, || noop := true)
    }

    init: func (=ui, message: String, =cb) {
        super(ui)

        bgRect := GlRectangle new()
        bgRect size set!(300, 40)
        bgRect color = color
        group add(bgRect)

        rect := GlRectangle new()
        rect size set!(300, 40)
        rect filled = false
        rect color = color lighten(0.1)
        group add(rect)

        text = GlText new(GnUI fontPath, message)
        text color = color lighten(0.03)
        text pos set!(- rect size x / 2 + 10, 0)
        group add(text)

        group center!(ui dye)
    }

    update: func {
        if (initialized) return

        cb := this cb // silly workaround..
        input onKeyPress(|kev|
            destroy()
            cb()
        )
        initialized = true
    }

}
