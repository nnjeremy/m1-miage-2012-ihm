inherit NoOrderOperator TaskOperator

#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
method NoOrderOperator constructor {name L_children} {
 this inherited $name "|=|" $L_children
 set this(changing_child_state) 0
 set this(Liste_child_done) [list]
 set this(candonesequence) 0
 set this(activeChild) 0
}

#___________________________________________________________________________________________________________________________________________
method NoOrderOperator child_state_changed {child new_state} {
	this inherited $child $new_state
	
	set this(activeChild) $child

	if {$new_state == "WIP"} {
		if {[this get_state] == "Undone"} {
			this set_state_WIP
		}
	   
		foreach c [this get_L_children] {
			if { $c != $child } {
		 		$c set_user_interaction_Unavailable
			}
		}
	 }
	 
	 if {$new_state == "Done"} {
		if {[this get_state] == "Undone"} {
			this set_state_WIP
		}
	 
	 	this AddListIfNotAdded $child
		
		foreach c [this get_L_children] {
			$c set_user_interaction_Unavailable
		}
		
		this SetChilOKAvailable
		
		if {([this NeedForDone] <= [this NbListMinDone])} {
			set this(candonesequence) 1
			
			if {[this CanAutoSetDone] == 1} {
				this set_state_Done
			}
		}
	 }	
}

#_____________________________________________________________________________________________________________
#Retourne le nombre de Fils Min qui doivent être Done pour Done le père
method NoOrderOperator NeedForDone	{} {
	set cpt 0
	
		foreach c [this get_L_children] {
			if {([$c get_is_optional] != 1)} {
				incr cpt
			}
		}
		
	return $cpt
}

#_____________________________________________________________________________________________________________
#Retourne le nombre de Fils Min qui doivent être Done pour Done le père
method NoOrderOperator CanAutoSetDone	{} {
	set auto 1
	
		foreach c [this get_L_children] {
			if {([$c get_is_optional] == 1) && ([$c get_state] != "Done")} {
				set auto 0
			}
		}
		
		foreach c [this get_L_children] {
			if {([$c get_is_iterative] == 1) && (([$c get_state] != "Done") || ($this(activeChild) == $c))} {
				set auto 0
			}
		}
		
	return $auto
}

#_____________________________________________________________________________________________________________
#Retourne le nombre de fils done parmis ceux qui sont obligatoires
method NoOrderOperator NbListMinDone	{} {
	set cpt 0
	
		foreach c $this(Liste_child_done) {
			if {([$c get_is_optional] != 1)} {
				incr cpt
			}
		}
		
	return $cpt
}

#_____________________________________________________________________________________________________________
#Ajoute le fils en param a la liste des fils deja DOne
method NoOrderOperator AddListIfNotAdded	{child} {
	set chilFound 0

	foreach e $this(Liste_child_done) {
		if {$e == $child} {
			set chilFound 1
		}
	}
	
	if { $chilFound == 0 } {
		lappend this(Liste_child_done) $child
	}
}

#_____________________________________________________________________________________________________________
#Passe les fils qui peuvent etre available à l'etat available
method NoOrderOperator SetChilOKAvailable	{} {
	 	foreach c [this get_L_children] {
			set chilFound 0
		
			foreach e $this(Liste_child_done) {
				if {$e == $c} {
					set chilFound 1
				}
			}
			
	 		if { $chilFound == 0 } {
	 			$c set_user_interaction_Available
	 		}
	 	}
		
		foreach c [this get_L_children] {
			if {([$c get_is_iterative] == 1) && ($this(activeChild) == $c)} {
		 		$c set_user_interaction_Available
			}
		}
}

#_____________________________________________________________________________________________________________
#affiche la liste des element de la liste des fils Done
method NoOrderOperator AfficherListe	{} {
	puts ---AfficherListe---
		foreach e $this(Liste_child_done) {
		  puts $e
		}
	puts -------------------
}

#_____________________________________________________________________________________________________________
method NoOrderOperator set_state_WIP    {} {
	this inherited
	
	if {$this(candonesequence) == 1} {
		set this(candonesequence) 0
		
		foreach c [this get_L_children] {
				$c set_state_Undone
		}
		
		this SetChilOKAvailable
	}
}

#_____________________________________________________________________________________________________________
method NoOrderOperator set_state_Undone {} {
	this inherited
	
		foreach c [this get_L_children] {
				$c set_state_Undone
		}
}

#_____________________________________________________________________________________________________________
method NoOrderOperator set_state_Done   {{force_done 0}} {
	this inherited $force_done
	
	foreach c [this get_L_children] {
			$c set_user_interaction_Unavailable
	}
	
	set this(Liste_child_done) [list]
	
	if {([this get_is_iterative] != 1)} {
		this set_user_interaction_Unavailable
	}
}

#_____________________________________________________________________________________________________________
method NoOrderOperator set_user_interaction_Unavailable {} {
	this inherited
	
	foreach c [this get_L_children] {
			$c set_user_interaction_Unavailable
	}
}

#_____________________________________________________________________________________________________________
method NoOrderOperator set_user_interaction_Available   {} {
	this inherited
	
	#set this(candonesequence) 0
	
	 set this(Liste_child_done) [list]
	
	foreach c [this get_L_children] {
			$c set_user_interaction_Available
	}
}

#_____________________________________________________________________________________________________________
method NoOrderOperator Can_be_switched_to_Done   {} {
	set rep [this inherited]
	##puts $this(candonesequence)
	if {$this(candonesequence) == 1} {
	incr rep
	}
	return $rep
}