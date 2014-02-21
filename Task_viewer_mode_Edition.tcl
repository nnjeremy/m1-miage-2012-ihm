#_____________________________________________________________________________________________________________
method Task_viewer Action_press_Edition {b x y} {
 set this(button_pressed) $b
 set this(last_x) $x
 set this(last_y) $y
 
 set this(start_x) $x; set this(start_y) $y
}

#_____________________________________________________________________________________________________________
method Task_viewer Action_release_Edition {x y} {
 if {$this(mode) != "Edition"} {return}
 # puts "$objName Action_release_Edition $x $y"
 lassign $this(last_press) b0 x0 y0
 set id ""
 
 # Had a new C&T element ?
 if {$this(button_pressed) == 1 && $this(current_element) == "" && $this(current_edition_tool) != "" && $x == $this(start_x) && $y == $this(start_y)} {
   lassign $this(current_edition_tool) type CT_class
   switch $type {
     TASK    {set new_task [this get_a_unique_name]
	          Task $new_task $CT_class [list]
			  this Create_nodes_from $new_task; Add_list this(L_root_task) $new_task
			  TK_representation_of_$new_task Move_to $x $y
	         }
	 TASK_OP {set new_task_op [this get_a_unique_name]
	          $CT_class $new_task_op "Name" [list]
	          this Create_nodes_from $new_task_op; Add_list this(L_root_task) $new_task_op
			  TK_representation_of_$new_task_op Move_to $x $y
	         }
    }
  }
  
 # Is it a contextual query?
 set this(button_pressed) 0
 if {$this(current_contextual_element) != ""} {
   # What is under <x,y> ?
   set L_id [$this(canvas) find overlapping $x $y $x $y]
   if {[llength $L_id] > 1} {
     set id [lindex $L_id end]
	 if {$id == $this(tk_contextual_connection)} {
	   set id [lindex $L_id end-1]
	  }
    }
   
   catch [list $this(canvas) delete $this(tk_contextual_connection)]; set this(tk_contextual_connection) ""
   
   if {$id != ""} {
	   set ct_start $this(current_contextual_element)
	   set ct_end   [lindex [$this(canvas) gettags $id] 0]
	   set this(current_contextual_element) ""

	   # Check if one is descendant of the other
	   if {[lsearch [$ct_start get_all_descendants] $ct_end] >= 0 || [lsearch [$ct_end get_all_descendants] $ct_start] >= 0}  {
		 if {[$ct_end get_parent] == $ct_start} {
		   $ct_start Sub_L_children $ct_end
		   Add_list this(L_root_task) $ct_end
		  }
		 if {[$ct_start get_parent] == $ct_end} {
		   $ct_end Sub_L_children $ct_start
		   Add_list this(L_root_task) $ct_start
		  }
		} else {if {[$ct_end get_parent] == ""} {
				  if {![catch [list $ct_start Add_L_children $ct_end] err]} {Sub_list this(L_root_task) $ct_end}
				 }
			   }
	}
  }
}

#_____________________________________________________________________________________________________________
method Task_viewer Contextual_move_Edition {b x y} {
 if {$this(mode) != "Edition"} {return}
 if {$this(current_contextual_element) != ""} {
   # Draw connection
   if {$this(tk_contextual_connection) < 0} {
     set this(tk_contextual_connection) [$this(canvas) create line $x $y $x $y]
	} else {lassign $this(last_press) b0 x0 y0
	        $this(canvas) coords $this(tk_contextual_connection) $x0 $y0 $x $y
	       }
  }
}

#_____________________________________________________________________________________________________________
method Task_viewer Contextual_Press_ct_element_Edition {ct_element x y} {
 if {$this(mode) != "Edition"} {return}
 # Register the position, so that we can decide if a connection has to be drawn or if a contextual menu has to be displayed
 set this(last_contextual_press) [list $ct_element $x $y]
}

