. ./dma_param.sh

#--------------------- 启动S2MM通道（C2H）---------------------#
echo "设置当前描述符地址（CURDESC）..."

addr_hex=$(printf "0x%x" $S2MM_CURDESC)
val_hex=$(printf "0x%x" $((DMA_DESC2 + XDMA_BIAS)))
echo "call \"reg_rw $dev $addr_hex w $val_hex\""
err=$("$tools/reg_rw" "$dev" $addr_hex w $val_hex)

echo "启动通道（DMACR.RS=1）..."

addr_hex=$(printf "0x%x" $S2MM_DMACR)
echo "call \"reg_rw $dev $addr_hex w\""
s2mm_dmacr=$("$tools/reg_rw" "$dev" $addr_hex w | awk '/Read 32-bit value/ {print $NF}')
val_hex=$(printf "0x%x" $((s2mm_dmacr | RS_MASK)))
echo "call \"reg_rw $dev $addr_hex w $val_hex\""
err=$("$tools/reg_rw" "$dev" $addr_hex w $val_hex)

echo "设置尾部描述符（TAILDESC）触发传输..."

addr_hex=$(printf "0x%x" $S2MM_TAILDESC)
val_hex=$(printf "0x%x" $((DMA_DESC3 + XDMA_BIAS)))
echo "call \"reg_rw $dev $addr_hex w $val_hex\""
err=$("$tools/reg_rw" "$dev" $addr_hex w $val_hex)

echo "轮询S2MM（C2H）状态..."

while true; do
    addr_hex=$(printf "0x%x" $S2MM_DMASR)
    echo "call \"reg_rw $dev $addr_hex w\""
    s2mm_dmasr=$("$tools/reg_rw" "$dev" $addr_hex w | awk '/Read 32-bit value/ {print $NF}')
    check_dma_error $s2mm_dmasr
    if [ $((s2mm_dmasr & HALTED_MASK)) -ne 0 ]; then
        echo -e "\033[31m[错误] S2MM通道已停止\033[0m"
        exit 1
    fi
    if [ $((s2mm_dmasr & IDLE_MASK)) -ne 0 ]; then
        break
    fi
    sleep 0.1
done

echo "S2MM（C2H）传输完成"