package require Tk
source block.tcl
namespace import block::*

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

ttk::style configure Green.TFrame -background #00c000
ttk::style configure Blue.TFrame -background #0000ff
ttk::style configure Magenta.TFrame -background #d000ff
ttk::style configure Red.TFrame -background #d00000

bind . <Leave> {updateScrollRegion .view.workspace}

set bset [createBlockSet .view.workspace]
addBlock $bset "0 0" {4 3} Green.TFrame
addBlock $bset "0 4" {4 3} Blue.TFrame
addBlock $bset "5 0" {4 3} Magenta.TFrame

updateScrollRegion .view.workspace
