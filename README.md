# MyMatrix
    我相信制作 *.dbc 文件是一件及其让人厌烦的事情，但是 *.dbc 文件又是如此的重要。如果可以将 *.xls(x) 电子表格格式的通信矩阵自动转换为 *.dbc 文件，那这岂不是汽车开发工程师的福音。基于此，我制作了一个 Bat 批处理脚本：
    A. 支持将 *.xls(x) 格式的通信矩阵转换为 *.dbc 格式的通信矩阵；
    B. 支持将 *.dbc 格式的通信矩阵转换为 *.xls(x) 格式的通信矩阵；
    C. 通过 *.dbc、*xls(x) 文件生成节点交互图；
    D. 通过 *.dbc、*xls(x) 文件生成简易的报文结构体源文件和头文件。
    在我之前，已有人完成了这样的工作，但是他们的程序需要一些外部依赖，而我想做的是尽量减少对外部环境的依赖，甚至不依赖外部环境，任何人都可以通过简单的操作，点一下鼠标就可以完成通信矩阵转换的工作，所以我最初设想通过批处理指令来完成这样的工作。
    脚本的使用方法为：将待转换的文件拖放到批处理脚本上，批处理脚本将弹出一个 CMD 命令行窗口，等待直到它工作完成。转换完成之后，在该目录下，将生成你所需要的文件，其中，名为 “AutoTool.bat” 脚本记录你上一次使用批处理脚本执行的操作，你可以双击它重复上一次的操作，就不用每次就转换的文件拖放到批处理脚本上。如果第一次转换不成功，请多尝试几次。
    虽然批处理脚本实现了以上的功能，但是在将 *.dbc 格式的通信矩阵转换为 *.xls(x) 格式的通信矩阵过程中，转换时间比较长，效率低，不适合信号和报文比较多的通信矩阵，当然，如果你不在意时间的话，也可以使用它进行转换。
    感谢看到这里，希望我的工作对你有帮助。
    （本脚本只作为学习交流使用，不对任何用于商业目的导致产生的问题负责！）
