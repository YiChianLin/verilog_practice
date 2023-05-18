Package installation 
----------------------------------------------------------------------------------------------------------------------------------------
The package that you need should be installed in your environment, it provide the "requirement.txt" to install totally.

The installing instruction:
>> pip install -r requirement.txt -f https://download.pytorch.org/whl/torch_stable.html

If you want to install the package individually, the package list below.
>> pip install numpy
>> pip install opencv-python
>> pip install torch==1.7.1+cu110 torchvision==0.8.2+cu110 torchaudio==0.7.2 -f https://download.pytorch.org/whl/torch_stable.html

Execution
----------------------------------------------------------------------------------------------------------------------------------------
Start to execute the program with instuction that you should place the name of "image.jpg" or "image.png" image data below the program:
>> python main.py

When it executed successfully, it would print the success message and produce the .dat in data folder.
>> Successfully open the image
>> Write the image grayscale data in path : ./data/img.dat
>> Write the convolution data in path : ./data/layer0_golden.dat
>> Write the maxpooling data from convolution data in path : ./data/layer1_golden.dat

When it executed with error, it would print the error message.
>> Fail to open the the png image
>> Fail to open the the jpg image
>> Invaild image path!