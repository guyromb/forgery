module Generators::Maps::Signatures

import Ast;
import List;
import Map;
import Set;
import IO;
import String;

public map[str, set[str]] Generate(Specifications specifications) {
	map[str, set[str]] structure = ();
	Signatures signatures = SignaturesExtractor(specifications);
	for(s <- signatures) {
		//iprintln(s.sig_name.name);
		//s.sig_name.name = "";
		str sig_name = s.sig_name.name;
		list[Relation] relations = s.sig_block.relations;
		structure += (sig_name : {});
		if(!isEmpty(relations))
			structure += RelationsExtractor(sig_name, relations);
	}
	
	structure = toLowerCase(structure);
	structure = relationSimplifer(structure);
	
	return structure;
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

public map[str, set[str]] RelationsExtractor(str parent_sig, list[Relation] relations) {
	map[str, set[str]] structure = ();
	for(r <- relations) {
		//println(typeOf(r));
		//println(r.unary);
		if(/UnaryRelation u := r) {
			structure += (u.relation_name.name : {parent_sig, u.operand1.name});
		}
		elseif(/BinaryRelation b := r) {
			structure += (b.relation_name.name : {parent_sig, b.operand1.name, b.operand2.name});
		}
	}
	return structure;
}