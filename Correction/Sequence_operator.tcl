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
	#this set_state_WIP
	set cpt 0
	##puts $this(activeChild)
	
	if {$new_state == "Done"} {
	if {[this get_state] != "WIP"} {
		this set_state_WIP
	}
	##puts $this(activeChild)
		if { [expr [llength [this get_L_children]] - 1] == $this(activeChild) } {
			set this(candonesequence) 1
			
			if {([[lindex [this get_L_children] $this(activeChild)] get_is_iterative] != 1)} {
				this set_state_Done
				if {([this get_is_iterative] != 1)} {
					this set_user_interaction_Unavailable
				}
			}
			
			foreach c [this get_L_children] {
				if {([$c get_is_iterative] != 1)} {
					$c set_user_interaction_Unavailable 
				}
			 }
			 

			
		} else {
		##puts $this(activeChild)
			
			foreach c [this get_L_children] {
				 $c set_user_interaction_Unavailable 
			 }
			
			set var [lindex [this get_L_children] $this(activeChild)]
			
			##si avant on a une option on incr activchild	
			while {$var != $child} {
				##puts $this(activeChild)
				incr this(activeChild)

				if { [expr [llength [this get_L_children]] - 1] == $this(activeChild) } {
					break
				} else {
					#puts $this(activeChild)
					set var [lindex [this get_L_children] [expr $this(activeChild)]]
				}
			}
			##puts $this(activeChild)
			set cpt 0
			
			if { [expr [llength [this get_L_children]] - 1] != $this(activeChild) } {
				if {([$var get_is_iterative] != 1)} {
					incr this(activeChild)
				} else {
					$var set_user_interaction_Available
					incr cpt
				}
				
				#set this(activeChild) {[expr $this(activeChild) + 1 ]}
				
				set var [lindex [this get_L_children] [expr $this(activeChild) + $cpt]]
				$var set_user_interaction_Available
				
				
				##si option on passe le suivant en dispo
				while {([$var get_is_optional] == 1)} {
					if { [expr [llength [this get_L_children]] - 1] == [expr $this(activeChild) + $cpt] } {
						break
					} else {
						incr cpt
						set var [lindex [this get_L_children] [expr $this(activeChild) + $cpt]]
						$var set_user_interaction_Available

					}
				}
				
			} else {
						set this(candonesequence) 1
						
						if {([[lindex [this get_L_children] $this(activeChild)] get_is_iterative] != 1)} {
							this set_state_Done
							if {([this get_is_iterative] != 1)} {
								this set_user_interaction_Unavailable
							}
						}
						
						foreach c [this get_L_children] {
							if {([$c get_is_iterative] != 1)} {
								$c set_user_interaction_Unavailable 
							}
						 }
						 
						 set this(activeChild) 0
			}
			
		}
	}
	
	if {$new_state == "WIP"} {
	 this set_state_WIP
	 #puts wip
	
	 set var [lindex [this get_L_children] $this(activeChild)]
	set trouverNewActif 0
	set trouverNewActifTrouve 0
			
	 	foreach c [this get_L_children] {
			if {$var != $c} {
	 			$c set_user_interaction_Unavailable
			}
			
			if {$c != $child && $trouverNewActifTrouve == 0} {
				incr trouverNewActif
				$c set_user_interaction_Unavailable
			} else {
				incr trouverNewActifTrouve
				$c set_user_interaction_Available
			}
	 	}
		
		set this(activeChild) $trouverNewActif
		
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
	
	if {$this(activeChild) == 0} {
		set var [lindex [this get_L_children] 0]
		##puts $var
		$var set_user_interaction_Available
		
		set var [lindex [this get_L_children] $this(activeChild)]
		set cpt 0
		##si option on passe le suivant en dispo
		while {([$var get_is_optional] == 1)} {
			if { [expr [llength [this get_L_children]] - 1] == [expr $this(activeChild) + $cpt] } {
				break
			} else {
				incr cpt
				set var [lindex [this get_L_children] [expr $this(activeChild) + $cpt]]
				$var set_user_interaction_Available

			}
		}
	}
}

#_____________________________________________________________________________________________________________
method SequenceOperator set_state_Undone {} {
	this inherited
	
	 	foreach c [this get_L_children] {
	 			$c set_state_Undone
	 	}
}

#_____________________________________________________________________________________________________________
method SequenceOperator set_state_Done   {{force_done 0}} {
	this inherited $force_done
	
	if {([this get_is_iterative] == 1)} {
	 	foreach c [this get_L_children] {
				$c set_user_interaction_Unavailable
	 			$c set_state_Undone
	 	}
	} else {
		foreach c [this get_L_children] {
			$c set_user_interaction_Unavailable
		}
		
		this set_user_interaction_Unavailable
	}
}

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method SequenceOperator set_user_interaction_Unavailable {} {
	this inherited
	
		 	foreach c [this get_L_children] {
	 			$c set_user_interaction_Unavailable
			}
}

#_____________________________________________________________________________________________________________
method SequenceOperator set_user_interaction_Available   {} {
	this inherited
	# foreach c [this get_L_children] {
		# $c set_user_interaction_Available
	# }
	
		if {([this get_is_iterative] == 1)} {
			foreach c [this get_L_children] {
					$c set_state_Undone
			}
		}
		
		set var [lindex [this get_L_children] $this(activeChild)]
		set cpt 0
		##si option on passe le suivant en dispo
		while {([$var get_is_optional] == 1)} {
			if { [expr [llength [this get_L_children]] - 1] == [expr $this(activeChild) + $cpt] } {
				break
			} else {
				incr cpt
				set var [lindex [this get_L_children] [expr $this(activeChild) + $cpt]]
				$var set_user_interaction_Available

			}
		}
	
	set var [lindex [this get_L_children] 0]
	$var set_user_interaction_Available
	set this(activeChild) 0
	set this(candonesequence) 0

}

#_____________________________________________________________________________________________________________
method SequenceOperator Can_be_switched_to_Done   {} {
	set rep [this inherited]
	##puts $this(candonesequence)
	if {$this(candonesequence) == 1} {
	incr rep
	}
	return $rep
}

