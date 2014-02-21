#_____________________________________________________________________________________________________________
method Task_viewer Action_press_Simulation {b x y} {
 set this(button_pressed) $b
 set this(last_x) $x
 set this(last_y) $y
 
 set this(start_x) $x; set this(start_y) $y
}

#_____________________________________________________________________________________________________________
method Task_viewer Action_release_Simulation {x y} {
 lassign $this(last_press) b0 x0 y0
 set id ""
 
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

   return
 
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
		} else {if {![catch [list $ct_start Add_L_children $ct_end] err]} {
		          Sub_list this(L_root_task) $ct_end
				 }
			   }
	}
  }
}

#_____________________________________________________________________________________________________________
method Task_viewer Contextual_move_Simulation {b x y} {}

#_____________________________________________________________________________________________________________
method Task_viewer Contextual_Press_ct_element_Simulation {ct_element x y} {
 # Register the position, so that we can decide if a connection has to be drawn or if a contextual menu has to be displayed
 set this(last_contextual_press) [list $ct_element $x $y]
}

#_____________________________________________________________________________________________________________
method Task_viewer Contextual_Release_ct_element_Simulation {ct_element x y} {
 # puts "$objName Contextual_Release_ct_element_Simulation"
 if {$this(last_contextual_press) == "$ct_element $x $y" && [$ct_element get_user_interaction] == "Available"} {
   set m ._${objName}_Contextual_menu
   if {![winfo exists $m]} {menu $m} else {$m delete 0 end}
     
   foreach state [list Undone WIP Done] {
     if {[$ct_element get_state] != $state} {$m add command -label $state -command "$ct_element set_state_$state; $objName Push_trace \[list ACTION {} $ct_element set_state_$state\]"}
    }
   # if {[$ct_element get_is_iterative] && [$ct_element get_state] == "Done"} {$m add command -label "Done" -command "$ct_element set_state_Done; $objName Push_trace \[list ACTION {} $ct_element set_state_Done\]"}
   tk_popup $m [expr $x + [winfo rootx $this(canvas)]] [expr $y + [winfo rooty $this(canvas)]]
  }
}
