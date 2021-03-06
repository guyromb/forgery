module ExtendedAst

extend Ast;

data Expr = table(str name, bool precondition);
data Expr = tableV(str name, str var);
data Expr = affected_table(str name, bool precondition);
data Expr = input(str name, str \type);
data Expr = notexists(Expr table, Expr col_id);
data Expr = exists(Expr table, Expr col_id);
data Expr = del(str name, str tableName);