//##################################################################################
// Utility Functions
//##################################################################################
//## Check if we've got a null entry; generally won't want to have these included
.fpml.isEmpty:{[cell]
	empties:(("";" "),"BGXHIJEFSPMDZNUVT"$" ");
	$[0=count cell;:1b;cell in empties;:1b;:0b]
 };

//## Used to split "-" delimited business centers into a list, i.e.
//## "GBLO-USNY" -> ("GBLO";"USNY")
.fpml.splitBusinessCenters:{[bcs]
	if[0=type bcs;bcs:raze bcs];
	split:.[{"-" vs x};enlist bcs;bcs];
	if[10h=type split;:split];
	split
 };

//## String format date with "-" rather than "." seperator,
//## as per requirements of standard
.fpml.dateFormat:{[dt]"-" sv "." vs string dt};

//## Primary function for tagging entities
//## Currently supports nested tags of depth <=2;
//## will extend to n layers of nesting
// Break out immediately if the component is empty
.fpml.tagit:{[d;tag;s]
	if[.fpml.isEmpty[s];:""]; 
	// Allow for nested tags; last one passed in will be applied first
	$[1<count tag;
		[nest:-1_tag; tag:last tag];
	nest:`];
	if[1=count nest;nest:first nest]; 
	// Ensure we've only got strings after this
	if[not 10h~type s;
		s:string s];
	if[not 10h~type tag;
		tag:string tag];
	if[not (0=count key d)|(all 10h~'type each d);
		d,:(where not 10h~'type each d)!string d[where not 10h~'type each d]]; 
	// Create initial tags
	pre:"<",tag,">";
	post:"</",tag,">"; 
	// Include attributes if the input dict is non-empty
	if[count key d;
		pre:"<",tag," ",(raze string[key d],'"=\"",/:get[d],\:"\" "),">"]; 
	// If no content or attributes, skip completely
	$[(not count s)&not count d;
		out:""; 
	// elif we have attributes but no content, close tag off; avoid duplicate
	not count s;
		out:(-1_pre),"/>\n"; 
	// Otherwise return the normal representation
	out:pre,s,post,"\n"]; 
	// If we're working with a nested tag, wrap what we've got so far in that
	if[not null nest;out:.fpml.tagit[()!();nest;out]];
	out
 };