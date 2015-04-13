module Generators::Database::Procedures

import Ast;
import IO;
import List;
import Map;
import Set;
import String;
import Generators::Maps::Signatures;
import Generators::Maps::Predicates;
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
					// we don't really need to add the table itself again, just the new record!
					if(!(/table(name) := op1 && name == affected_table_name)) {
						str columns = a_spec + "_id";
						for(/input(vname, vtype) := a) {
							columns += toLowerCase(", " + vtype + "_id");
							println("dafuk?");
						}
						p_content += "INSERT INTO `" + affected_table_name + "` (" + columns + " ...";
						print("nice!");
					}
					if(!(/table(name) := op2 && name == affected_table_name)) {
						str columns = a_spec + "_id";
						str vars = a_before_var;
						for(/input(vname, vtype) := a) {
							columns += toLowerCase(", " + vtype + "_id");
							vars += ", " + vname;
							println("dafuk?");
						}
						p_content += "\tINSERT INTO `" + affected_table_name + "` (" + columns + ") VALUES (" + vars + ");\n";
						print("nice!");
					}
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
					println(op2);
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
					p_content += "SELECT * FROM `<where_table>` WHERE `<where_id_name>_id`=<where_var_name>";
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
				
			}
		}
		//
		query += ProcedureWrapperQuery(predicate_key, l, p_content) + "\n\r";
		
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