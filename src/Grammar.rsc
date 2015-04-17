module Grammar

start syntax Alloy = alloy: Specification* spec;

syntax Specification  
	= signature: Sig
	| predicate: Pred
	| fact: Fact
	;
	
// facts

start syntax Facts = facts: Fact*;

syntax Fact = fact: "fact" FactName "{" Domain* Expr "}";

syntax Domain = domain: Quantifier DomainVars+ "|";
	
syntax DomainVars = domain_vars: VariableName ":" SigName ",";

//syntax FactExpr = fact_expr: [A-Za-z]+ fact_expr;

lexical FactName = fact_name: [A-Za-z]+ fact_name;

// predictions

start syntax Predicates = predicates: Pred*;

syntax Pred = pred: "pred" PredName "(" BeforeVar "," AfterVar ":" SigName PredInput* ")" "{" Expr "}";

lexical BeforeVar = before_name: [A-Za-z]+ before_name;
lexical AfterVar = after_name: [A-Za-z\']+ after_name;

//syntax PredBlock = pred_block: Expr ;

syntax Expr
  = variable: VariableName name
  //| integer: Integer integer
  //| boolean: Boolean boolean
  //| string: String string
  | bracket "(" Expr arg ")"
  > point: Expr "." Expr
  > \join: Expr "[" Expr "]"
  > left (
      add: Expr "+" Expr
    | dec: Expr "-" Expr
  )
  > set_var: Expr "=" Expr
  > \in: Expr "in" Expr
  > logic_and: Expr "&" Expr
  | negation: "no" Expr
  //| \all: "all" Expr
  //| \some: "some" Expr
  | not_in: Expr "not in" Expr
  //| assign: Expr ":" Expr
  //| comma: Expr "," Expr
  | right \tuple: Expr "-\>" Expr
  > right and: Expr "and" Expr
  > right then: Expr "implies" Expr
  //> right seperator: Expr "|" Expr
  ;

//syntax PredInput
//	= input_var: InputVar
//	| sig_var: SigVar
//	;

syntax PredInput = pred_input: "," VariableName ":" SigName;

//syntax SigVar = sig_var: VariableName ":" SigName ",";

lexical PredName = pred_name: [A-Za-z]+ pred_name;

lexical VariableName = variable_name: [0-9A-Za-z\']+ variable_name;

// signatures

start syntax Signatures = signatures: Sig* sig;

syntax Sig = sig: "sig" SigName sig_name "{" SigBlock sig_block "}";

lexical SigName = sig_name: [A-Za-z]+ sig_name;

syntax SigBlock = sig_block: Relation* relation;

syntax Relation 
	= unary: UnaryRelation unary
	| binary: BinaryRelation binary
	;

syntax UnaryRelation = unary_relation: RelationName ":" Quantifier "_" SigName ",";
syntax BinaryRelation = binary_relation: RelationName ":" RelationName "-\>" Quantifier "_" SigName ",";

lexical RelationName = relation_name: [a-zA-Z]+ relation_name;

lexical Quantifier = quantifier: [a-zA-Z]+;
	//= q_all: "all" all
	//| q_no: "no" no
	//| q_some: "some" some
	//| q_lone: "lone" lone
	//| q_set: "set" set
	//| q_one: "one" one
	//;

//layout MyLayout = [\t\n\r\f\ ]*;

syntax WhitespaceOrComment 
  = whitespace: Whitespace
  | comment: Comment
  ;
  
lexical Comment 
  = @category="Comment" "/*" CommentChar* "*/"
  | @category="Comment" "//" ![\n]* $
  ;
  
lexical CommentChar
  = ![*]
  | [*] !>> [/]
  ;

lexical Whitespace 
  = [\u0009-\u000D \u0020 \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000] // [\t\ \n\r]
  ; 
  
layout Standard = WhitespaceOrComment* !>> [\ \t\n\f\r] !>> "//" !>> "/*";
//