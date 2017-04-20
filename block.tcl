package require Tk

namespace eval block {
    namespace export createBlockSet addBlock updateScrollRegion 

    variable gridsz 20 blockctr 0 setctr 0
    variable sets 

    proc createBlockSet {workspace} {
        variable sets
        variable setctr

        set blockSpace [dict create ws $workspace]
        set wsParent [regsub {\.[^\.]*$} $workspace ""]
        if { "$wsParent" == "$workspace" || "$wsParent" == "" } {
            error "Workspace must have a non-root parent!"
        }
        dict set blockSpace wsParent $wsParent
        dict set blockSpace blocks [dict create]
        set sets($setctr) $blockSpace
        incr setctr
        return [expr $setctr - 1]
    }

    proc addBlock {setI pos dim style} {
        variable gridsz
        variable blockctr
        variable sets
        set blockSpace $sets($setI)

        set block [dict create\
                pos     $pos\
                dim     $dim\
                style   $style]

        set workspace [dict get $blockSpace ws]

        set pxX [expr [lindex $pos 0] * $gridsz]
        set pxY [expr [lindex $pos 1] * $gridsz]
        set pxW [expr [lindex $dim 0] * $gridsz]
        set pxH [expr [lindex $dim 1] * $gridsz]

        set blockFrame [ttk::frame\
            [dict get $blockSpace wsParent].block$blockctr -style $style]
        set blockWin [$workspace create window $pxX $pxY\
            -width $pxW -height $pxH -window $blockFrame -tags "block"\
            -anchor nw]

        dict set block frame $blockFrame
        dict set block window $blockWin

        dict set blockSpace blocks $blockctr $block
        set sets($setI) $blockSpace

        bind $blockFrame <1> "block::selectWindow $workspace %X %Y;\
            raise $blockFrame"
        bind $blockFrame <B1-Motion> "block::moveWindow $workspace\
            $blockWin %X %Y"
        bind $blockFrame <B1-ButtonRelease> "block::dropWindow $setI $blockctr"

        incr blockctr
        return [expr $blockctr - 1]
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

    proc updateWindow {workspace block blockWin} {
        variable gridsz

        lassign [dict get $block pos] x y
        lassign [dict get $block dim] w h
        set pxX [expr $x * $gridsz]
        set pxY [expr $y * $gridsz]
        set pxW [expr $w * $gridsz]
        set pxH [expr $h * $gridsz]
        
        $workspace coords $blockWin $pxX $pxY
        $workspace itemconfigure $blockWin -width $pxW -height $pxH
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

    proc overlap {block1 block2} {
        lassign [dict get $block1 pos] minX1 minY1
        lassign [dict get $block1 dim] w h
        set maxX1 [expr $minX1 + $w - 1]
        set maxY1 [expr $minY1 + $h - 1]
        lassign [dict get $block2 pos] minX2 minY2
        lassign [dict get $block2 dim] w h
        set maxX2 [expr $minX2 + $w - 1]
        set maxY2 [expr $minY2 + $h - 1]

        if {    $minX1 <= $maxX2 && $maxX1 >= $minX2 &&\
                $minY1 <= $maxY2 && $maxY1 >= $minY2    } {
            return 1
        } else {
            return 0
        }
    }

    proc dropWindow {setI blockI} {
        variable sets
        variable gridsz

        set blockSpace $sets($setI)
        set block [dict get $blockSpace blocks $blockI]
        set blockWin [dict get $block window]
        set workspace [dict get $blockSpace ws]
        lassign [$workspace coords $blockWin] x y
        set newx [expr int($x / $gridsz)]; set newy [expr int($y / $gridsz)]
        set newBlock $block
        dict set newBlock pos [list $newx $newy]

        set overlap 0
        for {set i 0} {$i < [dict size [dict get $blockSpace blocks]]} {incr i}\
        {
            if {$i != $blockI && [overlap $newBlock\
                    [dict get $blockSpace blocks $i]]} {
                set overlap 1
                break
            }
        }

        if {!$overlap} {
            set block $newBlock
            dict set blockSpace blocks $blockI $block
            set sets($setI) $blockSpace
        }
        
        updateWindow $workspace $block $blockWin
        updateScrollRegion $workspace
    }
}
