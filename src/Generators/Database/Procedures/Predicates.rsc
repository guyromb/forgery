module Generators::Database::Procedures::Predicates

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
import Generators::Database::Procedures;

public str Generate(list[Specification] specifications, invariants) {
	map[str, map[str, value]] structureP = Generators::Maps::Predicates::Generate(specifications);
	str query = "";
	for(predicate_key <- structureP) {
		p = structureP[predicate_key];
		str p_content = "";
		
		list[str] l = [];
		if(map[str,str] inputs := p["inputs"]) {
			for(i <- inputs) {
				if (/_[A-Za-z0-9_]*$/ := i) {
					l += "IN <i> VARCHAR(100)";
					p_content += "\tINSERT INTO " + toLowerCase(inputs[i]) + "(`value`) VALUES (<i>);\n";
					p_content += "\tSET <i> = LAST_INSERT_ID();\n";
					
				}
				else
		   			l += "IN <i> INT(6)";
		   	}
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
		if(set[Expr] actions := p["body"]) {
			for(a <- actions) {
				str affected_table_name = "";
				bool is_precondition = false;
				//println(a);
				if(/affected_table(name, isprecondition) := a) {
					affected_table_name = name;
					is_precondition = isprecondition;
				}
				//println("##########<affected_table_name>########");
				for(/add(op1, op2) := a) {
					str columns = "";
					str columns_where = "";
					str vars = "";
					
					// we don't really need to add the table itself again, just the new record!
					if(!(/table(name, isprecondition) := op1 && name == affected_table_name)) {
						columns = a_spec + "_id";
						vars = a_before_var;
						columns_where += toLowerCase(a_spec + "_id = ") + a_before_var;
						for(/input(vname, vtype) := op1) {
							columns += toLowerCase(", " + vtype + "_id");
							vars += ", " + vname;
							columns_where += toLowerCase("AND " + vtype + "_id = ") + vname;
						}
					}
					
					if(!(/table(name, isprecondition) := op2 && name == affected_table_name)) {
						columns = a_spec + "_id";
						vars = a_before_var;
						columns_where += toLowerCase(a_spec + "_id = ") + a_before_var;
						for(/input(vname, vtype) := op2) {
							columns += toLowerCase(", " + vtype + "_id");
							vars += ", " + vname;
							columns_where += toLowerCase(", " + vtype + "_id = ") + vname;
						}
					}
					
					// TODO:::: CHECK IF columns = columns (same relation/data type!)
					if(is_precondition) {
						p_content += "\tIF EXISTS (";
						p_content += "SELECT id FROM `<affected_table_name>` WHERE <columns_where>";
						p_content += ") THEN\n";
						p_content += "\t\tSELECT `An error has occurred, operation rollbacked and the stored procedure was terminated`;\n";
						p_content += "\t\tROLLBACK;\n";
						p_content += "\tEND IF;\n";
					}
					else
						p_content += "\tINSERT INTO `" + affected_table_name + "` (" + columns + ") VALUES (" + vars + ");\n";
						
					//println("#$#$# <vars>");
				}
				for(/notexists(op1, op2) := a) {
					str where_table = "";
					str where_id_name = "";
					str where_var_name = "";
					if(/table(name, isprecondition) := op1) {
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
					p_content += "\tEND IF;\n";
				}
				// TODO handle exists ..
				for(/not_in(op1, op2) := a) {
					str where_table = "";
					str where_id_name = "";
					str where_var_name = "";
					bool is_precondition = false;
					if(/table(name, isprecondition) := op2) {
						where_table = toLowerCase(name);
						is_precondition = isprecondition;
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
					if(is_precondition) {
						p_content += "\t\tSELECT `An error has occurred, operation rollbacked and the stored procedure was terminated`;\n";
						p_content += "\t\tROLLBACK;\n";
					}
					else
						p_content += "\tDELETE FROM `<where_table>` WHERE `<where_id_name>_id`=<where_var_name>";
					p_content += " AND `<a_spec>_id`=<a_before_var>;";
				}
				for(/\in(op1, op2) := a) {
					str where_table = "";
					str where_id_name = "";
					str where_var_name = "";
					bool is_precondition = false;
					if(/table(name, isprecondition) := op2) {
						where_table = toLowerCase(name);
						is_precondition = isprecondition;
					}
					else {
						throw "error: <op1> in <op2>";
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
					if(is_precondition) {
						p_content += "\t\tSELECT `An error has occurred, operation rollbacked and the stored procedure was terminated`;\n";
						p_content += "\t\tROLLBACK;\n";
					}
					else
						p_content += "\t\tINSERT INTO `<where_table>` (`<where_id_name>_id`, `<a_spec>_id`) VALUES(<where_var_name>, <a_before_var>);\n";
					p_content += "\tEND IF;\n";
				}
				
			}
		}
		
		//
		query += ProcedureWrapperQuery(predicate_key, l, "<p_content>\n<invariants>", true) + "\n\r";
		//drops += "DROP PROCEDURE IF EXISTS `" + toLowerCase(predicate_key) + "`;\n";
	}
	return query;
}

public str generateDrops(list[Specification] specifications) {
	str drops = "";
	map[str, map[str, value]] structureP = Generators::Maps::Predicates::Generate(specifications);
	for(predicate_key <- structureP) {
		drops += "DROP PROCEDURE IF EXISTS `" + toLowerCase(predicate_key) + "`;\n";
	}
	return drops;
}