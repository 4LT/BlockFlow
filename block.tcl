if {[info exists ::Block::included]} {
    return
}

namespace eval ::Block {
    variable included 1

    namespace export createBlockSet updateScrollRegion addOp addConduit\
        getPropBox setClickCB

    package require Tk

    variable gridsz 20 blockctr -1 edgeW 4 selected [list]
    variable blockSets

    ttk::style configure Op.TFrame -background #80c8ff
    ttk::style configure Op.TLabel -background #80c8ff
    ttk::style configure Conduit.TFrame -background #ff9010 
    ttk::style configure ConduitEdge.TFrame -background #b04000

    ttk::style configure SelFrame.TFrame -background #c0ffc0
    ttk::style configure SelLabel.TLabel -background #c0ffc0
    ttk::style configure SelEdge.TFrame -background #00c000

    proc addOp {workspace pos minDim dim propBox labelText} {

        set block [newBlock $workspace $pos $minDim $dim Op.TFrame $propBox]
        set ${block}::type "Op"
        set blockFrame [subst $${block}::frame]
        $blockFrame  configure -relief solid -borderwidth 1

        grid [ttk::label ${blockFrame}.label -text $labelText\
            -style Op.TLabel] -row 1 -column 1

        bindtags ${blockFrame}.label\
            [linsert [bindtags ${blockFrame}.label] 1\
            $blockFrame [subst $${block}::tag]]

        return $block
    }

    proc addConduit {workspace pos dim propBox} {
        variable edgeW

        set block [newBlock $workspace $pos {1 1} $dim Conduit.TFrame $propBox]
        set ${block}::type "Conduit"
        set blockFrame [subst $${block}::frame]
        set sideHandles [list\
            $blockFrame.nwHandle    $blockFrame.neHandle\
            $blockFrame.wHandle     $blockFrame.eHandle\
            $blockFrame.swHandle    $blockFrame.seHandle]

        set ${block}::sideHandles $sideHandles
        foreach h $sideHandles {
            $h configure -style ConduitEdge.TFrame
        }

        return $block
    }

