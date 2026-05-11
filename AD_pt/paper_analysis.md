# AD_pt: Active Directory Penetration Testing with Large Language Models — 论文分析

## 论文信息

- **标题**: AD_pt: Active Directory Penetration Testing with Large Language Models（基于大语言模型的Active Directory渗透测试研究）
- **作者**: 待确认
- **所属机构**: 待确认
- **发表**: arXiv / 学术会议论文（2025-2026）

## 一、核心产出

1. **AD渗透测试LLM框架**: 提出专门面向Active Directory（AD）环境的LLM驱动渗透测试框架，针对AD特有的攻击路径和认证机制设计智能体架构。

2. **基于Cochise框架的扩展**: 在Cochise渗透测试框架基础上进行适配和扩展，增加AD特定模块以支持Kerberos认证攻击、LDAP查询、域提权等AD渗透核心能力。

3. **GOADv3（Game of Active Directory v3）评估**: 在GOADv3这一专门用于AD渗透测试训练的复杂多域环境中进行系统评估，覆盖域林（Forest）、域信任关系（Domain Trust）、多域控制器等企业级AD架构要素。

4. **五款大模型对比**: 对多款前沿LLM（包括GPT-4系列、Claude系列等至少5款模型）在AD渗透任务上的表现进行横向对比，揭示不同模型在AD特定攻击路径规划上的能力差异。

5. **攻击路径自动规划与执行**: 集成BloodHound、Impacket等AD安全工具，实现从域信息收集到权限提升的全流程自动化。

## 二、框架架构设计

### AD渗透测试的特殊挑战

Active Directory是现代企业网络身份认证和访问控制的核心基础设施，其渗透测试面临独特的挑战：
- 复杂的域信任关系和委派机制
- Kerberos协议的多步认证流程（AS-REQ/AS-REP/TGS-REQ）
- 多种横向移动技术（Pass-the-Hash、Pass-the-Ticket、Kerberoasting、DCSync等）
- 多域林环境中不同域之间的信任路径分析
- 组策略对象（GPO）的权限传递链

LLM驱动的AD渗透测试需要同时理解这些技术细节，并能够基于侦察结果动态规划攻击路径。

### Cochise框架集成

框架在Cochise基础上进行扩展，Cochise是一个面向通用渗透测试的LLM智能体框架，AD_pt在其基础上增加了AD专用模块，包括：

- **AD侦察模块**: 自动化LDAP域信息查询、域用户枚举、域信任关系映射、SPN（Service Principal Name）扫描
- **凭证攻击模块**: 支持AS-REP Roasting、Kerberoasting、密码喷洒（Password Spraying）、暴力破解等
- **横向移动模块**: Pass-the-Hash（PtH）、Pass-the-Ticket（PtT）、Overpass-the-Hash、黄金票据（Golden Ticket）和白银票据（Silver Ticket）攻击
- **域提权模块**: ACL滥用（基于BloodHound分析结果）、DCSync攻击、MS14-068等已知漏洞利用
- **持久化模块**: 域管理员后门、SID历史注入、DCShadow等

### GOADv3评估环境

GOADv3是一个包含5台主机的多域Active Directory实验环境，模拟企业级AD部署：
- 多个域（Domain）和域林（Forest）结构
- 域间信任关系
- 多种AD安全配置（从低安全到高安全）
- 覆盖从初始访问到域管理员提权的完整攻击路径
- 包含真实的Web应用、SQL Server等典型企业服务

## 三、实验设计

- **评估环境**: GOADv3多域AD环境（5台主机，多个域和域林结构）
- **对比模型**: 至少5款大模型，包括：
  - GPT-4 / GPT-4 Turbo
  - Claude 3 / Claude 3.5 系列
  - Gemini系列
  - 开源模型（如Llama系列）
- **评估任务**: AD渗透测试全流程，从初始域信息收集到最终域管理员权限获取
- **核心指标**:
  - 攻击路径规划成功率
  - 各阶段攻击工具执行成功率
  - 端到端域管理员权限获取耗时和步数
  - 资源消耗（API调用次数和Token消耗）
- **每个模型重复多次实验以消除随机性**

## 四、实验结果

### 多模型对比表现

不同LLM在AD渗透测试中表现出显著差异：

- **GPT-4系列**: 在攻击路径推理和高级域攻击技术（如DCSync、ACL滥用）上表现最优，能够较为准确地规划多步攻击路径
- **Claude系列**: 在侦察阶段和信息综合分析上表现良好，但在特定AD攻击工具的精确参数生成上偶有错误
- **开源模型**: 在简单的AD攻击（如密码喷洒、AS-REP Roasting）上表现可用，但在复杂的多跳攻击链和域信任关系利用上能力不足

### 攻击阶段分析

- **信息收集阶段**: 各模型在LDAP查询和域信息枚举上表现普遍较好，能识别基本域结构
- **攻击路径规划**: GPT-4系列能有效利用BloodHound分析结果规划最优攻击路径，开源模型在此环节明显落后
- **工具执行**: 参数准确率是主要瓶颈，特别是Impacket工具包的复杂参数配置
- **失败模式**: 常见失败包括——错误理解域信任关系导致的路径错误、Token耗尽导致的长流程中断、攻击工具参数格式化错误

### GOADv3总体结果

在GOADv3环境上，最强模型能够完成从初始域用户到域管理员提权的完整攻击链，但成功率远低于简单的Web渗透场景。AD环境的复杂性和多步骤依赖关系对LLM的规划和记忆能力提出了更高要求。

## 五、讨论与局限

**AD渗透测试的独特价值**: 相比Web渗透测试，AD渗透测试面临更多环境依赖和步骤间依赖——前一步的结果（如特定凭证的获取）直接决定后续攻击路径的可用性。这要求LLM不仅理解技术本身，还需要动态管理和维护攻击状态。

**工具依赖性强**: AD渗透测试高度依赖专业工具（Impacket、BloodHound、Rubeus等），这些工具的参数复杂度和版本变化对LLM的工具调用能力提出了更高要求。工具使用的精确性直接决定攻击成败。

**实验规模有限**: GOADv3虽然是一个复杂的企业级AD环境，但相对于真实企业网络可能部署数百个域控制器和数万用户的环境而言，规模仍然有限。

**局限**: 未涉及跨森林攻击的高级场景；对自定义恶意软件投放（C2）和绕过EDR的Advanced AD攻击尚未覆盖；防御检测机制（如Advanced Audit Policy、Sysmon）对LLM攻击的影响也未评估。

## 六、总结

AD_pt聚焦于Active Directory这一企业网络核心基础设施的LLM自动化渗透测试，在Cochise框架基础上扩展AD特定能力，并在GOADv3多域环境中进行系统评估。通过对多款LLM的对比实验，揭示了不同模型在AD攻击路径规划、工具执行和状态管理上的能力差异。研究证明了LLM在企业级AD安全评估中的潜力，同时也指出AD环境的复杂性和工具依赖性对当前LLM构成了巨大挑战——特别在多跳攻击链规划和跨域信任关系利用方面。这项工作为AD安全自动化评估提供了有价值的基线，也为LLM在企业级基础设施安全测试中的应用指明了改进方向。
