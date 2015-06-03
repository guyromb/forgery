module Generators::Database::Scheme

import Ast;
import IO;
import List;
import Map;
import Set;
import String;
import Generators::Maps::Signatures;

public str Generate(list[Specification] specifications) {
	// atoms table
	str query = "";
	map[str, set[str]] tables = Generators::Maps::Signatures::getTables(specifications);
	map[str, tuple[str parentsig, str cardinality_type]] cardinalities = Generators::Maps::Signatures::getCardinalities(specifications);
	
	map[str, str] queries_map = ();
	for(table <- tables) {
		str cardinality_type = "";
		if(table in cardinalities) 
			cardinality_type = cardinalities[table].cardinality_type;
		queries_map += (table: TableQuery(table, tables[table], cardinality_type) + "\n\r");
	}
	
	//str atoms_query = "CREATE TABLE `atoms`(\n";
	//atoms_query += "\t`id` INT(6) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,\n";
	//atoms_query += "\t`value` VARCHAR(100) NULL\n";
	//atoms_query += ") ENGINE=InnoDB DEFAULT CHARSET=UTF8;\n\r";
	
	// order queries
	str drops = "";
	Signatures signatures = SignaturesExtractor(specifications);
	for(s <- signatures) {
		str sig_name = toLowerCase(s.sig_name.name);
		if(isEmpty(s.sig_block.relations)) { // if atomic relation(sig), must run first
			query = queries_map[sig_name] + query;
			drops = drops + "DROP TABLE IF EXISTS `" + sig_name + "`;\n";
		}
		else {  // non atomic relations are already ordered, should run at the end
			query = queries_map[sig_name] + query;
			drops = drops + "DROP TABLE IF EXISTS `" + sig_name + "`;\n";
			for(r <- s.sig_block.relations) {
				if(/UnaryRelation u := r) {
					query = query + queries_map[u.relation_name.name];
					drops = "DROP TABLE IF EXISTS `" + u.relation_name.name + "`;\n" + drops;
				}
				elseif(/BinaryRelation b := r) {
					query = query + queries_map[b.relation_name.name];
					drops = "DROP TABLE IF EXISTS `" + b.relation_name.name + "`;\n" + drops;
				}
			}
		}
	}
	//drops = drops + "DROP TABLE IF EXISTS `atoms`;\n";
	query = drops + "\n" + query; //drops + atoms_query + query;
	
	return query;
}

public str TableQuery(str table_name, set[str] fields, str cardinality_type) {
	table_name = toLowerCase(table_name);
	str query = "CREATE TABLE `" + table_name + "`(\n";
	query += "\t`id` INT(6) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,\n";
	if(size(fields) == 0) { // if it's not a relation
		query += "\t`value` VARCHAR(100) NULL";
		//query += "\t`atom_id` INT(6) UNSIGNED NOT NULL,\n";
		//query += "\tFOREIGN KEY (atom_id) REFERENCES atoms(id)\n";
	}
	int i = 0;
	str unique_index = "";
	str foreign_keys = "";
	for(field <- fields) {
		query += "\t`<field>_id` INT(6) UNSIGNED NOT NULL,\n";
		if(cardinality_type == "one" || cardinality_type == "lone" || cardinality_type == "set")
			unique_index += "`<field>_id`";
		foreign_keys += "\tFOREIGN KEY (`<field>_id`) REFERENCES `<field>`(`id`)";
		if(i < size(fields)-1) {
			if(cardinality_type == "one" || cardinality_type == "lone" || cardinality_type == "set")
				unique_index += ",";
			foreign_keys += ",\n";
		}
		//query += "\n";
		i += 1;
	}
	
	if(unique_index != "")
		query += "\tUNIQUE INDEX ui(<unique_index>)";
	if(foreign_keys != "") {
		if(unique_index != "")
			query += ",\n";
		query += foreign_keys;
	}
	
	query += "\n) ENGINE=InnoDB DEFAULT CHARSET=UTF8;";
	return query;
}