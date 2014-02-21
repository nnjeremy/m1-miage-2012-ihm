package require tdom

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method Task_viewer constructor {{root_task {}}} {
 # Set mode
 set this(mode)           "Edition"
 set this(last_press)     [list 0 0 0]
 set this(button_pressed) 0
 set this(last_contextual_press) [list 0 0 0]
 set this(current_contextual_element) ""
 set this(tk_contextual_connection) -1

 set this(current_edition_tool) ""
 
 set this(u_id) 0
 
 set this(do_not_delete_traces) 0
 set this(last_trace_index) end
 
 # Tasks
 set this(L_root_task) $root_task
 set this(current_task_selected) ""
 
 # Traces
 set this(expected_result) ""
 set this(L_traces) ${objName}_L_traces
 global $this(L_traces)
 set $this(L_traces) [list]
 
 set this(test_result) ""
 
 set this(simulation_palette) ._{objName}_TK_simulation_palette
 
 # Assertions
 global ${objName}_assert_type             ; set ${objName}_assert_type              "Availability"
 global ${objName}_assert_availability_bool; set ${objName}_assert_availability_bool 0
 global ${objName}_assert_state_type_bool  ; set ${objName}_assert_state_type_bool   0
 
 # Informations about C&T constructor (to be used when loading or adding C&T elements)
 set this(cmd_constructor,Task)          {$CT_class $id $name $L_concepts}
 set this(cmd_constructor,Task_operator) {$CT_class $id $name $L_children}

 # TK elements
 set this(top_win)      ._${objName}_TK_top_win     ; toplevel $this(top_win); wm title $this(top_win) "Concepts and Tasks models manager"
   set this(menu)         $this(top_win).menu        ; menu     $this(menu) -tearoff 0
     $this(menu) add cascade -menu $this(menu)._File -label "File"
	   menu $this(menu)._File
       $this(top_win) configure -menu $this(menu)
	   $this(menu)._File add command -label "New task tree"  -command "$objName New_task_tree"
	   $this(menu)._File add command -label "Load task tree" -command "$objName Load_file"
	   $this(menu)._File add command -label "Save task tree" -command "$objName Save_file"
	   $this(menu)._File add separator
	   $this(menu)._File add command -label "Reload operators from directory" -command "$objName Reload_operators"
	   $this(menu)._File add separator
	   $this(menu)._File add command -label "Load test file" -command "$objName Test"
	   $this(menu)._File add command -label "Send to test server" -command "$objName ServerTest"
     $this(menu) add cascade -menu $this(menu)._Mode -label "Mode"
	   menu $this(menu)._Mode
       $this(top_win) configure -menu $this(menu)
	   $this(menu)._Mode add command -label "Edition"    -command "$objName set_mode_Edition"
	   $this(menu)._Mode add command -label "Simulation" -command "$objName set_mode_Simulation"
	   $this(menu)._Mode add command -label "Network"    -command "$objName set_mode_Network"
   set this(frame_tools)  $this(top_win).frame_tools ; frame    $this(frame_tools) ; pack $this(frame_tools)  -side left -fill both
   set this(frame_canvas) $this(top_win).frame_canvas; frame    $this(frame_canvas); pack $this(frame_canvas) -side left -fill both -expand 1
     set this(canvas)       $this(frame_canvas).canvas ; canvas $this(canvas)        ; pack $this(canvas)       -side top -fill both -expand 1
	 set this(frame_info)   $this(frame_canvas).infos  ; frame  $this(frame_info)    ; pack $this(frame_info)   -side bottom -fill x
	   
 # L&F config
 $this(canvas) configure -background white
 $this(canvas) create line 0 0 10 10 -fill white -tags [list $objName origine_$objName]
 bind $this(canvas) <Motion>  "+ $objName Move %x %y"
 
 # bind $this(top_win) <MouseWheel> "+ $objName trigger %W %X %Y %D"
 # bind $this(canvas)  <<Wheel>>    "$objName Zoom %x %y \[$objName get_delta\]"
 
 bind $this(canvas)  <ButtonPress>   "+ $objName Button_pressed %b %x %y"
 bind $this(canvas)  <ButtonRelease> "+ $objName Button_pressed 0 %x %y"
 
 this Button_pressed 0 0 0
 
 # TK aspects 
 set this(current_element)      ""
 set this(L_tk_representations) [list]
 set this(zoom_factor)          1

 # Plug the root if there is one
 if {$root_task != ""} {this Plug $root_task}
 
 # Directories
 set this(initial_directory)        [pwd]
 set this(directory_for_operators)  $this(initial_directory)
 set this(directory_for_test_load)  $this(initial_directory)
 set this(directory_for_test_save)  $this(initial_directory)
 set this(directory_for_task_load)  $this(initial_directory)
 set this(directory_for_task_save)  $this(initial_directory)
 set this(directory_for_trace_load) $this(initial_directory)
 set this(directory_for_trace_save) $this(initial_directory)

 if {![file exists config.cfg]} {
	 set f [open config.cfg w]; puts $f "127.0.0.1\n9999"; close $f
	}
 set f [open config.cfg]; lassign [split [read $f] "\n"] this(server_ip) this(server_port); close $f
}

#_____________________________________________________________________________________________________________
method Task_viewer dispose {} {
 if {[catch {$this(top_win) delete} err]} {puts "Error while deleting the top level "}
 set tmp [pwd]
 cd $this(initial_directory)
	set f [open config.cfg w]; puts "$this(server_ip)\n$this(server_port)"; close $f
 cd $tmp
 
 this inherited
}
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method Task_viewer set_server_ip_port {ip port} {
	set this(server_ip)   $ip
	set this(server_port) $port
	set this(send_to_server) 1
	
	set tmp [pwd]
	cd $this(initial_directory)
		set f [open config.cfg w]; puts "$this(server_ip)\n$this(server_port)"; close $f
	cd $tmp
}

#_____________________________________________________________________________________________________________
method Task_viewer send_file_content_to_server {sock type file_name} {
	if {[catch {set f [open $file_name r]} err]} {puts stderr "Error while loading file $file_name :\n$err"; return}
		set file_name [string range $file_name [string length $this(original_directory_for_test_load)/] end]
		set str [list $type $file_name [read $f]]
		close $f
	# puts [concat $file_name " : " [string length $str]]
	puts -nonewline $sock [concat [string length $str] " " $str]
}

