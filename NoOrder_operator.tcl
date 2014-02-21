inherit NoOrderOperator TaskOperator

#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
method NoOrderOperator constructor {name L_children} {
 this inherited $name "|=|" $L_children
 set this(changing_child_state) 0
}

#___________________________________________________________________________________________________________________________________________
method NoOrderOperator child_state_changed {child new_state} {
	this inherited $child $new_state
}

#_____________________________________________________________________________________________________________
method NoOrderOperator set_state_WIP    {} {
	this inherited
}

#_____________________________________________________________________________________________________________
method NoOrderOperator set_state_Undone {} {
	this inherited
}

#_____________________________________________________________________________________________________________
method NoOrderOperator set_state_Done   {{force_done 0}} {
	this inherited $force_done
}

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method NoOrderOperator set_user_interaction_Unavailable {} {
	this inherited
}

#_____________________________________________________________________________________________________________
method NoOrderOperator set_user_interaction_Available   {} {
	this inherited
}

