if {[info exists block::included]} {
    return
}

namespace eval block {
    variable included 1

    namespace export createBlockSet updateScrollRegion addOp addConduit\
        getPropBox setClickCB

    package require Tk

    variable gridsz 20 blockctr -1 edgeW 4
    variable blockSets 

    ttk::style configure Op.TFrame -background #40a0ff
    ttk::style configure Conduit.TFrame -background #ff9010 
    ttk::style configure ConduitEdge.TFrame -background #ffff00

    proc getMaster {widg} {
        set master [regsub {\.[^\.]*$} $widg ""]
        if { "$master" == "$widg" || "$master" == "" } {
            error "Workspace must have a non-root master!"
        }
        return $master
    }

    proc createBlockSet {workspace} {
        variable blockSets
        set blockSets($workspace) [dict create]
        return $workspace
    }

    proc addOp {workspace pos dim propBox} {
        variable blockSets

        set blockI [newBlock $workspace $pos $dim Op.TFrame $propBox]
        set blockFrame [dict get $blockSets($workspace) $blockI frame]
        $blockFrame configure -relief solid -borderwidth 1

        return $blockI
    }

    proc addConduit {workspace pos dim propBox} {
        variable blockSets
        variable edgeW

        set blockI [newBlock $workspace $pos $dim Conduit.TFrame $propBox]
        set blockFrame [dict get $blockSets($workspace) $blockI frame]
        set sideHandles [list\
            $blockFrame.nwHandle    $blockFrame.neHandle\
            $blockFrame.wHandle     $blockFrame.eHandle\
            $blockFrame.swHandle    $blockFrame.seHandle]

        foreach h $sideHandles {
            $h configure -style ConduitEdge.TFrame
        }

        return $blockI
    }

    proc newBlock {workspace pos dim style propBox} {
        variable gridsz
        variable blockctr
        variable blockSets
        variable edgeW

        incr blockctr

        set blocks $blockSets($workspace)

        set block [dict create\
                pos     $pos\
                dim     $dim\
                propBox $propBox\
                clickCB ";"]

        set wsMaster [getMaster $workspace]

        set pxX [expr [lindex $pos 0] * $gridsz]
        set pxY [expr [lindex $pos 1] * $gridsz]
        set pxW [expr [lindex $dim 0] * $gridsz]
        set pxH [expr [lindex $dim 1] * $gridsz]

        set blockFrame [ttk::frame $wsMaster.block$blockctr -style $style]
        set blockWin [$workspace create window $pxX $pxY\
            -width $pxW -height $pxH -window $blockFrame -tags "block"\
            -anchor nw]
        
        grid [ttk::frame $blockFrame.nHandle    -style $style\
            -cursor top_side]\
            -row 0 -column 1 -sticky nsew
        grid [ttk::frame $blockFrame.neHandle   -style $style\
            -cursor top_right_corner]\
            -row 0 -column 2 -sticky nsew
        grid [ttk::frame $blockFrame.eHandle    -style $style\
            -cursor right_side]\
            -row 1 -column 2 -sticky nsew
        grid [ttk::frame $blockFrame.seHandle   -style $style\
            -cursor bottom_right_corner]\
            -row 2 -column 2 -sticky nsew
        grid [ttk::frame $blockFrame.sHandle    -style $style\
            -cursor bottom_side]\
            -row 2 -column 1 -sticky nsew
        grid [ttk::frame $blockFrame.swHandle   -style $style\
            -cursor bottom_left_corner]\
            -row 2 -column 0 -sticky nsew
        grid [ttk::frame $blockFrame.wHandle    -style $style\
            -cursor left_side]\
            -row 1 -column 0 -sticky nsew
        grid [ttk::frame $blockFrame.nwHandle   -style $style\
            -cursor top_left_corner]\
            -row 0 -column 0 -sticky nsew

        set handles [list $blockFrame.nHandle $blockFrame.neHandle\
            $blockFrame.eHandle $blockFrame.seHandle $blockFrame.sHandle\
            $blockFrame.swHandle $blockFrame.wHandle $blockFrame.nwHandle]

        grid rowconfigure $blockFrame 0 -minsize $edgeW 
        grid rowconfigure $blockFrame 1 -weight 1
        grid rowconfigure $blockFrame 2 -minsize $edgeW
        grid columnconfigure $blockFrame 0 -minsize $edgeW
        grid columnconfigure $blockFrame 1 -weight 1
        grid columnconfigure $blockFrame 2 -minsize $edgeW

        dict set block frame $blockFrame
        dict set block window $blockWin

        dict set blocks $blockctr $block
        set blockSets($workspace) $blocks

        bind $blockFrame <1> "block::selectWindow $workspace $blockFrame\
            %X %Y"
        bind $blockFrame <B1-Motion> "block::moveWindow $workspace\
            $blockWin %X %Y"

        foreach handle [list $blockFrame.nwHandle $blockFrame.nHandle\
                $blockFrame.neHandle] {
            bind $handle <B1-Motion> "+block::resizeWindowV $workspace\
                $blockWin %Y 1"
        }

        foreach handle [list $blockFrame.neHandle $blockFrame.eHandle\
                $blockFrame.seHandle] {
            bind $handle <B1-Motion> "+block::resizeWindowH $workspace\
                $blockWin %X 0"
        }

        foreach handle [list $blockFrame.swHandle $blockFrame.sHandle\
                $blockFrame.seHandle] {
            bind $handle <B1-Motion> "+block::resizeWindowV $workspace\
                $blockWin %Y 0"
        }

        foreach handle [list $blockFrame.nwHandle $blockFrame.wHandle\
                $blockFrame.swHandle] {
            bind $handle <B1-Motion> "+block::resizeWindowH $workspace\
                $blockWin %X 1"
        }

        foreach frame [concat $handles $blockFrame] {
            bind $frame <1> "block::selectWindow $workspace $blockFrame %X %Y"
            bind $frame <1> "+block::onClick $workspace $blockctr"
            bind $frame <B1-ButtonRelease>\
                "block::dropWindow $workspace $blockctr"
        }

        return $blockctr
    }

