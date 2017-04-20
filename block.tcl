package require Tk

namespace eval block {
    namespace export createBlockSet addBlock updateScrollRegion 

    variable gridsz 20 blockctr 0
    variable sets [list]

    proc createBlockSet {workspace} {
        variable sets

        set blockSet [dict create ws $workspace]
        set wsParent [regsub {\.[^\.]*$} $workspace ""]
        if { "$wsParent" == "$workspace" || "$wsParent" == "" } {
            error "Workspace must have a non-root parent!"
        }
        dict set blockSet wsParent $wsParent
        dict set blockSet blocks [list]
        lappend sets $blockSet
        return [expr [llength sets] - 1]
    }

    proc addBlock {setI pos dim style} {
        variable gridsz
        variable blockctr
        variable sets
        set blockSet [lindex $sets $setI]

        set block [dict create\
                pos     $pos\
                dim     $dim\
                style   $style]

        set workspace [dict get $blockSet ws]

        set pxX [expr [lindex $pos 0] * $gridsz]
        set pxY [expr [lindex $pos 1] * $gridsz]
        set pxW [expr [lindex $dim 0] * $gridsz]
        set pxH [expr [lindex $dim 1] * $gridsz]

        set blockFrame [ttk::frame [dict get $blockSet wsParent].block$blockctr\
            -style $style]
        set blockWin [$workspace create window $pxX $pxY\
            -width $pxW -height $pxH -window $blockFrame -tags "block"\
            -anchor nw]

        dict set block frame $blockFrame
        dict set block window $blockWin

        dict lappend blockSet blocks $block
        set blockI [expr [llength [dict get $blockSet blocks]] - 1]
        lset sets $setI $blockSet

        bind $blockFrame <1> "block::selectWindow $workspace %X %Y;\
            raise $blockFrame"
        bind $blockFrame <B1-Motion> "block::moveWindow $workspace\
            $blockWin %X %Y"
        bind $blockFrame <B1-ButtonRelease> "block::dropWindow $setI $blockI"

        incr blockctr
        return $blockI
    }

    proc updateScrollRegion { workspace } {
        variable gridsz

        set bbox [$workspace bbox "block"]
        for {set i 0} {$i < 2} {incr i} {
            set padding [expr 2 * $gridsz]
            lset bbox $i [expr [lindex $bbox $i] - $padding]
            lset bbox [expr $i + 2]\
                [expr [lindex $bbox [expr $i + 2]] + $padding]
        }
        $workspace configure -scrollregion $bbox
    }

    proc selectWindow {workspace mx my} {
        variable gridsz
        variable x0 [$workspace canvasx $mx $gridsz]\
            y0 [$workspace canvasy $my $gridsz]
    }

    proc moveWindow {workspace window mx my} {
        variable gridsz
        variable x0
        variable y0

        set x [$workspace canvasx $mx $gridsz]
        set y [$workspace canvasy $my $gridsz]
        $workspace move $window\
            [expr $x - $x0]\
            [expr $y - $y0]
        set x0 $x
        set y0 $y
    }

    proc dropWindow {setI blockI} {
        variable sets
        variable gridsz

        set blockSet [lindex $sets $setI]
        set block [lindex [dict get $blockSet blocks]  $blockI]
        set blockWin [dict get $block window]
        set workspace [dict get $blockSet ws]
        lassign [$workspace coords $blockWin] x y
        set newx [expr int($x / $gridsz)]; set newy [expr int($y / $gridsz)]
        dict set block pos [list $newx $newy]
        dict set blockSet blocks\
            [lreplace [dict get $blockSet blocks] $blockI $blockI $block]
        lset sets $setI $blockSet
        
        updateScrollRegion $workspace
    }
}
