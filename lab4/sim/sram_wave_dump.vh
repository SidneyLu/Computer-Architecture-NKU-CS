// Sampled only when the sim fileset defines WAVE_DUMP.
// #1 lets the NBA updates from this edge settle, so each row is the new state.
integer wave_fd;
integer wave_cyc;
initial begin
    wave_fd  = $fopen("D:/Architecture/lab4/sim/sram_wave.csv", "w");
    wave_cyc = 0;
    $fdisplay(wave_fd, "cyc,time_ns,fst,ireq,iaddr,iok,idok,irdata,fs_pc,fs_v,fs_inst,br,wait_bd,ds_v,ds_pc,ds_bj,dst,dreq,dwr,daddr,dwdata,dwstrb,dok_a,dok_d,mask,kill,flush,wb_pc");
end
always @(posedge soc_clk) begin
    if (!resetn) begin
        wave_cyc = 0;
    end else begin
        #1;
        wave_cyc = wave_cyc + 1;
        if (wave_cyc <= 4500) begin
            $fdisplay(wave_fd, "%0d,%0d,%0d,%b,%h,%b,%b,%h,%h,%b,%h,%b,%b,%b,%h,%b,%0d,%b,%b,%h,%h,%h,%b,%b,%b,%b,%b,%h",
                wave_cyc,
                $time,
                soc_lite.cpu.core.if_stage.st,
                soc_lite.cpu.core.if_stage.inst_sram_req,
                soc_lite.cpu.core.if_stage.inst_sram_addr,
                soc_lite.cpu.core.if_stage.inst_sram_addr_ok,
                soc_lite.cpu.core.if_stage.inst_sram_data_ok,
                soc_lite.cpu.core.if_stage.inst_sram_rdata,
                soc_lite.cpu.core.if_stage.fs_pc,
                soc_lite.cpu.core.if_stage.fs_valid,
                soc_lite.cpu.core.if_stage.fs_inst,
                soc_lite.cpu.core.if_stage.br_bus[32],
                soc_lite.cpu.core.id_stage.wait_bd,
                soc_lite.cpu.core.id_stage.ds_valid,
                soc_lite.cpu.core.id_stage.ds_pc,
                soc_lite.cpu.core.id_stage.ds_is_bj,
                soc_lite.cpu.core.exe_stage.dst,
                soc_lite.cpu.core.exe_stage.data_sram_req,
                soc_lite.cpu.core.exe_stage.data_sram_wr,
                soc_lite.cpu.core.exe_stage.data_sram_addr,
                soc_lite.cpu.core.exe_stage.data_sram_wdata,
                soc_lite.cpu.core.exe_stage.data_sram_wstrb,
                soc_lite.cpu.core.exe_stage.data_sram_addr_ok,
                soc_lite.cpu.core.exe_stage.data_sram_data_ok,
                soc_lite.u_confreg.ram_random_mask,
                soc_lite.cpu.core.if_stage.kill,
                soc_lite.cpu.core.if_stage.wb_flush,
                debug_wb_pc);
        end
        if ((wave_cyc % 200) == 0)
            $fflush(wave_fd);
        if (wave_cyc == 4500) begin
            $fclose(wave_fd);
            $display("WAVE_DUMP_DONE time=%0t", $time);
            $finish;
        end
    end
end
