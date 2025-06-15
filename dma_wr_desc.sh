. ./dma_param.sh

#--------------------- 配置DMA-SG描述符 ---------------------#
echo "写入描述符..."

write_descriptor() {
    local desc_base=$1
    local next_desc=$2
    local buffer_addr=$3
    local buffer_size=$4
    local mask=$5

    reg_write $((desc_base + 0x00)) $((next_desc + XDMA_BIAS))
    reg_write $((desc_base + 0x08)) $buffer_addr
    reg_write $((desc_base + 0x18)) $((buffer_size | mask))
    reg_write $((desc_base + 0x1C)) $((0))
}

# 描述符0：H2C传输到Buffer0（S2MM）
write_descriptor $DMA_DESC0 $DMA_DESC1 $BUFFER_ADDR0 $BUFFER_SIZE $SOF_MASK

# 描述符1：H2C传输到Buffer1（S2MM）
write_descriptor $DMA_DESC1 $DMA_DESC0 $BUFFER_ADDR1 $BUFFER_SIZE $EOF_MASK

# 描述符2：C2H从Buffer0读取（MM2S）
write_descriptor $DMA_DESC2 $DMA_DESC3 $BUFFER_ADDR0 $BUFFER_SIZE $SOF_MASK

# 描述符3：C2H从Buffer1读取（MM2S）
write_descriptor $DMA_DESC3 $DMA_DESC2 $BUFFER_ADDR1 $BUFFER_SIZE $EOF_MASK

echo "描述符写入完成"

#--------------------- 检查描述符 ---------------------#
echo "检查描述符..."

check_descriptor() {
    local desc_base=$1
    local next_desc=$2
    local buffer_addr=$3
    local buffer_size=$4
    local flags=$5

    read_dec=$(reg_read $((desc_base + 0x00)))
    if [ $read_dec -ne $((next_desc + XDMA_BIAS)) ]; then
        echo "\033[31m[错误] 地址：0x$(printf '%08x' $((desc_base + 0x00))) 值：0x$(printf '%08x' $read_dec)\033[0m"
        exit 1
    fi

    read_dec=$(reg_read $((desc_base + 0x08)))
    if [ $read_dec -ne $buffer_addr ]; then
        echo "\033[31m[错误] 地址：0x$(printf '%08x' $((desc_base + 0x08))) 值：0x$(printf '%08x' $read_dec)\033[0m"
        exit 1
    fi

    read_dec=$(reg_read $((desc_base + 0x18)))
    if [ $read_dec -ne $((buffer_size | flags)) ]; then
        echo "\033[31m[错误] 地址：0x$(printf '%08x' $((desc_base + 0x18))) 值：0x$(printf '%08x' $read_dec)\033[0m"
        exit 1
    fi

    read_dec=$(reg_read $((desc_base + 0x1C)))
    if [ $read_dec -ne $((0)) ]; then
        echo "\033[31m[错误] 地址：0x$(printf '%08x' $((desc_base + 0x1C))) 值：0x$(printf '%08x' $read_dec)\033[0m"
        exit 1
    fi
}

check_descriptor $DMA_DESC0 $DMA_DESC1 $BUFFER_ADDR0 $BUFFER_SIZE $SOF_MASK
check_descriptor $DMA_DESC1 $DMA_DESC0 $BUFFER_ADDR1 $BUFFER_SIZE $EOF_MASK
check_descriptor $DMA_DESC2 $DMA_DESC3 $BUFFER_ADDR0 $BUFFER_SIZE $SOF_MASK
check_descriptor $DMA_DESC3 $DMA_DESC2 $BUFFER_ADDR1 $BUFFER_SIZE $EOF_MASK

echo "描述符检查完成"
