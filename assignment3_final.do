cls
clear all
import excel "/Users/maksymilianpilat/Documents/Year 2/Period 6/Assignment 3/Transaction Screening Report.xls", sheet("Screening") cellrange(A8:P6321) firstrow
 
replace TargetStockPremium1DayPri = "" if TargetStockPremium1DayPri == "-"

gen completed = 0 
replace completed = 1 if TransactionStatus == "Closed"

drop if TransactionStatus == "Announced"
drop if TransactionStatus == "Effective"

gen yr=year(MAAnnouncedDate)
gen post = 0
replace post = 1 if yr >= 2020

gen lnTransactionValue = log(TotalTransactionValueUSDmm)
gen interaction = lnTransactionValue*post

destring TargetStockPremium1DayPri, gen(target_premium)
reg target_premium interaction lnTransactionValue post completed,r

sum target_premium interaction lnTransactionValue post completed

ssc install winsor

winsor target_premium, gen(trans_winsorized_winsorized) p(0.01)
winsor lnTransactionValue, gen(lnTransactionValue_winsorized) p(0.01)

reg trans_winsorized_winsorized  interaction lnTransactionValue_winsorized post completed, r
