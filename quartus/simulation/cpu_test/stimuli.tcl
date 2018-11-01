restart -f

force /CLOCK_50 0 0ns, 1 10ns -r 20ns
force /KEY 1 15ns
force /SW 2000D 0ns

run @2ms

set t 0
for { set i 1 } { $i <= 1 } { incr i } {
    echo "EMIT (" $i "): "
    set t [scan [lindex [expr [searchlog -expr {write == '1'} [expr $t]ns]] 0] "%d"]
    set f [examine -time [expr $t]ns /writedata]
    echo "            " $f
}
