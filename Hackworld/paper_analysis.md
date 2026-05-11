# HackWorld: Evaluating Computer-Use Agents on Exploiting Web Application Vulnerabilities — 论文分析

## 论文信息

- **标题**: HackWorld: Evaluating Computer-Use Agents on Exploiting Web Application Vulnerabilities
- **作者**: Xiaoxue Ren (浙江大学), Penghao Jiang (UNSW), Kaixin Li (NUS), Zhiyong Huang (NUS), Xiaoning Du (Monash), Jiaojiao Jiang (UNSW), Zhenchang Xing (CSIRO Data61/ANU), Jiamou Sun (CSIRO Data61), Terry Yue Zhuo (Monash, 通讯)
- **发表**: arXiv preprint, cs.CR, 2025年10月 (arXiv:2510.12200v1)

## 一、核心产出

**1. 首个面向计算机使用代理(CUA)的Web漏洞利用评估框架 HackWorld。** 现有基准如WebArena、OSWorld等都在"无菌"的、假设应用安全的受控环境中评估代理，完全忽略Web应用可能存在安全漏洞的情况。HackWorld填补此空白，是第一个系统性评估CUA在真实漏洞Web应用中发现和利用安全漏洞能力的框架。采用CTF评估方法学，为代理提供客观成功标准——只有成功挖掘出隐藏flag才算任务完成。

**2. 涵盖36个漏洞Web应用的全面基准测试集。** 挑战来自三个公开CTF基准(NYU CTF Bench、Cybench、InterCode-CTF)，时间跨度2013-2023年，覆盖11种Web框架和7种编程语言(Python、JavaScript、PHP、Java、Perl等)，包含SQL注入、认证绕过、不安全输入处理、目录遍历、文件包含等多种真实漏洞类型。

**3. 系统性实验揭示了CUA在网络安全任务中的严重局限性。** 实验评估了6个先进CUA模型，最佳模型Claude-3.7-Sonnet也仅11.11%成功率。通过统计分析发现感知能力并非主要瓶颈，**策略推理与工具编排能力**才是核心短板。Claude-4-Opus表现反而不如Claude-3.7-Sonnet，挑战了"模型越大越新性能越好"的假设。

## 二、框架架构设计

### 系统环境架构
HackWorld运行在Kali Linux之上——业界标准的渗透测试发行版，集成超过20种安全分析工具(Burp Suite、Nmap、DirBuster、Nikto、WFuzz等)。漏洞挑战通过Docker容器化部署，确保环境隔离。Kali VM运行在AWS裸金属实例上，使用A100 80GB GPU推理。

### 代理交互管道五阶段

1. **任务分配**: 代理接收自然语言安全场景描述和需要达成的目标
2. **环境感知**: 通过屏幕截图和可访问性树(a11y tree)观察Web应用，截图提供视觉信息，a11y树提供界面的结构化文本语义
3. **工具选择与执行**: 代理自主选择Kali环境中的安全工具，如Burp Suite(流量拦截)、DirBuster(目录枚举)、Nikto(漏洞扫描)等
4. **动作执行**: 通过Action Server将高层决策转为低层操作(如`click(300, 540)`)
5. **进度监控**: Controller管理交互过程，记录所有HTTP请求、工具调用和文件系统操作

### 任务形式化(POMDP)
每个漏洞利用任务建模为部分可观测马尔可夫决策过程，定义状态空间S、观测空间O(自然语言指令+Web界面截图)、动作空间A(点击/输入/提交flag)、转移函数T、奖励函数R(flag正确=1)和Flag验证函数F(编辑距离≤5字符的模糊匹配)。

### 观测空间三种配置
- **截图**: 1280x720分辨率，保留完整UI布局
- **截图+a11y树**: 增加可访问性树作为结构化文本表示
- **Set-of-Marks**: 可交互UI元素赋予数字标签叠加在截图上

单因素方差分析(ANOVA, p>0.1)证明观测空间差异无统计显著性——**感知保真度不是主要瓶颈**。

### 标志验证机制
编辑距离阈值5字符的模糊匹配，容忍OCR错误。如将"flag{secret}"识别为"flag{sec ret}"仍被视为成功。

## 三、实验设计

**36个挑战来源**: NYU CTF Bench(26个来自CSAW 2013-2023)、Cybench(8个来自HackTheBox/SekaiCTF等近期赛事)、InterCode-CTF(2个来自picoCTF)。筛选标准：可复现性、时间与难度覆盖、与研究目标的契合度。

**评估CUA**: 闭源(Claude-3.5/3.7/4-Sonnet, Claude-4-Opus)和开源(UI-TARS-1.5-7B, Qwen-2.5-VL-72B-Instruct)。开源模型部署在A100 80GB GPU + vLLM。

**实验配置**: 默认30步(扩展50/100步)，1280x720分辨率，统一系统提示模板。6模型×3观测空间×36挑战=648次运行。

## 四、实验结果

### 成功率

| 模型 | Screenshot | +a11yTree | SoM | 均值 |
|------|-----------|-----------|-----|------|
| Claude-3.7-Sonnet | 11.11% | 8.33% | 11.11% | **10.18%** |
| Claude-4-Opus | 5.56% | 5.56% | 2.78% | 4.63% |
| Claude-3.5-Sonnet | 2.78% | 5.56% | 2.78% | 3.71% |
| Claude-4-Sonnet | 0% | 0% | 0% | 0% |
| UI-TARS-1.5-7B | 0% | 0% | 0% | 0% |
| Qwen-2.5-VL-72B | 0% | 0% | 0% | 0% |

### 步数扩展实验
Claude-3.7-Sonnet: 30步11.1% → 50步11.1% → 100步16.7%。成功机制与OSWorld等传统基准根本不同——没有预定义解决路径，需要主动探索，一旦收集到足够证据flag可在几个决定性步骤中提取。

### 八大失败模式

1. **无效工具选择与输出解析**: 频繁启动不同工具却不分析先前输出，提取线索(robots.txt)但不利用
2. **差劲的失败恢复**: 面对404/403/302等HTTP错误时停滞或放弃，请求模式保持狭窄
3. **目录/源码枚举不足**: 省略系统性枚举或无法持久化结果
4. **不完整的端口/服务映射**: nmap缺少-p-或服务版本探测参数
5. **缺乏认证绕过/会话管理**: 无法建立或维护cookies/CSRF/session
6. **服务类型误分类**: 如将noVNC 6080端口误判为原生VNC
7. **肤浅的SQL注入测试**: 盲目尝试UNION或sqlmap，缺乏差分响应分析
8. **知识驱动的死循环**: 不确定时陷入重复无效动作

### 核心发现
- **从感知到策略的瓶颈**: 代理能"读"页面但无法将线索整合为利用计划
- **挑战缩放假说**: Claude-4-Opus表现弱于Claude-3.7-Sonnet——安全任务更依赖规划纪律和策略控制
- **Agent eXperience (AX)原则**: 提出工具输出应使用机器可读格式(JSON/JSONL)、显式状态码、持久化会话hook等

## 五、总结

HackWorld是首个系统性评估计算机使用代理通过视觉交互利用Web应用漏洞能力的框架。36个挑战、6个CUA模型、3种观测空间的全面实验揭示了CUA在安全任务上的严重局限性——即使最佳模型仅11.11%成功率，核心瓶颈是策略推理和工具编排能力，而非视觉感知。八大失败模式的详细分析为未来安全感知型CUA的设计提供了明确指引。
