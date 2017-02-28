//##################################################################################
//## FRA function
//##################################################################################
.fpml.fra:{[row] 
	// To set ourselves up we'll check where fix and float legs are, column wise
	c:key[row] where key[row] like "*legType";
	fltLeg:3_first "_" vs raze string where `FLT in/: c#row;
	fixLeg:3_first "_" vs raze string where `FIX in/: c#row;
	tagit:.fpml.tagit[()!()]; 
	// Some initial fields are left without nesting
	base:.fpml.tagit[enlist[`id]!enlist["-" sv ("AED";row`tradeKey;row`ct)];`adjustedEffectiveDate;.fpml.dateFormat row`$"leg",fixLeg,"_effectiveDate"],
		tagit[`adjustedTerminationDate] .fpml.dateFormat row`$"leg",fixLeg,"_maturityDate"; 
	// Payment date details
	paymentDate:tagit[`paymentDate] tagit[`unadjustedDate;.fpml.dateFormat row`$"leg",fixLeg,"_effectiveDate"],
		tagit[`dateAdjustments] tagit[`businessDayConvention;row`$"leg",fixLeg,"_paymentConvention"],
			tagit[`businessCenters] raze tagit[`businessCenter] each .fpml.splitBusinessCenters row`$"leg",fixLeg,"_paymentCalendar"; 
	// Fixing date offset
	fixingDateOffset:tagit[`fixingDateOffset] tagit[`periodMultiplier;-1_row`$"leg",fltLeg,"_fixingLag"],
		tagit[`period;-1#row`$"leg",fltLeg,"_fixingLag"],tagit[`dayType;row`$"leg",fltLeg,"_fixingLagType"],
			tagit[`businessDayConvention;row`$"leg",fltLeg,"_fixingConvention"],
				(tagit[`businessCenters] raze tagit[`businessCenter] each .fpml.splitBusinessCenters row`$"leg",fltLeg,"_fixingCalendar"),
					.fpml.tagit[enlist[`href]!enlist["-" sv ("AED";row`tradeKey;row`ct)];`dateRelativeTo;""]; 
	// Other loose objects with little or no nesting				
	end:tagit[`dayCountFraction;row`$"leg",fltLeg,"_dayCount"],
		tagit[`calculationPeriodNumberOfDays;abs[row[`$"leg",fixLeg,"_effectiveDate"]-row[`$"leg",fixLeg,"_maturityDate"]]],
			(tagit[`notional] tagit[`currency;row`$"leg",fixLeg,"_currency"], tagit[`amount;row`$"leg",fixLeg,"_notional"]),
				tagit[`fixedRate;row`$"leg",fixLeg,"_fixedRate"], tagit[`floatingRateIndex;row`$"leg",fltLeg,"_indexName"],
					(tagit[`indexTenor] tagit[`periodMultiplier;-1_row`$"leg",fltLeg,"_indexTenor"],tagit[`period;-1#row`$"leg",fltLeg,"_indexTenor"]),
						tagit[`fraDiscounting] row`fra_discounting;
	ssr[;"><";">\n<"] tagit[`fra] raze (base;paymentDate;fixingDateOffset;end)
 };