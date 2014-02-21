#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
#_____________________________________________________________________________________________________________
method Task_server constructor {port} {
 set this(port) $port
 
 socket -server "$objName New_connection" $port
}

#_____________________________________________________________________________________________________________
method Task_server New_connection {chan ad num} {
 fconfigure $chan -blocking 0
   set this(${chan},msg) ""
   set this(${chan},msg_attended_length) -1
 fileevent $chan readable "$objName Read_message $chan"
 fconfigure $chan -encoding utf-8
 #puts "$objName : Connection de la part de $ad;$num sur $chan"
 lappend this(clients) $chan
}

#_____________________________________________________________________________________________________________
method Task_server Read_message {chan} {
  if { [eof $chan] } {
    close $chan
	set this(clients) [lremove $this(clients) $chan]
  } else {append this(${chan},msg) [read $chan]
				  if {$this(${chan},msg_attended_length) == -1} {
					set pos [string first " " $this(${chan}msg)]
				    set this(${chan},msg_attended_length) [string range $this(${chan},msg) 0 [expr $pos - 1]]
					set this(${chan},msg)                 [string range $this(${chan},msg) [expr $pos + 1] end]
				   }
	              set recept [string length $this(${chan},msg)]
				  if {$recept >= $this(${chan},msg_attended_length)} {
				    set original_msg $this(${chan},msg)
					if {[catch {$objName Analyse_message $chan this(${chan},msg)} err]} {
					  puts $err					  
					  set err_txt "ERROR in COMETs:<br/>message was :<br/>$original_msg<br/>ERROR was<br/>$err"
	                  puts $chan $err_txt
					 }
					set this(${chan},msg_attended_length) -1
					set this(${chan},msg)                 ""
					
					set this(clients) [lremove $this(clients) $chan]
					
					unset this(${chan},msg_attended_length)
					unset this(${chan},msg)
					
					close $chan
				   }
		}
}

#_____________________________________________________________________________________________________________
method Task_server Analyse_message {chan msg_name} {
 upvar $msg_name msg
 
 puts "Message received from $chan :\n$msg"
}
