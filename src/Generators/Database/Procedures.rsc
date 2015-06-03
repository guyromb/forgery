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
import Generators::Database::Procedures::Atoms;
import Generators::Database::Procedures::Predicates;
import Generators::Database::Procedures::Facts;
import Generators::Database::Procedures::Cardinalities;
import Node;

public str Generate(list[Specification] specifications) {
	// drop procedures statements
	str query = Generators::Database::Procedures::Facts::generateDrops(specifications);
	query += Generators::Database::Procedures::Cardinalities::generateDrops(specifications);
	query += Generators::Database::Procedures::Atoms::generateDrops(specifications);
	query += Generators::Database::Procedures::Predicates::generateDrops(specifications);
	
	// invariants checker
	str invariants = invariantsChecker(specifications);
	
	// create procedures statements
	query += Generators::Database::Procedures::Facts::Generate(specifications);
	query += Generators::Database::Procedures::Cardinalities::Generate(specifications);
	query += Generators::Database::Procedures::Atoms::Generate(specifications, invariants);
	query += Generators::Database::Procedures::Predicates::Generate(specifications, invariants);
		
	return query;
}

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

///////////////////////////// Invariants /////////////////////////////

public str invariantsChecker(list[Specification] specifications) {
	str invariants_checker = factsChecker(specifications);
	invariants_checker += cardinalitiesChecker(specifications);
	return invariants_checker;
}

public str factsChecker(list[Specification] specifications) {
	map[str, map[str, value]] structureF = Generators::Maps::Facts::Generate(specifications);
	str f_caller = "\t-- facts:\n";
	x = 0;
	for(fact_name <- structureF) {
		f_caller += "\tCALL f_<fact_name>(@f<x>);\n";
		f_caller += "\tIF @f<x>!=0 THEN\n\t\tROLLBACK;\n";
		f_caller += "\t\tSELECT `An error has occurred, operation rollbacked and the stored procedure was terminated`;\n";
		f_caller += "\tEND IF;\n";
		x += 1;
	}
	f_caller += "\n";
	return f_caller;
}

public str cardinalitiesChecker(list[Specification] specifications) {
	map[str, tuple[str parent_sig, str cardinality_type]] cardinalities = Generators::Maps::Signatures::getCardinalities(specifications);	
	str c_caller = "\t-- cardinalities:\n";
	x = 0;
	for(cardinality <- cardinalities) {
		c_caller += "\tCALL c_<cardinality>(@c<x>);\n";
		c_caller += "\tIF @c<x>!=0 THEN\n\t\tROLLBACK;\n";
		c_caller += "\t\tSELECT `An error has occurred, operation rollbacked and the stored procedure was terminated`;\n";
		c_caller += "\tEND IF;\n";
		x += 1;
	}
	c_caller += "\n";
	return c_caller;
}