# ArkTS 编译错误修复计划

## 问题分析

编译失败，存在以下类型的 ArkTS 语法错误：

1. **PatrolStore.ets** - 第136、146行：对象字面量类型和结构类型不支持
2. **AlertRecords.ets** - 多处错误：
   - 索引签名不支持 `{ [key: string]: ... }`
   - 对象字面量不能作为类型声明
   - 字段索引访问不支持 `obj[key]`
   - 对象展开语法不支持 `{ ...obj }`
   - Scroll 组件没有 `maxHeight` 属性
3. **Index.ets** - 第353行：颜色资源 `status_normal` 不存在

## 修复方案

### 1. 修改 PatrolStore.ets
- 将 `triggerAiAnalysis` 中的内联对象改为使用明确的接口类型

### 2. 修改 AlertRecords.ets
- 创建 `ChatData` 和 `ChatInput` 类替代索引签名对象
- 使用类方法替代索引访问
- 使用 `height` 替代 `maxHeight`

### 3. 修改 Index.ets
- 将 `$r('app.color.status_normal')` 改为已存在的颜色资源

## 修改文件清单

| 文件 | 问题 | 修复方式 |
|------|------|----------|
| PatrolStore.ets | 未类型化对象字面量 | 使用接口类型 |
| AlertRecords.ets | 索引签名、展开语法 | 创建类替代 |
| Index.ets | 不存在的颜色资源 | 使用现有资源 |

## 风险处理

- ArkTS 严格类型系统限制较多，需确保所有类型声明符合规范
- 状态更新方式需使用类方法触发响应式更新