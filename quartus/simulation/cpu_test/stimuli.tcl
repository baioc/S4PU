restart -f


change /ARCH 16

force /clock 0 0ns, 1 10ns -r 20ns

force /reset_n 0 0ns, 1 15ns
force /mode 1 0ns


run
