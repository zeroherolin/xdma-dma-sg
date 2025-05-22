. ./dma_param.sh

#--------------------- 启动MM2S通道（H2C）---------------------#
echo "设置当前描述符地址（CURDESC）..."

addr_hex=$(printf "0x%x" $MM2S_CURDESC)
val_hex=$(printf "0x%x" $((DMA_DESC0 + XDMA_BIAS)))
echo "call \"reg_rw $dev $addr_hex w $val_hex\""
err=$("$tools/reg_rw" "$dev" $addr_hex w $val_hex)

echo "启动通道（DMACR.RS=1）..."

addr_hex=$(printf "0x%x" $MM2S_DMACR)
echo "call \"reg_rw $dev $addr_hex w\""
mm2s_dmacr=$("$tools/reg_rw" "$dev" $addr_hex w | awk '/Read 32-bit value/ {print $NF}')
val_hex=$(printf "0x%x" $((mm2s_dmacr | RS_MASK)))
echo "call \"reg_rw $dev $addr_hex w $val_hex\""
err=$("$tools/reg_rw" "$dev" $addr_hex w $val_hex)

echo "设置尾部描述符（TAILDESC）触发传输..."

addr_hex=$(printf "0x%x" $MM2S_TAILDESC)
val_hex=$(printf "0x%x" $((DMA_DESC1 + XDMA_BIAS)))
echo "call \"reg_rw $dev $addr_hex w $val_hex\""
err=$("$tools/reg_rw" "$dev" $addr_hex w $val_hex)

echo "轮询MM2S（H2C）状态..."

while true; do
    addr_hex=$(printf "0x%x" $MM2S_DMASR)
    echo "call \"reg_rw $dev $addr_hex w\""
    mm2s_dmasr=$("$tools/reg_rw" "$dev" $addr_hex w | awk '/Read 32-bit value/ {print $NF}')
    check_dma_error $mm2s_dmasr
    if [ $((mm2s_dmasr & HALTED_MASK)) -ne 0 ]; then
        echo -e "\033[31m[错误] MM2S通道已停止\033[0m"
        exit 1
    fi
    if [ $((mm2s_dmasr & IDLE_MASK)) -ne 0 ]; then
        break
    fi
    sleep 0.1
done

echo "MM2S（H2C）传输完成"