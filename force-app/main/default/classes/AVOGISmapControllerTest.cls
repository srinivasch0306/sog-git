@isTest
public class AVOGISmapControllerTest {

   static void setup() {
        // Setup County
        
            AVO_County__c county = new AVO_County__c(
            Name = 'TestCounty', 
            AVO_FIPS__c = 111, 
            AVO_County__c = 111
        );
        insert county;

        // Setup Permit with matching values
        MUSW__Permit2__c permit = new MUSW__Permit2__c(
            Name = 'Permit1',
            AVO_AppID__c = 'G-00284',
            AVO_Basin__c = 'Satilla',
            AVO_Volumetric_Limits__c = 100 ,
            AVO_County_Lookup__c = county.Id
        );
        insert permit;

        // Setup Withdrawal record types
        Id gwRT = Schema.SObjectType.AVO_Withdrawals__c.getRecordTypeInfosByName().get('Ground Water Withdrawal Application').getRecordTypeId();
        Id swRT = Schema.SObjectType.AVO_Withdrawals__c.getRecordTypeInfosByName().get('Surface Water Withdrawal Application').getRecordTypeId();

        // Create withdrawals matching GIS keys
        insert new List<AVO_Withdrawals__c>{
            new AVO_Withdrawals__c(
                AVO_Permit__c = permit.Id,
                AVO_GIS_UNIQUE__c = '',
                RecordTypeId = gwRT
            ),
            new AVO_Withdrawals__c(
                AVO_Permit__c = permit.Id,
                AVO_GIS_UNIQUE__c = 'G-00284_G1',
                RecordTypeId = swRT
            )
        };
    }

    @isTest(seealldata = true)
    static void testUploadFile() {
        setup();
        // Construct matching CSV data
       /* String csv = 
            'APP_ID,COUNTY,DNRBASINS,POINT_X,POINT_Y,GIS_unique,SUBAREA4,COASTAL24,FRBPCONZON,Suspension,CritStrBuf,PrioZone,DarkGreenA\n' +
            'APP001,TESTCOUNTY,ALTAMAHA,-84.12,31.55,GIS_GW,Yes,None,R,No,Yes,7,Yes\n' +
            'APP001,TESTCOUNTY,ALTAMAHA,-82.98,30.33,GIS_SW,No,None,X,Yes,No,3,No'; */

        
        String csv = 'OBJECTID,SOURCE,APP_ID,PERMIT_NO,PrimaryID,OwNameComm,MapCreate,Pond_Fund,PUMPNO,VERIFIED,GIS_unique,SUBAREA4,COUNTY,COASTAL24,HUC08,FRBPCONZON,HUC10,HUC12,HUC08NAME,HUC10NAME,DNRBASINS,POINT_X,POINT_Y,Type,HUC12NAME,AWDregion,Meter,Suspension,CritStrBuf,Inactive,Fips,APM,PrioZone,DarkGreenA\n'+
'17731,GFC,G-00284,,G-00284,,,,1,YES,G-00284_G1,no,LEE,none,3070202,R,307020201,30702020104,Little Satilla River,Big Satilla Creek-upper-,Satilla,-82.30672511,31.61119301,G,BIG SATILLA CREEK UPPER 3,,,GW only,Yes,,1,,10,Yes\n'+
'17519,GFC,G-00289,,G-00289,,,,1,YES,G-00289_G1,no,Laurens,Hello,3070202,R,307020201,30702020104,Little Satilla River,Big Satilla Creek-upper-,Satilla,-82.30353724,31.60461901,G,BIG SATILLA CREEK UPPER 3,,,GW only,No,,1,,9,No';
        
        //String encoded = EncodingUtil.base64Encode(Blob.valueOf(csv));
		 Blob csvBlob = Blob.valueOf(csv);
        String base64String = EncodingUtil.base64Encode(csvBlob);
        
        
        Test.startTest();
        String result = AVOGISmapController.uploadFile(base64String);
        Test.stopTest();

        System.debug('Result: ' + result);
        System.assert(result.contains('Updated'));

        // Validate the records were updated
        List<AVO_Withdrawals__c> updated = [
            SELECT AVO_GIS_UNIQUE__c, AVO_Well_Long__c, AVO_Well_Latitude__c, Point_X__c, Point_Y__c
            FROM AVO_Withdrawals__c
            WHERE AVO_GIS_UNIQUE__c IN ('GIS_GW', 'GIS_SW')
        ];
       // System.assertEquals(2, updated.size(), '2 withdrawals should be updated');

        for (AVO_Withdrawals__c w : updated) {
            if (w.AVO_GIS_UNIQUE__c == 'GIS_GW') {
                System.assertEquals(Decimal.valueOf('-84.12'), w.AVO_Well_Long__c);
                System.assertEquals(Decimal.valueOf('31.55'), w.AVO_Well_Latitude__c);
            } else {
                System.assertEquals(Decimal.valueOf('-82.98'), w.Point_X__c);
                System.assertEquals(Decimal.valueOf('30.33'), w.Point_Y__c);
            }
        }
    }
}