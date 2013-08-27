
// third-party stuff
use chipmunk
import chipmunk

use dye
import dye/[core, input, sprite, text, primitives, math, anim]

// sdk
import math, math/Random

extend CpSpace {

    createStaticBox: func ~fromGlRectangle (rect: GlRectangle) -> (CpBody, CpShape) {
        body := CpBody newStatic()
        body setPos(cpv(rect pos))
        shape := CpBoxShape new(body, rect size x, rect size y)
        return (body, shape)
    }

    createStaticBox: func ~fromGlSprite (rect: GlSprite) -> (CpBody, CpShape) {
        body := CpBody newStatic()
        body setPos(cpv(rect pos))
        shape := CpBoxShape new(body, rect size x, rect size y)
        return (body, shape)
    }

}

/* Dye <-> Chipmunk Vector conversion */

cpv: func ~fromVec2 (v: Vec2) -> CpVect {
    cpv(v x, v y)
}

vec2: func ~fromCpv (v: CpVect) -> Vec2 {
    vec2(v x, v y)
}

extend Vec2 {

    set!: func ~fromCpv (v: CpVect) {
        x = v x
        y = v y
    }

    add!: func ~fromCpv (v: CpVect) {
        x += v x
        y += v y
    }

    random: static func (halfSide: Int) -> Vec2 {
        vec2(Random randInt(-halfSide, halfSide) as Float,
             Random randInt(-halfSide, halfSide) as Float)
    }

}

/* Dye <-> Chipmunk physics/graphics sync */

extend GlDrawable {

    sync: func (body: CpBody) {
        bodyPos := body getPos()
        pos set!(bodyPos x, bodyPos y)
        angle = (body getAngle() as Float) toDegrees()
    }

}

