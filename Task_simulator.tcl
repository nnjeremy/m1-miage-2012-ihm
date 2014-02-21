#_____________________________________________________________________________________________________________
#Programmation gestionnaire d'arbre des tâches

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method CT_element constructor {name} {
 set this(name)             $name 
 set this(state)            "Undone"
 set this(user_interaction) "Unavailable"
 
 set this(is_optional)      0
 set this(is_iterative)     0
 set this(L_decorations)    [list]
 
 set this(nb_time_done)     0
 
 set this(parent)           ""
}

#_____________________________________________________________________________________________________________
method CT_element dispose {} {
 if {$this(parent) != ""} {$this(parent) Sub_L_children [list $objName]}
 this inherited
}

#_____________________________________________________________________________________________________________
Generate_List_accessor CT_element L_decorations L_decorations

#_____________________________________________________________________________________________________________
Generate_accessors CT_element [list name is_optional is_iterative parent]

#_____________________________________________________________________________________________________________
method CT_element get_state  {} {return $this(state) }
method CT_element get_parent {} {return $this(parent)}

#_____________________________________________________________________________________________________________
method CT_element set_state_WIP    {} {if {$this(user_interaction) == "Available"} {set this(state) "WIP" } else {set msg "Error in \"$objName ([this get_name]) CT_element::set_state_WIP\" :\n  The state can not be change if the user has no access (user_interaction is not available)"; puts stderr $msg; error $msg}}
method CT_element set_state_Undone {} {if {$this(state) == "Undone"} {return}; set this(nb_time_done) 0; set this(state) "Undone"}
method CT_element set_state_Done   {} {
	if {$this(user_interaction) == "Available"} {
		 if {$this(nb_time_done) > 0 && ![this get_is_iterative]} {error "$objName can not be done more than one time as it is not iterative"}
		 incr this(nb_time_done)
		 set this(state) "Done"
		} else {error "Error in \"$objName ([this get_name]) CT_element::set_state_Done\" :\n  The state can not be change if the user has no access (user_interaction is not available)"}
	}

#_____________________________________________________________________________________________________________
method CT_element Can_be_switched_to_Done {} {return [expr 2 * ($this(nb_time_done) >= 1)]}

#_____________________________________________________________________________________________________________
Inject_code CT_element set_state_WIP    {} {set p [this get_parent]; if {$p != ""} {$p child_state_changed $objName [this get_state]}}
Inject_code CT_element set_state_Undone {} {set p [this get_parent]; if {$p != ""} {$p child_state_changed $objName [this get_state]}}
Inject_code CT_element set_state_Done   {} {set p [this get_parent]; if {$p != ""} {$p child_state_changed $objName [this get_state]}}

#_____________________________________________________________________________________________________________
method CT_element get_user_interaction {} {return $this(user_interaction)}

#_____________________________________________________________________________________________________________
method CT_element set_user_interaction_Unavailable {} {set this(user_interaction) "Unavailable"}
method CT_element set_user_interaction_Available   {} {set this(user_interaction) "Available"}

#_____________________________________________________________________________________________________________
Manage_CallbackList CT_element [list set_state_Undone set_state_WIP set_state_Done set_user_interaction_Unavailable set_user_interaction_Available] end
Manage_CallbackList CT_element [list dispose] begin

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
inherit Task CT_element
method Task constructor {name L_concepts} {
 this inherited $name
 
 set this(L_concepts) $L_concepts
}

#_____________________________________________________________________________________________________________
Generate_List_accessor Task L_concepts L_concepts

#_____________________________________________________________________________________________________________
method Task switch_to_Done {} {
	incr this(nb_time_done) -1
	this set_state_Done
}
	
#_____________________________________________________________________________________________________________
method Task get_all_descendants {} {
 return [list $objName]
}

#_____________________________________________________________________________________________________________
method Task Serialize_to_xml {str_name {dec {}}} {
 upvar $str_name str

 set real_class [lindex [gmlObject info classes $objName] 0]
 
 append str $dec "<Task CT_class=\"" $real_class "\" id=\"" $objName "\" name=\"" [string map [list "\"" {\"}] [this get_name]] "\" configuration=\"is_optional $this(is_optional) is_iterative $this(is_iterative)\" L_concepts=\"" [string map [list "\"" {\"}] [this get_L_concepts]] "\"></Task>\n"
}

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
inherit TaskOperator CT_element 
method TaskOperator constructor {name type L_children} {
 this inherited $name
 
 set this(type)             $type
 set this(L_children)       [list]
 
 this set_L_children        $L_children
}

#_____________________________________________________________________________________________________________
method TaskOperator dispose {} {
	this set_L_children [list]
	
	this inherited
}

#_____________________________________________________________________________________________________________
Generate_accessors TaskOperator [list type]

#_____________________________________________________________________________________________________________
Generate_List_accessor TaskOperator L_children L_children

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method TaskOperator set_state_Done   {{force_done 0}} {
	if { !$force_done && !(1 & [this Can_be_switched_to_Done]) } {
		 error "$objName can not be set to done, maybe you want to switch it to done...?"
		}
		
	this inherited
}

#_____________________________________________________________________________________________________________
method TaskOperator switch_to_Done {} {
	if { !(1 & [this Can_be_switched_to_Done]) } {
		 incr this(nb_time_done) -1
		 set force 1
		} else {set force 0}
	this set_state_Done $force
}

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method TaskOperator get_L_children_after {c} {
 set pos [lsearch $this(L_children) $c]
 if {$pos >= 0} {
   incr pos
   return [lrange $this(L_children) $pos end]
  } else {return {}}
}

#_____________________________________________________________________________________________________________
method TaskOperator get_L_children_before {c} {
 set pos [lsearch $this(L_children) $c]
 if {$pos >= 0} {
   incr pos -1
   return [lrange $this(L_children) 0 $pos]
  } else {return {}}
}

#_____________________________________________________________________________________________________________
method TaskOperator Serialize_to_xml {str_name {dec {}}} {
 upvar $str_name str
 
 set real_class [lindex [gmlObject info classes $objName] 0]
 
 append str $dec "<Task_operator CT_class=\"$real_class\" id=\"$objName\" name=\"" [string map [list "\"" {\"}] [this get_name]] "\" configuration=\"is_optional $this(is_optional) is_iterative $this(is_iterative)\">\n"
   foreach ct [this get_L_children] {
     $ct Serialize_to_xml str "$dec  "
    }
 append str $dec "</Task_operator>\n"
}

#_____________________________________________________________________________________________________________
method TaskOperator get_all_descendants {} {
 set L_rep [list $objName]
 
 foreach c [this get_L_children] {set L_rep [concat $L_rep [$c get_all_descendants]]}
 
 return $L_rep
}

#_____________________________________________________________________________________________________________
method TaskOperator child_state_changed {child new_state} {
 # What to do with the state of $objName when child $child set his state to $new_state ?"
}
Manage_CallbackList TaskOperator [list child_state_changed] end

#_____________________________________________________________________________________________________________
Inject_code TaskOperator Add_L_children {} {
 foreach c $L {$c set_parent $objName}
}

#_____________________________________________________________________________________________________________
Inject_code TaskOperator Sub_L_children {} {
 foreach c $L {$c set_parent ""}
}

#_____________________________________________________________________________________________________________
Inject_code TaskOperator set_L_children {
 foreach c [this get_L_children] {$c set_parent ""}
} {
 foreach c [this get_L_children] {$c set_parent $objName}
}

#_____________________________________________________________________________________________________________
Manage_CallbackList TaskOperator [list Add_L_children Sub_L_children set_L_children] begin
