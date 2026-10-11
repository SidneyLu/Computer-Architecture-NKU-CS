# -*- coding: utf-8 -*-
from pathlib import Path

p = Path(r"d:\Architecture\lab1\report\report.tex")
text = p.read_text(encoding="utf-8")

old_task3 = r"""\subsection{实践任务三：前递}
在阻塞版本上增加旁路。ALU 相关不再插入气泡；load 在 EX、消费者已在 ID 时仍停一拍。
与任务二使用同一段 \texttt{hmc\_lab4} 程序，比较仿真结束时间或写回条数对应的周期。

\begin{figure}[H]
  \centering
  \fbox{\parbox{0.9\textwidth}{\centering\vspace{1.4em}
    待补波形：EX 结果前递到下一条 ID\\
    图文件 \texttt{fig/fwd\_ex.pdf}
  \vspace{1.4em}}}
  \caption{执行级结果前递}
\end{figure}

\begin{figure}[H]
  \centering
  \fbox{\parbox{0.9\textwidth}{\centering\vspace{1.4em}
    待补波形：load-use 停一拍后，从 MEM 前递\\
    图文件 \texttt{fig/fwd\_load.pdf}
  \vspace{1.4em}}}
  \caption{load-use 的一拍阻塞与访存级前递}
\end{figure}
"""

new_task3 = r"""\subsection{实践任务三：前递}
在阻塞版本上增加旁路。ALU 相关不再插入气泡；load 在 EX、消费者已在 ID 时仍停一拍。
与任务二使用同一段 \texttt{hmc\_lab4} 程序。

阻塞时 EX、MEM、WB 命中都把 \texttt{ds\_ready\_go} 拉低。前递把尚未写回的结果接到译码级的 \texttt{rs\_value}/\texttt{rt\_value}，优先级 EX $>$ MEM $>$ WB $>$ 寄存器堆。分支比较和 \texttt{jr} 用的也是这两个值。只保留 load-use：生产者是 \texttt{lw} 且还在 EX 时停一拍，下一拍从 MEM 前递 \texttt{ms\_final\_result}。

任务二里 \texttt{lui \$s0, 0} 与 \texttt{addiu \$s0, \$s0, 1} 隔着 \texttt{jal} 和延迟槽。加前递后 2.505\,\textmu s \texttt{addiu} 停在 ID 时 \texttt{ds\_ready\_go} 保持 1，\texttt{rs\_value} 取自 WB 的 0，不再插入气泡。相邻 ALU 相关更清楚的是 \texttt{n2\_addu} 里 \texttt{addu \$v0, \$t0, \$t1} 紧跟 \texttt{bne \$v0, \$v1}：14.755\,\textmu s \texttt{bne} 在 ID、\texttt{addu} 在 EX，\texttt{rs\_value} 与 \texttt{es\_alu\_result} 同为 \texttt{6cbc4bde}，没有气泡。见图~\ref{fig:fwd-ex}。

\begin{figure}[H]
  \centering
  \includegraphics[width=\linewidth]{fig/fwd_ex.png}
  \caption{14.75\,\textmu s 附近。\texttt{ds\_pc=bfc6de28} 的 \texttt{bne} 在 ID，
  \texttt{es\_pc=bfc6de24} 的 \texttt{addu} 在 EX，\texttt{rs\_value} 等于 ALU 结果，
  \texttt{ds\_ready\_go} 保持 1。}
  \label{fig:fwd-ex}
\end{figure}

\texttt{TEST\_LW} 的四条 \texttt{lw} 之后仍隔着比较，真正相邻的 load-use 在 \texttt{wait\_1s}：
\texttt{lw \$t2, 0(\$t0)} 紧跟 \texttt{xor \$t2, \$t2, \$t1}。
14.385\,\textmu s \texttt{xor} 进入 ID 时 load 还在 EX，\texttt{es\_load\_op=1}，\texttt{ds\_ready\_go} 拉低一拍，EX 出现气泡；
下一拍 load 已到 MEM，\texttt{rs\_value} 与 \texttt{ms\_final\_result} 同为 \texttt{aaaa}，再放行。见图~\ref{fig:fwd-load}。

\begin{figure}[H]
  \centering
  \includegraphics[width=\linewidth]{fig/fwd_load.png}
  \caption{14.39\,\textmu s 附近。\texttt{ds\_pc} 在 \texttt{bfc00698} 停留一拍，
  随后 \texttt{rs\_value} 变成访存结果。}
  \label{fig:fwd-load}
\end{figure}

加前递后 23 个功能点全部通过，测试在 1.148\,ms 结束，介于阻塞的 1.311\,ms 与参考 CPU 的 1.184\,ms 之间，比阻塞少约 $1.63\times 10^{4}$ 拍。控制台末尾：
\begin{verbatim}
----[1147165 ns] Number 8'd23 Functional Test Point PASS!!!
Test end!
----PASS!!!
$finish called at time : 1147805 ns
\end{verbatim}
"""

