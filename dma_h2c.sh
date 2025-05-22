. ./dma_param.sh

#--------------------- 启动MM2S通道（H2C）---------------------#
echo "设置当前描述符地址（CURDESC）..."

reg_write $MM2S_CURDESC $((DMA_DESC0 + XDMA_BIAS))

echo "启动通道（DMACR.RS=1）..."

mm2s_dmacr_dec=$(reg_read $MM2S_DMACR)

reg_write $MM2S_DMACR $((mm2s_dmacr_dec | RS_MASK))

echo "设置尾部描述符（TAILDESC）触发传输..."

reg_write $MM2S_TAILDESC $((DMA_DESC1 + XDMA_BIAS))

echo "轮询MM2S（H2C）状态..."

while true; do
    mm2s_dmasr_dec=$(reg_read $MM2S_DMASR)
    check_dma_error $mm2s_dmasr_dec
    if [ $((mm2s_dmasr_dec & HALTED_MASK)) -ne 0 ]; then
        echo -e "\033[31m[错误] MM2S通道已停止\033[0m"
        exit 1
    fi
    if [ $((mm2s_dmasr_dec & IDLE_MASK)) -ne 0 ]; then
        break
    fi
    sleep 0.1
done

echo "MM2S（H2C）传输完成"