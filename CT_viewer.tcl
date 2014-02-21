#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
method CT_viewer constructor {ct_element canvas task_viewer} {
 set this(task_viewer) $task_viewer
 set this(canvas)      $canvas
 set this(ct_element)  $ct_element
 
 set this(id_box)   [$canvas create rectangle 0 0 200 100 -fill grey -tags [list $ct_element Drag_zone_$ct_element $task_viewer $objName]]
 set ct_text "0 : [$ct_element get_name]"
 if {[$ct_element get_is_optional] || [$ct_element get_is_iterative]} {
   append ct_text "  "
   if {[$ct_element get_is_optional] } {append ct_text " o"}
   if {[$ct_element get_is_iterative]} {append ct_text " *"}
  }
 set this(lab_name) [$canvas create text 0 0 -text $ct_text -font "Times [expr int(12.0 / [$task_viewer get_zoom_factor])] normal" -anchor sw -tags [list $ct_element Drag_zone_$ct_element $task_viewer TEXT_$task_viewer $objName]]
 
 if {[lsearch [gmlObject info classes $ct_element] "TaskOperator"] != -1} {
   set this(lab_type) [$canvas create text 0 0 -text [$ct_element get_type] -font "Times [expr int(12.0 / [$task_viewer get_zoom_factor])] normal" -anchor center -tags [list $ct_element Drag_zone_$ct_element $task_viewer TEXT_$task_viewer $objName]]
   lassign [$canvas bbox $this(lab_name)]  lx1 ly1 lx2 ly2; set lmx [expr ($lx1 + $lx2) / 2]; set lmy [expr ($ly1 + $ly2) / 2]
   lassign [$canvas bbox $this(lab_type)]  tx1 ty1 tx2 ty2; set tmx [expr ($tx1 + $tx2) / 2]; set tmy [expr ($ty1 + $ty2) / 2]
   $this(canvas) move $this(lab_type) [expr $lmx - $tmx] [expr $ly1 - $ty1 + 20]
   lassign [$canvas bbox $this(lab_name) $this(lab_type)] x1 y1 x2 y2
  } else {lassign [$canvas bbox $this(lab_name)] x1 y1 x2 y2
         }
  
 
 
 $canvas coords $this(id_box) [expr $x1 - 5] [expr $y1 - 5]  [expr $x2 + 5] [expr $y2 + 5]
 
 lassign [$canvas bbox $objName] x1 y1 x2 y2
   set this(x) $x1; set this(y) $y1
 
 $canvas bind Drag_zone_$ct_element <ButtonPress>   "if {%b == 1} {$task_viewer set_current_element $objName %x %y} else {$task_viewer set_current_contextual_element $ct_element; $task_viewer Contextual_Press_ct_element_\[$task_viewer get_mode\] $ct_element %x %y}"
 $canvas bind Drag_zone_$ct_element <ButtonRelease> "if {%b == 1} {$task_viewer set_current_element {} 0 0} else {$task_viewer Contextual_Release_ct_element_\[$task_viewer get_mode\] $ct_element %x %y}"
 
 # Subscribe to events
 $ct_element Subscribe_to_set_state_Undone                 $objName "$objName Update_state"
 $ct_element Subscribe_to_set_state_WIP                    $objName "$objName Update_state"
 $ct_element Subscribe_to_set_state_Done                   $objName "$objName Update_state"
 $ct_element Subscribe_to_set_user_interaction_Unavailable $objName "$objName Update_user_interaction"
 $ct_element Subscribe_to_set_user_interaction_Available   $objName "$objName Update_user_interaction"
 
 # Subscribing to L_children modifications
 if {[lsearch [gmlObject info classes $ct_element] "TaskOperator"] != -1} {
   $ct_element Subscribe_to_Sub_L_children $objName "foreach e \$L {$task_viewer Sub_connection $ct_element \$e}"
   $ct_element Subscribe_to_Add_L_children $objName "foreach e \$L {$task_viewer Add_connection $ct_element \$e}"
   $ct_element Subscribe_to_set_L_children $objName "$task_viewer dispose_children_connections_of $ct_element ; foreach e \$L {$task_viewer Add_connection $ct_element \$e}"
  }
  
 # this Update_presentation
}

