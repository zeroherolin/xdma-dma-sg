. ./dma_param.sh

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
