
// ours
import gnaar/[zbag]

// sdk
import structs/[ArrayList]

FireHose: class {

    noses := ArrayList<Nose> new()
    queue := ArrayList<ZBag> new()

    init: func {
        // all good.
    }

    subscribe: func (f: Func (ZBag)) {
        noses add(Nose new(f))
    }

    publish: func (bag: ZBag) {
        queue add(bag)
    }

    dispatch: func {
        while (!queue empty?()) {
            bag := queue removeAt(0)
            for (nose in noses) {
                nose call(bag)
            }
        }
    }

}

Nose: class {

    f: Func (ZBag)

    init: func (=f)

    call: func (bag: ZBag) {
        f(bag)
    }

}


