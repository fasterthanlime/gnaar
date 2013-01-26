
// our stuff
import gnaar/[dialogs, events, utils]

// third-party stuff
use glew
import glew

use dye
import dye/[core, input, sprite, text, math, primitives]
import math

use deadlogger
import deadlogger/[Log, Logger]

use sdl2
import sdl2/[Core, Event]

// sdk stuff
import structs/[ArrayList, Stack, List]

Widget: class extends GlDrawable {

    // can be null
    parent: Panel

    position := PositionFlavor STATIC
    width := SizeFlavor AUTO
    height := SizeFlavor AUTO
    display := DisplayFlavor INLINE

    givenPos := vec2(0, 0)
    givenSize := vec2(0, 0)

    // computed size, will be invalid if dirty
    size := vec2(0, 0)

    hovered := false
    visible := true

    // if true, need a layout before display
    dirty := false

    draw: func (dye: DyeContext) {
        // override stuff here
    }

    touch: func {
        dirty = true
    }

    layout: func {
    }

    getDepth: func -> Int {
        if (parent) {
            parent getDepth() + 1
        } else {
            0
        }
    }

    setWidth: func ~length (value: Float) {
        givenSize x = value
        setWidthFlavor(SizeFlavor LENGTH)
        touch()
    }

    setRelativeWidth: func (value: Float) {
        givenSize x = value
        setWidthFlavor(SizeFlavor PERCENTAGE)
        touch()
    }

    setWidthFlavor: func (=width) {
        touch()
    }

    setHeight: func ~length (value: Float) {
        givenSize y = value
        setHeightFlavor(SizeFlavor LENGTH)
        touch()
    }

    setRelativeHeight: func (value: Float) {
        givenSize y = value
        setHeightFlavor(SizeFlavor PERCENTAGE)
        touch()
    }

    setHeightFlavor: func (=height) {
        touch()
    }

    setSize: func (x, y: Float) {
        setWidth(x)
        setHeight(y)
    }

    setDisplayFlavor: func (=display)

    setPositionFlavor: func (=position)

    setFixedPosition: func (.givenPos) {
        setPositionFlavor(PositionFlavor FIXED)
        this givenPos set!(givenPos)
    }

    process: func (e: GEvent) {
        // You shall override this if you
        // want to react to events, good sir.
    }

    collideTree: func (needle: Vec2, cb: Func (Widget, Bool)) {
        cb(this, contains?(needle))
    }

    contains?: func (needle: Vec2) -> Bool {
        BoundingBox contains?(pos, size, needle, false)
    }

    getParentWidth: func -> Float {
        if (!parent) {
            0
        } else if (parent width == SizeFlavor AUTO) {
            parent getParentWidth()
        } else {
            parent size x
        }
    }

    getParentHeight: func -> Float {
        if (!parent) {
            0
        } else if (parent width == SizeFlavor AUTO) {
            parent getParentHeight()
        } else {
            parent size y
        }
    }

}

Panel: class extends Widget {

    logger := Log getLogger(This name)
    children := ArrayList<Widget> new()

    margin := vec2(0, 0)
    padding := vec2(0, 0)

    backgroundColorRect: GlRectangle

    init: func {
        display = DisplayFlavor BLOCK
    }

    add: func (widget: Widget) {
        children add(widget)
        widget parent = this
        touch()
    }

    collideTree: func (needle: Vec2, cb: Func (Widget, Bool)) {
        super(needle, cb)

        subNeedle := needle sub(pos)
        for (child in children) {
            child collideTree(subNeedle, cb)
        }
    }

    draw: func (dye: DyeContext) {
        if (!visible) return

        if (dirty) {
            layout()
        }

        glPushMatrix()
        glTranslatef(pos x, pos y, 0)
        if (backgroundColorRect) {
            backgroundColorRect size set!(size)
            backgroundColorRect draw(dye)
        }

        for (c in children) {
            c draw(dye)
        }
        glPopMatrix()
    }

    setBackgroundColor: func (color: Color) {
        if (!backgroundColorRect) {
            backgroundColorRect = GlRectangle new()
            backgroundColorRect center = false
        }
        backgroundColorRect color set!(color)
    }

    preLayoutSize: func {
        match width {
            case SizeFlavor LENGTH =>
                size x = givenSize x
                logger info("(%02d) Width of %s inferred to %f", getDepth(), class name, size x)
            case SizeFlavor PERCENTAGE =>
                if (!parent) {
                    Exception new("Percentage-sized width with no parent") throw()
                }

                size x = getParentWidth() * (givenSize x * 0.01)
                logger info("(%02d) Width of %s inferred to %f", getDepth(), class name, size x)
        }

        match height {
            case SizeFlavor LENGTH =>
                size y = givenSize y
                logger info("(%02d) Height of %s inferred to %f", getDepth(), class name, size y)
            case SizeFlavor PERCENTAGE =>
                if (!parent) {
                    Exception new("Percentage-sized height with no parent") throw()
                }

                size y = getParentHeight() * (givenSize y * 0.01)
                logger info("(%02d) Height of %s inferred to %f", getDepth(), class name, size y)
        }
    }

    postLayoutSize: func {
        match width {
            case SizeFlavor AUTO =>
                // TODO: this is terribad
                size x = 0
                first := true
                for (child in children) {
                    if (first) {
                        first = false
                    } else {
                        size x += padding x
                    }
                    size x += child size x
                }
                logger info("(%02d) Width of %s inferred to %f", getDepth(), class name, size x)
        }

        match height {
            case SizeFlavor AUTO =>
                // TODO: this is terribad
                size y = 0
                for (child in children) {
                    logger info("size y = %.2f, child size y = %.2f", size y, child size y)
                    if (child size y > size y) {
                        size y = child size y
                    }
                }
                logger info("(%02d) Height of %s inferred to %f", getDepth(), class name, size y)
        }

    }

    layout: func {
        logger info("(%02d) Packing %s - %p", getDepth(), class name, this)
        preLayoutSize()
        for (child in children) {
            child layout()
        }

        baseX := margin x
        baseY := size y - margin y

        (x, y) := (baseX, baseY)

        previousChild : Widget = null
        currentDisplay := DisplayFlavor INLINE

        newlined := true

        for (child in children) {
            if (child display == DisplayFlavor BLOCK && !newlined) {
                x = baseX
                newlined = true

                if (previousChild) {
                    y -= (previousChild size y + padding y)
                }
            }

            match (child position) {
                // ----------------------------------
                case PositionFlavor CENTER =>
                    halfChildSize := child size mul(0.5)

                    logger info("centering, halfSize = %s, halfChildSize = %s",
                        size mul(0.5) _, halfChildSize _)

                    newpos := size mul(0.5) sub(halfChildSize)
                    logger info(" - center, (%.2f, %.2f)", newpos x, newpos y)
                    child pos set!(newpos)

                // ----------------------------------
                case PositionFlavor STATIC =>
                    if (child display == DisplayFlavor BLOCK) {
                        y -= child size y
                    }

                    logger info(" - static, (%.2f, %.2f)", x, y)
                    child pos set!(x, y)

                // ----------------------------------
                case PositionFlavor FIXED =>
                    child pos set!(child givenPos)
            }

            if (child display == DisplayFlavor BLOCK) {
                newlined = true
                x = baseX
                y -= padding y
            } else {
                newlined = false
                x += (child size x + padding x)
            }

            previousChild = child
        }
        postLayoutSize()

        dirty = false
    }

}

