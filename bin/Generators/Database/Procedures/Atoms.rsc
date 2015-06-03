module Generators::Database::Procedures::Atoms

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
	map[str, set[str]] tables = Generators::Maps::Signatures::getTables(specifications);
	str query = "";
	for(table <- tables) {
		//str p_content = "\tINSERT INTO `" + toLowerCase(table) + "` (`atom_id`) VALUES (atomId);\n";
		str p_content = "\tINSERT INTO `" + toLowerCase(table) + "` (`value`) VALUES (atomVal);\n";
		p_content += invariants;
		//list[str] input = ["IN atomId INT(6)"];
		list[str] input = ["IN atomVal VARCHAR(100)"];
		if(isEmpty(tables[table])) // only if it's not a relation
			query += ProcedureWrapperQuery("create_" + table, input, p_content, true) + "\n\r";
			//drops += "DROP PROCEDURE IF EXISTS `create_" + toLowerCase(table) + "`;\n";
	}
	return query;
}

public str generateDrops(list[Specification] specifications) {
	str drops = "";
	map[str, set[str]] tables = Generators::Maps::Signatures::getTables(specifications);
	for(table <- tables) {
		drops += "DROP PROCEDURE IF EXISTS `create_" + toLowerCase(table) + "`;\n";
	}
	return drops;
}