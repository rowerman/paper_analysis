# PTFusion: LLM-driven Context-aware Knowledge Fusion for Web Penetration Testing — 论文分析

## 论文信息

- **标题**: PTFusion: LLM-driven context-aware knowledge fusion for web penetration testing
- **作者**: Wenhao Wang, Hao Gu, Zhixuan Wu, Hao Chen, Xingguo Chen, Fan Shi
- **发表**: Information Fusion, Volume 127, 2026, Article 103731 (Elsevier)

## 一、核心产出

1. **半去中心化多智能体协同框架**: 采用MasterAgent（战略规划）、ReconAgent（侦察）和AttackAgent（攻击）三层分工架构，各自通过MCP Server调用不同工具，实现了全局战略与局部战术的平衡。

2. **上下文感知知识融合机制**: 包含两个核心创新——**动态知识图谱（DKG）**实时建模目标系统以引导任务规划，以及**基于偏好的链式思维提示（Preference-based CoT Prompting）**解决多源工具输出噪声问题。

3. **VulnHub 100%渗透成功率**: 以GPT-4.1-mini为基础模型，在全部6个VulnHub渗透测试靶机环境中实现100%的渗透成功率（PSR），且平均回合数和步数均优于所有对比方法。

4. **消融实验揭示协同价值**: 完整PTFusion在所有环境中均实现最低回合数和步数，DKG与动作历史的协同集成是关键——缺少任何一方都会导致规划死板或陷入局部循环。

5. **多LLM对比验证**: GPT-4.1-mini表现最佳（100% PSR），GPT-4o-mini在复杂环境降至20%且易出现幻觉，Qwen 72B在多个环境中完全失败。

## 二、框架架构设计

### 半去中心化多层架构

PTFusion采用半去中心化（Semi-decentralized）设计，区别于传统的集中式控制（所有决策由一个LLM做出）和完全去中心化（所有智能体完全自治）。MasterAgent负责全局战略协调，ReconAgent和AttackAgent在授权范围内拥有战术执行的自主权。

**MasterAgent（主控智能体）**: 战略决策节点，不直接执行具体渗透操作，而是负责分析任务意图、制定高层目标、动态调整总体规划。其工作流程为：从DKG和MCP Server检索当前知识状态 → 分析攻击进度和未覆盖区域 → 生成任务规划 → 向ReconAgent和AttackAgent分配侦察/攻击子任务。MasterAgent设计了两次退出确认机制——在连续两次确认无新任务后终止攻击循环，防止过早或过晚退出。

**ReconAgent（侦察智能体）**: 高度自主的战术执行者，基于LLM自主决定使用哪些工具和下一步行动。工作流程分为四步：(1) 分析MasterAgent指派的任务目标；(2) 向自身的LLM请求战术决策（选择工具和参数）；(3) 调用对应MCP Server执行命令；(4) 整理执行结果并提交结构化摘要。ReconAgent支持自由切换侦察方向——如果当前侦察路径无发现，可自主决定切换其他侦察策略。

**AttackAgent（攻击智能体）**: 工作流程与ReconAgent相同，但专注于对已识别漏洞的选择性利用。根据漏洞类型（SQL注入、文件上传、命令执行等）选择合适的利用工具和payload。同样具有战术自主权，可根据利用结果动态调整攻击策略。

### MCP工具调用架构

PTFusion通过Model Context Protocol (MCP) 标准化渗透测试工具的调用方式：

| MCP Server | 工具 | 用途 |
|------------|------|------|
| DKG Server | search_facts, add_episode, clear_graph | 知识图谱查询、存储和重置 |
| Recon Server | Nmap（端口扫描）、Dirb（目录枚举）、Curl（HTTP探测） | 目标侦察与信息收集 |
| Attack Server | Msfconsole（漏洞利用框架）、Hydra（暴力破解）、Sqlmap（SQL注入） | 漏洞利用和凭证攻击 |

MCP的引入使得工具集成标准化——每个工具以统一接口暴露给智能体，新增工具只需实现MCP Server协议即可。

### 上下文感知知识融合机制

**动态知识图谱（DKG）**: 以图结构建模9种实体关系类型——Host-HAS_PORT-Port、Port-RUNS-Service、Service-HAS_VULN-Vulnerability、Port-IS_OPEN-Boolean等。ReconAgent和AttackAgent的每次执行结果实时更新到DKG中（通过add_episode操作），使得知识状态始终保持最新。相比传统的静态知识库或动作历史，DKG的优势在于：(1) 以结构化关系呈现知识，便于LLM推理；(2) 支持多跳查询（如"哪些端口开放的服务存在已知漏洞"）；(3) 随着渗透过程推进逐步丰富。

**两阶段任务规划**:
- **阶段一（信息需求识别）**: LLM分析当前知识状态，确定需要查询什么信息，将模糊意图转化为精确的自然语言查询
- **阶段二（查询执行与推理）**: 基于检索到的结构化数据和原始高层目标，LLM进行逻辑推理生成战略步骤

**Preference-based CoT Prompting**: 四步信息对齐机制——
1. **严格去重（Deduplication）**: 合并同一实体的所有发现，避免重复信息和矛盾信息
2. **分类聚合（Classification）**: 将信息组织到预定义的语义类别中，形成结构化摘要
3. **严格禁止信息捏造（Prohibition of Fabrication）**: 明确禁止LLM生成任何非基于实际工具输出的信息
4. **事实验证原则（Fact Verification）**: 所有战术决策必须基于DKG中可追溯的真实信息，杜绝幻觉驱动的规划

## 三、实验设计

