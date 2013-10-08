*Analysis of completion time for each survey in Mooratganj

** PART 1: Get the relevant data from each module
*input: Bulk export of all modules from Moortganj basline using custom exports from 15 Augus 2013
*start point 1
*load relevant dataset

foreach module in M1 M2 M3 M3b M4 M5 M6 {

	import excel "/Users/jjwack/Desktop/mgh-india_custom_bulk_export_2013-10-06.xlsx", sheet("MRT- `module' 15 Aug 2013") firstrow clear
	
	*drop irrelevent data (not strictly necessary for this analysis)
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
	/*SL*/ generate TimeTotal = minutes(TimeEnd - TimeStart)
	
	rename TimeTotal TimeTotal`module'
	
	*view relevant table
	tabulate metausername, summarize(TimeTotal`module')
	
	***********************************
	* Account for outliers
	***********************************
	
	* Explore outliers
	disp
	disp in red "`module' cut-off values"
	disp
	sum TimeTotal`module' if TimeTotal`module'!=., detail
	local TimeTotal`module'High = r(p97)
	display `TimeTotal`module'High'
	local TimeTotal`module'Low = r(p3)
	display `TimeTotal`module'Low'
	
	* List outliers
	disp in red "`module': High outliers"
	list metausername TimeTotal`module' if TimeTotal`module'>`TimeTotal`module'High' & TimeTotal`module'!=., noobs separator(1000)
	disp
	disp in red "`module': Low outliers"
	list metausername TimeTotal`module' if TimeTotal`module'<`TimeTotal`module'Low' & TimeTotal`module'!=., noobs separator(1000)		
	
	* Create adjusted variables
	gen TimeTotal`module'Adj = TimeTotal`module'
	replace TimeTotal`module'Adj=. if (TimeTotal`module'>`TimeTotal`module'High' & TimeTotal`module'!=.) | (TimeTotal`module'<`TimeTotal`module'Low' & TimeTotal`module'!=.)
	
	*save dta file
	save "/Users/jjwack/Desktop/MG_`module'.dta", replace
	
}


**PART 2: combine all of the modules
use "/Users/jjwack/Desktop/MG_M1.dta", clear

foreach module in M2 M3 M3b M4 M5 M6 {
	merge m:1 casecase_id using "/Users/jjwack/Desktop/MG_`module'.dta" /* SL: Should this be 1:1 not m:1? */
	drop _merge
}

**PART 3: clean the combined data
drop TimeStart TimeEnd metatimeStart metatimeEnd serverdoc_type

*create a variable that shows the total time for each interview
generate TotalInterview = TimeTotalM6 + TimeTotalM5 + TimeTotalM4 + TimeTotalM3b + TimeTotalM3 + TimeTotalM2 + TimeTotalM1
generate TotalInterviewAdj = TimeTotalM6Adj + TimeTotalM5Adj + TimeTotalM4Adj + TimeTotalM3bAdj + TimeTotalM3Adj + TimeTotalM2Adj + TimeTotalM1Adj

*look at the data
by metausername, sort : summarize TotalInterview
by metausername, sort : summarize TotalInterviewAdj
summarize TimeTotalM* TotalInterview*
