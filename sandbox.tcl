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

ttk::frame .view.boxframe -style Green.TFrame
ttk::frame .view.boxframe2 -style Blue.TFrame
set box [.view.workspace create window 20 20 -width 80 -height 60\
    -window .view.boxframe -tags "element" -anchor nw]
set box2 [.view.workspace create window 20 120 -width 80 -height 60\
    -window .view.boxframe2 -tags "element" -anchor nw]

proc setScrollRegion {} {
    set bbox [.view.workspace bbox "element"]
    for {set i 0} {$i < 2} {incr i} {
        lset bbox $i [expr [lindex $bbox $i] - 40]
        lset bbox [expr $i + 2] [expr [lindex $bbox [expr $i + 2]] + 40]
    }
    .view.workspace configure -scrollregion $bbox
}

setScrollRegion

foreach boxMaterials {{$box .view.boxframe} {$box2 .view.boxframe2}} {
    bind [lindex $boxMaterials 1] <1> "selectElement %X %Y; raise\
        [lindex $boxMaterials 1]"
    bind [lindex $boxMaterials 1] <B1-Motion> "moveElement\
        [lindex $boxMaterials 0] %X %Y"
    bind [lindex $boxMaterials 1] <B1-ButtonRelease> "dropElement\
        [lindex $boxMaterials 0]"
}

proc selectElement {mx my} {
    set ::x0 [.view.workspace canvasx $mx 20]
    set ::y0 [.view.workspace canvasy $my 20]
}

proc moveElement {element mx my} {
    set x [.view.workspace canvasx $mx 20]
    set y [.view.workspace canvasy $my 20]
    .view.workspace move $element [expr $x - $::x0] [expr $y - $::y0]
    set ::x0 $x
    set ::y0 $y
}

proc dropElement {element} {
    setScrollRegion
}
