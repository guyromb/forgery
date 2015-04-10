module main
import Ast;
import Parser;
import Generators::Database::Scheme;
import Generators::Database::Procedures;
import Generators::Maps::Signatures;
import Generators::Maps::Predicates;
import IO;

public str run() {
	Alloy structure = getAlloyAST();
	//print(structure);
	str scheme = Generators::Database::Scheme::Generate(structure.specifications);
	println(scheme);
	str procedures = Generators::Database::Procedures::Generate(structure.specifications);
	println(procedures);
	return scheme + "\n\r" + procedures;
}

public map[str, value] runBuilder() {
	Alloy ast = getAlloyAST();
	//print(structure);
	Specifications ss = ast.specifications;
	map[str, list[str]] structure = Generators::Maps::Signatures::Generate(ss);
	
	map[str, map[str, value]] predicates = Generators::Maps::Predicates::Generate(ss);
	println(predicates);
	return structure;
}

//////////////////////////////////

public str runSig() {
	Signatures structure = getSignatures();
	//print(structure);
	str scheme = GenerateSig(structure.sigs);
	println(scheme);
	return scheme;
}

public map[str, list[str]] runBuilderSig() {
	Signatures structure = getSignatures();
	//print(structure);
	map[str, list[str]] scheme = MapBuilderSig(structure.sigs);
	//println(scheme);
	return scheme;
}