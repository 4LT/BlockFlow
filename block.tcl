package require Tk

namespace eval block {
    namespace export createBlock updateScrollRegion 

    variable gridsz 20 blockctr 0

    proc createBlock {workspace pos dim style} {
        variable gridsz
        variable blockctr

        set block [dict create\
                ws      $workspace\
                pos     $pos\
                dim     $dim\
                style   $style]

        set wsparent [regsub {\.[^\.]*$} $workspace ""]

        if { "$wsparent" == "$workspace" || "$wsparent" == "" } {
            error "Workspace must have a non-root parent!"
        }

        set pxX [expr [lindex $pos 0] * $gridsz]
        set pxY [expr [lindex $pos 1] * $gridsz]
        set pxW [expr [lindex $dim 0] * $gridsz]
        set pxH [expr [lindex $dim 1] * $gridsz]

        set blockFrame [ttk::frame $wsparent.block$blockctr\
            -style $style]
        set blockWin [$workspace create window $pxX $pxY -width $pxW\
            -height $pxH -window $blockFrame -tags "block" -anchor nw]

        dict set block frame $blockFrame
        dict set block window $blockWin

        bind $blockFrame <1> "block::selectWindow $workspace %X %Y;\
            raise $blockFrame"
        bind $blockFrame <B1-Motion> "block::moveWindow $workspace\
            $blockWin %X %Y"
        bind $blockFrame <B1-ButtonRelease> "block::dropWindow $workspace\
            $blockWin"

        incr blockctr

        return $block
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

    proc dropWindow {workspace window} {
        updateScrollRegion $workspace
    }
}
