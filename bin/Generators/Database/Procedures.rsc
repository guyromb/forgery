module Generators::Database::Procedures

import Ast;
import IO;
import List;
import Map;
import Set;
import String;
import Generators::Maps::Signatures;
import Generators::Maps::Predicates;
import Generators::Maps::Facts;
import Node;

public str Generate(list[Specification] specifications) {
	str query = "";
	
	// procedures for non-relational signarue tables
	map[str, set[str]] structure = Generators::Maps::Signatures::Generate(specifications);
	for(table <- structure) {
		str p_content = "\tINSERT INTO `" + toLowerCase(table) + "` (`value`) VALUES (strVar);";
		list[str] input = ["IN strVar VARCHAR(100)"];
		if(isEmpty(structure[table])) // only if it's not a relation
			query += ProcedureWrapperQuery("create_" + table, input, p_content) + "\n\r";
	}
	
	
	// procedures for pedicates
	
	//signatures_map = Generators::Maps::Signatures::Generate(specifications);
	
	map[str, map[str, value]] structureP = Generators::Maps::Predicates::Generate(specifications);
	for(predicate_key <- structureP) {
		p = structureP[predicate_key];
		
		list[str] l = [];
		if(map[str,str] inputs := p["inputs"]) {
			for(i <- inputs)
		   		l += "IN <i> INT(6)";
		}
		
		str a_spec = "";
		if(str affected_spec := p["affected_spec"]) {
			a_spec = toLowerCase(affected_spec);
		}
		
		str a_before_var = "";
		if(str before_var := p["before_var"]) {
			a_before_var = before_var;
		}
		
		// CONTENT
		str p_content = "";
		if(set[Expr] actions := p["body"]) {
			for(a <- actions) {
				str affected_table_name = "";
				if(/affected_table(name) := a) {
					affected_table_name = name;
				}
				for(/add(op1, op2) := a) {
					str columns = "";
					str vars = "";
					// we don't really need to add the table itself again, just the new record!
					if(!(/table(name) := op1 && name == affected_table_name)) {
						columns = a_spec + "_id";
						vars += a_before_var;
						for(/input(vname, vtype) := op1) {
							columns += toLowerCase(", " + vtype + "_id");
							vars += ", " + vname;
						}
					}
					if(!(/table(name) := op2 && name == affected_table_name)) {
						columns = a_spec + "_id";
						vars += a_before_var;
						for(/input(vname, vtype) := op2) {
							columns += toLowerCase(", " + vtype + "_id");
							vars += ", " + vname;
						}
					}
					// TODO:::: CHECK IF columns = columns (same relation/data type!)
					p_content += "\tINSERT INTO `" + affected_table_name + "` (" + columns + ") VALUES (" + vars + ");\n";
				}
				for(/notexists(op1, op2) := a) {
					str where_table = "";
					str where_id_name = "";
					str where_var_name = "";
					if(/table(name) := op1) {
						where_table = toLowerCase(name);
					}
					else {
						throw "error";
					}
					if(/input(var_name, id_name) := op2) {
						where_id_name = toLowerCase(id_name);
						where_var_name = var_name;
					}
					else {
						throw "error";
					}
					//str vars = a_before_var;
					//for(/input(vname, vtype) := a) {
					//	columns += toLowerCase(", " + vtype + "_id");
					//	vars += ", " + vname;
					//	println("dafuk?");
					//}
					
					
					p_content += "\tIF EXISTS (";
					p_content += "SELECT id FROM `<where_table>` WHERE `<where_id_name>_id`=<where_var_name>";
					p_content += " AND `<a_spec>_id`=<a_before_var>";
					p_content += ") THEN\n";
					p_content += "\t\tSELECT `An error has occurred, operation rollbacked and the stored procedure was terminated`;\n";
					p_content += "\t\tROLLBACK;\n";
					p_content += "\tEND IF;";
				}
				// TODO handle exists ..
				for(/not_in(op1, op2) := a) {
					str where_table = "";
					str where_id_name = "";
					str where_var_name = "";
					if(/table(name) := op2) {
						where_table = toLowerCase(name);
					}
					else {
						throw "error";
					}
					
					if(/input(var_name, id_name) := op1) {
						where_id_name = toLowerCase(id_name);
						where_var_name = var_name;
					}
					else {
						throw "error";
					}
					p_content += "DELETE FROM `<where_table>` WHERE `<where_id_name>_id`=<where_var_name>";
					p_content += " AND `<a_spec>_id`=<a_before_var>";
				}
				for(/\in(op1, op2) := a) {
					str where_table = "";
					str where_id_name = "";
					str where_var_name = "";
					if(/table(name) := op2) {
						where_table = toLowerCase(name);
					}
					else {
						throw "error";
					}
					
					if(/input(var_name, id_name) := op1) {
						where_id_name = toLowerCase(id_name);
						where_var_name = var_name;
					}
					//else {
					//	throw "error";
					//}
					p_content += "\tIF NOT EXISTS (SELECT `id` FROM `<where_table>` WHERE `<where_id_name>_id`=<where_var_name>";
					p_content += " AND `<a_spec>_id`=<a_before_var>";
					p_content += ") THEN\n";
					p_content += "\t\tINSERT INTO `<where_table>` (`<where_id_name>_id`, `<a_spec>_id`) VALUES(<where_var_name>, <a_before_var>)\n";
					p_content += "\tEND IF;\n";
				}
				
			}
		}
		//
		query += ProcedureWrapperQuery(predicate_key, l, p_content) + "\n\r";
		
	}
	
	// facts
	
	map[str, map[str, value]] structureF = Generators::Maps::Facts::Generate(specifications);
	for(fact_key <- structureF) {
		f = structureF[fact_key];		
		str f_content = "";
		// vars
		map[str,str] vars = ();
		if(map[str,str] fvars := f["vars"]) {
			vars = fvars;
		}
		// expr
		Expr expression;
		if(Expr expr := f["expr"]) {
			expression = expr;
		}
	//all c : Course, s1 : Student , s2 : Student, b : Submission, |
	//b in (c.work [s1] & c.work [s2]) implies
	//c.gradebook [s1][b] = c.gradebook [s2][b]
		println("---------");
		for(/then(top1, top2) := expression) {
			
			if(/\in(iop1, iop2) := top1) {
				str select_col = "";
				if(/input(i_name, i_type) := iop1)
					select_col = toLowerCase(vars[i_name]) + "_id";
				println(select_col);
				f_content += "\tSELECT table1.`<select_col>` FROM \n\t\t(";
				
				if(/logic_and(aop1, aop2) := iop2) {
					str table1_name = "";
					str grouper1 = "";
					str table2_name = "";
					str grouper2 = "";
					
					if(\join(jop1, jop2) := aop1) {
						if(/table(name) := jop1)
							table1_name = name;
						
						if(/input(name, c_type) := jop2)
							grouper1 = toLowerCase(vars[name]);
					}
					if(\join(jop1, jop2) := aop2) {
						if(/table(name) := jop1)
							table2_name = name;
						
						if(/input(name, c_type) := jop2)
							grouper2 = toLowerCase(vars[name]);
					}
					
					if(table1_name == table2_name && grouper1 == grouper2) {
						set[str] table_cols = structure[table1_name] - grouper1;
						str group = "";
						int i = 0;
						for(col <- table_cols) {
							group += "`<col>`";
							if(i < size(table_cols)-1)
								group += ",";
							i += 1;
						}
						f_content += "SELECT * FROM `<table1_name>` GROUP BY <group> HAVING count(*)=2";
					}
					else {
						throw "error";
					}
					
				}
				
				f_content += ") table1";
				
			}
			
		}
		
		query += ProcedureWrapperQuery("f_" + fact_key, [], f_content) + "\n\r";
	}
	
	
	return query;
}

public str GenerateFromSignatures(list[Specification] specifications) {
	str query = "";
	map[str, list[str]] structure = Generators::Maps::Signatures::Generate(specifications);
	for(procedure <- structure) {
		query += ProcedureQuery(procedure, structure[procedure]) + "\n\r";
	}
	return query;
}

public str GenerateFromPredicates(list[Specification] specifications) {

}

public str ProcedureWrapperQuery(str procedure_name, list[str] inputs, str content_query) {
	procedure_name = toLowerCase(procedure_name);
	str query = "DROP PROCEDURE IF EXISTS `" + procedure_name + "`;\n";
	query += "DELIMITER //\nCREATE PROCEDURE `" + procedure_name + "`(";
	
	// procedure parameters
	for(input_key <- [0..size(inputs)]) {
		query += inputs[input_key];
		if(input_key < size(inputs)-1)
			query += ", ";
	}
	
	query += ")\nBEGIN\n";
	query += content_query;
	query += "\nEND //";
	return query;
}