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
	str drops = "";
	
	// facts callers
	map[str, map[str, value]] structureF = Generators::Maps::Facts::Generate(specifications);
	str facts_caller = "\t-- facts list:\n";
	x = 0;
	for(fact_name <- structureF) {
		facts_caller += "\tCALL f_<fact_name>(@f<x>);\n";
		facts_caller += "\tIF @f<x>!=0 THEN\n\t\tROLLBACK;\n";
		facts_caller += "\t\tSELECT `An error has occurred, operation rollbacked and the stored procedure was terminated`;\n";
		facts_caller += "\tEND IF;";
		x += 1;
	}
	
		
	// get cardinalities and tables
	map[str, set[str]] tables = Generators::Maps::Signatures::getTables(specifications);
	map[str, tuple[str parent_sig, str cardinality_type]] cardinalities = Generators::Maps::Signatures::getCardinalities(specifications);
	
	// cardinalities procedures
	str cardinality_caller = "\t-- cardinalities list:\n";
	for(cardinality <- cardinalities) {
		str c_type = cardinalities[cardinality].cardinality_type;
		str c_condition = "";
		if(c_type == "set")
			continue;
		elseif(c_type == "one")
			c_condition = "\<\> 1";
		elseif(c_type == "lone")
			c_condition = "\> 1";
		elseif(c_type == "some")
			c_condition = "\< 1";
		else
			throw "error - cardinality unknown";
		
		str parent_sig = cardinalities[cardinality].parent_sig;
		str cp_content = "\t\tSELECT * FROM `<parent_sig>`\n";
		cp_content += "\t\tLEFT JOIN `<cardinality>` ON `<cardinality>`.`<parent_sig>_id`=`<parent_sig>`.`id`\n";
		str c_group_by = "";
		int j = 0;
		for(gtable <- tables[cardinality]) {
			c_group_by += "`<gtable>_id`";
			if(j < size(tables[cardinality])-1)
				c_group_by += ", ";
			j += 1;
		}
		
		
		cp_content += "\t\tGROUP BY <c_group_by> HAVING COUNT(`<cardinality>`.`id`) <c_condition>";
		
		str car_content = "\tIF EXISTS (\n<cp_content>";
		car_content += "\n\t) THEN\n";
		car_content += "\t\tset return_value = 1;\n\tELSE set return_value = 0;\n";
		car_content += "\tEND IF;";
		
		str exitq = "DECLARE EXIT HANDLER FOR SQLEXCEPTION";
    	exitq += "\nBEGIN";
    	exitq += "\n\tset return_value = 1;";
    	exitq += "\nEND;\n\n";
		
		query += ProcedureWrapperQuery("c_" + cardinality, ["OUT return_value tinyint unsigned"], car_content, false) + "\n\r";
		drops += "DROP PROCEDURE IF EXISTS `c_" + toLowerCase(cardinality) + "`;\n";
		// cardinalities procedures caller
		cardinality_caller += "\tCALL c_<cardinality>(@f<x>);\n";
		cardinality_caller += "\tIF @f<x>!=0 THEN\n\t\tROLLBACK;\n";
		cardinality_caller += "\t\tSELECT `An error has occurred, operation rollbacked and the stored procedure was terminated`;\n";
		cardinality_caller += "\tEND IF;";
		x += 1;
	}
	
	// procedures for inserting atoms
	//str a_content = "\tINSERT INTO `atoms` (`value`) VALUES (atomVal);\n";
	//a_content += facts_caller;
	//a_content += cardinality_caller;
	//list[str] input = ["IN atomVal VARCHAR(100)"];
	//query += ProcedureWrapperQuery("create_atom", input, a_content, true) + "\n\r";
			
	// procedures for atomic relations/ signarues tables
	for(table <- tables) {
		//str p_content = "\tINSERT INTO `" + toLowerCase(table) + "` (`atom_id`) VALUES (atomId);\n";
		str p_content = "\tINSERT INTO `" + toLowerCase(table) + "` (`value`) VALUES (atomVal);\n";
		p_content += facts_caller;
		p_content += cardinality_caller;
		//list[str] input = ["IN atomId INT(6)"];
		list[str] input = ["IN atomVal VARCHAR(100)"];
		if(isEmpty(tables[table])) // only if it's not a relation
			query += ProcedureWrapperQuery("create_" + table, input, p_content, true) + "\n\r";
			drops += "DROP PROCEDURE IF EXISTS `create_" + toLowerCase(table) + "`;\n";
	}
	
	// procedures for pedicates
	
	//signatures_map = Generators::Maps::Signatures::Generate(specifications);
	
	map[str, map[str, value]] structureP = Generators::Maps::Predicates::Generate(specifications);
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
		query += ProcedureWrapperQuery(predicate_key, l, "<p_content>\n<facts_caller>\n<cardinality_caller>", true) + "\n\r";
		drops += "DROP PROCEDURE IF EXISTS `" + toLowerCase(predicate_key) + "`;\n";
	}
	
	// facts
	
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
	
		str select_col = "";
		str table_name = "";
		str group_q = "";
		for(/logic_and(aop1, aop2) := expression) {
			str table1_name = "";
			str grouper1 = "";
			str table2_name = "";
			str grouper2 = "";
			
			if(\join(jop1, jop2) := aop1) {
				if(/tableV(name, _) := jop1)
					table1_name = name;
				
				if(/input(name, c_type) := jop2)
					grouper1 += toLowerCase(vars[name]);
			}
			if(\join(jop1, jop2) := aop2) {
				if(/tableV(name, _) := jop1)
					table2_name = name;
				
				if(/input(name, c_type) := jop2)
					grouper2 += toLowerCase(vars[name]);
			}
			
			if(table1_name == table2_name && grouper1 == grouper2) {
				set[str] table_cols = tables[table1_name] - grouper1;
				str group = "";
				int i = 0;
				for(col <- table_cols) {
					group += "`<col>_id`";
					if(i < size(table_cols)-1)
						group += ",";
					i += 1;
				}
				// TODO: number 2 -> variable based on size
				table_name = table1_name;
				//f_content += "SELECT `<select_col>` FROM `<table1_name>` GROUP BY `<select_col>` HAVING count(*)=2";
				group_q = "GROUP BY <group> HAVING count(*)=2";
			}
			else {
				throw "error";
			}
					
		}
		left_join = "";
		for(/\in(iop1, iop2) := expression) {
			if(/input(i_name, i_type) := iop1)
				select_col = "`" + toLowerCase(vars[i_name]) + "_id`";
			else {			
				if(/\tableV(vtop1, vtop2) := iop1) {
					table_name = vtop1;
					set[str] table_cols = tables[vtop1];
					int i = 0;
					select_col = "";
					for(col <- table_cols) {
						select_col += "`<table_name>`.`<col>_id`";
						if(i < size(table_cols)-1)
							select_col += ",";
						i += 1;
					}
				}
				
				if(/\tableV(vtop3, vtop4) := iop2) {
					set[str] table_cols = tables[vtop3];
					int i = 0;
					str on_cols = "";
					str where_nulls = "";
					for(col <- table_cols) {
						on_cols += "`<table_name>`.`<col>_id`=`<vtop3>`.`<col>_id`";
						where_nulls += "`<vtop3>`.`<col>_id` IS NULL";
						if(i < size(table_cols)-1) {
							on_cols += ", ";
							where_nulls += " OR ";
						}
						i += 1;
					}
					left_join = "LEFT JOIN `<vtop3>` ON <on_cols> WHERE <where_nulls>";
				}
			}
				
			f_content += "SELECT <select_col> FROM `<table_name>` <group_q> <left_join>";	
				
		}
			
	
		for(/then(top1, top2) := expression) {
			
			
			
			// INNER JOIN
			// c.gradebook [s1][b] = c.gradebook [s2][b]
			if(/set_var(sop1, sop2) := top2) {
				
				set[str] join_inputs = {};
				str join_table = "";
				str join_table_var = "";
				for(/\join(jjop1, jjop2) := sop1)  {
					if ((\input(_,ival) := jjop1))
						join_inputs += toLowerCase(ival);
					elseif ((\input(_,ival) := jjop2))
						join_inputs += toLowerCase(ival);
						
						
					if(tableV(tname, vname) := jjop1) {
						join_table = tname;
						join_table_var = toLowerCase(vars[vname]);
					}
					elseif(tableV(tname, vname) := jjop2) {
						join_table = tname;
						join_table_var = toLowerCase(vars[vname]);
					}
						
				}
				
				
				set[str] table_cols = tables[join_table] - join_inputs - join_table_var;
				str cmp_cols = "";
				str where_cmp = "";
				int i = 0;
				for(col <- table_cols) {
					cmp_cols += "SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(`<col>_id` SEPARATOR \',\'), \',\', 1), \',\', -1) AS `<col>1`,";
					cmp_cols += "\n\t\t\t\tSUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(`<col>_id` SEPARATOR \',\'), \',\', 2), \',\', -1) AS `<col>2`";
					if(i < size(table_cols)-1)
						cmp_cols += ",\n\t\t\t";
					where_cmp += "cmp_data.`<col>1` \<\> cmp_data.`<col>2`";
					
					i += 1;
				}
				
				//str group = "";
				//int i = 0;
				//for(col <- table_cols) {
				//	group += "`<col>`";
				//	if(i < size(table_cols)-1)
				//		group += ",";
				//	i += 1;
				//}
				
				str tmp_content = f_content;
				f_content = "\t\tSELECT * FROM(";
				f_content += "\n\t\t\tSELECT \n\t\t\t\t<cmp_cols>\n\t\t\tFROM ("; // \n\t\t\tSELECT\n\t\t\t\ttable1.`<select_col>`\n\t\t\tFROM\n\t\t\t
				f_content += "<tmp_content>";
				f_content += ") table1";	
				f_content += "\n\t\t\tINNER JOIN `<join_table>` on `<join_table>`.<select_col>=`table1`.<select_col>\n\t\t) cmp_data";
				f_content += "\n\t\tWHERE\n\t\t\t<where_cmp>";
			}
			
		}
		
		/////////////
		
		f_content = "\tIF EXISTS (\n<f_content>";
		f_content += "\n\t) THEN\n";
		f_content += "\t\tset return_value = 1;\n\tELSE set return_value = 0;\n";
		f_content += "\tEND IF;";
		
		str exitq = "DECLARE EXIT HANDLER FOR SQLEXCEPTION";
    	exitq += "\nBEGIN";
    	exitq += "\n\tset return_value = 1;";
    	exitq += "\nEND;\n\n";
		
		query += ProcedureWrapperQuery("f_" + fact_key, ["OUT return_value tinyint unsigned"], exitq + f_content, false) + "\n\r";
		drops += "DROP PROCEDURE IF EXISTS `f_" + toLowerCase(fact_key) + "`;\n";
	}
	
	
	return drops + "\n" + query;
}

//public str GenerateFromSignatures(list[Specification] specifications) {
//	str query = "";
//	map[str, list[str]] structure = Generators::Maps::Signatures::Generate(specifications);
//	for(procedure <- structure) {
//		query += ProcedureQuery(procedure, structure[procedure]) + "\n\r";
//	}
//	return query;
//}

public str ProcedureWrapperQuery(str procedure_name, list[str] inputs, str content_query, bool dec_rollback) {
	procedure_name = toLowerCase(procedure_name);
	str query = "DELIMITER //\nCREATE PROCEDURE `" + procedure_name + "`(";
	
	// procedure parameters
	for(input_key <- [0..size(inputs)]) {
		query += inputs[input_key];
		if(input_key < size(inputs)-1)
			query += ", ";
	}
	query += ")\nBEGIN\n";
	if(dec_rollback) {
		query += "DECLARE EXIT HANDLER FOR SQLEXCEPTION";
    	query += "\nBEGIN";
    	query += "\n\tROLLBACK;";
    	query += "\nEND;\n\n";
    	query += "START TRANSACTION;\n";
    	query += content_query;
		query += "\nCOMMIT;";
	}	
	else
		query += content_query;
	query += "\nEND //";
	return query;
}