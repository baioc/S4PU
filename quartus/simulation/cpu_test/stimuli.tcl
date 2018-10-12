restart -f

force /clock 0 0ns, 1 10ns -r 20ns
force /reset_n 0 0ns, 1 15ns
force /mode 1 0ns

run @1814730ns

set t 0
for { set i 0 } { $i < 19 } { incr i } {
    echo $i "th EMIT"
    set t [scan [lindex [expr [searchlog -expr {cpu_write == '1'} [expr $t]ns]] 0] "%d"]
    set f [examine -time [expr $t]ns /cpu_writedata]
    echo "    " $f
}
