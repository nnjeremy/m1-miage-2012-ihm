inherit ChoiceOperator TaskOperator

#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
method ChoiceOperator constructor {name L_children} {
	this inherited $name "\[ \]" $L_children
	set this(changing_child_state) 0
	set this(L_children) $L_children 
}

#___________________________________________________________________________________________________________________________________________
method ChoiceOperator child_state_changed {child new_state} {
	this inherited $child $new_state			
	if { $new_state == "WIP" } {
		if {[this get_state] != "WIP"} {
                    this set_state_WIP
                }
		foreach c $this(L_children) {
			if {$child != $c} {
				$c set_user_interaction_Unavailable	
			}
		}
	}	
	if {$new_state == "Done"} {
		if {[$child get_is_iterative] == 0} {
			this switch_to_Done
		} elseif {[this get_state] != "WIP"} {
			this set_state_WIP
		}
	}		
}

#_____________________________________________________________________________________________________________
method ChoiceOperator set_state_WIP    {} {
	this inherited
		if {[this get_is_iterative] == 1} {
                    foreach c $this(L_children) {
                        $c set_user_interaction_Available
                        if {[$c get_state] == "Done"} {
                            $c set_state_Undone
                        }
		   }
                }
}

#_____________________________________________________________________________________________________________
method ChoiceOperator set_state_Undone {} {
	this inherited
	foreach c $this(L_children) {
		$c set_state_Undone
	}
}

#_____________________________________________________________________________________________________________
method ChoiceOperator set_state_Done   {{force_done 0}} {
	this inherited $force_done
	foreach c $this(L_children) {
		$c set_user_interaction_Unavailable
	}
        if {[this get_is_iterative] == 0} {
            this set_user_interaction_Unavailable
        }
}

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method ChoiceOperator set_user_interaction_Unavailable {} {
	this inherited
	foreach c $this(L_children) {
		$c set_user_interaction_Unavailable	
	}
}

#_____________________________________________________________________________________________________________
method ChoiceOperator set_user_interaction_Available   {} {
	this inherited
	foreach c $this(L_children) {
		$c set_user_interaction_Available	
	}
}

#_____________________________________________________________________________________________________________
method ChoiceOperator Can_be_switched_to_Done	{} {
	set rep [this inherited]
	if {$rep == 0} {
		foreach c $this(L_children) {
			if {[$c get_state] == "Done"} {
				set rep 1
			}
		}
		if {[this get_state] == "Done" && [this get_is_iterative] == 0} {
			set rep 2
		}
	} else {
		if {[this get_is_iterative] == 1} {
			set rep 3
		}
	}
	return $rep
}

