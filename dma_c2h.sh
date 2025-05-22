. ./dma_param.sh

#--------------------- 启动S2MM通道（C2H）---------------------#
echo "设置当前描述符地址（CURDESC）..."

reg_write $S2MM_CURDESC $((DMA_DESC2 + XDMA_BIAS))

echo "启动通道（DMACR.RS=1）..."

s2mm_dmacr_dec=$(reg_read $S2MM_DMACR)

reg_write $S2MM_DMACR $((s2mm_dmacr_dec | RS_MASK))

echo "设置尾部描述符（TAILDESC）触发传输..."

reg_write $S2MM_TAILDESC $((DMA_DESC3 + XDMA_BIAS))

echo "轮询S2MM（C2H）状态..."

while true; do
    s2mm_dmasr_dec=$(reg_read $S2MM_DMASR)
    check_dma_error $s2mm_dmasr_dec
    if [ $((s2mm_dmasr_dec & HALTED_MASK)) -ne 0 ]; then
        echo -e "\033[31m[错误] S2MM通道已停止\033[0m"
        exit 1
    fi
    if [ $((s2mm_dmasr_dec & IDLE_MASK)) -ne 0 ]; then
        break
    fi
    sleep 0.1
done

echo "S2MM（C2H）传输完成"