#_____________________________________________________________________________________________________________
method CT_viewer dispose {} {
 $this(canvas) delete $objName
 this inherited
}

#_____________________________________________________________________________________________________________
Generate_accessors CT_viewer [list ct_element x y]

#_____________________________________________________________________________________________________________
method CT_viewer get_origine {} {
	return [lrange [$this(canvas) bbox $objName] 0 1]
}

#_____________________________________________________________________________________________________________
method CT_viewer Update_presentation {} {
 set ct_text "[$this(ct_element) attribute nb_time_done] : [$this(ct_element) get_name]"
 if {[$this(ct_element) get_is_optional] || [$this(ct_element) get_is_iterative]} {
   append ct_text "  "
   if {[$this(ct_element) get_is_optional] } {append ct_text " o"}
   if {[$this(ct_element) get_is_iterative]} {append ct_text " *"}
  }
  
 $this(canvas) itemconfigure $this(lab_name) -text $ct_text
 set zoom_factor [$this(task_viewer) attribute zoom_factor]
 
 if {[lsearch [gmlObject info classes $this(ct_element)] "TaskOperator"] != -1} {
   lassign [$this(canvas) bbox $this(lab_name)]  lx1 ly1 lx2 ly2; set lmx [expr ($lx1 + $lx2) / 2]; set lmy [expr ($ly1 + $ly2) / 2]
   lassign [$this(canvas) bbox $this(lab_type)]  tx1 ty1 tx2 ty2; set tmx [expr ($tx1 + $tx2) / 2]; set tmy [expr ($ty1 + $ty2) / 2]
   $this(canvas) move $this(lab_type) [expr $lmx - $tmx] [expr $ly1 - $ty1 + 20 / $zoom_factor]
   lassign [$this(canvas) bbox $this(lab_name) $this(lab_type)] x1 y1 x2 y2
  } else {lassign [$this(canvas) bbox $this(lab_name)] x1 y1 x2 y2
         }
 
 set margin [expr 5 / $zoom_factor]; 
 $this(canvas) coords $this(id_box) [expr $x1 - $margin] [expr $y1 - $margin]  [expr $x2 + $margin] [expr $y2 + $margin]
 
 $this(task_viewer) Update_all_node_connections $this(ct_element)
}

#_____________________________________________________________________________________________________________
method CT_viewer Update_state {} {
 set T_color(Undone) grey
 set T_color(WIP)    yellow
 set T_color(Done)   green
 
 this Update_presentation
 $this(canvas) itemconfigure $this(id_box) -fill $T_color([$this(ct_element) get_state])
}

#_____________________________________________________________________________________________________________
method CT_viewer Update_user_interaction {} {
 if {[$this(ct_element) get_user_interaction] == "Available"} {
   $this(canvas) itemconfigure $this(id_box) -width 3
  } else {$this(canvas) itemconfigure $this(id_box) -width 1
         }
}

#___________________________________________________________________________________________________________________________________________
method CT_viewer Translate {x y} {
 set zoom_factor [$this(task_viewer) attribute zoom_factor]
 set x [expr int($x)]; set y [expr int($y)]
 incr this(x) $x; incr this(y) $y
 $this(canvas) move $objName $x $y
}

#___________________________________________________________________________________________________________________________________________
method CT_viewer Move_to {x y} {
 set x [expr int($x)]; set y [expr int($y)]
 $this(canvas) move $objName [expr $x - $this(x)] [expr $y - $this(y)]
 set this(x) $x; set this(y) $y
}

#___________________________________________________________________________________________________________________________________________
Manage_CallbackList CT_viewer [list Translate Move_to] end

