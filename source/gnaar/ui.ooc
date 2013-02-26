
// our stuff
import gnaar/[dialogs, events, utils]

// third-party stuff
use dye
import dye/[core, input, sprite, text, math, primitives]

use deadlogger
import deadlogger/[Log, Logger]

use sdl2
import sdl2/[Core, Event, OpenGL]

use yaml
import yaml/[Document]

// sdk stuff
import structs/[ArrayList, Stack, List, HashMap]
import math

Widget: class extends GlDrawable {

    // can be null
    id := ""

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

    // if true, need a layout before display
    dirty := false

    draw: func (dye: DyeContext, modelView: Matrix4) {
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

    absorb: func (props: HashMap<String, DocumentNode>) {
        props each(|k, v|
            match k {
                case "width" =>
                    parseSize(v toScalar(), |flavor, value|
                        width = flavor
                        givenSize x = value
                    )

                case "height" =>
                    parseSize(v toScalar(), |flavor, value|
                        height = flavor
                        givenSize y = value
                    )

                case "position" =>
                    position = parsePosition(v toScalar())

                case "display" =>
                    display = parseDisplay(v toScalar())
            }
        )
    }

    parseSize: func (value: String, f: Func (SizeFlavor, Float)) {
        if (value == "auto") {
            f(SizeFlavor AUTO, 0)
        } else if (value endsWith?("%")) {
            f(SizeFlavor PERCENTAGE, value trim("%") toInt())
        } else {
            f(SizeFlavor LENGTH, value toInt())
        }
    }

    parsePosition: func (value: String) -> PositionFlavor {
        match value {
            case "static" => PositionFlavor STATIC
            case "fixed"  => PositionFlavor FIXED
            case "center" => PositionFlavor CENTER
        }
    }

    parseDisplay: func (value: String) -> DisplayFlavor {
        match value {
            case "inline"       => DisplayFlavor INLINE
            case "block"        => DisplayFlavor BLOCK
            case "inline-block" => DisplayFlavor INLINEBLOCK
        }
    }

    parseColor: func (value: DocumentNode) -> Color {
        values := value toList() map(|v| v toInt())
        Color new(values get(0), values get(1), values get(2))
    }

    bubbleAction: func (action: Action) {
        if (parent) {
            parent bubbleAction(action)
        }
    }

    find: func (needle: String) -> Widget {
        if (id == needle) {
            return this
        }

        null
    }

    find: func ~withType <T> (needle: String, T: Class) -> T {
        result := find(needle)

        if (result && result instanceOf?(T)) {
            return result
        }

        null
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

    draw: func (dye: DyeContext, modelView: Matrix4) {
        if (!visible) return

        if (dirty) {
            layout()
        }

        glPushMatrix()
        glTranslatef(pos x, pos y, 0)
        if (backgroundColorRect) {
            backgroundColorRect size set!(size)
            backgroundColorRect draw(dye, modelView)
        }

        for (c in children) {
            c draw(dye, modelView)
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
            case SizeFlavor PERCENTAGE =>
                if (!parent) {
                    Exception new("Percentage-sized width with no parent") throw()
                }

                size x = getParentWidth() * (givenSize x * 0.01)
        }

        match height {
            case SizeFlavor LENGTH =>
                size y = givenSize y
            case SizeFlavor PERCENTAGE =>
                if (!parent) {
                    Exception new("Percentage-sized height with no parent") throw()
                }

                size y = getParentHeight() * (givenSize y * 0.01)
        }
    }

    postLayoutSize: func {
        match width {
            case SizeFlavor AUTO =>
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
                logger debug("(%02d) Width of %s inferred to %f",
                        getDepth(), class name, size x)
        }

        match height {
            case SizeFlavor AUTO =>
                size y = 0
                for (child in children) {
                    if (child size y > size y) {
                        size y = child size y
                    }
                }
                logger debug("(%02d) Height of %s inferred to %f",
                        getDepth(), class name, size y)
        }

    }

    layout: func {
        logger debug("(%02d) Packing %s - %p", getDepth(), class name, this)
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
                    newpos := size mul(0.5) sub(halfChildSize)
                    child pos set!(newpos)

                // ----------------------------------
                case PositionFlavor STATIC =>
                    if (child display == DisplayFlavor BLOCK) {
                        y -= child size y
                    }
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

    absorb: func (props: HashMap<String, DocumentNode>) {
        super(props)

        props each(|k, v|
            match k {
                case "margin" =>
                    margin set!(v toVec2())

                case "padding" =>
                    padding set!(v toVec2())

                case "background" =>
                    setBackgroundColor(parseColor(v))
            }
        )
    }

    find: func (needle: String) -> Widget {
        result := super(needle)
        if (result) {
            return result
        }

        for (child in children) {
            result = child find(needle)
            if (result) {
                return result
            }
        }

        null
    }

}

Icon: class extends Widget {

    _sprite: GlSprite

    init: func { }

    init: func ~withSource (src: String) {
        this src = src
    }

    src: String {
        get {}
        set (=src) {
            _sprite = GlSprite new(src)
            _sprite center = false
            layout()
        }
    }

    draw: func (dye: DyeContext, modelView: Matrix4) {
        if (!_sprite) { return }
        _sprite pos set!(pos)
        _sprite render(dye, modelView)
    }

    layout: func {
        if (!_sprite) { return }
        size set!(_sprite size)
    }

    absorb: func (props: HashMap<String, DocumentNode>) {
        super(props)

        props each(|k, v|
            match k {
                case "src" =>
                    src = v toScalar()
            }
        )
    }

}

Label: class extends Widget {

    _text: GlText

    color := Color new(220, 220, 220)

    init: func (value := "", fontSize := 30) {
        this fontPath = Frame fontPath
        this value = value
        this fontSize = fontSize

        _text = GlText new(fontPath, value, fontSize)

        layout()
    }

    fontSize: Int {
        get
        set (_fontSize) {
            fontSize = _fontSize

            if (!_text) { return }

            _reload()
        }
    }

    fontPath: String {
        get
        set (_fontPath) {
            fontPath = _fontPath

            if (!_text) { return }

            _reload()
        }
    }

    value: String {
        get
        set (_value) {
            value = _value

            if (!_text) { return }

            _text value = value
            layout()
            if (parent) {
                parent touch()
            }
        }
    }

    setValue: func ~var (value: String, args: ...) {
        this value = value format(args)
    }

    _reload: func {
        _text = GlText new(fontPath, value, fontSize)
    }

    draw: func (dye: DyeContext, modelView: Matrix4) {
        _text color set!(color)
        _text pos set!(pos)
        _text render(dye, modelView)
    }

    layout: func {
        size set!(_text size)
    }

    absorb: func (props: HashMap<String, DocumentNode>) {
        super(props)

        props each(|k, v|
            match k {
                case "value" =>
                    value = v toScalar()

                case "font-size" =>
                    fontSize = v toInt()
            }
        )
    }

}

Button: class extends Label {

    callback: ActionCallback
    baseColor := Color new(220, 220, 220)

    init: super func

    draw: func (dye: DyeContext, modelView: Matrix4) {
        if (hovered) {
            color set!(baseColor)
        } else {
            color set!(baseColor mul(0.7))
        }

        super(dye, modelView)
    }

    process: func (e: GEvent) {
        match e {
            case ce: ClickEvent =>
                bubbleAction(Action new(id, this))
        }
    }

}


Frame: class extends Panel {

    fontPath := static "assets/ttf/font.ttf"

    // FIXME: should rock allow redefinitions that are static?
    //logger := static Log getLogger(This name)

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

        scene add(this)
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
        input onMousePress(MouseButton LEFT, |ev|
            dragStart = true
            dragPath = vec2(0, 0)
            dragging = false
        )

        input onMouseRelease(MouseButton LEFT, |ev|
            dragStart = false
            if (dragging) {
                dragging = false
                queue push(DragStopEvent new())
            } else {
                clickPos := input getMousePos()
                clickEvent := ClickEvent new(MouseButton LEFT, clickPos)

                collideTree(clickPos, |widget, touching|
                    if (touching) {
                        widget process(clickEvent)
                    }
                )

                queue push(clickEvent)
            }
        )

        input onMouseRelease(MouseButton MIDDLE, |ev|
            queue push(ClickEvent new(MouseButton MIDDLE, input getMousePos()))
        )

        input onMouseRelease(MouseButton RIGHT, |ev|
            queue push(ClickEvent new(MouseButton RIGHT, input getMousePos()))
        )
    }

    draw: func (dye: DyeContext, modelView: Matrix4) {
        // draw children
        super(dye, modelView)

        // then draw rest: dialogs, etc.
        group draw(dye, modelView)
    }

    /* Action handling */

    actionCallbacks := ArrayList<ActionCallback> new()

    bubbleAction: func (action: Action) {
        for (cb in actionCallbacks) {
            cb f(action)
        }
    }

    onAction: func (f: Func (Action)) {
        actionCallbacks add(ActionCallback new(f))
    }

}

Action: class {
    id: String
    origin: Widget

    init: func (=id, =origin)
}

ActionCallback: class {
    f: Func (Action)

    init: func (=f) {}
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

