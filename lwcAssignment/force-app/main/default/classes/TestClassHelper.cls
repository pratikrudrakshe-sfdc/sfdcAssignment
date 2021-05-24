/*Helper class which contains reusable methods for generating test data */
@isTest
public class TestClassHelper {
    //create users
    public static void createDefaultUsers() {
        List<User> lstUser = new List<User>();
        User standardUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            FirstName = 'Standard',
            LastName = 'User',
            Email = 'standarduser@pratik.com',
            Username = 'standarduser@pratik.com',
            CompanyName = 'PratikCorp',
            Title = 'Sales Representative',
            Alias = 'SUser',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = True
        );
        lstUser.add(standardUser);
        
        User adminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            FirstName = 'System',
            LastName = 'Administrator',
            Email = 'systemadmin@pratik.com',
            Username = 'systemadmin@pratik.com',
            CompanyName = 'PratikCorp',
            Title = 'System Administrator',
            Alias = 'SAdmin',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = True
        );
        lstUser.add(adminUser);
        insert lstUser;
    }
	
    /*
     * helper method which will create data by accepting dynamic paraters
     * Key paramters include any sObject type like "Contact", "Account", "Order"..etc and field mapping with values
    */
    public static SObject createSObject(String objectType, Map<String,Object> fieldValues, Boolean insertRecord) {
        SObject newRecord;
        Map<String,Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        if(globalDescribeMap.containsKey(objectType)) {
            newRecord = globalDescribeMap.get(objectType).newSObject();
            for(String fieldName : fieldValues.keySet()) {
                newRecord.put(fieldName, fieldValues.get(fieldName));
            }
            
            if(insertRecord) {
                insert newRecord;
            }
        }
        
        return newRecord;
    }
}