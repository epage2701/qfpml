//##################################################################################
// Top-Level Implementation Functions
//##################################################################################
//## Central wrapper; run this on a table of appropriate schema
.fpml.main:{[table] 
	out:"";
	// Remove console limit on characters for numbers, to allow full granularity
	system"P 15"; 
	// Add an index indicator variable so we can create unique ids within a document
	table:update ct:string i from table; 
	// Make header
	out,:"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<dataDocument xmlns=\"http://www.fpml.org/FpML-5/confirmation\" 
		xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" fpmlVersion=\"5-7\" 
			xsi:schemaLocation=\"http://www.fpml.org/FpML-5/confirmation ../../fpml-main-5-7.xsd 
				http://www.w3.org/2000/09/xmldsig# ../../xmldsig-core-schema.xsd\">\n"; 
	// Generate timestamp of creation time
	out,:ssr[;"><";">\n<"] .fpml.tagit[()!();`header`creationTimestamp;string .z.p]; 
	// Generate FpML for trades
	out,:raze .fpml.trade each table; 
	// Add party identifiers, footer
	out,:ssr[;"><";">\n<"] .fpml.tagit[enlist[`id]!enlist["party1"];`party] .fpml.tagit[enlist[`partyIdScheme]!enlist("http://www.fpml.org/coding-scheme/external/iso17442");`partyId;`LEI1]; 
	// Identifier for counterparty
	out,:ssr[;"><";">\n<"] .fpml.tagit[enlist[`id]!enlist["party2"];`party] .fpml.tagit[enlist[`partyIdScheme]!enlist("http://www.fpml.org/coding-scheme/external/iso17442");`partyId;`LEI2]; 
	out"\n</dataDocument>"; 
	system"P 7";
	out
 };
// Instead of above, could write output to file, as below
/

path:` sv (hsym `$getenv`QHOME),`FPML.xml; 
system"mkdir -p ",1_string path; 
system"touch ",1_string ` sv path,filename; 
out:hopen ` sv path,filename; 
out"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<dataDocument xmlns=\"http://www.fpml.org/FpML-5/confirmation\" 
	xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" fpmlVersion=\"5-7\" 
		xsi:schemaLocation=\"http://www.fpml.org/FpML-5/confirmation ../../fpml-main-5-7.xsd 
			http://www.w3.org/2000/09/xmldsig# ../../xmldsig-core-schema.xsd\">\n"; 
out ssr[;"><";">\n<"] .fpml.tagit[()!();`header`creationTimestamp;string .z.p]; 
out@/:.fpml.trade each table; 
out ssr[;"><";">\n<"] .fpml.tagit[enlist[`id]!enlist["party1"];`party] .fpml.tagit[enlist[`partyIdScheme]!enlist("http://www.fpml.org/coding-scheme/external/iso17442");`partyId;`LEI1]; 
out ssr[;"><";">\n<"] .fpml.tagit[enlist[`id]!enlist["party2"];`party] .fpml.tagit[enlist[`partyIdScheme]!enlist("http://www.fpml.org/coding-scheme/external/iso17442");`partyId;`LEI2]; 
out"\n</dataDocument>";
hclose out;
\
//## Trade level function; we run through each trade individually, applying
//## an appropriate function while covering geenral identifiers etc. here.
.fpml.trade:{[row] 
	// We'll only run for valid trade types
	tradeType:row`trade_type;
	if[not tradeType in `IRS`Basis`FRA;:""];
	out:"<trade>\n"; 
	// Trade Header tag
	out,:ssr[;"><";">\n<"] .fpml.tagit[()!();`tradeHeader] 
		(.fpml.tagit[()!();`partyTradeIdentifier] .fpml.tagit[enlist[`href]!enlist "party2";`partyReference;""],
			 .fpml.tagit[enlist[`tradeIdScheme]!enlist "http://www.testSite.com/coding-scheme/trade-ids";`tradeId;row`tradeID]),
				(.fpml.tagit[()!();`partyTradeIdentifier] .fpml.tagit[enlist[`href]!enlist "party2";`partyReference;""],
					 .fpml.tagit[enlist[`tradeIdScheme]!enlist "http://www.testSite.com/coding-scheme/trade-ids";`tradeId;row[`tradeKey],row[`ct]]),
						.fpml.tagit[()!();`tradeDate] row`trade_date; 
	// For a supported swap type...
	out,:$[tradeType in `IRS`Basis; 
		// we run a swap-specific function
		.fpml.swap[row]; 
		// and for FRAs,
	tradeType in `FRA; 
		// there's a FRA-specific function
		.fpml.fra[row];
	""];
	out,"</trade>\n"
 };