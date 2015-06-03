module Generators::Database::Procedures::Cardinalities

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
	map[str, tuple[str parent_sig, str cardinality_type]] cardinalities = Generators::Maps::Signatures::getCardinalities(specifications);
	str query = "";
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
		//drops += "DROP PROCEDURE IF EXISTS `c_" + toLowerCase(cardinality) + "`;\n";
		// cardinalities procedures caller
		//cardinality_caller += "\tCALL c_<cardinality>(@f<x>);\n";
		//cardinality_caller += "\tIF @f<x>!=0 THEN\n\t\tROLLBACK;\n";
		//cardinality_caller += "\t\tSELECT `An error has occurred, operation rollbacked and the stored procedure was terminated`;\n";
		//cardinality_caller += "\tEND IF;";
	}
	return query;
}

public str generateDrops(list[Specification] specifications) {
	str drops = "";
	map[str, tuple[str parent_sig, str cardinality_type]] cardinalities = Generators::Maps::Signatures::getCardinalities(specifications);
	for(cardinality <- cardinalities) {
		drops += "DROP PROCEDURE IF EXISTS `c_" + toLowerCase(cardinality) + "`;\n";
	}
	return drops;
}