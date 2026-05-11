# CyberGym: Evaluating AI Agents' Real-World Cybersecurity Capabilities at Scale — 论文分析

## 论文信息
- **标题**: CyberGym: Evaluating AI Agents' Real-World Cybersecurity Capabilities at Scale
- **作者**: Zhun Wang*, Tianneng Shi*, Jingxuan He, Matthew Cai, Jialin Zhang, Dawn Song（UC Berkeley）
- **发表**: ICLR 2026

## 一、核心产出

**贡献1: 大规模网络安全基准CyberGym，含1,507个真实漏洞实例。** 来自188个开源C/C++项目，覆盖网络、加密、多媒体、OS等广泛领域，规模是现有最大基准的7倍以上。每个实例提供漏洞文本描述、补丁前代码库和容器化可执行环境，基于sanitizer(ASan/MSan/UBSan)的执行验证确保评测可靠性。已被Claude、Kimi、GLM等前沿模型的系统卡采纳。

**贡献2: 对4个智能体框架和11个前沿LLM的全面评测。** 消耗超4万美元API额度和1000小时H100 GPU。最佳组合(OpenHands+Claude-Sonnet-4)仅17.9%成功率(GPT-5+thinking达22.0%)。SWE-bench专用模型在CyberGym上<2.0%，证明两者互补性。所有模型结果并集仅27.2%，成功案例重叠度低。

**贡献3: 发现34个零日漏洞和18个不完整补丁。** 评估中智能体生成的PoC意外触发补丁后版本的崩溃。进一步在431个项目上主动探索，确认额外25个零日。总计34个零日(平均存在969天)，已获4个CVE编号。验证了AI智能体产生真实安全影响的潜力。

**贡献4: 四级难度梯度。** Level 0(开放探索,3.5%)→Level 1(文本描述,9.4%)→Level 2(+崩溃栈,13.1%)→Level 3(+补丁diff,17.1%)。模拟从零日挖掘到一日利用的完整生命周期。

## 二、框架设计

### 数据构造Pipeline
1. **漏洞来源**: OSS-Fuzz(Google持续fuzzing服务，覆盖1000+项目)
2. **补丁定位**: 二分搜索OSS-Fuzz确认修复当天内的commits，精确定位patch commit
3. **描述生成**: GPT-4.1改写commit message(去commit hash/issue编号/交叉引用)
4. **质量过滤**: GPT-4.1信息量判据+300样本人工校验(96%精确率)+可复现性验证+冗余消除
5. **最终规模**: 1,507实例(2017.1.1-2025.4.21)，中位数1117文件/387K行代码

### 核心组件
- **任务定义**: Agent接收描述+预补丁代码库，生成PoC文件，通过`bash submit.sh`提交
- **执行验证**: PoC必须在预补丁版本触发sanitizer崩溃(exit≠0)且在补丁后版本不触发
- **容器化环境**: Docker容器封装，提交服务器2x AMD EPYC 9654 96核/1.5TB RAM/10TB存储
- **28种sanitizer崩溃类型**: heap-buffer-overflow(458例最多)、use-of-uninitialized-value(287例)等

### 设计动机
选择漏洞复现为核心任务：Mu et al.(2018)显示人类专家平均需5小时复现漏洞；自动化fuzzing中位触发时间324天。选择sanitizer为检测oracle：被GCC/Clang原生支持的成熟技术。选择OSS-Fuzz为数据源：历史数据丰富，每个漏洞有完整信息链(PoC/patch/report)。

## 三、实验设计

**Agent框架(4个)**: OpenHands、OpenAI Codex CLI、EnIGMA(CTF专用)、Cybench agent(CTF专用)

**LLM(11个)**: 
- 闭源通用: GPT-4.1, GPT-5, o4-mini, Claude-3.7-Sonnet, Claude-Sonnet-4, Gemini-2.5-Flash
- 开源: Qwen3-235B-A22B, DeepSeek-V3
- SWE-bench微调: SWE-Gym-32B, R2E-Gym-32B, OpenHands-LM-32B

**消融实验**: 数据污染分析(Fisher/Z-test,均p>0.1)、难度级别对比、Agent框架对比、Thinking模式对比、PoC长度分组分析

**配置**: max 100迭代，non-thinking为主(thinking对比时禁用tool use)，约$3000/全量评测

## 四、实验结果

### LLM对比(OpenHands, Level 1, non-thinking)

| 模型 | 成功率 |
|------|--------|
| Claude-Sonnet-4 | **17.9%** |
| Claude-3.7-Sonnet | 11.9% |
| GPT-4.1 | 9.4% |
| GPT-5 (minimal) | 7.8% |
| Gemini-2.5-Flash | 4.8% |
| DeepSeek-V3 | 3.6% |
| o4-mini | 2.5% |
| R2E-Gym-32B | 2.0% |
| Qwen3-235B-A22B | 1.9% |
| OpenHands-LM-32B | 1.7% |
| SWE-Gym-32B | 0.1% |

### Thinking模式(GPT-5跳跃显著)

| 模型 | w/o Thinking | w/ Thinking |
|------|-------------|-------------|
| GPT-5 | 7.7% | **22.0%** |
| Claude-Sonnet-4 | 17.7% | 19.3% |
| Claude-3.7-Sonnet | 14.3% | 17.3% |

### Agent框架对比(GPT-4.1 backbone)
OpenHands 9.4%, Cybench 9.0%, Codex CLI 7.4%, EnIGMA 7.2%；并集**18.4%**(互补性强)

### PoC长度与成功率
[0,10)字节: 43.5-55.3%; [10,100): 11.1-22.9%; >=100字节(占65.7%实例): ~10%
短PoC任务Agent处理较好，长PoC需要更复杂的输入构造能力。

### 失败模式
- 过早终止: ~30%
- 过长明文PoC导致解析错误: ~20%
- 低效grep/ls/find检索: 大量预算浪费在无效搜索上

### 零日发现
GPT-5触发56次崩溃(确认22个零日)，GPT-4.1触发16次(确认7个)，4个重叠，合计25个独特零日。常见类型: 越界读(6)、空指针解引用(13)、栈溢出(11)、通配地址读(2)、双重释放(1)。

## 五、总结

CyberGym以1,507实例、四级难度、sanitizer执行验证构成当前最大最强的AI网络安全基准。评测揭示了当前最佳Agent仅约20%成功率，且发现SWE-bench模型在网络安全任务上几乎无效。更重要的是，评测过程直接导致了34个零日漏洞的发现，证明了AI智能体已具备产生真实安全影响的能力。
