
// third-party stuff
use chipmunk
import chipmunk

use dye
import dye/[core, input, sprite, text, primitives, math, anim]

use yaml
import yaml/[Parser, Document]

// sdk stuff
import math, math/Random
import structs/[HashMap, List, ArrayList]
import io/File
import text/StringTokenizer

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

/* YAML utils */

parseYaml: func (path: String) -> DocumentNode {
    file := File new(path)
    if (!file exists?()) {
        return null
    }

    parser := YAMLParser new()
    parser setInputFile(path)

    doc := Document new()
    parser parseAll(doc)
    doc getRootNode()
}

extend DocumentNode {

    toMap: func -> HashMap<String, DocumentNode> {
        match this {
            case mn: MappingNode =>
                mn toHashMap()
            case =>
                Exception new("Called toMap() on a %s" format(class name)) throw()
                null
        }
    }

    toList: func -> List<DocumentNode> {
        match this {
            case sn: SequenceNode =>
                sn toList()
            case =>
                Exception new("Called toList() on a %s" format(class name)) throw()
                null
        }
    }

    toScalar: func -> String {
        match this {
            case sn: ScalarNode =>
                sn value
            case =>
                Exception new("Called toScalar() on a %s" format(class name)) throw()
                null
        }
    }

    toInt: func -> Int {
        toScalar() toInt()
    }

    toFloat: func -> Float {
        toScalar() toFloat()
    }

    toBool: func -> Bool {
        toScalar() trim() == "true"
    }

    toVec2: func -> Vec2 {
        list := toList()
        vec2(list[0] toFloat(), list[1] toFloat())
    }

    toVec2List: func -> List<Vec2> {
        list := toList()
        result := ArrayList<Vec2> new()
        list map(|e| e toVec2())
        result
    }

}

extend String {

    toScalar: func -> ScalarNode {
        ScalarNode new(this)
    }

}

extend Int {

    toScalar: func -> ScalarNode {
        ScalarNode new(this toString())
    }

}

extend Bool {

    toScalar: func -> ScalarNode {
        (this ? "true" : "false") toScalar()
    }

}

extend Vec2 {

    toSeq: func -> SequenceNode {
        seq := SequenceNode new()
        seq add(ScalarNode new(x toString()))
        seq add(ScalarNode new(y toString()))
        seq
    }

}

isPrintable: func (u: UInt16) -> Bool {
    /* ASCII 32 = ' ', ASCII 126 = '~' */
    (u >= 32 && u <= 126)
}

/* List .yml files in a directory, with the '.yml' extension stripped */

listDefs: func (path: String) -> List<String> {
        File new(path) \
            getChildrenNames() \
            filter(|x| x endsWith?(".yml")) \
            map(|x| x[0..-5]) \
}

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

/* Time formatting / parsing utility */

TimeHelper: class {

    MILLIS_IN_MINUTES := static 60 * 1000
    MILLIS_IN_SECONDS := static 1000
    MILLIS_IN_TENTHS := static 10

    format: static func (millis: Long) -> String {
	if (millis == -1) {
	    return "Unknown"
	}

	// Look, I'm not always proud of my code, okay?
	rest := millis

	minutes := (rest - (rest % MILLIS_IN_MINUTES)) / MILLIS_IN_MINUTES
	rest -= minutes * MILLIS_IN_MINUTES	

	seconds := (rest - (rest % MILLIS_IN_SECONDS)) / MILLIS_IN_SECONDS
	rest -= seconds * MILLIS_IN_SECONDS

	tenths := (rest - (rest % MILLIS_IN_TENTHS)) / MILLIS_IN_TENTHS

	"%d\"%02d'%02d" format(minutes, seconds, tenths)
    }

    parse: static func (s: String) -> Long {
	tokens := s split("\"")
	
	minutes := tokens get(0) toInt()
	secondsAndTenths := tokens get(1)

	tokens2 := secondsAndTenths split("'")
	seconds := tokens2 get(0) toInt()
	tenths := tokens2 get(1) toInt()

	minutes * MILLIS_IN_MINUTES + seconds * MILLIS_IN_SECONDS + tenths * MILLIS_IN_TENTHS
    }

}
