module Generators::Maps::Signatures

import Ast;
import List;
import Map;
import Set;
import IO;
import String;

public map[str, set[str]] getTables(Specifications specifications) {
	map[str, set[str]] tables = ();
	Signatures signatures = SignaturesExtractor(specifications);
	for(s <- signatures) {
		str sig_name = toLowerCase(s.sig_name.name);
		list[Relation] relations = s.sig_block.relations;
		tables += (sig_name : {});
		if(!isEmpty(relations))
			tables += TablesExtractor(sig_name, relations);
	}
	
	//tables = toLowerCase(tables);
	tables = relationSimplifer(tables);
	return tables;
}

public map[str, tuple[str, str]] getCardinalities(Specifications specifications) {
	map[str, tuple[str, str]] cardinalities = ();
	Signatures signatures = SignaturesExtractor(specifications);
	for(s <- signatures) {
		str sig_name = toLowerCase(s.sig_name.name);
		list[Relation] relations = s.sig_block.relations;
		if(!isEmpty(relations)) {
			cardinalities += CardinalitiesExtractor(sig_name, relations);
		}
	}
	
	return cardinalities;
}

// add sub-fields recursively
public map[str, set[str]] relationSimplifer(map[str, set[str]] structure) {
	for(key <- structure) {
		for(e <-structure[key]) {
			if(e in structure && !isEmpty(structure[e])) {
				structure[key] += structure[e];
				structure[key] -= e;
				structure = relationSimplifer(structure);
			}
			else 
				structure[key] += e;
		}
	}
	return structure;
}

public map[str, set[str]] toLowerCase(map[str, set[str]] structure) {
	for(key <- structure) {
		set[str] new_set = {};
		for(e <-structure[key]) {
			new_set += toLowerCase(e);
		}
		structure = delete(structure, key);
		structure += (toLowerCase(key): new_set);
	}
	return structure;
}

public Signatures SignaturesExtractor(Specifications specifications) {
	list[Sig] sigs = [];
	for(s <- specifications) {
		if(/Sig sig := s) {
			sigs += sig;
			//main_map += ("signatures": main_map["signatures"] + s);
		}
	}
	return sigs;
}

public map[str, tuple[str parentsig, str cardinality]] CardinalitiesExtractor(str parent_sig, list[Relation] relations) {
	parent_sig = toLowerCase(parent_sig);
	map[str, tuple[str, str]] cardinalities = ();
	for(r <- relations) {
		if(/UnaryRelation u := r)
			cardinalities += (toLowerCase(u.relation_name.name): <parent_sig, toLowerCase(u.cardinality.name)>);
		elseif(/BinaryRelation b := r)
			cardinalities += (toLowerCase(b.relation_name.name): <parent_sig, toLowerCase(b.cardinality.name)>);
	}
	return cardinalities;
}

public map[str, set[str]] TablesExtractor(str parent_sig, list[Relation] relations) {
	parent_sig = toLowerCase(parent_sig);
	map[str, set[str]] tables = ();
	for(r <- relations) {
		if(/UnaryRelation u := r)
			tables += (toLowerCase(u.relation_name.name) : {parent_sig, toLowerCase(u.operand1.name)});
		elseif(/BinaryRelation b := r)
			tables += (toLowerCase(b.relation_name.name) : {parent_sig, toLowerCase(b.operand1.name), toLowerCase(b.operand2.name)});
	}
	return tables;
}