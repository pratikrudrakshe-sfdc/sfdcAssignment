/*
 * Controller class of availableProducts lwc component, used to pull available Products based on Order’s PriceBook. 
 * On “Add Products” action new Order Products will get created under the same order if not present already 
 * else will update the quantity and price in the existing Order Items.
*/
public with sharing class AvailableProductsController {
    //return list of products who has Pricebook Entry in the Pricebook related to the current order
    @AuraEnabled(Cacheable = true)
    public static List<ProductWrapper> getProducts(String selectedOrderId, String strProdName, Integer limitSize, Integer offset) {
        system.debug('selectedOrderId=='+selectedOrderId);
        List<Order> lstOrder = [Select Id, Pricebook2Id From Order Where Id =:selectedOrderId];
        system.debug('lstOrder=='+lstOrder);
        List<ProductWrapper> lstProductWrapper;
        if(!lstOrder.isEmpty()) {
            lstProductWrapper = getProductsUsingPriceBook(lstOrder[0].Pricebook2Id, strProdName, limitSize, offset);
            //lstProduct = [SELECT  Id, Name, (Select Id, UnitPrice, IsActive, PriceBook2.IsStandard From PriceBookEntries Where Pricebook2Id =:lstOrder[0].Pricebook2Id) FROM Product2 WHERE Name LIKE : '%' +strProdName+ '%'];
        }
        system.debug('lstProductWrapper=='+lstProductWrapper);
        return lstProductWrapper; 
    }
    
    //helper method to generate ProductWrapper list for Add Products page
    static List<ProductWrapper> getProductsUsingPriceBook(Id pbookId, String strProdName, Integer limitSize, Integer offset) {
        String query = 'SELECT Id, Product2Id, Product2.Name, Product2.IsActive, UnitPrice FROM PricebookEntry';
        query += ' WHERE IsActive = True AND Pricebook2Id =:pbookId';

        if(String.isNotBlank(strProdName)) {
            strProdName = '\'%' + String.escapeSingleQuotes(strProdName.trim()) + '%\'';
            query += ' AND (Product2.Name Like ' +strProdName+ ' OR Product2.ProductCode Like '+strProdName+ ')';
        }
        query += ' LIMIT :limitSize OFFSET :offset';
        List<PriceBookEntry> lstPBEntries = Database.query(query);
    
        List<ProductWrapper> lstProductWrapper = new List<ProductWrapper>();
        for (PriceBookEntry pEntry: lstPBEntries) {
            if(pEntry.Product2.IsActive) {
                ProductWrapper productWrapperRecord = new ProductWrapper();
                productWrapperRecord.productId = pEntry.Product2Id;
                productWrapperRecord.productName = pEntry.Product2.Name;
                productWrapperRecord.listPrice = pEntry.UnitPrice;
                productWrapperRecord.priceBookId = pEntry.Id;
                lstProductWrapper.add(productWrapperRecord);
            }
        }
        return lstProductWrapper;
    }
	
    //Method used to create / update Order Products.
    @AuraEnabled
    public static Map<String,Object> updateOrderProducts(List<ProductWrapper> lstProductWrapper, String orderId) {
        Map<String,Object> resultMap = new Map<String,Object>();
        try {
            List<Order> lstOrderInfo = [Select Status, (Select Id, Product2Id, Quantity From OrderItems) 
                                            From Order 
                                            Where Id =:orderId];
            System.debug('lstOrderInfo=='+lstOrderInfo);
            //stop the transaction if Order is Active, show proper error to end user.
            if(lstOrderInfo[0].Status == Label.Active_Order_Status) {
                resultMap.put('success', false);
                resultMap.put('message', Label.Add_OLI_Error_Message_for_Active_Order);
                return resultMap;
            }
            List<OrderItem> lstOrderItemToUpdate = new List<OrderItem>();
            Map<String, OrderItem> mapOrderItemWithProductIdAsKey = new Map<String, OrderItem>();
            for(OrderItem oItem :lstOrderInfo[0].OrderItems) {
                mapOrderItemWithProductIdAsKey.put(oItem.Product2Id, oItem);
            }
            for(ProductWrapper newProductWrapper :lstProductWrapper) {
                OrderItem orderItem;
                //increase quantity by 1 if order product is already present under the order.
                if(mapOrderItemWithProductIdAsKey.containsKey(newProductWrapper.productId)) {
                    orderItem = mapOrderItemWithProductIdAsKey.get(newProductWrapper.productId);
                    orderItem.Quantity = orderItem.Quantity + 1;
                }
                else {
                    //create new order product
                    orderItem = new OrderItem();
                    orderItem.OrderId = orderId;
                    orderItem.Quantity = 1;
                    orderItem.UnitPrice = newProductWrapper.listPrice;
                    orderItem.Product2Id = newProductWrapper.productId;
                    orderItem.PricebookEntryId = newProductWrapper.priceBookId;
                }
                lstOrderItemToUpdate.add(orderItem);
            }

            if(!lstOrderItemToUpdate.isEmpty()) {
                upsert lstOrderItemToUpdate;
            }
            resultMap.put('success', true);
            resultMap.put('message', Label.Order_Modification_Success_Message);
        }
        catch(Exception ex) {
            resultMap.put('success', false);
            resultMap.put('message', ex.getMessage());
        }
        return resultMap;
    }

    public class ProductWrapper {
        @AuraEnabled public String productId {get; set;}
        @AuraEnabled public String productName {get; set;}
        @AuraEnabled public Decimal listPrice {get; set;}
        @AuraEnabled public String priceBookId {get; set;}
        @AuraEnabled public String productLink {get{ return '/'+productId; } set;}
    }
}