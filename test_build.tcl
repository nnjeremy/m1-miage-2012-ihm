package require Tk

source gmlObject.tcl

if {[info procs lremove] == ""} {
	proc lremove2 {L args} {
		 foreach a $args {
			 set pos [lsearch $L $a]
			 if {$pos >= 0} {set L [lreplace $L $pos $pos]}
			}
		 return $L
		}
}

source utils.tcl

source Task_simulator.tcl
source Task_viewer.tcl

source Task_operators.tcl

Task_viewer TV ""