    proc newBlock {workspace pos minDim dim style propBox} {
        variable gridsz
        variable blockctr
        variable blockSets
        variable edgeW

        incr blockctr

        set wsParent [winfo parent $workspace]

        set pxX [expr [lindex $pos 0] * $gridsz]
        set pxY [expr [lindex $pos 1] * $gridsz]
        set pxW [expr [lindex $dim 0] * $gridsz]
        set pxH [expr [lindex $dim 1] * $gridsz]

        set blockFrame [ttk::frame $wsParent.block$blockctr -style $style]
        set blockWin [$workspace create window $pxX $pxY\
            -width $pxW -height $pxH -window $blockFrame -tags "block"\
            -anchor nw]

        set blockNs [namespace current]::instance$blockctr

        set blockTag block$blockctr
        namespace eval $blockNs [subst {
            variable\
                tag         "$blockTag"\
                type        {}\
                ws          "$workspace"\
                pos         "$pos"\
                dim         "$dim"\
                minDim      "$minDim"\
                propBox     "$propBox"\
                clickCB     {;}\
                frame       "$blockFrame"\
                win         "$blockWin"
        }] 

        if {[info exists blockSets($workspace)]} {
            lappend blockSets($workspace) $blockNs
        } else {
            set blockSets($workspace) [list $blockNs]
        }
        
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

        foreach handle [concat $handles $blockFrame] {
            bindtags $handle [linsert [bindtags $handle] 1 $blockTag]
        }

        grid rowconfigure $blockFrame 0 -minsize $edgeW 
        grid rowconfigure $blockFrame 1 -weight 1
        grid rowconfigure $blockFrame 2 -minsize $edgeW
        grid columnconfigure $blockFrame 0 -minsize $edgeW
        grid columnconfigure $blockFrame 1 -weight 1
        grid columnconfigure $blockFrame 2 -minsize $edgeW

        foreach handle [list $blockFrame.nwHandle $blockFrame.nHandle\
                $blockFrame.neHandle] {
            bind $handle <B1-Motion> "+::Block::resizeWindowV $blockNs %Y 1"
        }

        foreach handle [list $blockFrame.neHandle $blockFrame.eHandle\
                $blockFrame.seHandle] {
            bind $handle <B1-Motion> "+::Block::resizeWindowH $blockNs %X 0"
        }

        foreach handle [list $blockFrame.swHandle $blockFrame.sHandle\
                $blockFrame.seHandle] {
            bind $handle <B1-Motion> "+::Block::resizeWindowV $blockNs %Y 0"
        }

        foreach handle [list $blockFrame.nwHandle $blockFrame.wHandle\
                $blockFrame.swHandle] {
            bind $handle <B1-Motion> "+::Block::resizeWindowH $blockNs %X 1"
        }

        bind $blockTag <1> "::Block::selectWindow $blockNs %X %Y"
        bind $blockFrame <B1-Motion> "::Block::moveWindow $blockNs %X %Y"
        bind $blockTag <1> "+::Block::onClick $blockNs"
        bind $blockTag <B1-ButtonRelease> "::Block::dropWindow $blockNs"

        return $blockNs
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

    proc updateWindow {block} {
        variable gridsz

        lassign [subst $${block}::pos] x y
        lassign [subst $${block}::dim] w h
        set pxX [expr $x * $gridsz]
        set pxY [expr $y * $gridsz]
        set pxW [expr $w * $gridsz]
        set pxH [expr $h * $gridsz]
        
        set workspace [subst $${block}::ws]
        set blockWin [subst $${block}::win]
        $workspace coords $blockWin $pxX $pxY
        $workspace itemconfigure $blockWin -width $pxW -height $pxH
    }

    proc selectWindow {block mx my} {
        variable gridsz
        set workspace [subst $${block}::ws]
        variable x0 [$workspace canvasx $mx $gridsz]\
            y0 [$workspace canvasy $my $gridsz]

        set blockFrame [subst $${block}::frame]

        $blockFrame configure -style SelFrame.TFrame
        foreach child [winfo children $blockFrame] {
            switch [winfo class $child] {
                TFrame {
                    $child configure -style SelFrame.TFrame
                } TLabel {
                    $child configure -style SelLabel.TLabel
                }
            }
        }
        if {[subst $${block}::type] == "Conduit"} {
            foreach h [subst $${block}::sideHandles] {
                $h configure -style SelEdge.TFrame
            }
        }
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

    proc moveWindow {block mx my} {
        set workspace [subst $${block}::ws]
        set blockWin [subst $${block}::win]
        $workspace move $blockWin [dx $workspace $mx] [dy $workspace $my]
    }

    proc resizeWindowH {block mx left} {
        variable gridsz

        set workspace [subst $${block}::ws]
        set blockWin [subst $${block}::win]
        set minW [lindex [subst $${block}::minDim] 0]

        set dx [dx $workspace $mx]
        set w0 [$workspace itemcget $blockWin -width]
        if {$left} {
            set w [expr $w0 - $dx]
        } else {
            set w [expr $w0 + $dx]
        }
        if {$w >= [expr $gridsz * $minW]} {
            $workspace itemconfigure $blockWin -width $w
            if {$left} {
                $workspace move $blockWin $dx 0
            }
        }
    }

    proc resizeWindowV {block my top} {
        variable gridsz

        set workspace [subst $${block}::ws]
        set blockWin [subst $${block}::win]
        set minH [lindex [subst $${block}::minDim] 1]

        set dy [dy $workspace $my]
        set h0 [$workspace itemcget $blockWin -height]
        if {$top} {
            set h [expr $h0 - $dy]
        } else {
            set h [expr $h0 + $dy]
        }
        if {$h >= [expr $gridsz * $minH]} {
            $workspace itemconfigure $blockWin -height $h
            if {$top} {
                $workspace move $blockWin 0 $dy
            }
        }
    }

    proc overlap {block1 minX2 minY2 w2 h2} {
        lassign [subst $${block1}::pos] minX1 minY1
        lassign [subst $${block1}::dim] w1 h1
        set maxX1 [expr $minX1 + $w1 - 1]
        set maxY1 [expr $minY1 + $h1 - 1]
        set maxX2 [expr $minX2 + $w2 - 1]
        set maxY2 [expr $minY2 + $h2 - 1]

        if {    $minX1 <= $maxX2 && $maxX1 >= $minX2 &&\
                $minY1 <= $maxY2 && $maxY1 >= $minY2    } {
            return 1
        } else {
            return 0
        }
    }

    proc dropWindow {block} {
        variable gridsz
        variable blockSets

        set workspace [subst $${block}::ws]
        set blockWin [subst $${block}::win]

        lassign [$workspace coords $blockWin] x y
        set w [$workspace itemcget $blockWin -width]
        set h [$workspace itemcget $blockWin -height]
        set gridX [expr int($x / $gridsz)]; set gridY [expr int($y / $gridsz)]
        set gridW [expr int($w / $gridsz)]; set gridH [expr int($h / $gridsz)]

        set overlap 0
        foreach b $blockSets($workspace) {
            if {$b != $block && [overlap $b $gridX $gridY $gridW $gridH]} {
                set overlap 1
                break
            }
        }

        if {!$overlap} {
            set ${block}::pos [list $gridX $gridY]
            set ${block}::dim [list $gridW $gridH]
        }
        
        updateWindow $block 
        updateScrollRegion $workspace
    }

    proc getPropBox {block} {
        return [subst $${block}::propBox]
    }

    proc setClickCB {block cbScript} {
        set ${block}::clickCB $cbScript 
    }

    proc onClick {block} {
        eval [subst $${block}::clickCB]
    }
}