Icon: class extends Widget {

    _sprite: GlSprite

    init: func (path: String) {
        _sprite = GlSprite new(path)
        _sprite center = false
        layout()
    }

    draw: func (dye: DyeContext) {
        _sprite pos set!(pos)
        _sprite render(dye)
    }

    layout: func {
        size set!(_sprite size)
    }

}

Label: class extends Widget {

    _text: GlText

    color := Color new(220, 220, 220)

    init: func (value: String, fontSize := 30) {
        _text = GlText new(Frame fontPath, value, fontSize)
        layout()
    }

    setValue: func (value: String) {
        _text value = value
        layout()
        if (parent) {
            parent touch()
        }
    }

    setValue: func ~var (value: String, args: ...) {
        setValue(value format(args))
    }

    draw: func (dye: DyeContext) {
        _text color set!(color)
        _text pos set!(pos)
        _text render(dye)
    }

    layout: func {
        size set!(_text size)
    }

}

Frame: class extends Panel {

    fontPath := static "assets/ttf/font.ttf"
    logger := static Log getLogger(This name)

    scene: Scene
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
    init: func (=scene) {
        super()

        input = scene input
        setSize(scene size x, scene size y)

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

        // Everything after this point doesn't happen when we have dialogs
        if (!root?) return

        collideTree(mousePos, |widget, touching| {
            if (touching) {
                if (!widget hovered) {
                    widget hovered = true
                    widget process(MouseLeaveEvent new(mousePos))
                }
            } else {
                if (widget hovered) {
                    widget hovered = false
                    widget process(MouseEnterEvent new(mousePos))
                }
            }
        })
    }

    initEvents: func {
        input onMousePress(MouseButton LEFT, ||
            dragStart = true
            dragPath = vec2(0, 0)
            dragging = false
        )

        input onMouseRelease(MouseButton LEFT, ||
            dragStart = false
            if (dragging) {
                dragging = false
                queue push(DragStopEvent new())
            } else {
                clickPos := input getMousePos()
                clickEvent := ClickEvent new(MouseButton LEFT, clickPos)

                logger info("Click at %s", clickPos _)
                collideTree(clickPos, |widget, touching|
                    if (touching) {
                        widget process(clickEvent)
                    }
                )

                queue push(clickEvent)
            }
        )

        input onMouseRelease(MouseButton MIDDLE, ||
            queue push(ClickEvent new(MouseButton MIDDLE, input getMousePos()))
        )

        input onMouseRelease(MouseButton RIGHT, ||
            queue push(ClickEvent new(MouseButton RIGHT, input getMousePos()))
        )
    }

    draw: func (dye: DyeContext) {
        // draw children
        super(dye)

        // then draw rest: dialogs, etc.
        group draw(dye)
    }

}
                
PositionFlavor: enum {
    STATIC
    FIXED
    CENTER
}

SizeFlavor: enum {
    AUTO
    LENGTH /* e.g. 12px */
    PERCENTAGE /* e.g. 33% */

    toString: func -> String {
        match this {
            case This AUTO => "auto"
            case This LENGTH => "length"
            case This PERCENTAGE => "percentage"
        }
    }
}

DisplayFlavor: enum {
    INLINE
    BLOCK
    INLINEBLOCK
}

