@isTest
public with sharing class AvailableProductsControllerTest {
    //prepare test data
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

    public static testMethod void testAvailableProducts() {
        User standardUser = [SELECT Id FROM User WHERE Username = 'standarduser@pratik.com' LIMIT 1];
        system.assertNotEquals(standardUser.Id, Null);
        System.runAs(standardUser) {
            List<Order> lstOrder = [Select Id, Status From Order Limit 1];
            system.assertEquals(lstOrder[0].Status, 'Draft');
            
            List<AvailableProductsController.ProductWrapper> lstProductWrapperInfo = AvailableProductsController.getProducts(lstOrder[0].Id, 'SLA-Diamond', 10, 0);
            system.assertEquals(lstProductWrapperInfo.size(), 1);
            
            List<PriceBookEntry> lstPBEntries = [Select Id, Product2Id, Product2.Name, Product2.IsActive, UnitPrice FROM PricebookEntry Limit 1];
            
            List<AvailableProductsController.ProductWrapper> lstProductWrapper = new List<AvailableProductsController.ProductWrapper>();
            for (PriceBookEntry pEntry: lstPBEntries) {
                if(pEntry.Product2.IsActive) {
                    AvailableProductsController.ProductWrapper productWrapperRecord = new AvailableProductsController.ProductWrapper();
                    productWrapperRecord.productId = pEntry.Product2Id;
                    productWrapperRecord.productName = pEntry.Product2.Name;
                    productWrapperRecord.listPrice = pEntry.UnitPrice;
                    productWrapperRecord.priceBookId = pEntry.Id;
                    lstProductWrapper.add(productWrapperRecord);
                }
            }
            
            List<Product2> lstProduct = [Select Id FROM Product2 Where Name = 'SLA-Platinum'];
            AvailableProductsController.ProductWrapper secondProductRecord = new AvailableProductsController.ProductWrapper();
            secondProductRecord.productId = lstProduct[0].Id;
            secondProductRecord.productName = 'SLA-Platinum';
            secondProductRecord.listPrice = 200;
            secondProductRecord.priceBookId = lstPBEntries[0].Id;
            lstProductWrapper.add(secondProductRecord);
            
            AvailableProductsController.updateOrderProducts(lstProductWrapper, lstOrder[0].Id);
            
            //verify new order product record got created
            List<OrderItem> lstOrderItem = [Select Id From OrderItem];
            system.assertEquals(lstOrderItem.size(), 2);
            
            Test.setMock(HttpCalloutMock.class, new OrderMockHttpResponseGenerator());
            Test.startTest();
            ConfirmOrderController.submitOrderToExtSystem(lstOrder[0].Id);
            
            //verify order status got updated on success
            List<Order> lstOrderInfo = [Select Id, Status From Order Limit 1];
            system.assertEquals(lstOrderInfo[0].Status, 'Activated');
            
            //test -ve scenario
            AvailableProductsController.updateOrderProducts(lstProductWrapper, lstOrder[0].Id);
            Test.stopTest();
        }
    }

    //test -ve scenario, i.e. catch block
    public static testMethod void testNegativeScenario() {
        User standardUser = [SELECT Id FROM User WHERE Username = 'standarduser@pratik.com' LIMIT 1];
        system.assertNotEquals(standardUser.Id, Null);
        System.runAs(standardUser) {
            Test.startTest();
            List<Order> lstOrder = [Select Id, Status From Order Limit 1];
            system.assertEquals(lstOrder[0].Status, 'Draft');
            
            List<PriceBookEntry> lstPBEntries = [Select Id, Product2Id, Product2.Name, Product2.IsActive, UnitPrice FROM PricebookEntry Limit 1];
            
            List<AvailableProductsController.ProductWrapper> lstProductWrapper = new List<AvailableProductsController.ProductWrapper>();
            
            List<Product2> lstProduct = [Select Id FROM Product2 Where Name = 'SLA-Platinum'];
            AvailableProductsController.ProductWrapper secondProductRecord = new AvailableProductsController.ProductWrapper();
            secondProductRecord.productId = 'abcs1';
            secondProductRecord.productName = 'SLA-Platinum';
            secondProductRecord.listPrice = -200;
            secondProductRecord.priceBookId = lstPBEntries[0].Id;
            secondProductRecord.productLink = 'testlink';
            lstProductWrapper.add(secondProductRecord);
            
            AvailableProductsController.updateOrderProducts(lstProductWrapper, lstOrder[0].Id);
            
            List<OrderItem> lstOrderItem = [Select Id From OrderItem];
            system.assertEquals(lstOrderItem.size(), 1);
            Test.stopTest();
        }
    }
}