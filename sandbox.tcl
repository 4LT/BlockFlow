package require Tk

# Aqua won't allow setting of background colors
ttk::style theme use default

option add *tearOff 0

. configure -menu [menu .menubar]

ttk::frame .view 
tk::canvas .view.workspace -xscrollcommand {.workscrollx set}\
    -yscrollcommand {.workscrolly set}
ttk::frame .fill
ttk::scrollbar .workscrollx -orient horizontal -command {.view.workspace xview}
ttk::scrollbar .workscrolly -orient vertical -command {.view.workspace yview}
ttk::label .status -text "Status Bar"

grid .view -row 0 -column 0 -sticky nsew
pack .view.workspace -expand 1 -fill both
grid .fill -row 1 -column 1 -sticky nsew
grid .workscrollx -row 1 -column 0 -sticky ew
grid .workscrolly -row 0 -column 1 -sticky ns
grid .status -row 2 -column 0 -columnspan 2 -sticky ew

grid rowconfigure . 0 -weight 1
grid columnconfigure . 0 -weight 1

ttk::style configure Green.TFrame -background green
ttk::style configure Blue.TFrame -background blue

set gridsz 20
set blockctr 0

bind . <Leave> {setScrollRegion}

proc createBlock {q style} {
    set x [expr [lindex $q 0] * $::gridsz]
    set y [expr [lindex $q 1] * $::gridsz]
    set w [expr [lindex $q 2] * $::gridsz]
    set h [expr [lindex $q 3] * $::gridsz]
    set blockFrame [ttk::frame .view.$::blockctr -style $style]
    set block [.view.workspace create window $x $y -width $w -height $h\
        -window $blockFrame -tags "block" -anchor nw]

    bind $blockFrame <1> "selectElement %X %Y; raise $blockFrame"
    bind $blockFrame <B1-Motion> "moveElement $block %X %Y"
    bind $blockFrame <B1-ButtonRelease> "dropElement $block"

    incr ::blockctr
}

proc setScrollRegion {} {
    set bbox [.view.workspace bbox "block"]
    for {set i 0} {$i < 2} {incr i} {
        set padding [expr 2 * $::gridsz]
        lset bbox $i [expr [lindex $bbox $i] - $padding]
        lset bbox [expr $i + 2] [expr [lindex $bbox [expr $i + 2]] + $padding]
    }
    .view.workspace configure -scrollregion $bbox
}

createBlock {0 0 4 3} Green.TFrame
createBlock {0 4 4 3} Blue.TFrame

setScrollRegion

proc selectElement {mx my} {
    set ::x0 [.view.workspace canvasx $mx $::gridsz]
    set ::y0 [.view.workspace canvasy $my $::gridsz]
}

proc moveElement {element mx my} {
    set x [.view.workspace canvasx $mx $::gridsz]
    set y [.view.workspace canvasy $my $::gridsz]
    .view.workspace move $element [expr $x - $::x0] [expr $y - $::y0]
    set ::x0 $x
    set ::y0 $y
}

proc dropElement {element} {
    setScrollRegion
}
