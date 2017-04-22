package require Tk

# Aqua won't allow setting of background colors
ttk::style theme use default
source block.tcl
namespace import block::*

option add *tearOff 0

. configure -menu [menu .menubar]

ttk::style configure Properties.TFrame -background white -borderwidth 1\
    -relief solid
font create PropertyKey -size 12
font create PropertyValue -size 12 -family\
    [font actual TkTextFont -family]
ttk::style configure Property.TLabel -background white -borderwidth 1\
    -relief solid -font PropertyKey
ttk::style configure Property.TEntry -relief solid -borderwidth 1\
    -font PropertyValue

ttk::frame .view 
tk::canvas .view.workspace -xscrollcommand {.workscrollx set}\
    -yscrollcommand {.workscrolly set}
ttk::frame .fill
ttk::scrollbar .workscrollx -orient horizontal -command {.view.workspace xview}
ttk::scrollbar .workscrolly -orient vertical -command {.view.workspace yview}
ttk::panedwindow .controls
ttk::frame .controls.properties -padding "4 2 4 0"
ttk::frame .controls.blocklist -padding "4 2 4 0"
ttk::label .controls.properties.label -text "Properties"
ttk::frame .controls.properties.frame -style Properties.TFrame -height 100
ttk::label .controls.blocklist.label -text "Blocks"
tk::listbox .controls.blocklist.list -font PropertyKey
ttk::label .status -text "Status Bar"

grid .view -row 0 -column 0 -sticky nsew
pack .view.workspace -expand 1 -fill both
grid .fill -row 1 -column 1 -sticky nsew
grid .workscrollx -row 1 -column 0 -sticky ew
grid .workscrolly -row 0 -column 1 -sticky ns
grid .controls -row 0 -column 2 -rowspan 2 -sticky nsew -ipadx 4
    .controls add .controls.properties
        pack .controls.properties.label -anchor w
        pack .controls.properties.frame -fill both -expand 1
    .controls add .controls.blocklist
        pack .controls.blocklist.label -anchor w
        pack .controls.blocklist.list -fill both -expand 1
grid rowconfigure .controls 1 -weight 2 -uniform list
grid rowconfigure .controls 3 -weight 3 -uniform list
grid .status -row 2 -column 0 -columnspan 3 -sticky ew

grid rowconfigure . 0 -weight 1
grid columnconfigure . 0 -weight 1

.controls sashpos 0 80

ttk::label .controls.properties.frame.l1 -text "Property 1"\
    -style Property.TLabel
ttk::entry .controls.properties.frame.e1 -textvariable prop1\
    -font PropertyValue -style Property.TEntry
ttk::label .controls.properties.frame.l2 -text "Property 2"\
    -style Property.TLabel
ttk::entry .controls.properties.frame.e2 -textvariable prop2\
    -font PropertyValue -style Property.TEntry

grid .controls.properties.frame.l1 -row 0 -column 0 -sticky nsew
grid .controls.properties.frame.e1 -row 0 -column 1 -sticky nsew
grid .controls.properties.frame.l2 -row 1 -column 0 -sticky nsew
grid .controls.properties.frame.e2 -row 1 -column 1 -sticky nsew

grid columnconfigure .controls.properties.frame 0 -weight 1
grid columnconfigure .controls.properties.frame 1 -weight 1

.controls.blocklist.list insert end Conduit Add Sub Mul Div

bind . <Leave> {updateScrollRegion .view.workspace}

set bset [createBlockSet .view.workspace]
addOp $bset "0 0" {4 3} 
addConduit $bset "1 3" {1 6}

updateScrollRegion .view.workspace
