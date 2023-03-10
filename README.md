## verilog_practice
 
* Download the modelsim for free : [link](https://www.intel.com/content/www/us/en/products/details/fpga/development-tools/quartus-prime/resource.html)
    * step 1 : sign or create an account
    * step 2 : download from "Lite Edition" (free, no license required)
    * step 3 : select version 20.1.1
    * step 4 : individual file -> download modelsim for .exe
    * step 5 : installation

* Use the modelsim in two methods:
    * modelsim.exe : your download path should be here `C:\intelFPGA\20.1\modelsim_ase\win32aloem\modelsim.exe`
    * use modelsim instruction(make sure the modelsim was set in your PC's Environment Variables)
        * Add the path `C:\intelFPGA\20.1\modelsim_ase\win32aloem` and restart your device

* Modelsim instruction(use commander)
Create your verilog work file 
```
vlib work
```

Compile your verilog code, it will present your top module 
```
vlog *.v // compile all or you can compile individually
```

Open the modelsim interface
```
vism work.<your top module name>
```

Run your code, enter the instruction in transcript
```
run -all //if you don't set the finish, it would run the time infinitely
run 10ns //you can just run 10ns 
```

* Note that if you change your code, you need to recompile again