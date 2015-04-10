module Generators::Database::Scheme

import Ast;
import IO;
import List;
import Map;
import String;
import Generators::Maps::Signatures;

public str Generate(list[Specification] specifications) {
	str query = "";
	map[str, list[str]] structure = Generators::Maps::Signatures::Generate(specifications);
	for(table <- structure) {
		query += TableQuery(table, structure[table]) + "\n\r";
	}
	return query;
}

public str TableQuery(str table_name, list[str] fields) {
	table_name = toLowerCase(table_name);
	str query = "DROP TABLE IF EXISTS `" + table_name + "`;\n";
	query += "CREATE TABLE `" + table_name + "`(\n";
	query += "\t`id` INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,\n";
	if(size(fields) == 0) // if it's not a relation
		query += "\t`value` varchar(100) NULL\n";
	for(field_key <- [0..size(fields)]) {
		query += "\t`" + toLowerCase(fields[field_key]) + "_id` INT(6) UNSIGNED NOT NULL";
		if(field_key < size(fields)-1)
			query += ",";
		query += "\n";
	}
	
	query += ") ENGINE=InnoDB DEFAULT CHARSET=UTF8;";
	return query;
}


//////////////////////////////

//public str GenerateSig(list[Sig] signatures) {
//	str query = "";
//	map[str, list[str]] structure = MapBuilder(signatures);
//	for(table <- structure) {
//		query += TableQuery(table, structure[table]) + "\n\r";
//	}
//	return query;
//}
//
//public map[str, list[str]] MapBuilderSig(list[Sig] signatures) {
//	map[str, list[str]] scheme = ();
//	for(s <- signatures) {
//		//iprintln(s.sig_name.name);
//		//s.sig_name.name = "";
//		str sig_name = s.sig_name.name;
//		list[Relation] relations = s.sig_block.relations;
//		scheme += (sig_name : []);
//		if(!isEmpty(relations))
//			scheme += RelationsExtractor(sig_name, relations);
//	}
//	
//	return scheme;
//}