module Generators::Database::Scheme

import Ast;
import IO;
import List;
import Map;
import Set;
import String;
import Generators::Maps::Signatures;

public str Generate(list[Specification] specifications) {
	str query = "";
	map[str, set[str]] structure = Generators::Maps::Signatures::Generate(specifications);
	for(table <- structure) {
		query += TableQuery(table, structure[table]) + "\n\r";
	}
	return query;
}

public str TableQuery(str table_name, set[str] fields) {
	table_name = toLowerCase(table_name);
	str query = "DROP TABLE IF EXISTS `" + table_name + "`;\n";
	query += "CREATE TABLE `" + table_name + "`(\n";
	query += "\t`id` INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,\n";
	if(size(fields) == 0) // if it's not a relation
		query += "\t`value` varchar(100) NULL\n";
	int i = 0;
	str unique_index = "";
	for(field <- fields) {
		query += "\t`<field>_id` INT(6) UNSIGNED NOT NULL,\n";
		unique_index += "`<field>_id`";
		if(i < size(fields)-1)
			unique_index += ",";
		//query += "\n";
		i += 1;
	}
	
	if(unique_index != "")
		query += "\tUNIQUE INDEX ui(<unique_index>)\n";
	
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