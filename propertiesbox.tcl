if {[info exists propbox::included]} {
    return
}

namespace eval propbox {
    variable included 1

    namespace export createPropertiesBox getProperty

    package require Tk

    variable boxctr 0

    ttk::style configure Properties.TFrame -background white -borderwidth 1\
        -relief sunken
    font create PropertyKey 
    font create PropertyValue -family [font actual TkTextFont -family]
    ttk::style configure Property.TLabel -background white -borderwidth 1\
        -relief solid -font PropertyKey
    ttk::style configure Property.TEntry -relief solid -borderwidth 1\
        -font PropertyValue

    proc createPropertiesBox {master labelList} {
        variable boxctr

        set propboxFrame ${master}.propbox$boxctr
        ttk::frame $propboxFrame -style Properties.TFrame

        grid columnconfigure $propboxFrame 0 -weight 0
        grid columnconfigure $propboxFrame 1 -weight 1

        for {set i 0} {$i < [llength $labelList]} {incr i} {
            ttk::label $propboxFrame.l$i -text [lindex $labelList $i]\
                -style Property.TLabel -padding "2 0 2 0"
            ttk::entry $propboxFrame.e$i -font PropertyValue\
                -style Property.TEntry -width 0 

            grid $propboxFrame.l$i -row $i -column 0 -sticky nsew
            grid $propboxFrame.e$i -row $i -column 1 -sticky nsew
        }

        incr boxctr
        return $propboxFrame
    }

    proc getProperty {propboxFrame, index} {
        $propboxFrame.e$index get
    }
}
