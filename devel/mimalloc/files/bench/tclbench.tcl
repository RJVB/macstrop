# http://www.metacard.com/tclbench.html

proc repeatloop count {
    for {set i 0}  {$i < $count} {incr i} {
    }
}

proc ifact1loop count {
    for {set i 0}  {$i < $count} {incr i} {
        set x 1.0
	for {set j 1}  {$j <= 100} {incr j} {
	    set x [expr $x * $j]
        }
    }
}

proc ifact2loop count {
    for {set i 0}  {$i < $count} {incr i} {
        set x 1.0
	for {set j 1}  {$j <= 100} {incr j} {
            if { $j != 1.0 } {
		set x [expr $x * $j]
	    }
        }
    }
}

proc fact x {
    if { $x <= 1 } {
	return 1.0
    }
    expr $x * [fact [expr $x - 1]]
}

proc factloop count {
    for {set i 0}  {$i < $count} {incr i} {
	fact 100.0
    }
}

proc execloop count {
    for {set i 0}  {$i < $count} {incr i} {
# MetaCard actually does the following
#	exec sh -c echo test
	exec echo test
    }
}

proc fileloop count {
    for {set i 0}  {$i < $count} {incr i} {
	set myoutput [open "/tmp/tmp" w]
	for {set j 0}  {$j < 100} {incr j} {
	    puts $myoutput "LINE -> $j"
	}
	close $myoutput
	set myoutput [open "/tmp/tmp" r]
	set j 0
	while { [gets $myoutput line] >= 0 } {
	    incr j
	}
	close $myoutput
	if {$j != 100} {
	    puts "WARNING: Retrieved only $j lines!"
	}
    }
}

proc stems {} {
    set f [open "/usr/share/dict/words" r]
    set words [read $f]
    close $f
    foreach w $words {
	if {[string length $w] == 4} {
	    set lastfour $w
	} elseif {([string length $w] == 5) && ([string first ' $w] == -1)\
		&& (([string index $w 4] != "s")\
		|| ([string range $w 0 3] != $lastfour))} {
	    append wordlist([string range $w 0 2]) $w
	}
    }
    foreach w [lsort [array names wordlist]] {
	set t $wordlist($w)
	set nwords [expr [string length $t] / 5]
	if {$nwords > 1} {
	    append outputstring "$w $nwords\t[string range $t 0 4]\n"
	    for { set n 1 } { $n < $nwords } { incr n } {
		set i [expr $n * 5]
		append outputstring \
			"\t[string range $t $i [expr $i + 4]]\n"
	    }
	}
    }
#puts $outputstring
}

proc stemsloop count {
    for {set i 0}  {$i < $count} {incr i} {
	stems
    }
}

set NREPEAT [expr 50000000 / 4]
set NIFACT1 [expr 2000 / 4]
set NIFACT2 [expr 2000 / 4]
set NFACT [expr 2000 / 4]
set NSYSTEM [expr 500 / 4]
set NFILE [expr 2000 / 4]
set NSTEM [expr 10 / 4]
set totaltime 0

scan [time {repeatloop $NREPEAT}] {%d} result
set ttime [expr $result / 1000000.0]
# puts "$NREPEAT repeats in $ttime"
set totaltime [expr $totaltime + $ttime]

scan [time {ifact1loop $NIFACT1}] {%d} result
set ttime [expr $result / 1000000.0]
# puts "$NIFACT1 iterative factorial(100) in $ttime"
set totaltime [expr $totaltime + $ttime]

scan [time {ifact2loop $NIFACT2}] {%d} result
set ttime [expr $result / 1000000.0]
# puts "$NIFACT2 iterative factorial(100) with 'if' in $ttime"
set totaltime [expr $totaltime + $ttime]

scan [time {factloop $NFACT}] {%d} result
set ttime [expr $result / 1000000.0]
# puts "$NFACT recursive factorial(100) in $ttime"
set totaltime [expr $totaltime + $ttime]

scan [time {execloop $NSYSTEM}] {%d} result
set ttime [expr $result / 1000000.0]
# puts "$NSYSTEM exec calls in $ttime"
set totaltime [expr $totaltime + $ttime]

scan [time {fileloop $NFILE}] {%d} result
set ttime [expr $result / 1000000.0]
# puts "$NFILE 100-line file writes and reads in $ttime"
set totaltime [expr $totaltime + $ttime]

scan [time {stemsloop $NSTEM}] {%d} result
set ttime [expr $result / 1000000.0]
# puts "$NSTEM stem generation took $ttime"
set totaltime [expr $totaltime + $ttime]

puts "tclbench.tcl total time was $totaltime"