#_____________________________________________________________________________________________________________
method Task_viewer send_from_test_file {sock file_name} {
	 if {[catch {set f [open $file_name r]} err]} {puts stderr "Error while loading file $file_name :\n$err"; return}
     if {[catch {set test_file_content [read $f]; dom parse $test_file_content doc} err]} {puts stderr "Error while parsing file $file_name : \n$err"; close $f; return}
	 close $f
	 
	 $doc documentElement root
	 foreach node [$root selectNodes {/test/*}] {
		 if {[string first $this(directory_for_test_load)/ [$node asText]] == 0} {
			 set item_long_name  [$node asText]
			 set item_short_name [string range $item_long_name [string length $this(directory_for_test_load)/] end]
			} else {if {[file exists $this(directory_for_test_load)/[$node asText]]} {
						 set item_long_name  $this(directory_for_test_load)/[$node asText]
						 set item_short_name [$node asText]
						} else {puts stderr "Impossible to find $this(directory_for_test_load)/[$node asText]"
							    continue
							   }
				   }
		 switch [$node nodeName] {
			 test      {this send_file_content_to_server $sock "test_file" $item_long_name
						set tmp $this(directory_for_test_load)
						set this(directory_for_test_load) [file dirname $item_long_name]
						puts "Changing dir :\n\t -from : $tmp\n\t  to: $this(directory_for_test_load)"
						this send_from_test_file $sock $item_long_name 
						set this(directory_for_test_load) $tmp
					   }
			 task_tree {this send_file_content_to_server $sock "task_file" $item_long_name
					   }
			 traces    {this send_file_content_to_server $sock "trace_file" $item_long_name
					   }
			 default   {puts stderr "\t[$node nodeName] is not a valid node name"}
			}
		}
	$doc delete
}

#_____________________________________________________________________________________________________________
method Task_viewer ServerTest {} {
 set file_name [tk_getOpenFile -defaultextension "test" -initialdir $this(directory_for_test_load) -title "Select a test file to send to server"]
 
 if {$file_name != ""} {
	 set this(directory_for_test_load)  [file dirname $file_name]
	 set this(original_directory_for_test_load) $this(directory_for_test_load)
	 if {[catch {set f [open $file_name r]} err]} {puts stderr "Error while loading file $file_name :\n$err"; return}
     if {[catch {set test_file_content [read $f]; dom parse $test_file_content doc} err]} {puts stderr "Error while parsing file $file_name : \n$err"; close $f; return}
	 close $f
	 $doc delete
	 
	 # Sprecify server adress
	 set this(send_to_server) 0
	 toplevel ._win_server
		wm title ._win_server "Specify server adress"
		frame ._win_server.ip  ; pack ._win_server.ip   -side top -fill x -expand 1
			entry ._win_server.ip.e              ; ._win_server.ip.e insert 0 $this(server_ip); pack ._win_server.ip.e -side right -fill x -expand 0
			label ._win_server.ip.l -text "IP : "; pack ._win_server.ip.l -side right -fill none -expand 0
		frame ._win_server.port; pack ._win_server.port -side top -fill x -expand 1
			entry ._win_server.port.e              ; ._win_server.port.e insert 0 $this(server_port); pack ._win_server.port.e -side right -fill none -expand 0
			label ._win_server.port.l -text "port : "; pack ._win_server.port.l -side right -fill none -expand 0
		frame ._win_server.cmd; pack ._win_server.cmd -side top -fill x -expand 1
			button ._win_server.cmd.ok     -text "  OK  " -command "$objName set_server_ip_port \[._win_server.ip.e get\] \[._win_server.port.e get\]; destroy ._win_server"; pack ._win_server.cmd.ok     -side right
			button ._win_server.cmd.cancel -text "Cancel" -command "puts Cancel; destroy ._win_server"; pack ._win_server.cmd.cancel -side right
	 grab ._win_server
	 tkwait window ._win_server
	 
	 # Send test files
	 #	- operator code
	 #	- task and trace file referenced by the test file
	 #	- the test file
	 if {[catch {set sock [socket $this(server_ip) $this(server_port)]} err]} {
		 puts stderr "Error connecting to $this(server_ip) on port $this(server_port)\n$err"
		 return
		}
		
	 # Operators
	 foreach op [list ChoiceOperator InterleavingOperator SequenceOperator NoOrderOperator] {
		 set str [list "operator" $op  [gmlObject info class $op]]
		 puts "\t$op : Sending [string length $str] bytes"
		 puts -nonewline $sock [concat [string length $str] " " $str]
		}
		
	 # Test file
	 this send_file_content_to_server $sock "test_file" $file_name
	 
	 # Parse test file and send related traces and tasks files
	 this send_from_test_file $sock $file_name 
	 
	 # Ask for processing
	 set str [list "do_test_on" \
				   [string range $file_name [string length $this(original_directory_for_test_load)/] end] \
				   " " \
			 ]
	 puts -nonewline $sock [concat [string length $str] " " $str]
	 
	 puts $sock "0 "
	 flush $sock
	 
	 # Read the response
	 set response ""
	 while {![eof $sock]} {
		 append response [read $sock]
		}
	 puts "Response contains [string length $response] bytes"
	 this Display_test_result "Server response" $response 1
	 close $sock
	}
}

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method Task_viewer Reload_operators {{path ""}} {
	if {$path == ""} {
		 set path [tk_chooseDirectory -title "Select operators directory" -mustexist 1 -initialdir $this(directory_for_operators)]
		}
	if {$path == ""} {return}
	
	this New_task_tree
	set this(directory_for_operators) $path
	
	# Unload operators
	foreach op [gmlObject info specializations TaskOperator] {
		 gmlObject delete class $op
		}
	# Reload initial operators
	cd $this(initial_directory)
	foreach f [list Choice_operator Disabbling_operator Interleaving_operator NoOrder_operator Sequence_operator Suspend_operator] {
		 source ${f}.tcl
		}
	# Load operators
	foreach f [glob $this(directory_for_operators)/*.tcl] {
		 puts "\tsource $f"
		 source $f
		}
}

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method Task_viewer set_mode_Edition    {} {
 set this(mode) "Edition"
 # Create a window with a tools palette
 set this(edition_palette) ._{objName}_TK_edition_palette
 if {![winfo exists $this(edition_palette)]} {
   toplevel $this(edition_palette)
     wm title     $this(edition_palette) "Tasks edition toolbox"
	 wm resizable $this(edition_palette) 0 0
   # Add a label for tasks
   label $this(edition_palette).lab_info -text "Tasks edition toolbox"; pack $this(edition_palette).lab_info -side top -fill x -expand 1
   label $this(edition_palette).lab_task -text "Tasks"
     pack $this(edition_palette).lab_task -side top -fill x -expand 1
   # Add a button for task addition
   foreach t [list USER SYSTEM] {
     set bt $this(edition_palette).bt_task_$t 
	 button $bt -background lightgrey -state normal -text $t -command "lassign \[$objName get_current_edition_tool\] type CT_class; if {\$CT_class != \"\"} {$this(edition_palette).bt_task_\$CT_class configure -state normal -background lightgrey}; if {\$CT_class != \"$t\"} {$objName set_current_edition_tool TASK $t; $this(edition_palette).bt_task_$t configure -state disable -background green; puts {task $t is highlighted}} else {$objName set_current_edition_tool {} {}}"
	 pack $bt -side top -fill x -expand 1
    }
   # Add label for task operators
   label $this(edition_palette).lab_task_op -text "Operators"
     pack $this(edition_palette).lab_task_op -side top -fill x -expand 1
   puts "# Add one button per task operation"
   foreach class_op [gmlObject info specializations TaskOperator] {
     set bt $this(edition_palette).bt_task_$class_op
	   $class_op PIPO_$objName pipo ""
	   set type_name [PIPO_$objName get_type]
	   PIPO_$objName dispose
	 button $bt -background lightgrey -text $type_name -command "lassign \[$objName get_current_edition_tool\] type CT_class; if {\$CT_class != \"\"} {$this(edition_palette).bt_task_\$CT_class configure -state normal -background lightgrey}; if {\$CT_class != \"$class_op\"} {$objName set_current_edition_tool TASK_OP $class_op; $this(edition_palette).bt_task_$class_op configure -state disable -background green; puts {TaskOperator $class_op is highlighted}} else {$objName set_current_edition_tool {} {}}"
	 pack $bt -side top -fill x -expand 1
    }
  }
  
 wm attribute $this(edition_palette) -topmost 1
}

#_____________________________________________________________________________________________________________
method Task_viewer get_current_edition_tool {} {return $this(current_edition_tool)}
#_____________________________________________________________________________________________________________
method Task_viewer set_current_edition_tool {type CT_class} {set this(current_edition_tool) [list $type $CT_class]}

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method Task_viewer get_mode {} {return $this(mode)}

#_____________________________________________________________________________________________________________
method Task_viewer set_mode_Simulation {} {
 set this(mode) "Simulation"
 
 # Create a window with a tools palette
 if {![winfo exists $this(simulation_palette)]} {
   toplevel $this(simulation_palette)
     wm title     $this(simulation_palette) "Tasks edition toolbox"
	 wm resizable $this(simulation_palette) 1 1
   set this(menu)         $this(simulation_palette).menu        ; menu     $this(menu) -tearoff 0
     $this(menu) add cascade -menu $this(menu)._File -label "File"
	   menu $this(menu)._File
       $this(simulation_palette) configure -menu $this(menu)
	   $this(menu)._File add command -label "Load traces" -command "$objName Load_trace_file"
	   $this(menu)._File add command -label "Save traces" -command "$objName Save_trace_file"

   # Add a label for tasks
   label $this(simulation_palette).lab_info -text "Simulation commands"; pack $this(simulation_palette).lab_info -side top -fill x -expand 0
   set frame_cmd $this(simulation_palette)._frame_cmd;
   frame $frame_cmd; pack $frame_cmd -side top -expand 0 -fill x
     set this(bt_Reset)     $frame_cmd.bt_Reset ; button  $this(bt_Reset)  -text "Reset"  -command "$objName Reset_simulation"; pack $this(bt_Reset) -side left -fill x -expand 1
     set this(bt_Start)     $frame_cmd.bt_Start ; button  $this(bt_Start)  -text "Start"  -command "$objName Start_simulation"; pack $this(bt_Start) -side left -fill x -expand 1
   set frame_evt $this(simulation_palette)._frame_evt;
   frame $frame_evt; pack $frame_evt -side top -fill both -expand 1
     label $frame_evt.lab -text "Traces"
	   pack $frame_evt.lab -side top -fill x -expand 0
     
	 global $this(L_traces); set $this(L_traces) [list]
	 listbox $frame_evt.lb -listvariable $this(L_traces) -selectmode normal
       pack $frame_evt.lb -side left -expand 1 -fill both
       scrollbar $frame_evt.sb -orient vertical
         pack $frame_evt.sb -side left -expand 0 -fill y
       $frame_evt.lb configure -yscrollcommand "$frame_evt.sb set"
       $frame_evt.sb configure -command        "$frame_evt.lb yview"
       bind $frame_evt.lb <<ListboxSelect>> "foreach p \[$frame_evt.lb curselection\] {$objName Go_to_trace \$p}"
   
   destroy $this(simulation_palette)._frame_assert
   set frame_assert $this(simulation_palette)._frame_assert
   frame $frame_assert; pack $frame_assert -fill x -expand 0
	 label ${frame_assert}.label -text "Add a new assertion"; pack ${frame_assert}.label -side top -anchor w
	 set f_assert_params ${frame_assert}._f_params; set this(f_assert_params) $f_assert_params
	 frame $f_assert_params; pack $f_assert_params -side top -expand 0 -fill x
		frame ${f_assert_params}.f_comment; pack ${f_assert_params}.f_comment -side top -expand 0 -fill x
			label ${f_assert_params}.f_comment.lab   -text "Comment : "; pack ${f_assert_params}.f_comment.lab   -side left
			entry ${f_assert_params}.f_comment.entry                   ; pack ${f_assert_params}.f_comment.entry -side left -expand 1 -fill x
		frame ${f_assert_params}.f_task_id; pack ${f_assert_params}.f_task_id -side top -expand 0
		  label ${f_assert_params}.f_task_id.label -text "task id : " 
		  pack  ${f_assert_params}.f_task_id.label -side left -anchor w
		  this Subscribe_to_set_current_element update_task_for_assertion_$objName "$objName update_current_task_for_assertion \$e"
		global ${objName}_assert_type
		set ${objName}_assert_type Availability
		tk_optionMenu ${f_assert_params}.assert_type ${objName}_assert_type Availability State
		trace remove variable ${objName}_assert_type write "$objName set_assert_type "
		trace add    variable ${objName}_assert_type write "$objName set_assert_type "
		pack ${f_assert_params}.assert_type -side top -fill x -expand 0
			
		destroy ${f_assert_params}.fp
		frame ${f_assert_params}.fp; pack ${f_assert_params}.fp -side top -expand 0
		set ${objName}_assert_type [subst $${objName}_assert_type]
		
	 button ${frame_assert}.bt_ok -text "Add assertion" -command [list $objName Add_assertion]
	 pack   ${frame_assert}.bt_ok -side right -expand 0
  }
  
 wm attribute $this(simulation_palette) -topmost 1
}

#_____________________________________________________________________________________________________________
method Task_viewer Add_assertion {} {
	if {[winfo exists $this(simulation_palette)]} {
		 global ${objName}_assert_type
		 set type [subst $${objName}_assert_type]
		 set task $this(current_task_selected)
		 switch $type {
			 Availability {global ${objName}_assert_availability_bool
						   this Push_trace [list ASSERT "" $task $type [subst $${objName}_assert_availability_bool]] 0
						  }
			 State        {global ${objName}_assert_state_type
						   global ${objName}_assert_state_type_bool
						   this Push_trace [list ASSERT "" $task $type [list [subst $${objName}_assert_state_type_bool] [subst $${objName}_assert_state_type]]] 0
						  }
			}
		}
}

#_____________________________________________________________________________________________________________
method Task_viewer update_current_task_for_assertion {task_viewer} {
	if {[winfo exists $this(simulation_palette)] && $task_viewer != ""} {
		 set this(current_task_selected) [$task_viewer get_ct_element]
		 $this(f_assert_params).f_task_id.label configure -text "task id : $this(current_task_selected)"
		}
}

#_____________________________________________________________________________________________________________
method Task_viewer set_assert_type {var_name index_name op} {
	# upvar $var_name v
	global $var_name
	set v [subst $$var_name]

	destroy $this(f_assert_params).fp
	frame $this(f_assert_params).fp; pack $this(f_assert_params).fp -side top -expand 0 -fill x
	switch $v {
		 Availability {set v_name ${objName}_assert_availability_bool
					   global $v_name
					   if {![info exists $v_name]} {set $v_name 0}
					   set L_txt [list "is not available" "is available"]
					   button $this(f_assert_params).fp.bt -text [lindex $L_txt [subst $$v_name]] -command "set $v_name \[expr 1 - $$v_name\]; $this(f_assert_params).fp.bt configure -text \[lindex {$L_txt}  $$v_name\]"
		               pack $this(f_assert_params).fp.bt -fill x
					   # checkbutton $this(f_assert_params).fp.cb -command [list $objName set_assert_type $var_name 0 pipo] -text [lindex [list "is not available" "is available"] [subst $$v_name]] -variable $v_name
					   # pack $this(f_assert_params).fp.cb -fill x
					  }
		 State        {set v_name ${objName}_assert_state_type
					   global $v_name
		               tk_optionMenu $this(f_assert_params).fp.list $v_name Done WIP Undone
					   set $v_name Done
					   set v_b_name ${objName}_assert_state_type_bool
					   global $v_b_name
					   set L_txt [list "is not " "is "]
					   button $this(f_assert_params).fp.bt -text [lindex $L_txt [subst $$v_b_name]] -command "set $v_b_name \[expr 1 - $$v_b_name\]; $this(f_assert_params).fp.bt configure -text \[lindex {$L_txt}  $$v_b_name\]"
					   pack $this(f_assert_params).fp.bt   -side left -fill none
					   # checkbutton $this(f_assert_params).fp.cb -command [list $objName set_assert_type $var_name 0 pipo] -text [lindex [list "is not" "is "] [subst $$v_b_name]] -variable $v_b_name
					   # pack $this(f_assert_params).fp.cb   -side left -fill none
					   pack $this(f_assert_params).fp.list -side left -fill x 
					  }
		}
}

#_____________________________________________________________________________________________________________
method Task_viewer Push_trace {t {erase_after 1}} {
 global $this(L_traces) 
 
 if {$erase_after} {
	 if {$this(last_trace_index) != "end" && $this(last_trace_index) != [llength [subst $$this(L_traces)]]-1} {
	   set $this(L_traces) [lrange [subst $$this(L_traces)] 0 $this(last_trace_index)]
	  }
	  
	 lappend $this(L_traces) [concat [llength [subst $$this(L_traces)]] ": " $t]
	 set this(last_trace_index) end
	 } else {if {$this(last_trace_index) == "end"} {set end [llength [subst $$this(L_traces)]]} else {set end $this(last_trace_index)}
			 set $this(L_traces) [linsert [subst $$this(L_traces)] [expr 1+$end] [concat [expr 1+$end] ": " $t]]
			}
}

#_____________________________________________________________________________________________________________
method Task_viewer Assert_State {num_command task bool_state comment} {
	lassign $bool_state is_or_not state
	set comparaison [string equal [$task get_state] $state]
	if {$is_or_not == 0} {set op "!="; set comparaison [expr !$comparaison]} else {set op "=="}
	if {$comparaison} {
		 set rep ""
		 append rep "\t<success_assert num_command=\"$num_command\" type=\"State\" task=\"$task\" comparator=\"$op\" state=\"$state\">" {<![CDATA[} $comment {]]>} "</success_assert>"
		 append this(test_result) $rep
		 set i_rep 0
		} else {set rep ""
				append rep "\t<error_assert num_command=\"$num_command\" type=\"State\" task=\"$task\" comparator=\"$op\" state=\"$state\">" {<![CDATA[} $comment {]]>} "</error_assert>"
			    # if {$this(expected_result) != "failure"} {puts stderr $rep}
				append this(test_result) $rep
				set i_rep 1
			   }
	return $i_rep
}

#_____________________________________________________________________________________________________________
method Task_viewer Assert_Availability {num_command task available comment} {
	# puts "$objName Assert_Availability $task $available"
	set comparaison [string equal [$task get_user_interaction] "Available"]
	if {($available && $comparaison) || (!$available && !$comparaison)} {
		 set rep ""
		 append rep "\t<success_assert num_command=\"$num_command\" type=\"Availability\" task=\"$task\" availability=\"$available\">" {<![CDATA[} $comment {]]>} "</success_assert>"
		 append this(test_result) $rep;
		 set i_rep 0
		} else {set rep ""
				append rep "\t<error_assert num_command=\"$num_command\" type=\"Availability\" task=\"$task\" availability=\"$available\">" {<![CDATA[} $comment {]]>} "</error_assert>"
				# if {$this(expected_result) != "failure"} {puts stderr $rep}
				append this(test_result) $rep
				set i_rep 1
			   }
	return $i_rep
}

#_____________________________________________________________________________________________________________
method Task_viewer Go_to_trace {num} {
 global $this(L_traces) 
 set L [subst $$this(L_traces)]

 if {$num == "end"} {set num [expr [llength $L] - 1]}
 set this(last_trace_index) $num

 set this(do_not_delete_traces) 1
   if {[catch {this Start_simulation} err]} {
		 set rep ""; append rep "\t<error_action num_command=\"0\" task=\"Start_simulation\" action=\"\" comment=\"\"></error_action>"
		 append this(test_result) $rep
		 set this(last_trace_index) 0
		 set this(do_not_delete_traces) 0
		 return [list 1 0 "failure"]
		}
 set this(do_not_delete_traces) 0
 set i 0; set nb_error_assert 0; set result "success"
 foreach t $L {
   lassign $t nb deux_points act comment obj mtd param
   switch $act {
		 ACTION {if {[catch {$obj $mtd} err]} {
					 set rep ""; append rep "\t<error_action num_command=\"[expr $i + 1]\" task=\"$obj\" action=\"$mtd\" comment=\"\">" {<![CDATA[} $err {]]>} "</error_action>"
					 # if {$this(expected_result) == "success"} {puts stderr $rep} else {puts $rep}
					 append this(test_result) $rep
					 set result "failure"
					 break
					}
				}
		 ASSERT {incr nb_error_assert [this Assert_$mtd [expr $i + 1] $obj $param $comment]
				 if {$nb_error_assert > 0} {set result "failure"}
			    }
		}
   
   incr i
   if {$i > $num} {break}
  }

 if {[winfo exists $this(simulation_palette)]} {
	 $this(simulation_palette)._frame_evt.lb selection clear 0 end
	 $this(simulation_palette)._frame_evt.lb selection set $num
	}

 if {$i >= $num} {set i end}
 return [list $nb_error_assert $i $result]
}

#_____________________________________________________________________________________________________________
method Task_viewer Load_trace_file {{file_name {}}} {
 if {$file_name == ""} {
	 set file_name [tk_getOpenFile -defaultextension "trc" -initialdir $this(directory_for_trace_load) -title "Load the current traces list"]
	 set this(directory_for_trace_load) [file dirname $file_name]
	}
 if {$file_name != ""} {
   set f [open $file_name r]
     set str [read $f]
   close $f
   global $this(L_traces)
   
   dom parse $str doc
   $doc documentElement root
   foreach a [$root selectNodes {/traces/*}] {
		 if {[$a hasAttribute comment]} {set comment [$a getAttribute comment]} else {set comment ""}
		 switch [$a nodeName] {
			 action {lappend $this(L_traces) [concat [expr [llength [subst $$this(L_traces)]] + 1] " : " [list ACTION $comment [$a getAttribute task] [$a getAttribute operation]]]}
			 assert {lappend $this(L_traces) [concat [expr [llength [subst $$this(L_traces)]] + 1] " : " [list ASSERT $comment [$a getAttribute task] [$a getAttribute type] [$a getAttribute parameter]]]}
			}
		}
   
   $doc delete
  }
}

#_____________________________________________________________________________________________________________
method Task_viewer Save_trace_file {} {
 set file_name [tk_getSaveFile -defaultextension "trc" -initialdir $this(directory_for_trace_save) -title "Save the current traces list"]
 if {$file_name != ""} {
   set this(directory_for_trace_save) [file dirname $file_name]
   set f [open $file_name w]
     fconfigure $f -encoding utf-8
     global $this(L_traces)
     puts $f "<traces>"
	 foreach t [subst $$this(L_traces)] {
		 lassign $t num deux_points act comment obj mtd param
		 switch $act {
			 ACTION {puts $f "\t<action task=\"$obj\" operation=\"$mtd\" comment=\"$comment\"/>"}
			 ASSERT {puts $f "\t<assert task=\"$obj\" type=\"$mtd\" parameter=\"$param\" comment=\"comment\"/>"}
			}
		}
	 puts $f "</traces>"
	 
   close $f
  }
}

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method Task_viewer set_mode_Network    {} {
 set this(mode) "Network"
}

#_____________________________________________________________________________________________________________
method Task_viewer Reset_simulation {} {
 global $this(L_traces)
 set $this(L_traces) [list]
 
 foreach root $this(L_root_task) {
   foreach t [$root get_all_descendants] {
     $t set_user_interaction_Unavailable
	 $t set_state_Undone
    }
  }
}

#_____________________________________________________________________________________________________________
method Task_viewer Reinit_simulation {} {
 # Set every task to undone and no user interaction
 foreach root $this(L_root_task) {
   foreach t [$root get_all_descendants] {
     $t set_user_interaction_Unavailable
	 $t set_state_Undone
    }
  }
}

#_____________________________________________________________________________________________________________
method Task_viewer Start_simulation {} {
 this Reinit_simulation
 # Init the root with WIP and user interaction
 foreach root $this(L_root_task) {
   $root set_user_interaction_Available
   # $root set_state_WIP
  }
  
 if {!$this(do_not_delete_traces)} {
	 global $this(L_traces)
	 if {[llength [subst $$this(L_traces)]]} {
	   $this(simulation_palette)._frame_evt.lb selection clear 0 end
	   $this(simulation_palette)._frame_evt.lb selection set 0
	  } else {$this(simulation_palette)._frame_evt.lb selection set 0
			 }
  }
}

#_____________________________________________________________________________________________________________
method Task_viewer New_task_tree {} {
 # Delete tasks, and therefore their representations
 foreach root $this(L_root_task) {
   foreach t [$root get_all_descendants] {$t dispose}
  }
 set this(L_root_task) [list]
 set this(zoom_factor) 1
 $this(canvas) coords origine_$objName 0 0 10 10
}

#_____________________________________________________________________________________________________________
method Task_viewer Display_test_result {title str_xml {display_traces 0}} {
	 set this(toplevel_trace) ._toplevel_trace_[clock milliseconds]
	 set toplevel_trace $this(toplevel_trace)
	 destroy $toplevel_trace
	 toplevel $toplevel_trace
	 wm title $toplevel_trace $title	
	 ttk::treeview $toplevel_trace.tree
	 pack $toplevel_trace.tree -side left -expand 1 -fill both
	 
	 scrollbar $toplevel_trace.sb -orient vertical
	 pack $toplevel_trace.sb -side left -expand 0 -fill y
	 $toplevel_trace.tree configure -yscrollcommand "$toplevel_trace.sb set"
	 $toplevel_trace.sb   configure -command        "$toplevel_trace.tree yview"
	 
     if {[catch {dom parse $str_xml doc} err]} {puts stderr "Error while parsing result to be displayed : \n$err"; return}
	 
	 # Create toplevel for accessing the test	 
	 $doc documentElement root
	 foreach node [$root selectNodes {//*}] {
		 switch [$node nodeName] {
			 task_tree {set last_task_tree $this(directory_for_test_load)/[$node getAttribute src]
						set last_task_tree_id [$toplevel_trace.tree insert "" end -text [$node getAttribute src] ]
						$toplevel_trace.tree item $last_task_tree_id -tags [list $last_task_tree_id]
					    $toplevel_trace.tree tag configure $last_task_tree_id -background #9F9
					    $toplevel_trace.tree tag bind $last_task_tree_id <Double-ButtonPress-1> "$objName Load_file {$last_task_tree}"
					   }
			 trace     {set last_trace_id [$toplevel_trace.tree insert $last_task_tree_id end -text "[$node getAttribute src]"]
						$toplevel_trace.tree item $last_trace_id -tags [list $last_trace_id]
						set expected_result [$node getAttribute expected_result]
						$toplevel_trace.tree item $last_trace_id -text "Expected ${expected_result} for [$node getAttribute src]"
						$toplevel_trace.tree tag bind $last_trace_id <Double-ButtonPress-1> "$objName Load_file {$last_task_tree}; $objName Reset_simulation; $objName Load_trace_file {$this(directory_for_test_load)/[$node getAttribute src]}"
						# Selection du fils summary pour savoir si ça passe ou pas
						set result [lindex [lindex [$node selectNodes {summary/attribute::result}] 0] 1]
						if {$result == "success"} {set color #9F9} else {set color #F99
																		 # puts stderr $result
																		 $toplevel_trace.tree tag configure $last_task_tree_id -background $color
																		}
						$toplevel_trace.tree tag configure $last_trace_id     -background $color
						
						if {$display_traces} {
							 foreach n_trace [$node selectNodes {*}] {
								 switch [$n_trace nodeName] {
									 success_assert {if {[string tolower [$n_trace getAttribute type]] == "state"} {
														 set str "[$n_trace getAttribute num_command] : Assert [$n_trace getAttribute type] succeed for task [$n_trace getAttribute task] [$n_trace getAttribute comparator] [$n_trace getAttribute state]"
														} else {set str "[$n_trace getAttribute num_command] : Assert [$n_trace getAttribute type] succeed for task [$n_trace getAttribute task] [$n_trace getAttribute availability]"
															   }
													 set last_element_id [$toplevel_trace.tree insert $last_trace_id end -text $str]
													 $toplevel_trace.tree item $last_element_id -tags [list $last_element_id]
													 $toplevel_trace.tree tag configure $last_element_id -background #9F9
													}
									 error_assert	{if {[string tolower [$n_trace getAttribute type]] == "state"} {
														 set str "[$n_trace getAttribute num_command] : Assert [$n_trace getAttribute type] failed for task [$n_trace getAttribute task] [$n_trace getAttribute comparator] [$n_trace getAttribute state]"
														} else {set str "[$n_trace getAttribute num_command] : Assert [$n_trace getAttribute type] failed for task [$n_trace getAttribute task] [$n_trace getAttribute availability]"
															   }
													 set last_element_id [$toplevel_trace.tree insert $last_trace_id end -text $str]
													 $toplevel_trace.tree item $last_element_id -tags [list $last_element_id]
													 $toplevel_trace.tree tag configure $last_element_id -background #F99
													}
									 error_action	{set last_element_id [$toplevel_trace.tree insert $last_trace_id end -text "[$n_trace getAttribute num_command] : [$n_trace getAttribute task] [$n_trace getAttribute action]"]
													 $toplevel_trace.tree item $last_element_id -tags [list $last_element_id]
													 $toplevel_trace.tree tag configure $last_element_id -background #F99
													}
									 default		{continue}
									}
								 $toplevel_trace.tree tag bind $last_element_id <Double-ButtonPress-1> "$objName Load_file {$last_task_tree}; \
										$objName Reset_simulation; \
										$objName Load_trace_file {$this(directory_for_test_load)/[$node getAttribute src]}; \
										$objName Go_to_trace [expr [$n_trace getAttribute num_command] - 1] \
										"
								}
							}
					   }
			}
		}

}

#_____________________________________________________________________________________________________________
method Task_viewer Test {{file_name {}} {record 1} {chan {}}} {	
 if {$file_name == ""} {
	 set file_name [tk_getOpenFile -defaultextension "test" -initialdir $this(directory_for_test_load) -title "Load a test file"]
	 # set this(directory_for_task_load)  [file dirname $file_name]
	 # set this(directory_for_trace_load) [file dirname $file_name]
	}
 
 if {$file_name != ""} {
	 if {[lrange [lindex [get_stack] 1] 0 3] != "Task_viewer::Test $objName Task_viewer Test"} {
		 set this(directory_for_test_load_for_xml) [file dirname $file_name]
		 puts "directory_for_test_load_for_xml : $this(directory_for_test_load_for_xml)\n\tstack : [get_stack]"
		}
	 set this(directory_for_test_load)  [file dirname $file_name]
		set dir_move [string range $this(directory_for_test_load) [string length $this(directory_for_test_load_for_xml)/] end]
		if {$dir_move != ""} {set dir_move "$dir_move/"}
		puts "\tdir_move : $dir_move"
	 if {[catch {set f [open $file_name r]} err]} {puts stderr "Error while loading file $file_name :\n$err"; return}
     if {[catch {dom parse [read $f] doc} err]} {puts stderr "Error while parsing file $file_name : \n$err"; return}
	 close $f
	 
	 # Create toplevel for accessing the test	 
	 $doc documentElement root
	 set nb_total_error_assert 0; set nb_failures 0; set nb_tests 0
	 set this(test_result) "<test_result test=\"$file_name\">\n"
	 foreach act [$root selectNodes {/test/*}] {
		 switch [$act nodeName] {
			 test      {set test_result_tmp             $this(test_result)
					    set directory_for_test_load_tmp $this(directory_for_test_load)
						lassign [this Test $this(directory_for_test_load)/[$act asText] 0] tmp_nb_tests tmp_nb_failures tmp_nb_total_error_assert
						set this(directory_for_test_load) $directory_for_test_load_tmp
						append test_result_tmp $this(test_result)
						set this(test_result) $test_result_tmp
					   }
			 task_tree {set str "<task_tree src=\"$dir_move[$act asText]\" />"
						append this(test_result) $str
						if {[catch {this Load_file $this(directory_for_test_load)/[$act asText]} err]} {
							 puts stderr "Error while loading task file : $err"
							}
						set last_task_tree $this(directory_for_test_load)/[$act asText]
					   }
			 traces    {incr nb_tests
						set expected_result [$act getAttribute expected_result "success"]
							set this(expected_result) $expected_result
						set str "<trace expected_result=\"$expected_result\" src=\"$dir_move[$act asText]\">"
						append this(test_result) $str
						this Reset_simulation
						if {[catch {this Load_trace_file $this(directory_for_test_load)/[$act asText]} err]} {
							 puts stderr "Error while loading trace file : $err"
							 append this(test_result) "</trace>"
							 set this(expected_result) ""
							 continue
							}
						lassign [this Go_to_trace end] nb_error_assert last_index result
						incr nb_total_error_assert $nb_error_assert
						if {$last_index  == "end" && $result == $expected_result} {
							 set result "success"
							} else {set result "failure"
									incr nb_failures
									# puts stderr "\tExpected $expected_result but got $result"
								   }
						append this(test_result) "<summary nb_error_assert=\"$nb_error_assert\" result=\"$result\"/>"
						append this(test_result) "</trace>"
						set this(expected_result) ""
					   }
			 default   {puts stderr "\t[$act nodeName] is not a valid node name"}
			}
		}
	 append this(test_result) "<summary nb_error_assert=\"$nb_total_error_assert\" nb_tests=\"$nb_tests\" nb_failures=\"$nb_failures\"/>"
	 append this(test_result) "</test_result>\n "
	 $doc delete
	 
	 if {$chan != ""} {puts $chan [string map [list "&" "&amp;"] $this(test_result)]}
	 if {$record && $chan == ""} {this Display_test_result $file_name [string map [list "&" "&amp;"] $this(test_result)] 1}

	 return [list $nb_tests $nb_failures $nb_total_error_assert]
	}
	
 return [list]
}

#_____________________________________________________________________________________________________________
method Task_viewer Load_file {{file_name {}}} {
 if {$file_name == ""} {
	 set file_name [tk_getOpenFile -defaultextension "tsk" -initialdir $this(directory_for_task_load) -title "Load a task tree"]
	 set this(directory_for_task_load) [file dirname $file_name]
	}
 if {$file_name != ""} {
   this New_task_tree
   set f [open $file_name r]
     dom parse [read $f] doc
	 close $f
	 $doc documentElement root
	 set L_n_Task              [$root selectNodes {/Task_tree_viewer/Task_tree}]
	 if {$L_n_Task == ""} {error "The format of the file $file_name is not recognize ..."}
	 set L_obj [list]
	 foreach n_Task $L_n_Task {
	   lappend L_obj [this Plug [this Create_tasks_from_xml [lindex [lindex [$n_Task asList] 2] 0]]]
	  }
	   
	 set L_n_Task_presentation [$root selectNodes {/Task_tree_viewer/Task_tree_Presentation}]
	 foreach n_Task_presentation $L_n_Task_presentation {
		 foreach preso [lindex [$n_Task_presentation asList] 2] {
		   lassign $preso obj L_cmd
		   foreach {cmd val} $L_cmd {
			 eval "$obj $cmd $val"
			}
		   $obj Update_presentation
		  }
	  }
	 $doc delete
	 
	 # Translate so that everything is visible
	 lassign [$this(canvas) bbox $objName] x1 y1 x2 y2
	 $this(canvas) move $objName [expr -$x1] [expr -$y1] 
  }
}

#_____________________________________________________________________________________________________________
method Task_viewer Save_file     {} {
 set file_name [tk_getSaveFile -defaultextension "tsk" -initialdir $this(directory_for_task_save) -title "Save the current task tree"]
 if {$file_name != ""} {
   set this(directory_for_task_save) [file dirname $file_name]
   set f [open $file_name w]
     puts $f "<Task_tree_viewer>"
	 set str ""
	 foreach root $this(L_root_task) {
	   append str "<Task_tree>\n"
       $root Serialize_to_xml str
	   append str "</Task_tree>\n\n"
	  }
     this Serialize_to_xml str
	 puts -nonewline $f $str
	 puts $f "</Task_tree_viewer>\n"
   close $f
  }
}

#_____________________________________________________________________________________________________________
method Task_viewer Serialize_to_xml {str_name} {
 upvar $str_name str
 
 lassign [$this(canvas) bbox origine_$objName] OX OY
 append str "<Task_tree_Presentation>\n"
 foreach tk_r $this(L_tk_representations) {
   lassign [$tk_r get_origine] X Y
   set X [expr int(($X - $OX)*$this(zoom_factor))]; set Y [expr int(($Y - $OY)*$this(zoom_factor))]
   append str "  <TK_representation_of_[$tk_r get_ct_element] Move_to=\"" $X " " $Y "\"></TK_representation_of_[$tk_r get_ct_element]>\n"
  }
 append str "</Task_tree_Presentation>\n"
}

#_____________________________________________________________________________________________________________
method Task_viewer Create_tasks_from_xml {xml_str} {
 set configuration [list]
 lassign $xml_str ct_type L_attr L_xml_children
   foreach {att val} $L_attr {set $att $val}
   
   # Create childrens
   set L_children [list]
   foreach xml_children $L_xml_children {
     set L_children [concat $L_children [this Create_tasks_from_xml $xml_children]]
    }
	
   # Create C&T element
   eval $this(cmd_constructor,$ct_type)
   foreach {mtd param} $configuration {$id set_$mtd $param}
   
 return $id
}

#_____________________________________________________________________________________________________________
method Task_viewer get_a_unique_name {} {
 incr this(u_id)
 while {[gmlObject info exists object OBJ_$this(u_id)]} {incr this(u_id)}
 return OBJ_$this(u_id)
}

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
source Task_viewer_mode_Edition.tcl
source Task_viewer_mode_Simulation.tcl
source Task_viewer_mode_Network.tcl

#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method Task_viewer Button_pressed {b x y} {
 if {$b > 0} {
   set this(last_press) [list $b $x $y]
   this Action_press_$this(mode) $b $x $y
  } else {this Action_release_$this(mode) $x $y
		  # puts "Action_release_$this(mode) $x $y on $this(canvas)"
         } 
}

#_____________________________________________________________________________________________________________
method Task_viewer Move {x y} {
 if {$this(button_pressed) == 1} {
	 if {$this(current_element) != ""} {
	   $this(current_element) Translate [expr $x - $this(last_x)] [expr $y - $this(last_y)]
	  } else {$this(canvas) move $objName [expr $x - $this(last_x)] [expr $y - $this(last_y)]
			 }
			 
	 set this(last_x) $x
	 set this(last_y) $y
  } else {
          # Contextual operations
		  if {$this(button_pressed)} {this Contextual_move_$this(mode) $this(button_pressed) $x $y}
         }
}


#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method Task_viewer Plug {root} {
 #if {$this(root_task) != ""} {this Clear_all}
 Add_list this(L_root_task) $root
 
 this Create_nodes_from $root
 
 this Tree_layout            $root
 this Update_all_connections $root
 
 return $root
}

#_____________________________________________________________________________________________________________
method Task_viewer Clear_all {} {
 foreach r $this(L_tk_representations) {$r dispose}
  
 set this(L_tk_representations) [list]
}

#_____________________________________________________________________________________________________________
method Task_viewer Create_nodes_from {ct_element} {
 if {[lsearch [gmlObject info objects CT_viewer] TK_representation_of_$ct_element] == -1} {
   CT_viewer TK_representation_of_$ct_element $ct_element $this(canvas) $objName
   $ct_element Subscribe_to_dispose $objName "$objName Task_element_has_been_deleted $ct_element"
  }
 
 lappend this(L_tk_representations) TK_representation_of_$ct_element
 
 if {[lsearch [gmlObject info classes $ct_element] "TaskOperator"] != -1} {
	 foreach e [$ct_element get_L_children] {
	   set tk_representation_of_e [this Create_nodes_from $e]
	   this Add_connection $ct_element $e
	  }
  }
  
 return "TK_representation_of_$ct_element"
}

#_____________________________________________________________________________________________________________
method Task_viewer Task_element_has_been_deleted {ct_element} {
 Sub_list this(L_root_task) $ct_element
 
 TK_representation_of_$ct_element dispose
 # Dispose also th econnection that are tagged with this C&T element
 $this(canvas) delete connecting_$ct_element
 
 set this(L_tk_representations) [lremove $this(L_tk_representations) TK_representation_of_$ct_element]
}

#_____________________________________________________________________________________________________________
proc Compare_by_abscisses_f_presentation {e1 e2} {
 set C [TK_representation_of_$e1 attribute canvas]
 
 lassign [$C bbox $e1] x1; lassign [$C bbox $e2] x2
 return [expr $x1 > $x2]
 # return [expr [TK_representation_of_$e1 get_x] > [TK_representation_of_$e2 get_x]]
}

#_____________________________________________________________________________________________________________
method Task_viewer Re_order_in_L_children {ct} {
 set p [$ct get_parent]
 if {$p != ""} {
   set L_children [$p get_L_children]
   set new_list [lsort -increasing -command "Compare_by_abscisses_f_presentation" $L_children]
   if {$new_list != $L_children} {
     # puts "$p set_L_children $new_list"
     $p set_L_children $new_list
    }
  }
}

#_____________________________________________________________________________________________________________
proc get_stack {} {
    set result {}
    for {set i [expr {[info level] -1}]} {$i >0} {incr i -1} {
        lappend result [info level $i]
    }
    return $result
}

#_____________________________________________________________________________________________________________
method Task_viewer Add_connection {parent child} {
 # if {$this(mode) != "Edition"} {return}
 set id_line [$this(canvas) create line 0 0 0 0 -tags [list $objName From_${parent}_to_$child connecting_$parent connecting_$child]]
 this Update_connection $parent $child
 
 TK_representation_of_$parent Subscribe_to_Translate update_connection_with_$child  "$objName Update_connection $parent $child"
 TK_representation_of_$child  Subscribe_to_Translate update_connection_with_$parent "$objName Update_connection $parent $child"

 TK_representation_of_$parent Subscribe_to_Move_to update_connection_with_$child  "$objName Update_connection $parent $child"
 TK_representation_of_$child  Subscribe_to_Move_to update_connection_with_$parent "$objName Update_connection $parent $child"
 
 TK_representation_of_$child Subscribe_to_Translate update_order_$objName "$objName Re_order_in_L_children $child"
 TK_representation_of_$child Subscribe_to_Move_to   update_order_$objName "$objName Re_order_in_L_children $child"
}

#_____________________________________________________________________________________________________________
method Task_viewer Sub_connection {p c} {
 # if {$this(mode) != "Edition"} {return}
 $this(canvas) delete From_${p}_to_$c
 catch [list TK_representation_of_$p UnSubscribe_to_Translate update_connection_with_$c]
 catch [list TK_representation_of_$c UnSubscribe_to_Translate update_connection_with_$p]
}

#_____________________________________________________________________________________________________________
method Task_viewer dispose_children_connections_of {e} {
 foreach c [$e get_L_children] {
   this Sub_connection $e $c
  }
}

#_____________________________________________________________________________________________________________
method Task_viewer Update_connection {parent child} {
 lassign [$this(canvas) bbox $parent] xp1 yp1 xp2 yp2; set mpx [expr ($xp1 + $xp2) / 2]; set mpy [expr ($xp1 + $xp2) / 2]
 lassign [$this(canvas) bbox $child]  xc1 yc1 xc2 yc2; set mcx [expr ($xc1 + $xc2) / 2]; set mcy [expr ($xc1 + $xc2) / 2]
 
 $this(canvas) coords From_${parent}_to_$child $mpx $yp2 $mcx $yc1 
}

#_____________________________________________________________________________________________________________
method Task_viewer Update_all_connections {r} {
 TK_representation_of_$r Update_presentation
 if {[lsearch [gmlObject info classes $r] "TaskOperator"] != -1} {
   foreach e [$r get_L_children] {
     this Update_connection $r $e
	 this Update_all_connections $e
    }
  }
}

#_____________________________________________________________________________________________________________
method Task_viewer Update_all_node_connections {node} {
 set p [$node get_parent]; if {$p != ""} {this Update_connection $p $node}
 if {[lsearch [gmlObject info classes $node] "TaskOperator"] != -1} {
   foreach e [$node get_L_children] {this Update_connection $node $e}
  } 
}

#_____________________________________________________________________________________________________________
method Task_viewer Tree_layout {r} {
 set right_border 0
 lassign  [$this(canvas) bbox $r] rx1 ry1 rx2 ry2; set rtx [expr $rx2 - $rx1]; set rty [expr $ry2 - $ry1]
 set L_desc [list $r]
 
 if {[lsearch [gmlObject info classes $r] "TaskOperator"] != -1} {
   foreach e [$r get_L_children] {
     set L_desc_e [this Tree_layout $e]

	 lassign [eval "$this(canvas) bbox $L_desc_e"] x1 y1 x2 y2
	   set dx [expr $right_border - $x1]; incr right_border [expr $x2 - $x1 + 10]
	   set dy [expr 20 - $y1 + $rty]
	 
	 foreach d $L_desc_e {
	   $this(canvas) move $d $dx $dy
	   lassign [$this(canvas) bbox $d] x1 y1 x2 y2
	   TK_representation_of_$d set_x $x1; TK_representation_of_$d set_y $y1
	  }
	 
	 set L_desc [concat $L_desc $L_desc_e]
    }
   
   if {[llength $L_desc]} {
	   lassign [eval "$this(canvas) bbox $L_desc"] x1 y1 x2 y2; set mx [expr ($x2 + $x1) / 2]
	   $this(canvas) move $r [expr $mx - $rx1 - $rtx / 2] [expr - $ry1]
	   lassign [$this(canvas) bbox $r] x1 y1 x2 y2
		 TK_representation_of_$r set_x $x1; TK_representation_of_$r set_y $y1
	  }
  }
  
 
 return [concat [list $r] $L_desc]
}

#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
method Task_viewer set_current_element {e x y} {
 set this(current_element) $e
 set this(last_x) $x
 set this(last_y) $y
 if {$e != ""} {$this(canvas) raise $e}
}

Manage_CallbackList Task_viewer [list set_current_element] end

#___________________________________________________________________________________________________________________________________________
method Task_viewer get_current_contextual_element { } {return $this(current_contextual_element)}
method Task_viewer set_current_contextual_element {e} {set this(current_contextual_element) $e }

#___________________________________________________________________________________________________________________________________________
method Task_viewer trigger {W X Y D} {
    set w [winfo containing -displayof $W $X $Y]
    if { $w == $this(canvas) } {
        set x [expr {$X-[winfo rootx $w]}]
        set y [expr {$Y-[winfo rooty $w]}]
        if {$D > 0} {
		  set D [expr $D / 100.0]
		 } else {set D [expr 100.0 / (-$D)]}
		set this(delta) $D
	event generate $w <<Wheel>> -rootx $X -rooty $Y -x $x -y $y
   }
 }

#___________________________________________________________________________________________________________________________________________
method Task_viewer get_delta {} {return $this(delta)}

#___________________________________________________________________________________________________________________________________________
method Task_viewer Zoom {x y factor} {
 set canvas $this(canvas)
 set this(zoom_factor)   [expr $this(zoom_factor) * $factor]
 this Zoom_canvas $objName [expr 1.0/$factor] $x $y
 $canvas itemconfigure TEXT_$objName -font "Times [expr int(12.0 / $this(zoom_factor) )] normal"
 
 foreach root $this(L_root_task) {
   this Update_all_connections $root
  }
}

#___________________________________________________________________________________________________________________________________________
method Task_viewer Zoom_canvas {e factor x y} {
 $this(canvas) scale $e $x $y $factor $factor
}

#___________________________________________________________________________________________________________________________________________
method Task_viewer get_zoom_factor {} {return $this(zoom_factor)}


#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
source CT_viewer.tcl

#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
method Task_viewer Assert_traces_succeed {L_traces} {
 this Start_simulation
 set i 0
 foreach t $L_traces {
   incr i
   set name [lassign $t obj mtd]
   if {[catch [list $obj $mtd] err]} {
     error "Error during the evaluation of the trace of index $i \"$name\", the command \"$obj $mtd\" returned :\n$err"
    }
  }
}

#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________________________________
proc Display_class_description {C {RE_OK .} {RE_not_OK ^$}}  {
	set L_mtd [list] 
	foreach m [gmlObject info methods $C] {
		 if {[regexp $RE_OK $m] && ![regexp $RE_not_OK $m]} {lappend L_mtd $m}
		}
	set L_classes [list $C]; set L_classes [concat $L_classes [gmlObject info classes $C]]
	
	foreach c $L_classes {set L_mtd_$c [list]}
	foreach m $L_mtd {
		 foreach c $L_classes {
			 if {![catch {set argsL [gmlObject info arglist $c $m]} err]} {
				 lappend L_mtd_$c [list $m $argsL]
				}
			}
		}
		
	# Display
	foreach c $L_classes {
		 puts "$c"
		 foreach m [subst \$L_mtd_$c] {
			 puts "\t$m"
			}
		}
}

