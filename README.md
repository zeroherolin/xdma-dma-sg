# Configuring FPGA DMA-SG via PCIe XDMA

This repository provides a comprehensive guide to working with the XDMA driver for DMA-SG operations.

The flow is based on connecting the DMA-s port to PCIe XDMA. This may seem redundant, but it is just for testing. You can connect the s-port to any stream device without reconstructing the shell scripts.

## Getting Started

### Prerequisites

  * Make sure you have the necessary hardware and software environment set up, including the DMA IP drivers [[https://github.com/Xilinx/dma_ip_drivers](https://github.com/Xilinx/dma_ip_drivers)].
  * Make sure you have the required permissions to execute commands and access devices.

### Instructions

- 编译XDMA驱动和tools
``` bash
cd external/dma_ip_drivers/XDMA/linux-kernel/xdma
make
sudo insmod xdma.ko # 临时安装
cd ../tools
make
```

- 生成测试数据
``` bash
# cd external/dma_ip_drivers/XDMA/linux-kernel/tools
rm -f *.bin
# dd if=/dev/zero of=test0.bin bs=4096 count=1 # 生成全0
python -c 'open("test0.bin", "wb").write(bytes([i % 256 for i in range(4096)]))' # 生成递增数
cd ../../../../..
```

- 添加可执行权限
``` bash
sudo chmod +x dma_rst.sh
sudo chmod +x dma_wr_desc.sh
sudo chmod +x dma_h2c.sh
sudo chmod +x dma_c2h.sh
```

- 执行测试
``` bash
# DMA软复位
sudo ./dma_rst.sh

# XDMA写DMA数据（to MM）
sudo external/dma_ip_drivers/XDMA/linux-kernel/tools/dma_to_device -d /dev/xdma0_h2c_0 \
    -f external/dma_ip_drivers/XDMA/linux-kernel/tools/test0.bin -s 4096 -a 0 -c 1

# DMA写描述符
sudo ./dma_wr_desc.sh

# DMA S2MM（H2C）传输
sudo ./dma_h2c.sh

# DMA MM2S（C2H）传输
sudo ./dma_c2h.sh

# XDMA读取DMA数据（from MM）
sudo external/dma_ip_drivers/XDMA/linux-kernel/tools/dma_from_device -d /dev/xdma0_c2h_0 \
    -f external/dma_ip_drivers/XDMA/linux-kernel/tools/test1.bin -s 4096 -a 0 -c 1

# 核对数据
xxd external/dma_ip_drivers/XDMA/linux-kernel/tools/test1.bin
```

## Flow
<a href="fig/flow.png"><img width=900 src="fig/flow.png"/></a>
