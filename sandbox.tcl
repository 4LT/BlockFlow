package require Tk

# Aqua won't allow setting of background colors
ttk::style theme use default
source block.tcl
namespace import block::*

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

bind . <Leave> {updateScrollRegion .view.workspace}

set bset [createBlockSet .view.workspace]
addOp $bset "0 0" {4 3} 
addConduit $bset "1 3" {1 6}

updateScrollRegion .view.workspace
