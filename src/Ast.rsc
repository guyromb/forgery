module Ast

data Alloy = alloy(list[Specification] specifications);

alias Specifications = list[Specification];

data Specification
	= signature(Sig s)
	| predicate(Pred p)
	;

// predictions

alias Predicates = list[Pred];

data Pred = pred(PredName pred_name, BeforeName before, AfterName after, 
					SigName sig_name, list[PredInput] pred_inputs, Expr expression);

//data PredBlock = pred_block(str block);

data Expr
	= variable(str var)
	| point(Expr lhsValue, Expr rhsValue)
	| add(Expr lhsValue, Expr rhsValue)
	| dec(Expr lhsValue, Expr rhsValue)
	| and(Expr lhsValue, Expr rhsValue)
	| set_var(Expr lhsValue, Expr rhsValue)
	| negation(Expr notValue)
	//| and_neg(Expr lhsValue, Expr rhsValue)
	| \join(Expr lhsValue, Expr rhsValue)
	| \in(Expr lhsValue, Expr rhsValue)
	| not_in(Expr lhsValue, Expr rhsValue)
	| \tuple(Expr lhsValue, Expr rhsValue)
	;

//data PredInput
	//= input_var(InputVar ivar)
	//| sig_var(SigVar svar)
	//;
	
data PredInput = pred_input(VariableName var_name, SigName sig_name);

//data SigVar = sig_var(VariableName var_name, SigName sig_name);

data PredName = pred_name(str name);

data VariableName = variable_name(str name);

data AfterName = after_name(str name);

data BeforeName = before_name(str name);

// signatures

alias Signatures = list[Sig];

// data Signatures = signatures(list[Sig] sigs);

data Sig = sig(SigName sig_name, SigBlock sig_block);
  
data SigName = sig_name(str name);

data SigBlock = sig_block(list[Relation] relations);

data Relation
	= unary(UnaryRelation unary)
	| binary(BinaryRelation binary)
	;

data UnaryRelation = unary_relation(RelationName relation_name, Quantifier, SigName operand1); //  RelationName, str Quantifier, str SigName

data BinaryRelation = binary_relation(RelationName relation_name, RelationName operand1, Quantifier, SigName operand2);

//data BinaryRelation = binary_relation(str); //  RelationName, str SigName, str Quantifier, str SigName

data RelationName = relation_name(str name);

data Quantifier = quantifier(str);
	//= q_all(str \all)
	//| q_no(str no)
	//| q_some(str some)
	//| q_lone(str lone)
	//| q_set(str \set)
	//| q_one(str \one)
	//; 