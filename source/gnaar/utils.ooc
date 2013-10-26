
// third-party
use dye
import dye/[core, math]

BoundingBox: class {

    contains?: static func ~rect (pos, size, needle: Vec2, center := true) -> Bool {
        topLeft, bottomRight: Vec2

        if (center) {
            halfSize := size mul(0.5)
            topLeft     = pos sub(halfSize)
            bottomRight = pos add(halfSize)
        } else {
            topLeft     = pos
            bottomRight = pos add(size)
        }

        (
            (needle x >= topLeft x) &&
            (needle x <= bottomRight x) &&
            (needle y >= topLeft y) &&
            (needle y <= bottomRight y)
        )
    }
}

// 16-bit char functions:

isPrintable: func (u: UInt16) -> Bool {
    /* ASCII 32 = ' ', ASCII 126 = '~' */
    (u >= 32 && u <= 126)
}

