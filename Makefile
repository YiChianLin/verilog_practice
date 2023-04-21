# your project folder name
project := HW1
# top module
top_m := MMS_tb

vfile = $(project)/*.v
svfile = $(project)/*.sv

top_module_name = work.$(top_m)

# show the result in cmd
# In cmd shell : > make project="<project name>" top_m="<top module name>"
all :
	-@vlib work
	-@vlog $(vfile) $(svfile)
	-@vsim -c -do "run -all" $(top_module_name)

# show modelsim in gui
vsim : 
	-@vlib work
	-@vlog $(vfile) $(svfile)
	-@vsim $(top_module_name)

