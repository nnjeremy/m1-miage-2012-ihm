#Task_viewer_mode_Network
package require http

#_____________________________________________________________________________________________________________
method Task_viewer Send_code_over_network {} {
	# Get the actual code
	set str ""
	foreach op [gmlObject info specializations TaskOperator] {
		 append str [gmlObject info class $op]
		}
	
	# Requête HTTP
	set token [::http::geturl $url -query [::http::formatQuery code $str]]
	
}
