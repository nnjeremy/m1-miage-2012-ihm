set found_Gmlobject 0
foreach loaded_dll [info loaded] {
    if {[string equal [lindex $loaded_dll 1] Gmlobject]} {set found_Gmlobject 1; break}
}

if {!$found_Gmlobject || [lsearch [info command] method] == -1} {
    if {[catch {load gmlObject.dll} err]} {
	    puts "Windows binary failed : $err"
		if {[catch {load libgiltclobject.so} err]} {
			puts "Impossible to load the binary version of gmlObject, trying to load the TCL version..."
			source gmlObject.old_tcl
		} else {
			proc gmlObject args { eval "gilObject $args"}
			puts "Linux binary version of gmlobject loaded"
		}
    } else {puts "Windows binary version of gmlobject loaded"}
} else {puts "gmlObject has still been loaded"}
