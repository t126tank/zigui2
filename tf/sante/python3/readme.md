upgraded

■win10 + py3.6

>py -3 -m pip install beautifulsoup4
>py -3 -m pip install tensorflow
>py -3 -m pip install --upgrade tensorflow
>py -3 -m pip install tensorlayer
>py -3 -m pip install lxml
>py -3 -m pip install pandas

    "TensorLayer does not support Tensorflow version older than 2.0.0.\n"
RuntimeError: TensorLayer does not support Tensorflow version older than 2.0.0.
Please update Tensorflow with:
 - `pip install --upgrade tensorflow`
 - `pip install --upgrade tensorflow-gpu`
https://github.com/tensorlayer/openpose-plus/issues/203#issuecomment-507225606

> py -3 -m pip install --upgrade tensorflow==1.12
> py -3 -m pip install --upgrade tensorlayer==1.11.0
