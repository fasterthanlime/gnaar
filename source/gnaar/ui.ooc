
// libs
use dye
import dye/[core, input, sprite, font, math, primitives]

import math
import structs/[ArrayList, Stack, List]

use deadlogger
import deadlogger/[Log, Logger]

use sdl2
import sdl2/[Core, Event]

// internal
import gnaar/[dialogs, events]

Widget: class extends GlDrawable {

    pos := vec2(0, 0)
    size := vec2(0, 0)

    draw: func (dye: DyeContext) {
        // override stuff here
    }

}

Panel: class extends Widget {

    children := ArrayList<Widget> new()

    add: func (widget: Widget) {
        children add(widget)
    }

}

Label: class extends Widget {

    _text: GlText

    color := Color black()

    init: func (value: String) {
        _text = GlText new(Frame fontPath, value)
    }

    setValue: func (value: String) {
        _text value = value
    }

    setValue: func ~var (value: String, args: ...) {
        _text value = value format(args)
    }

}

Frame: class extends Panel {

    fontPath := static "assets/ttf/font.ttf"
    logger := static Log getLogger(This name)

    dye: DyeContext
    input: Input

    queue := EventQueue new()

    // mouse stuff
    prevMousePos := vec2(0, 0)
    delta := vec2(0, 0)

    // drag stuff
    dragging := false
    dragStart := false
    dragThreshold := 2.0
    dragPath := vec2(0, 0)
    
    // Dye groups
    group: GlGroup { get set }
    hudGroup: GlGroup
    dialogGroup: GlGroup
    
    // Dialogs
    dialogStack := Stack<Dialog> new()

    // Constructor
    init: func (=dye) {
        input = dye input
        size set!(dye width, dye height)

        group = GlGroup new()

        hudGroup = GlGroup new()
        group add(hudGroup)

        dialogGroup = GlGroup new()
        group add(dialogGroup)

        initEvents()
        prevMousePos set!(input getMousePos())
    }

    push: func (dialog: Dialog) {
        dialogStack push(dialog)
    }

    pop: func (dialog: Dialog) {
        if (root?) return
        dialogStack pop()
    }

    root?: Bool { get { dialogStack empty?() } }

    update: func {
        updateMouse()

        if (!root?) {
            dialog := dialogStack peek()
            dialog update()
        }

        queue dispatch()
    }

    updateMouse: func {
        mousePos := input getMousePos()
        delta = mousePos sub(prevMousePos)

        if (dragging) {
            queue push(DragEvent new(delta))
        }

        if (dragStart) {
            dragPath add!(delta)

            if (dragPath norm() >= dragThreshold) {
                // Yup, it's a drag
                dragStart = false
                dragging = true

                queue push(DragStartEvent new(mousePos sub(dragPath)))
                queue push(DragEvent new(dragPath))
            }
        }

        prevMousePos set!(mousePos)
    }

    initEvents: func {
        input onMousePress(Buttons LEFT, ||
            dragStart = true
            dragPath = vec2(0, 0)
            dragging = false
        )

        input onMouseRelease(Buttons LEFT, ||
            dragStart = false
            if (dragging) {
                dragging = false
                queue push(DragStopEvent new())
            } else {
                queue push(ClickEvent new(Buttons LEFT, input getMousePos()))
            }
        )

        input onMouseRelease(Buttons MIDDLE, ||
            queue push(ClickEvent new(Buttons MIDDLE, input getMousePos()))
        )

        input onMouseRelease(Buttons RIGHT, ||
            queue push(ClickEvent new(Buttons RIGHT, input getMousePos()))
        )
    }
}
                
