module Generators::Database::Procedures::Facts

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

public str Generate(list[Specification] specifications) {
	map[str, set[str]] tables = Generators::Maps::Signatures::getTables(specifications);
	map[str, map[str, value]] structureF = Generators::Maps::Facts::Generate(specifications);
	str query = "";
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
		//drops += "DROP PROCEDURE IF EXISTS `f_" + toLowerCase(fact_key) + "`;\n";
	}
	return query;
}

public str generateDrops(list[Specification] specifications) {
	str drops = "";
	map[str, map[str, value]] structureF = Generators::Maps::Facts::Generate(specifications);
	for(fact_key <- structureF) {
		drops += "DROP PROCEDURE IF EXISTS `f_" + toLowerCase(fact_key) + "`;\n";
	}
	return drops;
}