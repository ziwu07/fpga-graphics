# run_with_trace.tcl – captures errors and writes full trace to a file
set script_file [lindex $argv 0]
set error_log   "/tmp/yosys_error.log"   ;# Hard‑coded output path

if {[catch {source $script_file} msg]} {
    # Print a short message to console
    puts "Error in $script_file: $msg"
    puts "Full stack trace written to $error_log"

    # Write detailed trace to the log file (overwrites previous content)
    set fh [open $error_log w]
    puts $fh "Error in $script_file: $msg"
    puts $fh "Stack trace:\n$::errorInfo"
    close $fh

    exit 1
}
