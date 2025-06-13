# XDMA设备
dev="/dev/xdma0_user"

# 可执行文件路径
tools="/home/kylin/桌面/dma_ip_drivers/XDMA/linux-kernel/tools"

#--------------------- 参数定义 ---------------------#
# DMA IP寄存器基地址
DMA_BASE=$((0x60000))

# 描述符地址（64字节对齐）
BRAM_BASE=$((0x20000))
XDMA_BIAS=$((0x44a00000))
DMA_DESC0=$((BRAM_BASE + 0))
DMA_DESC1=$((BRAM_BASE + 64))
DMA_DESC2=$((BRAM_BASE + 128))
DMA_DESC3=$((BRAM_BASE + 192))

# DDR Buffer地址
DDR_BASE=$((0x80000000))
BUFFER_SIZE=$((1024))
BUFFER_ADDR0=$((DDR_BASE + 0))
BUFFER_ADDR1=$((DDR_BASE + BUFFER_SIZE))

#--------------------- DMA寄存器控制 ---------------------#
# MM2S通道寄存器偏移（H2C）
MM2S_DMACR=$((DMA_BASE + 0x00))
MM2S_DMASR=$((DMA_BASE + 0x04))
MM2S_CURDESC=$((DMA_BASE + 0x08))
MM2S_TAILDESC=$((DMA_BASE + 0x10))

# S2MM通道寄存器偏移（C2H）
S2MM_DMACR=$((DMA_BASE + 0x30))
S2MM_DMASR=$((DMA_BASE + 0x34))
S2MM_CURDESC=$((DMA_BASE + 0x38))
S2MM_TAILDESC=$((DMA_BASE + 0x40))

#--------------------- 掩码定义 ---------------------#
# 描述符掩码
SOF_MASK=$((1 << 27))    # TXSOF/RXSOF (Start of Frame)
EOF_MASK=$((1 << 26))    # TXEOF/RXEOF (End of Frame)
# 控制掩码
RS_MASK=$((1 << 0))      # DMACR.RS位
RESET_MASK=$((1 << 2))   # DMACR.Reset位
# 状态掩码
IDLE_MASK=$((1 << 1))    # DMASR.Idle位
HALTED_MASK=$((1 << 0))  # DMASR.Halted位
ERROR_MASK=$(( (0x7 << 4) | (0x7 << 8) ))

#--------------------- 寄存器读写函数 ---------------------#
reg_read() {
    local addr_dec=$1
    local addr_hex
    local reg_read_hex
    local reg_read_dec

    addr_hex=$(printf "0x%x" "$addr_dec")

    echo "call \"reg_rw $dev $addr_hex w\"" >&2

    reg_read_hex=$("$tools/reg_rw" "$dev" "$addr_hex" w | awk '/Read 32-bit value/ {print $NF}')
    reg_read_dec=$(printf "%d" "$reg_read_hex")

    echo "$reg_read_dec"
}

reg_write() {
    local addr_dec=$1
    local val_dec=$2
    local addr_hex
    local val_hex
    local err

    addr_hex=$(printf "0x%x" "$addr_dec")
    val_hex=$(printf "0x%x" "$val_dec")

    echo "call \"reg_rw $dev $addr_hex w $val_hex\"" >&2

    err=$("$tools/reg_rw" "$dev" "$addr_hex" w "$val_hex")
}

#--------------------- 错误处理函数 ---------------------#
check_dma_error() {
    local dmasr=$1
    if [ $((dmasr & ERROR_MASK)) -ne 0 ]; then
        echo -e "\033[31m[DMA错误] 状态寄存器值：0x$(printf '%08x' $dmasr)\033[0m"
        # 解析具体错误位
        if [ $((dmasr & (1 << 4))) -ne 0 ]; then
            echo " - DMAIntErr: 内部错误"
        fi
        if [ $((dmasr & (1 << 5))) -ne 0 ]; then
            echo " - DMASlvErr: AXI从设备错误"
        fi
        if [ $((dmasr & (1 << 6))) -ne 0 ]; then
            echo " - DMADecErr: 地址解码错误"
        fi
        if [ $((dmasr & (1 << 8))) -ne 0 ]; then
            echo " - SGIntErr: 描述符完整性错误"
        fi
        if [ $((dmasr & (1 << 9))) -ne 0 ]; then
            echo " - SGSlvErr: SG从设备错误"
        fi
        if [ $((dmasr & (1 << 10))) -ne 0 ]; then
            echo " - SGDecErr: SG地址解码错误"
        fi
        exit 1
    fi
}
