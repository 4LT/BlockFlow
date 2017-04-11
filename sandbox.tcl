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

set box [.workspace create rectangle 10 60 200 150 -fill black]
.workspace bind $box <1> {selectElement $box %x %y}
.workspace bind $box <B1-Motion> {moveElement %x %y}

proc selectElement {element mx my} {
    set ::el $element
    set ::initx $mx 
    set ::inity $my
}

proc moveElement {mx my} {
    if { [info exists ::el] } {
        .workspace move $::el\
                [expr $mx - $::initx] [expr $my - $::inity]
        set ::initx $mx
        set ::inity $my
    }
}
