*Analysis of completion time for each survey in Mooratganj

** PART 1: Get the relevant data from each module
*input: Bulk export of all modules from Moortganj basline using custom exports from 15 Augus 2013
*load relevant dataset

/* THIS IS A MODIFIED VERSION FOR ONLY M1*/

	import excel "/Users/jjwack/Desktop/mgh-india_custom_bulk_export_2013-10-06.xlsx", sheet("MRT- M1 15 Aug 2013") firstrow clear
	
	*drop irrelevent variables (not strictly necessary for this analysis)
	keep metatimeStart metatimeEnd metausername serverdoc_type casecase_id asha_serial_number
	
	*transform date time into time only NOTE: this assumes date does not matter in this situation
	replace metatimeStart = substr(metatimeStart,12,8)
	replace metatimeEnd = substr(metatimeEnd,12,8)
	
	*drop non-real observations
	drop if metausername=="sugu" | metausername=="test2" | metausername=="test3" | metausername=="test1" | asha_serial_number=="44444" | serverdoc_type=="XFormDuplicate"
	
	*calculate variables in Stata format from HRF
	generate TimeStart = clock(metatimeStart, "hms")
	generate TimeEnd = clock(metatimeEnd, "hms")
	
	*generate variable containing difference between start and end times
	generate TimeTotal = minutes(TimeEnd - TimeStart)
	
	rename TimeTotal TimeTotalM1
	
	*view relevant table
	tabulate metausername, summarize(TimeTotalM1)
	
	***********************************
	* Account for outliers
	***********************************
	
	* Explore outliers
	disp
	disp in red "M1 cut-off values"
	disp
	sum TimeTotalM1 if TimeTotalM1!=., detail
	local TimeTotalM1High = r(p97)
	display `TimeTotalM1High'
	local TimeTotalM1Low = r(p3)
	display `TimeTotalM1Low'
	
	* List outliers
	disp in red "M1: High outliers"
	list metausername TimeTotalM1 if TimeTotalM1>`TimeTotalM1High' & TimeTotalM1!=., noobs separator(1000)
	disp
	disp in red "M1: Low outliers"
	list metausername TimeTotalM1 if TimeTotalM1<`TimeTotalM1Low' & TimeTotalM1!=., noobs separator(1000)		
	
	* Create adjusted variables
	gen TimeTotalM1Adj = TimeTotalM1
	replace TimeTotalM1Adj=. if (TimeTotalM1>`TimeTotalM1High' & TimeTotalM1!=.) | (TimeTotalM1<`TimeTotalM1Low' & TimeTotalM1!=.)
	
	*save dta file
	save "/Users/jjwack/Desktop/MGN_M1.dta", replace	

