import torch
import cv2
import numpy as np
import os

def atconv(img):
    ### image data ###
    # resize the image to 64 x 64
    img = cv2.resize(img, (64, 64), interpolation=cv2.INTER_AREA)

    # transter to grayscale
    gray_img = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)

    # save the image data for pattern 1(as img.dat)
    gray_img_data = gray_img.flatten()
    gray_img_data = np.reshape(gray_img_data, (len(gray_img_data), -1))
    gray_img_data = gray_img_data.astype(np.uint16) # transter the format the data should be 13bit
    gray_img_data = gray_img_data * 16  # shift 4

    gray_data = []
    # save the data in binary string
    for i in range(len(gray_img_data)):
        gray_data.append(f'{gray_img_data[i][0]:013b}')

    # write into pattern data
    np.savetxt('./data/img.dat', gray_data, fmt='%s')
    print("Write the image grayscale data in path : " + "./data/img.dat")

    ### Layer 0 golden data ###
    # Convolution setting 
    # ref : https://pytorch.org/docs/stable/generated/torch.nn.Conv2d.html
    conv_m = torch.nn.Conv2d(in_channels = 1, out_channels = 1, kernel_size = (3, 3), dilation = (2, 2), groups=1, bias=True, stride=(1,1)
                            , padding=(2,2), padding_mode='replicate')
    # ref : https://pytorch.org/docs/stable/generated/torch.nn.ReLU.html
    relu_m = torch.nn.ReLU()
    # ref : https://pytorch.org/docs/stable/generated/torch.nn.MaxPool2d.html
    maxpool_m = torch.nn.MaxPool2d(kernel_size = (2, 2), stride = (2, 2))
    # kernel weight setting
    conv_m.weight.data = torch.FloatTensor( 
        [[[[-0.0625, -0.125, -0.0625],
        [  -0.25,      1,   -0.25],
        [-0.0625, -0.125, -0.0625]]]]
    )
    # bias setting
    conv_m.bias.data = torch.FloatTensor([-0.75])

    # modify the input data format
    gray_img = torch.FloatTensor(gray_img.reshape(1, 1, 64, 64))

    # use module to calculate
    output = conv_m(gray_img)
    output = relu_m(output)
    output_maxpool = maxpool_m(output)

    # data processing
    output = output.data.squeeze().numpy()
    output = output.flatten()
    output = np.reshape(output, (len(output), -1))
    output = output * 16 # shift 4
    output = output.astype(np.uint16) # transter the format

    # float to binary 
    gray_data_L0 = []
    for i in range(len(output)):
        gray_data_L0.append(f'{output[i][0]:013b}')

    # write into pattern data
    np.savetxt('./data/layer0_golden.dat', gray_data_L0, fmt='%s')
    print("Write the convolution data in path : " + "./data/layer0_golden.dat")

    ### Layer 1 golden data ###
    # data processing
    output_maxpool = output_maxpool.data.squeeze().numpy()
    output_maxpool_plt = cv2.cvtColor(output_maxpool, cv2.COLOR_BGR2RGB)
    output_maxpool = output_maxpool.flatten()
    output_maxpool = np.reshape(output_maxpool, (len(output_maxpool), -1))
    output_maxpool = output_maxpool * 16 # shift 4

    # round up
    for i in range(len(output_maxpool)):
        if ((output_maxpool[i][0] % 16) > 0):
            output_maxpool[i][0] = output_maxpool[i][0] - (output_maxpool[i][0] % 16) + 16
        else :
            output_maxpool[i][0] = output_maxpool[i][0]
    output_maxpool = output_maxpool.astype(np.uint16) # transter the format

    # float to binary 
    gray_data_L1 = []
    for i in range(len(output_maxpool)):
        gray_data_L1.append(f'{output_maxpool[i][0]:013b}')

    # write into pattern data
    np.savetxt('./data/layer1_golden.dat', gray_data_L1, fmt='%s')
    print("Write the maxpooling data from convolution data in path : " + "./data/layer1_golden.dat")

if __name__=='__main__':
    # check the folder of storing the data
    folder_data_path = "data"
    is_exist_path = os.path.exists(folder_data_path)
    if not is_exist_path:
        os.makedirs(folder_data_path)
        print("Create the data folder")
    else:
        print("Folder exist")

    # image path
    img_path_png = "image.png"
    img_path_jpg = "image.jpg"

    # check and load the pattern image
    img = cv2.imread(img_path_png)
    if (type(img) is not np.ndarray):
        img = cv2.imread(img_path_jpg)
        print("Fail to open the the png image")

    # input the image
    if (type(img) is not np.ndarray):
        print("Fail to open the the jpg image")
        print("Invaild image path!")
    else:
        print("Successfully open the image")
        atconv(img)