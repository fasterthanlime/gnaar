
// sdk stuff
import structs/[HashMap, ArrayList]

// third-party stuff
use dye
import dye/[math]

/**
 * An infinite, sparse grid, where you can put
 * objects wherever you feel like
 */
SparseGrid: class <T> {
    
    rows := HashMap<Int, Row<T>> new()
    listeners := ArrayList<GridNotificationListener<T>> new()

    init: func

    put: func (col, row: Int, obj: T) -> T {
        getRow(row) put(col, obj)
    }

    remove: func (col, row: Int) -> T {
        getRow(row) remove(col)
    }

    notify: func (col, row: Int) {
        obj := get(col, row)
        notifyListeners(obj)
    }

    onNotification: func (f: Func(T)) {
        listeners add(GridNotificationListener<T> new(f))
    }

    notifyListeners: func (obj: T) {
        for (l in listeners) {
            l f(obj)
        }
    }

    get: func (col, row: Int) -> T {
        getRow(row) get(col)
    }

    getRow: func (row: Int) -> Row<T> {
        if (rows contains?(row)) {
            rows get(row)
        } else {
            obj := Row<T> new()
            rows put(row, obj)
            obj
        }
    }

    clear: func {
        rows each(|k, row|
            row clear()
        )
        rows clear()
        rows = HashMap<Int, Row<T>> new()
    }

    contains?: func (colNum, rowNum: Int) -> Bool {
        if (!rows contains?(rowNum)) return false
        row := rows get(rowNum)
        row cols contains?(colNum)
    }

    each: func (f: Func (Int, Int, T)) {
        rows each(|rowNum, row|
            row cols each(|colNum, item|
                f(colNum, rowNum, item)
            )
        )
    }

    getBounds: func -> AABB2i {
        bounds := AABB2i new()

        rows each(|rowNum, row|
            row cols each(|colNum, col|
                bounds expand!(vec2i(colNum, rowNum))
            )
        )

        bounds
    }

}

GridNotificationListener: class <T> {
    f: Func (T)

    init: func (=f) { }
}

Row: class <T> {

    cols := HashMap<Int, T> new()

    init: func {
    }

    put: func (col: Int, obj: T) -> T {
        cols put(col, obj)
        obj
    }

    get: func (col: Int) -> T {
        cols get(col)
    }

    remove: func (col: Int) -> T {
        obj := cols get(col)
        if (obj) {
            cols remove(col)
            obj
        }
        obj
    }

    clear: func {
        cols clear()
    }

}
