inherit InterleavingOperator TaskOperator

#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
method InterleavingOperator constructor {name L_children} {
 this inherited $name "|||" $L_children
 set this(changing_child_state) 0
 set this(Liste_child_done) [list]
 set this(candonesequence) 0
}

#___________________________________________________________________________________________________________________________________________
method InterleavingOperator child_state_changed {child new_state} {
	this inherited $child $new_state

	if {$new_state == "WIP"} {
            if {[this get_state] != "WIP"} {
                this set_state_WIP
            }
	 } elseif {$new_state == "Done"} {
            if {[this get_state] != "WIP"} {
                this set_state_WIP
            }
            if {[$child get_is_iterative] == 0} {
                $child set_user_interaction_Unavailable
            }
            set ttdone 0
            foreach c $this(L_children) {
                if {[$c get_state] != "Done" || [$c get_is_iterative] == 1} {
                    set ttdone 1
                }
            }
            if {$ttdone == 0} {
                this switch_to_Done
            }
	 }	
}

#_____________________________________________________________________________________________________________
method InterleavingOperator set_state_WIP    {} {
	this inherited
	
        foreach c $this(L_children) {
            $c set_user_interaction_Available
            if {[$c get_state] == "Done" && [this get_is_iterative] == 1} {
                $c set_state_Undone
            }
	}
}

#_____________________________________________________________________________________________________________
method InterleavingOperator set_state_Undone {} {
	this inherited

        foreach c [this get_L_children] {
            $c set_state_Undone
	}
}

#_____________________________________________________________________________________________________________
method InterleavingOperator set_state_Done   {{force_done 0}} {
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
method InterleavingOperator set_user_interaction_Unavailable {} {
	this inherited
	
	foreach c [this get_L_children] {
            $c set_user_interaction_Unavailable
	}
}

#_____________________________________________________________________________________________________________
method InterleavingOperator set_user_interaction_Available   {} {
	this inherited
	
        foreach c [this get_L_children] {
            $c set_user_interaction_Available
	}

        #Hors sujet -> algo pour sequence
        #set var [lindex [this get_L_children] 0]
        #$var set_user_interaction_Available
        #while {[$var get_is_optional] == 1} {
        #    set $var [lindex [this get_L_children_after $var] 0]
        #    $var set_user_interaction_Available
        #}
}

#_____________________________________________________________________________________________________________
method InterleavingOperator Can_be_switched_to_Done   {} {
	set rep [this inherited]
        set var 0
	if {$rep == 0} {
            foreach c $this(L_children) {
                if {[$c get_is_optional] == 0 && [$c get_state] != "Done"} {
                    set var 7
                }
            }
            if {$var == 0} {
                set rep 1
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