    proc updateScrollRegion {workspace} {
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

    proc selectWindow {workspace blockFrame mx my} {
        variable gridsz
        variable x0 [$workspace canvasx $mx $gridsz]\
            y0 [$workspace canvasy $my $gridsz]
        raise $blockFrame
    }

    proc dx {workspace mx} {
        variable gridsz
        variable x0
        set x [$workspace canvasx $mx $gridsz]
        set dx [expr $x - $x0]
        set x0 $x
        return $dx
    }

    proc dy {workspace my} {
        variable gridsz
        variable y0
        set y [$workspace canvasy $my $gridsz]
        set dy [expr $y - $y0]
        set y0 $y
        return $dy
    }

    proc moveWindow {workspace window mx my} {
        $workspace move $window [dx $workspace $mx] [dy $workspace $my]
    }

    proc resizeWindowH {workspace window mx left} {
        variable gridsz

        set dx [dx $workspace $mx]
        set w0 [$workspace itemcget $window -width]
        if {$left} {
            set w [expr $w0 - $dx]
        } else {
            set w [expr $w0 + $dx]
        }
        if {$w >= $gridsz} {
            $workspace itemconfigure $window -width $w
            if {$left} {
                $workspace move $window $dx 0
            }
        }
    }

    proc resizeWindowV {workspace window my top} {
        variable gridsz

        set dy [dy $workspace $my]
        set h0 [$workspace itemcget $window -height]
        if {$top} {
            set h [expr $h0 - $dy]
        } else {
            set h [expr $h0 + $dy]
        }
        if {$h >= $gridsz} {
            $workspace itemconfigure $window -height $h
            if {$top} {
                $workspace move $window 0 $dy
            }
        }
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

    proc dropWindow {workspace blockI} {
        variable gridsz
        variable blockSets

        set blocks $blockSets($workspace)
        set block [dict get $blocks $blockI]
        set blockWin [dict get $block window]
        lassign [$workspace coords $blockWin] x y
        set w [$workspace itemcget $blockWin -width]
        set h [$workspace itemcget $blockWin -height]
        set newX [expr int($x / $gridsz)]; set newY [expr int($y / $gridsz)]
        set newW [expr int($w / $gridsz)]; set newH [expr int($h / $gridsz)]

        set newBlock $block
        dict set newBlock pos [list $newX $newY]
        dict set newBlock dim [list $newW $newH]

        set overlap 0
        for {set i 0} {$i < [dict size $blocks]} {incr i} {
            if {$i != $blockI && [overlap $newBlock [dict get $blocks $i]]} {
                set overlap 1
                break
            }
        }

        if {!$overlap} {
            set block $newBlock
            dict set blocks $blockI $block
            set blockSets($workspace) $blocks
        }
        
        updateWindow $workspace $block $blockWin
        updateScrollRegion $workspace
    }

    proc getPropBox {workspace boxI} {
        variable blockSets
        return [dict get $blockSets($workspace) $boxI propBox]
    }

    proc setClickCB {workspace blockI cbScript} {
        variable blockSets
        dict set blockSets($workspace) $blockI clickCB $cbScript
    }

    proc onClick {workspace blockI} {
        variable blockSets
        eval [dict get $blockSets($workspace) $blockI clickCB]
    }
}
