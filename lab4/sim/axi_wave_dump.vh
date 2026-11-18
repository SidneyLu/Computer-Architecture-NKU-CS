// Sampled only when the sim fileset defines WAVE_DUMP.
// #1 lets the NBA updates from this edge settle, so each row is the new state.
integer wave_fd;
integer wave_cyc;
initial begin
    wave_fd  = $fopen("D:/Architecture/lab4/sim/axi_wave.csv", "w");
    wave_cyc = 0;
    $fdisplay(wave_fd, "cyc,time_ns,fst,ireq,iaddr,iok,idok,ist,iarv,iarr,irv,irr,irlast,iaraddr,irdata,dst,dreq,dwr,daddr,dwdata,daxist,darv,darr,dawv,dawr,dwv,dww,dbv,dbr,dawaddr,axi_wdata,wstrb,arid,awid,arvalid,awvalid,mask,wb_pc");
end
always @(posedge soc_clk) begin
    if (!resetn) begin
        wave_cyc = 0;
    end else begin
        #1;
        wave_cyc = wave_cyc + 1;
        if (wave_cyc <= 4500) begin
            $fdisplay(wave_fd, "%0d,%0d,%0d,%b,%h,%b,%b,%0d,%b,%b,%b,%b,%b,%h,%h,%0d,%b,%b,%h,%h,%0d,%b,%b,%b,%b,%b,%b,%b,%b,%h,%h,%h,%h,%h,%b,%b,%b,%h",
                wave_cyc,
                $time,
                soc_lite.u_cpu.core.if_stage.st,
                soc_lite.u_cpu.core.if_stage.inst_sram_req,
                soc_lite.u_cpu.core.if_stage.inst_sram_addr,
                soc_lite.u_cpu.core.if_stage.inst_sram_addr_ok,
                soc_lite.u_cpu.core.if_stage.inst_sram_data_ok,
                soc_lite.u_cpu.inst_axi.st,
                soc_lite.u_cpu.inst_axi.arvalid,
                soc_lite.u_cpu.inst_axi.arready,
                soc_lite.u_cpu.inst_axi.rvalid,
                soc_lite.u_cpu.inst_axi.rready,
                soc_lite.u_cpu.inst_axi.rlast,
                soc_lite.u_cpu.inst_axi.araddr,
                soc_lite.u_cpu.inst_axi.axi_rdata,
                soc_lite.u_cpu.core.exe_stage.dst,
                soc_lite.u_cpu.core.exe_stage.data_sram_req,
                soc_lite.u_cpu.core.exe_stage.data_sram_wr,
                soc_lite.u_cpu.core.exe_stage.data_sram_addr,
                soc_lite.u_cpu.core.exe_stage.data_sram_wdata,
                soc_lite.u_cpu.data_axi.st,
                soc_lite.u_cpu.data_axi.arvalid,
                soc_lite.u_cpu.data_axi.arready,
                soc_lite.u_cpu.data_axi.awvalid,
                soc_lite.u_cpu.data_axi.awready,
                soc_lite.u_cpu.data_axi.wvalid,
                soc_lite.u_cpu.data_axi.wready,
                soc_lite.u_cpu.data_axi.bvalid,
                soc_lite.u_cpu.data_axi.bready,
                soc_lite.u_cpu.data_axi.awaddr,
                soc_lite.u_cpu.data_axi.axi_wdata,
                soc_lite.u_cpu.data_axi.axi_wstrb,
                soc_lite.u_cpu.arid,
                soc_lite.u_cpu.awid,
                soc_lite.u_cpu.arvalid,
                soc_lite.u_cpu.awvalid,
                soc_lite.u_confreg.ram_random_mask,
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
