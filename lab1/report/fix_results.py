# -*- coding: utf-8 -*-
from pathlib import Path
p = Path(r"d:\Architecture\lab1\report\report.tex")
t = p.read_text(encoding="utf-8")
old = r"""\subsection{原始执行}
\texttt{lui \, 0} 与 \texttt{addiu \, \, 1} 只隔 \texttt{jal} 和延迟槽。
\texttt{addiu} 在 ID 时生产者在 WB，\texttt{rs\_value} 为 X，写回 \texttt{\} 得到 X。见图~\ref{fig:stall-before}。

\subsection{阻塞之后}
同一条指令对：\texttt{ds\_ready\_go} 拉低，\texttt{ds\_pc} 停在 \texttt{bfc408b0}，
下一拍 \texttt{rs\_value} 变为 0，写回 1。全程比参考 CPU 多约 \.27\times 10^{4}\$ 拍气泡。见图~\ref{fig:stall-after}。"""
new = r"""\subsection{原始执行}
\texttt{lui \$s0, 0} 与 \texttt{addiu \$s0, \$s0, 1} 只隔 \texttt{jal} 和延迟槽。
\texttt{addiu} 在 ID 时生产者在 WB，\texttt{rs\_value} 为 X，写回 \texttt{\$16} 得到 X。见图~\ref{fig:stall-before}。

\subsection{阻塞之后}
同一条指令对：\texttt{ds\_ready\_go} 拉低，\texttt{ds\_pc} 停在 \texttt{bfc408b0}，
下一拍 \texttt{rs\_value} 变为 0，写回 1。全程比参考 CPU 多约 $1.27\times 10^{4}$ 拍气泡。见图~\ref{fig:stall-after}。"""
if old not in t:
    raise SystemExit("block not found")
t = t.replace(old, new, 1)
t = t.replace(
    r"第一条 \texttt{addiu \,\,1} 就读到 X。",
    r"第一条 \texttt{addiu \$s0,\$s0,1} 就读到 X。",
)
p.write_text(t, encoding="utf-8", newline="\n")
print("fixed")
