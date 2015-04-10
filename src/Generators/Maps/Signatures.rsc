module Generators::Maps::Signatures

import Ast;
import List;
import IO;

public map[str, list[str]] Generate(Specifications specifications) {
	map[str, list[str]] structure = ();
	Signatures signatures = SignaturesExtractor(specifications);
	for(s <- signatures) {
		//iprintln(s.sig_name.name);
		//s.sig_name.name = "";
		str sig_name = s.sig_name.name;
		list[Relation] relations = s.sig_block.relations;
		structure += (sig_name : []);
		if(!isEmpty(relations))
			structure += RelationsExtractor(sig_name, relations);
	}
	println(structure);
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

public map[str, list[str]] RelationsExtractor(str parent_sig, list[Relation] relations) {
	map[str, list[str]] structure = ();
	for(r <- relations) {
		//println(typeOf(r));
		//println(r.unary);
		if(/UnaryRelation u := r) {
			structure += (u.relation_name.name : [parent_sig, u.operand1.name]);
		}
		elseif(/BinaryRelation b := r) {
			structure += (b.relation_name.name : [parent_sig, b.operand1.name, b.operand2.name]);
		}
	}
	return structure;
}