old_fwd_code = r"""\subsection{前递后的操作数}
\begin{verbatim}
% rs_value / rt_value 的优先级：
% EX 结果，MEM 最终结果，WB 写数据，寄存器堆
% 分支比较和 jr 目标使用这两个值
\end{verbatim}

\subsection{执行级与访存级}
\begin{verbatim}
% EXE：alu_src1 接 es_alu_src1
% MEM：es_to_ms_bus_r 使用非阻塞赋值
% 送到 ID 的前递数据：es 的 ALU 结果，ms 的 final_result
\end{verbatim}
"""

new_fwd_code = r"""\subsection{前递后的操作数}
\begin{verbatim}
wire load_use = es_valid && es_load_op && es_gr_we && (es_dest != 5'd0) &&
                ((rs_need && (es_dest == rs)) || (rt_need && (es_dest == rt)));
assign ds_ready_go = ~load_use;

wire es_fwd = es_valid && es_gr_we && (es_dest != 5'd0) && !es_load_op;
wire ms_fwd = ms_valid && ms_gr_we && (ms_dest != 5'd0);
wire ws_fwd = rf_we && (rf_waddr != 5'd0);
assign rs_value = (es_fwd && es_dest == rs) ? es_alu_result :
                  (ms_fwd && ms_dest == rs) ? ms_final_result :
                  (ws_fwd && rf_waddr == rs) ? rf_wdata : rf_rdata1;
assign rt_value = (es_fwd && es_dest == rt) ? es_alu_result :
                  (ms_fwd && ms_dest == rt) ? ms_final_result :
                  (ws_fwd && rf_waddr == rt) ? rf_wdata : rf_rdata2;
\end{verbatim}

\subsection{执行级与访存级}
\begin{verbatim}
// EXE 送到 ID：es_valid, es_gr_we, es_dest, es_load_op, es_alu_result
// MEM 送到 ID：ms_valid, ms_gr_we, ms_dest, ms_final_result
\end{verbatim}
"""

old_table = r"""    前递 & ALU 旁路；load-use 停 1 拍 & 待填 \\"""
new_table = r"""    前递 & ALU 旁路；load-use 停 1 拍 & 1.148\,ms \\"""

old_after = r"""\subsection{前递之后}
同一条指令对不再停顿：消费者留在 ID 的那一拍，操作数已等于 EX 的 ALU 结果。
再取一条 \texttt{lw} 及其下一条使用指令，说明这一拍不能前递、下一拍由 MEM 供给。
前递版本的总周期应明显小于阻塞版本。
"""

new_after = r"""\subsection{前递之后}
同一条 \texttt{lui}/\texttt{addiu \$s0} 不再停顿：2.505\,\textmu s 消费者在 ID，生产者已在 WB，\texttt{rs\_value} 为 0。
相邻的 \texttt{addu}/\texttt{bne} 在同一拍从 EX 拿到 \texttt{6cbc4bde}，见图~\ref{fig:fwd-ex}。
\texttt{lw \$t2} 后紧跟 \texttt{xor} 仍停一拍，下一拍 \texttt{rs\_value=aaaa} 来自 MEM，见图~\ref{fig:fwd-load}。
前递版本 1.148\,ms，比阻塞少约 $1.63\times 10^{4}$ 拍，已接近参考 CPU 的 1.184\,ms。
"""

old_harvest = r"""  \item 待补：前递省下的是气泡，load-use 为什么仍然要停一拍。"""
new_harvest = r"""  \item 前递省下的是可以旁路的气泡。load 在 EX 只有地址，数据要到 MEM 才从 SRAM 回来，所以 load-use 仍须停一拍，再从 MEM 前递。"""

old_results_intro = r"""时钟周期 10\,ns。参考 CPU 在 1.184\,ms 结束，阻塞版本在 1.311\,ms 结束。"""
new_results_intro = r"""时钟周期 10\,ns。参考 CPU 在 1.184\,ms 结束，阻塞版本在 1.311\,ms 结束，前递版本在 1.148\,ms 结束。"""

repls = [
    (old_task3, new_task3, "task3"),
    (old_fwd_code, new_fwd_code, "fwdcode"),
    (old_table, new_table, "table"),
    (old_after, new_after, "after"),
    (old_harvest, new_harvest, "harvest"),
    (old_results_intro, new_results_intro, "intro"),
]
for old, new, name in repls:
    if old not in text:
        raise SystemExit(f"missing block: {name}")
    text = text.replace(old, new, 1)
    print("replaced", name)

p.write_text(text, encoding="utf-8", newline="\n")
print("wrote", p, "chars", len(text))
