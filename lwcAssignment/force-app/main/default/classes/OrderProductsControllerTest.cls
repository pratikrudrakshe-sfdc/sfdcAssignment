@isTest
public class OrderProductsControllerTest {
    @testSetup
    public static void setupTestData() {
        TestClassHelper.createDefaultUsers();
        User standardUser = [SELECT Id FROM User WHERE Username = 'standarduser@pratik.com' LIMIT 1];
        
        System.runAs(standardUser) {
            //Account account = TestClassHelper.getAccount('KPN Corp');
            //insert account;
            List<SObject> lstAccount = new List<SObject>(); 
            lstAccount.add(TestClassHelper.createSObject('Account', new Map<String,Object>{ 'Name' => 'Edge Communication'}, false));
            insert lstAccount;

            List<SObject> lstProduct = new List<SObject>();
            lstProduct.add(TestClassHelper.createSObject('Product2', new Map<String,Object>{ 'Name' => 'SLA-Diamond', 'ProductCode' => 'WSD-01', 'IsActive' => TRUE}, false));
            lstProduct.add(TestClassHelper.createSObject('Product2', new Map<String,Object>{ 'Name' => 'SLA-Platinum', 'ProductCode' => 'WSD-02', 'IsActive' => TRUE}, false));
            insert lstProduct;
            
            List<SObject> lstPricebookEntry = new List<SObject>();
            lstPricebookEntry.add(TestClassHelper.createSObject('PricebookEntry', new Map<String,Object>{ 'Pricebook2Id' => Test.getStandardPricebookId(), 'Product2Id' => lstProduct[0].Id, 'UnitPrice' => 100, 'IsActive' => TRUE, 'UseStandardPrice' => FALSE }, false));
            insert lstPricebookEntry;
            
            List<SObject> lstOrder = new List<SObject>();
            lstOrder.add(TestClassHelper.createSObject('Order', new Map<String,Object>{ 'Name' => 'First Order', 'Status' => 'Draft', 'EffectiveDate' => System.today(), 'EndDate' => System.today() + 30, 'AccountId' => lstAccount[0].Id, 'Pricebook2Id' => Test.getStandardPricebookId()}, false));
            insert lstOrder;

            List<SObject> lstOrderItem = new List<SObject>();
            lstOrderItem.add(TestClassHelper.createSObject('OrderItem', new Map<String,Object>{ 'OrderId' => lstOrder[0].Id, 'Quantity' => 10, 'UnitPrice' => 1000, 'Product2Id' => lstProduct[0].Id, 'PricebookEntryId' => lstPricebookEntry[0].Id}, false));
            insert lstOrderItem;
        }
    }

    public static testMethod void testOrderProducts() {
        User standardUser = [SELECT Id FROM User WHERE Username = 'standarduser@pratik.com' LIMIT 1];
        
        System.runAs(standardUser) {
            List<Order> lstOrder = [Select Id From Order Limit 1];
            List<OrderItem> lstOrderItem = OrderProductsController.getOrderItems(lstOrder[0].Id);
            system.assertEquals(lstOrderItem.size(), 1);
        }
    }
}