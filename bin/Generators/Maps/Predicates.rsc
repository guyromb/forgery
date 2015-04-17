module Generators::Maps::Predicates

import ExtendedAst;
import List;
import Set;
import IO;
import Node;

public map[str, map[str, value]] Generate(Specifications specifications) {
	map[str, map[str, value]] structure = ();
	Predicates predicates = PredicatesExtractor(specifications);
	println(predicates);
	for(p <- predicates) {
		//iprintln(s.sig_name.name);
		//s.sig_name.name = "";
		str pred_name = p.pred_name.name;
		str var_before = p.before.name;
		str var_after = p.after.name;
		str spec_name = p.sig_name.name;
		
		list[PredInput] inputs_list = p.pred_inputs;
		map[str, str] sig_vars = ();
		for(i <- inputs_list) {
			sig_vars += (i.var_name.name: i.sig_name.name);
		}
		sig_vars += (var_before: spec_name);
		//sig_vars += (var_after: table_name);
		
		Expr expression = p.expression;
		
		map[str, value] preconditions = ();
		map[str, value] postconditions = ();
		set[Expr] actions = {};
		
		//println(getName(expression));
		
		
		structure += (pred_name: ("before_var": var_before,
						  		  "after_var": var_after,
						  		  "affected_spec": spec_name, 
						  	 	  "inputs": sig_vars,
								  "body": actions)
					  );

		
		expression = visit(expression) {
			//case Expr and(operand1, operand2) => add(operand1, operand)
			//case Expr self:set_var(operand1, operand2): structure[pred_name] = set_var(operand1, operand2, structure[pred_name]);
			//case Expr self:add(operand1, operand2): structure[pred_name] = add(operand1, operand2, structure[pred_name]);
			case point(variable(_), variable(str tableName)) => table(tableName)
			case set_var(table(str tableName), op2) => set_var(affected_table(tableName), op2)
			case negation(\join(op1, op2)) => notexists(op1, op2)
			//case not_in(Expr(op1), table(op2)) => del(op1, op2)
			//case variable(str varName) => input(varName, sig_vars[varName])
			//case add(op1, op2) => add(op1, op2)
		}
		
		expression = visit(expression) {
			case variable(str varName) => input(varName, sig_vars[varName])
			case \join(op1, op2) => exists(op1, op2)
		}
		
		set[Expr] exprs = {};
		for(/and(op1, op2) := expression) {
			// we don't want the internal and(s)
			if (!(/and(_,_) := op1))
				exprs += op1;
			if (!(/and(_,_) := op2)) 
				exprs += op2;
		}
		
		if(isEmpty(exprs)) {
			exprs = {expression};
		}

		structure[pred_name] += ("body": exprs);
		
		
	}
	println(structure);
	return structure;
}

//public map[str, value] set_var(before, after, structure) {
//	structure["postconditions"] = (after: "");
//	return structure;
//}

//public map[str, value] add(before, after, structure) {
//	structure["postconditions"] = (after: "");
//	return structure;
//}


public Predicates PredicatesExtractor(Specifications specifications) {
	list[Pred] predicates = [];
	for(s <- specifications) {
		if(/Pred pred := s) {
			predicates += pred;
			//main_map += ("signatures": main_map["signatures"] + s);
		}
	}
	return predicates;
}