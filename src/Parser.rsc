module Parser

import IO;
import ParseTree;
import Grammar;
import Ast;

public start[Alloy] parseSource(str src) {
	parsed = parse(#start[Alloy], src);
	
	if (/amb(_) := parsed) {
		println("Ambiguities detected!");
	}
	
	return parsed;
}

public Alloy implodeSource(str src) 
	= implode(#Alloy, parseSource(src));
	
public Alloy getAlloyAST() 
	= implodeSource(readFile(|project://forgery/input.als|));

// parseSource(readFile(|project://forgery/input.als|));

//////////////////////////////////////

public start[Signatures] parseSignatures(str src) 
	= parse(#start[Signatures], src);

public Signatures implodeSignatures(str src) 
	= implode(#Signatures, parseSignatures(src));
	
public Signatures getSignatures() 
	= implodeSignatures(readFile(|project://forgery/input.als|));