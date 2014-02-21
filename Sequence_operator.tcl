inherit SequenceOperator TaskOperator

#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
method SequenceOperator constructor {name L_children} {
 this inherited $name ">>" $L_children
 set this(activeChild) 0
 set this(candonesequence) 0
 set this(changing_child_state) 0
}
#___________________________________________________________________________________________________________________________________________
method SequenceOperator child_state_changed {child new_state} {
	this inherited $child $new_state
	set cpt 0
	puts $this(activeChild)
	
	if {$new_state == "Done"} {
		if { [expr [llength [this get_L_children]] - 1] == $this(activeChild) } {
			set this(candonesequence) 1
			puts "fini"
			
			foreach c [this get_L_children] {
				 $c set_user_interaction_Unavailable 
			 }
			
		} else {
			
			foreach c [this get_L_children] {
				 $c set_user_interaction_Unavailable 
			 }
			
			set var [lindex [this get_L_children] $this(activeChild)]
			
			##si avant on a une option on incr activchild	
			while {[$var get_state] == "Undone"} {
				puts $this(activeChild)
				incr this(activeChild)
				set var [lindex [this get_L_children] [expr $this(activeChild)]]
			}
			
			set cpt 0
			
			incr this(activeChild)
			
			#set this(activeChild) {[expr $this(activeChild) + 1 ]}
			
			set var [lindex [this get_L_children] [expr $this(activeChild) + $cpt]]
			$var set_user_interaction_Available
			
			##si option on passe le suivant en dispo
			while {[$var get_is_optional] == 1} {
				incr cpt
				set var [lindex [this get_L_children] [expr $this(activeChild) + $cpt]]
				$var set_user_interaction_Available
			}
			
		}
	}
}

#_____________________________________________________________________________________________________________
method SequenceOperator set_state_WIP    {} {
	this inherited
	#set var [lindex [this get_L_children] 0]
	#$var set_state_WIP
	
	#set var [lindex [this get_L_children] 0]
	#$var set_user_interaction_Available
	#set this(activeChild) 0
	#set this(candonesequence) 0
}

#_____________________________________________________________________________________________________________
method SequenceOperator set_state_Undone {} {
	this inherited
}

#_____________________________________________________________________________________________________________
method SequenceOperator set_state_Done   {{force_done 0}} {
	this inherited $force_done
}

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method SequenceOperator set_user_interaction_Unavailable {} {
	this inherited
}

#_____________________________________________________________________________________________________________
method SequenceOperator set_user_interaction_Available   {} {
	this inherited
	# foreach c [this get_L_children] {
		# $c set_user_interaction_Available
	# }
	
	set var [lindex [this get_L_children] 0]
	$var set_user_interaction_Available
	set this(activeChild) 0
	set this(candonesequence) 0

}

#_____________________________________________________________________________________________________________
method SequenceOperator Can_be_switched_to_Done   {} {
	set rep [this inherited]
	puts $this(candonesequence)
	if {$this(candonesequence) == 1} {
	incr rep
	}
	return $rep
}

