package require Tk

option add *tearOff 0

. configure -menu [menu .menubar]

tk::canvas .workspace -xscrollcommand {.workscrollx set}\
    -yscrollcommand {.workscrolly set}
ttk::frame .fill
ttk::scrollbar .workscrollx -orient horizontal -command {.workspace xview}
ttk::scrollbar .workscrolly -orient vertical -command {.workspace yview}
ttk::label .status -text "Status Bar"

grid .workspace -row 0 -column 0 -sticky nsew
grid .fill -row 1 -column 1 -sticky nsew
grid .workscrollx -row 1 -column 0 -sticky ew
grid .workscrolly -row 0 -column 1 -sticky ns
grid .status -row 2 -column 0 -columnspan 2 -sticky ew

grid rowconfigure . 0 -weight 1
grid columnconfigure . 0 -weight 1

.workspace configure -scrollregion [list 0 0 640 480]

set box [.workspace create rectangle 20 20 40 40 -fill black -tags "element"]
set box2 [.workspace create rectangle 20 60 40 80 -fill red -tags "element"]
foreach b "$box $box2" {
    .workspace bind $b <1> "selectElement $b %x %y"
    .workspace bind $b <B1-Motion> "moveElement $b %x %y"
    .workspace bind $b <B1-ButtonRelease> "dropElement $b"
}

proc selectElement {element mx my} {
    set ::initx $mx
    set ::inity $my
    .workspace raise $element 
}

proc moveElement {element mx my} {
    .workspace move $element [expr $mx - $::initx] [expr $my - $::inity]
    set ::initx $mx
    set ::inity $my
}

proc dropElement {element} {
    set coords [.workspace coords $element]
    for {set i 0} {$i < 2} {incr i} {
        lset coords $i [expr {20 * round( [lindex $coords $i] / 20) }]
        lset coords [expr $i + 2] [expr [lindex $coords $i] + 20]
    }
    .workspace coords $element $coords
    set bbox [.workspace bbox "element"]
    for {set i 0} {$i < 2} {incr i} {
        lset bbox $i [expr [lindex $bbox $i] - 20]
        lset bbox [expr $i + 2] [expr [lindex $bbox [expr $i + 2]] + 20]
    }
    .workspace configure -scrollregion $bbox
}