- **实验环境**: 6个VulnHub渗透测试靶机——AI Web 1.0、from_sqli_to_shell、JIS-CTF、Metasploitable 2、SickOs 1.2、Basic Pentesting 1，覆盖从简单到复杂的多种漏洞类型和攻击路径

- **硬件**: Intel i7-12700K / 32GB RAM / 1TB SSD

- **渗透目标**: 在目标机器上自主获取Webshell执行权限

- **对比方法**: 
  1. **PTFusion（完整）** —— 全文提出的完整系统
  2. **PTFusion with action history** —— 仅动作历史记录，无DKG
  3. **PTFusion with DKG** —— 仅DKG，无动作历史记录
  4. **PentestGPT + 经验专家** —— PentestGPT框架配经验丰富的专家策略
  5. **PentestGPT + 新手** —— PentestGPT框架配新手策略

- **基础LLM对比**: GPT-4.1-mini（主模型，1M token上下文窗口）、GPT-4o-mini（128K上下文）、Qwen 72B（32K上下文）

- **评估指标**: 
  - **PSR（Penetration Success Rate，渗透成功率）**: 成功获取Webshell的比率
  - **AE（Average Episodes，平均回合数）**: 完成渗透所需的平均回合数
  - **AS（Average Steps，平均步数）**: 完成渗透所需的平均步数
  - **RSS（Reasoning Similarity Score，推理相似度）**: 多次运行间推理路径的一致性

- **每方法每环境执行5次**

## 四、实验结果

### 任务完成性能

- **PTFusion（完整）在全部6个环境中实现了100%的PSR**，是所有方法中唯一实现全渗透成功率的系统
- PentestGPT + 经验专家在大多数环境表现尚可，但在env6（Basic Pentesting 1）中出现未给出任何建议的"静默失败"情况
- PentestGPT + 新手在env2（from_sqli_to_shell）中因SQL注入命令生成不准确而频繁失败
- PTFusion with action history（无DKG）在env1（AI Web 1.0）中因无法利用已知路径构建webshell上传路径而失败
- PTFusion with DKG（无动作历史）在env4（Metasploitable 2）中完全失败（PSR=0%），缺乏实时反馈导致规划过于死板

### 效率对比

完整PTFusion在所有环境中均实现最低AE和AS：
- env1（AI Web 1.0）：PTFusion仅需4回合/6.8步，而PentestGPT+专家需8.4回合/14.2步
- env3（JIS-CTF）：PTFusion需7.2回合/14.6步（最高），体现环境复杂性带来的探索成本
- 消融版本（仅DKG或仅历史）的回合数和步数均显著高于完整版本

### 不同LLM对比

| 模型 | 最佳表现 | 失败情况 |
|------|---------|---------|
| GPT-4.1-mini | 6/6环境100% PSR | 无 |
| GPT-4o-mini | 部分环境100% | env4降至20%，env3易产生幻觉（生成假凭证并报告成功） |
| Qwen 72B | 有限 | env4完全失败(0%)，env5和env6仅40% |

GPT-4.1-mini的1M token上下文窗口和强大的代码生成能力是其全面优势的关键。Qwen 72B难以同时维持全局理解和精确攻击载荷生成，在复杂环境中表现不佳。

### 推理相似度（RSS）分析

- env1的RSS均值最高（约0.61），表明不同运行间推理策略高度一致——简单的环境导致收敛的推理路径
- env3需要最多执行回合（均值7.2），反复重新规划，推理路径差异大，RSS最低
- 总体趋势：环境越简单或约束越多，推理相似度越高；环境越复杂或不确定性越大，推理路径多样性越高

## 五、讨论与局限

**半去中心化设计的优势**: 相比完全集中的架构（所有决策由一个LLM做出），半去中心化设计降低了单一LLM的认知负荷，允许ReconAgent和AttackAgent在战术层面快速响应。相比完全去中心化，MasterAgent的存在确保了全局战略的一致性，避免了智能体间的冲突和冗余操作。

**DKG与动作历史的协同效应**: 消融实验清晰表明DKG和动作历史是互补的——DKG提供结构化、关系化的知识表示，动作历史提供时间序贯的上下文信息。两者结合时，LLM既能理解目标系统的静态结构关系（DKG），又能把握攻击过程的动态演化（动作历史），从而实现最优规划。

**MCP标准化的价值**: 通过MCP统一工具调用接口，新增工具只需实现对应MCP Server即可，显著提升了系统的可扩展性。这是PTFusion能够快速集成Nmap、Dirb、Curl、Sqlmap、Hydra、Msfconsole等多种异构工具的关键。

**局限**: 实验验证仅限于6个VulnHub环境，规模有限；未验证在更大规模企业网络或真实生产环境中的表现；框架依赖外部LLM API，离线场景部署受限；对需要逆向工程或自定义漏洞利用的复杂场景尚未覆盖。

## 六、总结

PTFusion是一个基于LLM驱动的半去中心化多智能体协同框架，通过MasterAgent+ReconAgent+AttackAgent三层架构实现全局战略与局部战术的平衡。其核心创新在于动态知识图谱实时建模目标系统以指导任务规划，以及基于偏好的CoT提示解决多源工具输出噪声问题。MCP协议的引入为渗透测试工具的标准化集成提供了可行方案。在6个VulnHub环境上100%的成功率和系统消融实验共同证明：**DKG与动作历史的协同集成是性能最优的关键**，为Web渗透测试自动化建立了新范式。论文同时揭示了LLM能力差异带来的性能鸿沟——更强的LLM（GPT-4.1-mini）不仅能提升成功率还能减少执行步数，但架构设计的优化同样不可或缺。
