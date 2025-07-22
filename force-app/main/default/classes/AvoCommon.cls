public class AvoCommon {
//Add business days to a date
    public static Date AddBusinessDays(Date startDate, Integer businessDaysToAdd )
    {
        //Add or decrease business days
        Date finalDate = startDate;
        Integer direction = businessDaysToAdd < 0 ? -1 : 1;
        while(businessDaysToAdd != 0)
        {
            finalDate = finalDate.addDays(direction);
            if (!IsWeekend(finalDate))
            {
                businessDaysToAdd -= direction;
            }
        }
        return finalDate;
    }
    
	// Check if a date is a weekend day
    public static Boolean IsWeekend(Date myDate)
    {
		String myDateString = Datetime.newInstance(myDate.year(), myDate.month(),myDate.day()).format('EEE');
        return 'Sat'.equals(myDateString) || 'Sun'.equals(myDateString);
    }
    
}