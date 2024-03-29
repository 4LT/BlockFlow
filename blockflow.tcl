package require Tk

source propertiesbox.tcl
source block.tcl
namespace import propbox::*
namespace import Block::*

option add *tearOff 0

. configure -menu [menu .menubar]


ttk::frame .view 
tk::canvas .view.workspace -xscrollcommand {.workscrollx set}\
    -yscrollcommand {.workscrolly set}
ttk::frame .fill
ttk::scrollbar .workscrollx -orient horizontal -command {.view.workspace xview}
ttk::scrollbar .workscrolly -orient vertical -command {.view.workspace yview}
ttk::panedwindow .controls -width 280
ttk::frame .controls.properties -padding "4 2 4 0"
ttk::frame .controls.blocklist -padding "4 2 4 0"
ttk::label .controls.properties.label -text "Properties"
ttk::label .controls.blocklist.label -text "Blocks"
ttk::label .status -text "Status Bar"

ttk::frame .controls.properties.container -height 240
tk::listbox .controls.blocklist.list -font PropertyKey -relief sunken

grid .view -row 0 -column 0 -sticky nsew
pack .view.workspace -expand 1 -fill both
grid .fill -row 1 -column 1 -sticky nsew
grid .workscrollx -row 1 -column 0 -sticky ew
grid .workscrolly -row 0 -column 1 -sticky ns
grid .controls -row 0 -column 2 -rowspan 2 -sticky nsew -ipadx 4
    .controls add .controls.properties
        pack .controls.properties.label -anchor w
        pack .controls.properties.container -fill both -expand 1
    .controls add .controls.blocklist
        pack .controls.blocklist.label -anchor w
        pack .controls.blocklist.list -fill both -expand 1
grid rowconfigure .controls 1 -weight 2 -uniform list
grid rowconfigure .controls 3 -weight 3 -uniform list
grid .status -row 2 -column 0 -columnspan 3 -sticky ew

grid rowconfigure . 0 -weight 1
grid columnconfigure . 0 -weight 1

.controls sashpos 0 80

.controls.blocklist.list insert end Conduit Send 

bind . <Leave> {updateScrollRegion .view.workspace}

set sendBlockPBox [createPropertiesBox .controls.properties.container\
    "Destination"]
set conduitPBox [createPropertiesBox .controls.properties.container ""]
set sender [addOp .view.workspace "0 0" {3 2} {4 3} sendBlockPBox send]
set conduit [addConduit .view.workspace "1 3" {1 6} conduitPBox]

proc setPropertiesSlave {newSlave} {
    set slaves [pack slaves .controls.properties.container]
    foreach oldSlave $slaves {
        pack forget $oldSlave
    }
    pack $newSlave -fill both -expand 1
    focus $newSlave
}

Block::setClickCB $sender "setPropertiesSlave $sendBlockPBox"
Block::setClickCB $conduit "setPropertiesSlave $conduitPBox"

updateScrollRegion .view.workspace
