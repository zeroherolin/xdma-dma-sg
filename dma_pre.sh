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
}

# 描述符0：H2C传输到Buffer0（MM2S）
write_descriptor $DMA_DESC0 $DMA_DESC1 $BUFFER_ADDR0 $BUFFER_SIZE $SOF_MASK

# 描述符1：H2C传输到Buffer1（MM2S）
write_descriptor $DMA_DESC1 $DMA_DESC0 $BUFFER_ADDR1 $BUFFER_SIZE $EOF_MASK

# 描述符2：C2H从Buffer0读取（S2MM）
write_descriptor $DMA_DESC2 $DMA_DESC3 $BUFFER_ADDR0 $BUFFER_SIZE $SOF_MASK

# 描述符3：C2H从Buffer1读取（S2MM）
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
        echo "描述符检查错误：$desc_base + 0x00"
        exit 1
    fi

    read_dec=$(reg_read $((desc_base + 0x08)))
    if [ $read_dec -ne $buffer_addr ]; then
        echo "描述符检查错误：$desc_base + 0x08"
        exit 1
    fi

    read_dec=$(reg_read $((desc_base + 0x18)))
    if [ $read_dec -ne $((buffer_size | flags)) ]; then
        echo "描述符检查错误：$desc_base + 0x18"
        exit 1
    fi
}

check_descriptor $DMA_DESC0 $DMA_DESC1 $BUFFER_ADDR0 $BUFFER_SIZE $SOF_MASK
check_descriptor $DMA_DESC1 $DMA_DESC0 $BUFFER_ADDR1 $BUFFER_SIZE $EOF_MASK
check_descriptor $DMA_DESC2 $DMA_DESC3 $BUFFER_ADDR0 $BUFFER_SIZE $SOF_MASK
check_descriptor $DMA_DESC3 $DMA_DESC2 $BUFFER_ADDR1 $BUFFER_SIZE $EOF_MASK

echo "描述符检查完成"

echo "DMA复位..."
#--------------------- 复位DMA MM2S ---------------------#
reg_write $MM2S_DMACR $RESET_MASK

# 等待复位完成
while true; do
    mm2s_dmacr_dec=$(reg_read $MM2S_DMACR)
    if [ $((mm2s_dmacr_dec & RESET_MASK)) -eq 0 ]; then
        break
    fi
    sleep 0.1
done

#--------------------- 复位DMA S2MM---------------------#
reg_write $S2MM_DMACR $RESET_MASK

# 等待复位完成
while true; do
    s2mm_dmacr_dec=$(reg_read $S2MM_DMACR)
    if [ $((s2mm_dmacr_dec & RESET_MASK)) -eq 0 ]; then
        break
    fi
    sleep 0.1
done

echo "DMA复位完成"