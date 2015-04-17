module Generators::Maps::Facts

import ExtendedAst;
import List;
import Set;
import IO;
import Node;

	//all c : Course, s1 : Student , s2 : Student, b : Submission, |
	//b in (c.work [s1] & c.work [s2]) implies
	//c.gradebook [s1][b] = c.gradebook [s2][b]
	
	//SELECT (*-WHERE) FROM gradebook WHERE s=s1 AND b=b AND c=c;
	// SELECT (*-WHERE) FROM gradebook WHERE s=s2 AND b=b AND c=c;

public map[str, map[str, value]] Generate(Specifications specifications) {
	map[str, map[str, value]] structure = ();
	Facts facts = FactsExtractor(specifications);
	for(f <- facts) {
		str fact_name = f.fact_name.name;
		Expr expression = f.expression;
		// quantifiers and variables
		map[str, str] vars = ();
		for(d <- f.domains) {
			str q_name = d.quantifier.name;
			for(v <- d.vars) {
				vars += (v.var.name: v.sig.name);
			}
		}
		
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
			case variable(str varName) => input(varName, vars[varName])
		}
		
		structure += (fact_name: ("vars": vars,
								  "expr": expression));
		
		println(expression);
	}
	
	return structure;
}

public Facts FactsExtractor(Specifications specifications) {
	list[Fact] facts = [];
	for(s <- specifications) {
		if(/Fact fact := s) {
			facts += fact;
			//main_map += ("signatures": main_map["signatures"] + s);
		}
	}
	return facts;
}