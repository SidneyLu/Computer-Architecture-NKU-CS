integer wave_fd;
integer wave_cyc;
initial begin
    wave_fd  = $fopen("D:/Architecture/lab4/sim/native_wave.csv", "w");
    wave_cyc = 0;
    $fdisplay(wave_fd, "cyc,time_ns,fst,arv,arr,rv,rr,rlast,araddr,rdata,dst,awv,awr,wv,wr,bv,br,awaddr,wdata,arvalid,awvalid,arid,awid,wb_pc");
end
always @(posedge soc_clk) begin
    if (!resetn) begin
        wave_cyc = 0;
    end else begin
        #1;
        wave_cyc = wave_cyc + 1;
        if (wave_cyc <= 4500) begin
            $fdisplay(wave_fd, "%0d,%0d,%0d,%b,%b,%b,%b,%b,%h,%h,%0d,%b,%b,%b,%b,%b,%b,%h,%h,%b,%b,%h,%h,%h",
                wave_cyc, $time,
                soc_lite.u_cpu.core.if_stage.st,
                soc_lite.u_cpu.core.if_stage.arvalid,
                soc_lite.u_cpu.core.if_stage.arready,
                soc_lite.u_cpu.core.if_stage.rvalid,
                soc_lite.u_cpu.core.if_stage.rready,
                soc_lite.u_cpu.core.if_stage.rlast,
                soc_lite.u_cpu.core.if_stage.araddr,
                soc_lite.u_cpu.core.if_stage.rdata,
                soc_lite.u_cpu.core.exe_stage.dst,
                soc_lite.u_cpu.core.exe_stage.awvalid,
                soc_lite.u_cpu.core.exe_stage.awready,
                soc_lite.u_cpu.core.exe_stage.wvalid,
                soc_lite.u_cpu.core.exe_stage.wready,
                soc_lite.u_cpu.core.exe_stage.bvalid,
                soc_lite.u_cpu.core.exe_stage.bready,
                soc_lite.u_cpu.core.exe_stage.awaddr,
                soc_lite.u_cpu.core.exe_stage.wdata,
                soc_lite.u_cpu.arvalid,
                soc_lite.u_cpu.awvalid,
                soc_lite.u_cpu.arid,
                soc_lite.u_cpu.awid,
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