#_____________________________________________________________________________________________________________
method Task_viewer Contextual_Release_ct_element_Edition {ct_element x y} {
 if {$this(mode) != "Edition"} {return}
 # puts "$objName Contextual_Release_ct_element_Edition $x $y"
 if {$this(last_contextual_press) == "$ct_element $x $y"} {
   set m ._${objName}_Contextual_menu
   if {![winfo exists $m]} {menu $m} else {$m delete 0 end}
     
   $m add command -label "Edit" -command "$objName Edit_ct_element $ct_element $x $y"
   $m add separator
   if {[$ct_element get_is_iterative]} {set str "Non iterative"} else {set str "Iterative"}
   $m add command -label $str -command "$ct_element set_is_iterative \[expr 1 - \[$ct_element get_is_iterative\]\]; TK_representation_of_$ct_element Update_presentation"
   if {[$ct_element get_is_optional]} {set str "Non optional"} else {set str "Optional"}
   $m add command -label $str -command "$ct_element set_is_optional \[expr 1 - \[$ct_element get_is_optional\]\]; TK_representation_of_$ct_element Update_presentation"
   $m add separator
   $m add command -label "Delete" -command "$ct_element dispose"
 
   tk_popup $m [expr $x + [winfo rootx $this(canvas)]] [expr $y + [winfo rooty $this(canvas)]]
  }
}

#_____________________________________________________________________________________________________________
method Task_viewer Edit_ct_element {ct_element x y} {
 if {$this(mode) != "Edition"} {return}
 set fen ._${objName}_fen_edit_node_$ct_element
 toplevel $fen
 set frame_name $fen.frame_name; frame $frame_name; pack $frame_name -side top -fill x -expand 1
   set lab_name   $frame_name.lab; label $lab_name   -text "Name : "; pack $lab_name -side left -expand 0 -fill none
   set entry_name $frame_name.entry; entry $entry_name; $entry_name insert 0 [$ct_element get_name]; pack $entry_name -side left -fill x -expand 1
 
 set cmd_ok "$ct_element set_name \[$entry_name get\]"
 
 if {[lsearch [gmlObject info classes $ct_element] TaskOperator] >= 0} {
   set frame_type_op_name $fen.frame_type; frame $frame_type_op_name; pack $frame_type_op_name -side top -fill x -expand 1
     set lab_op $frame_type_op_name.lab; label $lab_op -text "Type of the operator"; pack $lab_op -side left -expand 0 -fill none;
	 set opt_menu $frame_type_op_name.opt; 
	 eval "tk_optionMenu $opt_menu ${objName}_type_opt_menu [gmlObject info specializations TaskOperator]"
	   global ${objName}_type_opt_menu
	   set ${objName}_type_opt_menu [lindex [gmlObject info classes $ct_element] 0]
	 pack $opt_menu -side left -expand 1 -fill x
	 append cmd_ok "; global ${objName}_type_opt_menu; $objName Substitute_CT_op_by_type $ct_element \$${objName}_type_opt_menu"
  }
  
 set frame_bt $fen.frame_bt; frame $frame_bt; pack $frame_bt -side right -fill none -expand 0
   append cmd_ok "; TK_representation_of_$ct_element Update_presentation; destroy $fen"
   set bt_ok $frame_bt._OK; button $bt_ok -text "Validate" -command $cmd_ok
     pack $bt_ok -side left
   set bt_ca $frame_bt._CA; button $bt_ca -text "Cancel"   -command "destroy $fen"
     pack $bt_ca -side left
	 
 wm attribute $fen -topmost 1
   incr x [winfo rootx $this(canvas)]
   incr y [winfo rooty $this(canvas)]
 after 10 "lassign \[split \[wm geometry $fen\] +\] size; wm geometry $fen \${size}+$x+$y; puts Done"
}

#_____________________________________________________________________________________________________________
method Task_viewer Substitute_CT_op_by_type {ct_element type} {
 if {[lindex [gmlObject info classes $ct_element] 0] != $type} {
   set name [$ct_element get_name]
   set x [TK_representation_of_$ct_element get_x]
   set y [TK_representation_of_$ct_element get_y]
   set parent [$ct_element get_parent]
   set L_children [$ct_element get_L_children]
   $ct_element dispose
   
   $type $ct_element $name [list]
     this Create_nodes_from $ct_element; Add_list this(L_root_task) $ct_element
	 TK_representation_of_$ct_element Move_to $x $y
   if {$parent != ""}    {$parent Add_L_children $ct_element}
   foreach c $L_children {$ct_element Add_L_children $c}
  }
}
