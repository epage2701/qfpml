//##################################################################################
// Swap Functions
//##################################################################################

//## Swap specific function
.fpml.swap:{[row] 
	// Check the number of legs to the swap
	legs:string 1+til max "J"$first each "_" vs' 3_'string[cols[row]]; 
	// Apply the same process to each
	ssr[;"><";">\n<"] .fpml.tagit[()!();`swap] raze .fpml.swapLeg[row] each legs
 };

//## For each swap leg, we can break it into managable chunks
.fpml.swapLeg:{[row;legn] 
	// This altogether gets tagged as a <swapStream>
	.fpml.tagit[()!();`swapStream] raze (.fpml.calculationPeriodDates[row;legn];
	.fpml.paymentDates[row;legn];
	.fpml.calculationPeriodAmount[row;legn];
	.fpml.resetDates[row;legn];
	.fpml.stubCalculationPeriodAmount[row;legn])
 };

//#########################
//## SWAP LEG SUB-SECTIONS:
//## 1. calculationPeriodDates
.fpml.calculationPeriodDates:{[row;legn]
	tagit:.fpml.tagit[()!()]; 
	// Effective date
	effective:tagit[`effectiveDate] tagit[`unadjustedDate;.fpml.dateFormat row`$"leg",legn,"_effectiveDate"],
		tagit[`dateAdjustments] tagit[`businessDayConvention;row`$"leg",legn,"_effectiveConvention"],
			tagit[`businessCenters] raze tagit[`businessCenter] each .fpml.splitBusinessCenters row`$"leg",legn,"_effectiveCalendar"; 
	// Termination date
	termination:tagit[`terminationDate] tagit[`unadjustedDate;.fpml.dateFormat row`$"leg",legn,"_maturityDate"],
		tagit[`dateAdjustments] tagit[`businessDayConvention;row`$"leg",legn,"_maturityConvention"],
			tagit[`businessCenters] raze tagit[`businessCenter] each .fpml.splitBusinessCenters row`$"leg",legn,"_maturityCalendar"; 
	// Calculation convention
	cpdAdj:tagit[`calculationPeriodDatesAdjustments] tagit[`businessDayConvention;row`$"leg",legn,"_calculationConvention"],
		tagit[`businessCenters] raze tagit[`businessCenter] each .fpml.splitBusinessCenters row`$"leg",legn,"_calculationCalendar"; 
	// Frequency of calculation
	cpFreq:tagit[`calculationPeriodFrequency] tagit[`periodMultiplier;-1_row`$"leg",legn,"_calculationFrequency"],
		tagit[`period;-1#row`$"leg",legn,"_calculationFrequency"],
			tagit[`rollConvention;row`$"leg",legn,"_rollConvention"]; 
	// Put it all together
	ssr[;"><";">\n<"] .fpml.tagit[enlist[`id]!enlist["-" sv ("CPD";row`tradeKey;row`ct;legn)];`calculationPeriodDates] raze (effective;termination;cpdAdj;cpFreq)
 };

//## 2. paymentDates
.fpml.paymentDates:{[row;legn]
	tagit:.fpml.tagit[()!()]; 
	// Calc Period Dates Ref
	cpdr:raze ("<calculationPeriodDatesReference href=\"";"-" sv ("CPD";row`tradeKey;row`ct;legn);"\"/>"); 
	// Payment Frequency
	payFreq:(tagit[`paymentFrequency] tagit[`periodMultiplier;-1_row`$"leg",legn,"_paymentFrequency"],
		tagit[`period;-1#row`$"leg",legn,"_paymentFrequency"]), tagit[`payRelativeTo;row`$"leg",legn,"_paymentRelativeTo"]; 
	// Payment Dates Offset
	pdOff:tagit[`paymentDaysOffset] tagit[`periodMultiplier;-1_row`$"leg",legn,"_paymentLag"],
		tagit[`period;-1#row`$"leg",legn,"_paymentLag"], tagit[`dayType] row`$"leg",legn,"_paymentLagType"; 
	// Payment Dates Adjustments
	pdAdj:tagit[`paymentDatesAdjustments] tagit[`businessDayConvention;row`$"leg",legn,"_paymentConvention"],
		tagit[`businessCenters] raze tagit[`businessCenter] each .fpml.splitBusinessCenters row`$"leg",legn,"_paymentCalendar"; 
	// Put it all together
	ssr[;"><";">\n<"] .fpml.tagit[enlist[`id]!enlist["-" sv ("PD";row`tradeKey;row`ct;legn)];`paymentDates] raze (cpdr;payFreq;pdOff;pdAdj)
 };

//## 3. calculationPeriodAmount
.fpml.calculationPeriodAmount:{[row;legn]
	tagit:.fpml.tagit[()!()]; 
	// Define legtype
	legtype:row`$"leg",legn,"_legType";
	if[not -11=type legtype;legtype:`$legtype]; 
	// Act accordingly
	if[legtype~`FIX;
		ret:tagit[`calculation] (tagit[`notionalSchedule`notionalStepSchedule;tagit[`initialValue;row`$"leg",legn,"_notional"], tagit[`currency;row`$"leg",legn,"_currency"]]),
			tagit[`fixedRateSchedule`initialValue;row`$"leg",legn,"_fixedRate"],tagit[`dayCountFraction;row`$"leg",legn,"_dayCount"]];
	if[legtype~`FLT;
		ret:tagit[`calculation] (tagit[`notionalSchedule`notionalStepSchedule;tagit[`initialValue;row`$"leg",legn,"_notional"], tagit[`currency;row`$"leg",legn,"_currency"]]),
			(tagit[`floatingRateCalculation] tagit[`floatingRateIndex;row`$"leg",legn,"_indexName"], (tagit[`indexTenor] tagit[`periodMultiplier;-1_row`$"leg",legn,"_indexTenor"],
				tagit[`period;-1#row`$"leg",legn,"_indexTenor"]),tagit[`spreadSchedule`floatingRateCalculation;row`$"leg",legn,"_indexSpread"]),
					tagit[`dayCountFraction;row`$"leg",legn,"_dayCount"]];
	if[not legtype in `FIX`FLT;ret:"<!-- Leg type not recognised -->"]; 
	// Clean it up
	:ssr[;"><";">\n<"] tagit[`calculationPeriodAmount;ret];
 };

//## 4. resetDates
.fpml.resetDates:{[row;legn] 
	// Define legtype
	legtype:row`$"leg",legn,"_legType";
	if[not -11=type legtype;legtype:get legtype];
	if[not legtype~`FLT;:"\n"];
	tagit:.fpml.tagit[()!()]; 
	// Reset relative to
	rrt:tagit[`resetRelativeTo] row`$"leg",legn,"_fixingRelativeTo"; 
	// Fixing dates
	fixDts:tagit[`fixingDates] tagit[`periodMultiplier;-1_row`$"leg",legn,"_fixingLag"],
		tagit[`period;-1#row`$"leg",legn,"_fixingLag"],tagit[`dayType;row`$"leg",legn,"_fixingLagType"],
			tagit[`businessDayConvention;row`$"leg",legn,"_fixingConvention"],
				tagit[`businessCenters] raze tagit[`businessCenter] .fpml.splitBusinessCenters each row`$"leg",legn,"_fixingCalendar"; 
	// Reset Frequency
	rFreq:tagit[`resetFrequency] tagit[`periodMultiplier;-1_row`$"leg",legn,"_resetFrequency"],
		tagit[`period;-1#row`$"leg",legn,"_resetFrequency"]; 
	// Reset Dates Adjustments
	rdAdj:tagit[`resetDatesAdjustments] tagit[`businessDayConvention;row`$"leg",legn,"_resetConvention"],
		tagit[`businessCenters] raze tagit[`businessCenter] each .fpml.splitBusinessCenters row`$"leg",legn,"_resetCalendar"; 
	// Put it all together
	ssr[;"><";">\n<"] .fpml.tagit[enlist[`id]!enlist["-" sv ("RD";row[`tradeKey];row[`ct];legn)];`resetDates] raze (rrt;fixDts;rFreq;rdAdj)
 };

//## 5. stubCalculationPeriodAmount
.fpml.stubCalculationPeriodAmount:{[row;legn] 
	// Define stubtype
	if[.fpml.isEmpty[row`$"leg",legn,"_stubType"];:""];
	stubtype:lower row`$"leg",legn,"_stubType"; 
	// Verify stubtype
	$[stubtype like "*initial*";stubtype:"initial";
		stubtype like "*final*";stubtype:"final";
	:"<!-- Stub type not recognised -->"]; 
	// Other reasons to escape include:
	//# Not having a distinct tenor to the main calculations
	//# OR not having two seperate tenors to interpolate
	//# OR not having a rate
	tenors:row`$("leg",legn),/:("_indexTenor";"_stubTenor1";"_stubTenor2");
	tenors[where not 10=type each tenors]:string tenors[where not 10=type each tenors];
	tenors:tenors where not .fpml.isEmpty each tenors;
	if[any (1=count distinct tenors;
		.fpml.isEmpty[row`$"leg",legn,"_stubRate"]);
	:""];
	tagit:.fpml.tagit[()!()]; 
	// Calculation Period Dates Reference - refers out to the 
	cpdr:raze ("<calculationPeriodDatesReference href=\"";"-" sv ("CPD";row`tradeKey;row`ct;legn);"\"/>");
	frate:tagit[`floatingRate] tagit[`floatingRateIndex;row`$"leg",legn,"_stubIndexName"],
		(tagit[`indexTenor] tagit[`periodMultiplier;last -1_tenors],
			tagit[`period;last -1_tenors]),
		(tagit[`indexTenor] tagit[`periodMultiplier;last tenors],
			tagit[`period;last tenors]);
	rate:tagit[`stubRate] row`$"leg",legn,"_stubRate";
	stub:frate,rate;
	tagit[`stubCalculationPeriodAmount] raze (cpdr,tagit[`$stubtype,"Stub"] stub)
 };