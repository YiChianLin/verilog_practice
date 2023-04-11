# your project folder name
target_name := HW1
# top module
top_module_name := MMS_tb

vfile = $(target_name)/*.v
top_module = work.$(top_module_name)

# show the result in cmd
all :
	-@vlib work
	-@vlog $(vfile)
	-@vsim -c -do "run -all" $(top_module)

# show modelsim gui
vsim : 
	-@vsim $(top_module)

