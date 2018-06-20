---
layout: _post
title: PostgreSQL查询和计划树绘图工具
date: 2018-06-09 17:06:25
categories: PostgreSQL
tags:
---

使用Graphviz的dot工具绘制QueryStmt和PlanStmt。

工具地址：[dotpgstmt](/download/dotpgstmt.sh)

使用方法：

1. 获取查询树或计划树

```shell
postgres=# set client_min_messages to log;
SET
postgres=# set debug_print_parse to on;
SET
postgres=# select * from t;
LOG:  parse tree:
DETAIL:     {QUERY 
   :commandType 1 
   :querySource 0 
   :canSetTag true 
   :utilityStmt <> 
   :resultRelation 0 
   :hasAggs false 
   :hasWindowFuncs false 
   :hasTargetSRFs false 
   :hasSubLinks false 
   :hasDistinctOn false 
   :hasRecursive false 
   :hasModifyingCTE false 
   :hasForUpdate false 
   :hasRowSecurity false 
   :cteList <> 
   :rtable (
      {RTE 
      :alias <> 
      :eref 
         {ALIAS 
         :aliasname t 
         :colnames ("id")
         }
      :rtekind 0 
      :relid 16498 
      :relkind r 
      :tablesample <> 
      :lateral false 
      :inh true 
      :inFromCl true 
      :requiredPerms 2 
      :checkAsUser 0 
      :selectedCols (b 9)
      :insertedCols (b)
      :updatedCols (b)
      :securityQuals <>
      }
   )
   :jointree 
      {FROMEXPR 
      :fromlist (
         {RANGETBLREF 
         :rtindex 1
         }
      )
      :quals <>
      }
   :targetList (
      {TARGETENTRY 
      :expr 
         {VAR 
         :varno 1 
         :varattno 1 
         :vartype 23 
         :vartypmod -1 
         :varcollid 0 
         :varlevelsup 0 
         :varnoold 1 
         :varoattno 1 
         :location 7
         }
      :resno 1 
      :resname id 
      :ressortgroupref 0 
      :resorigtbl 16498 
      :resorigcol 1 
      :resjunk false
      }
   )
   :override 0 
   :onConflict <> 
   :returningList <> 
   :groupClause <> 
   :groupingSets <> 
   :havingQual <> 
   :windowClause <> 
   :distinctClause <> 
   :sortClause <> 
   :limitOffset <> 
   :limitCount <> 
   :rowMarks <> 
   :setOperations <> 
   :constraintDeps <> 
   :stmt_location 0 
   :stmt_len 15
   }
```

2. 把`DETAIL:`之后的内容写入文件parse

3. 绘图

   ./dotpgstmt.sh parse

   ![parse](/img/parse.png)
