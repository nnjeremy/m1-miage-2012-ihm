#_________________________________________________________________________________________________________
proc Generate_accessors {class_name L_vars} {
 foreach v $L_vars {
   set    cmd "method $class_name get_$v \{ \} \{"
   append cmd {return $this(} $v ")\}"
     eval $cmd
   set    cmd "method $class_name set_$v \{v\} \{"
   append cmd {set this(} $v ") \$v\}"
     eval $cmd
  }
}


#____________________________________________________________________________________
proc Generate_List_accessor {class L_name suffixe} {
 set cmd "method $class get_$suffixe { } {return \$this($L_name)}"                  ; eval $cmd
 set cmd "method $class set_$suffixe {L} {set this($L_name) \$L}"                   ; eval $cmd
 set cmd "method $class Add_$suffixe {L} {set this($L_name) \[Liste_Union \$this($L_name) \$L\]}"           ; eval $cmd
 set cmd "method $class Sub_$suffixe {L} {Sub_list this($L_name) \$L}"; eval $cmd
 set cmd "method $class Contains_${suffixe} {e} {return \[expr \[lsearch \$this($L_name) \$e\] >= 0\]}"; eval $cmd
 set cmd "method $class Index_of_${suffixe} {e} {return \[lsearch \$this($L_name) \$e\]}"; eval $cmd
}

#_________________________________________________________________________________________________________
proc Inject_code {C mtd code_bgn code_end {mark {INJECTED_CODE}}} {
 set original_body [gmlObject info body $C $mtd];
 set pipo PIPO_Inject_code_$C$mtd
 method $C $mtd [gmlObject info arglist $C $mtd] $pipo
 
 set res [Add_aspect $C $mtd ${mark}_BEGIN $code_bgn begin]
 if {$res != ""} {
   set body [string map [list $pipo ""] $res]
   set res2 [Add_aspect $C $mtd ${mark}_END   $code_end end 0]
   set body $body$res2
   puts $body
  } else {Add_aspect $C $mtd ${mark}_END   $code_end end
          set body [gmlObject info body $C $mtd]
		 }
  
 method $C $mtd [gmlObject info arglist $C $mtd] [string map [list $pipo $original_body] $body]
}

#_________________________________________________________________________________________________________
proc Add_aspect {c m mark code {position begin} {do_eval 1}} {
 # Get the existing body
 set body [gmlObject info body $c $m]
 
 # Inject code into the body
 set bgn_mark "# <${mark}>"
 set end_mark "# </${mark}>"
 if {[regexp "^(.*)${bgn_mark}\n.*${end_mark}\n(.*)\$" $body reco bgn end]} {
   set body "$bgn$bgn_mark\n$code\n$end_mark\n$end"
  } else {if {$position == "begin"} {
            set body "$bgn_mark\n$code\n$end_mark\n$body"
		   } else {set body "$body\n$bgn_mark\n$code\n$end_mark"}	
		 }

 # Enter the new body into the TCL interpretor by building the command
 set   cmd "method $c $m {[gmlObject info arglist $c $m]} {\n$body}"
 
 if {$do_eval} {
	 if {[catch {eval $cmd} err]} {
	   return $body
	  }
	return ""
  } else {return $body}
}

#_________________________________________________________________________________________________________
proc Manage_CallbackList {c L_m pos args} {
 set L_varL_to_declare_in_constr [list]
 foreach m $L_m {
# Init the callback mechanism
   set body   [gmlObject info body    $c $m]
   set L_args [gmlObject info arglist $c $m]
   set argL   [gmlObject info args    $c $m]

   set L_CB_name "this\(L_CB_$m\)"
   lappend L_varL_to_declare_in_constr $L_CB_name
   set cmd "method $c Trigger_L_CB_$m \{L_CB args\} \{\n"
     append cmd " foreach CB \[subst \$\$L_CB\] \{\n"
     append cmd "   eval \""
       set p 0; foreach a $argL {append cmd "set $a \{\[lindex \$args $p\]\}; "; incr p}
                foreach a $args {append cmd "set $a \{\[lindex \$args $p\]\}; "; incr p}
     append cmd "\[lindex \$CB 1\]\"\n"
     append cmd "  \}\n"
   append cmd "\}\n"
   eval $cmd
# Generate the callback accessors
   eval "Generate_accessors $c L_CB_$m"
# Generate the callback accessors for subscribing
   set cmd "method $c Subscribe_to_$m \{id CB \{UNIQUE \{\}\}\} \{\n"
     append cmd " if \{\[string equal \$UNIQUE \{\}\]\} \{\} else \{\n"
     append cmd "   set L \{\}\n"
     append cmd "   foreach CB_current \$$L_CB_name \{\n"
     append cmd "     if \{\[string equal \$id \[lindex \$CB_current 0\]\]\} \{\} else \{lappend L \$CB_current\}\n"
     append cmd "    \}\n"
     append cmd "   set $L_CB_name \$L\n"
     append cmd "  \}\n"
     append cmd " lappend $L_CB_name \[list \$id \$CB\];\n"
   append cmd "\}\n"
   eval $cmd
# Generate the callback accessors for unsubscribing
   set cmd "method $c UnSubscribe_to_$m \{id\} \{\n"
     append cmd " set L \{\}\n"
     append cmd " foreach CB \$$L_CB_name \{\n"
     append cmd "   if \{\[string equal \$id \[lindex \$CB 0\]\]\} \{\} else \{lappend L \$CB\}\n"
     append cmd "  \}\n"
     append cmd " set $L_CB_name \$L;\n"
   append cmd "\}\n"
   eval $cmd
# Generate the callback mechanism
   set    cmd_to_trigger "  foreach CB \$this(L_CB_$m) {\n"
   append cmd_to_trigger "    if {\[catch \[lindex \$CB 1\] err\]} {puts \"Error in CallBack for $m\\n  \$err\"}\n"
   append cmd_to_trigger "   }\n"
   set cmd "method $c $m \{$L_args\} \{\n"
     if {[regexp "(.*)# INSERT CALLBACKS HERE(.*)" $body rep avant apres]} {
       append cmd $avant {# INSERT CALLBACKS HERE} "\n"
	   append cmd $cmd_to_trigger
       #append cmd " this Trigger_L_CB_$m $L_CB_name"
       #  foreach a $argL {append cmd " \$$a"}
       #  foreach a $args {append cmd " \$$a"}
       append cmd "\n" $apres
      } else {switch $pos {
                begin {append cmd $cmd_to_trigger
				       #append cmd " this Trigger_L_CB_$m $L_CB_name"
                       #  foreach a $argL {append cmd " \$$a"}
                       #  foreach a $args {append cmd " \$$a"}
                       append cmd "\n" $body "\n"
                      }
                end   {append cmd $body "\n"
                       append cmd $cmd_to_trigger
					   #append cmd " this Trigger_L_CB_$m $L_CB_name"
                       #  foreach a $argL {append cmd " \$$a"}
                       #  foreach a $args {append cmd " \$$a"}
                       append cmd "\n"
                      }
               }
             }
   append cmd "\}\n"
   eval $cmd
  }

# Add initialisation of lists of callbacks in the constructor
 set old_body [gmlObject info body    $c constructor]
 set argL [gmlObject info arglist $c constructor]
 set body "\n#___________________________________\n#Definition of some callback lists |\n#___________________________________\n"
 foreach CB $L_varL_to_declare_in_constr {
   append body " set $CB \[list\]\n"
  }
 append body $old_body

 set cmd "method $c constructor \{$argL\} \{\n"
   append cmd $body
 append cmd "\}\n"
 eval $cmd
}

#____________________________________________________________________________________
proc Is_prefixe {L1 L2} {
 set rep [string compare -length [string length $L1] $L1 $L2]
 return [expr $rep == 0]
}

#____________________________________________________________________________________
proc Is_sub_list {L1 L2} {
 set rep 1
 foreach e1 $L1 {
   if {[lsearch $L2 $e1] == -1} {set rep 0; break}
  }
 return $rep
}

#____________________________________________________________________________________
proc Liste_to_set {L} {
 set rep [list]
 foreach e $L {
   if {[lsearch $rep $e] == -1} {
     lappend rep $e
    }
  }
 return $rep
}

#____________________________________________________________________________________
proc Liste_Union {L1 L2} {
 set rep $L1
 foreach e2 $L2 {
   set to_be_added 1
   foreach e1 $L1 {
     if {[string equal $e1 $e2]} {
       set to_be_added 0
       break
      }
    }
   if {$to_be_added} {
     lappend rep $e2
    }
  }
 return $rep
}

#____________________________________________________________________________________
proc Liste_Intersection {L1 L2} {
 set rep [list]

 foreach e1 $L1 {
   if {[lsearch $L2 $e1]!=-1} {lappend rep $e1}
  }

 return $rep 
}

#____________________________________________________________________________________
proc Invert_list {nom_L} {
 upvar $nom_L L
   set L_tmp $L
   set L [list]
 foreach e $L_tmp {
   set L [linsert $L 0 $e]
  }
}

#____________________________________________________________________________________
proc Sub_element {nom_L e} {
 upvar $nom_L L
 set pos [lsearch $L $e]
 if {$pos!=-1} {set L [lreplace $L $pos $pos]
                return 1
               }
 return 0
}
#____________________________________________________________________________________
proc Sub_list {nom_L Le} {
 upvar $nom_L L
 set rep 0
 foreach e $Le {incr rep [Sub_element L $e]}
 return $rep
}

#____________________________________________________________________________________
proc Add_list {nom_L Le {index -1}} {
 upvar $nom_L L
 set rep 0
 if {$index == -1} {
   foreach e $Le {incr rep [Add_element L $e]}
  } else {set pos $index
          foreach e $Le {incr rep [Add_element L $e $pos]
                         incr pos}
         }
 return $rep
}

#____________________________________________________________________________________
proc Add_element {nom_L e {index -1}} {
 upvar $nom_L L
 if {[lsearch $L $e]!=-1} {return 0}

 if {$index==-1} {
   lappend L $e
   return 1}

 set L [linsert $L $index $e]
 return 1
}

#____________________________________________________________________________________
proc Add_element_quick {nom_L e {index -1}} {
 upvar $nom_L L

 if {$index==-1} {
   lappend L $e
   return 1}

 set L [linsert $L $index $e]
 return 1
}
