/*
 * Controller class of orderProducts lwc component
*/
public with sharing class OrderProductsController {
    //method return Order Products as per orderId input
    @AuraEnabled
    public static List<OrderItem> getOrderItems(String orderId) {
        List<OrderItem> lstOrderItem = [Select Id, Product2Id, Product2.Name, UnitPrice, Quantity, TotalPrice 
                                            From OrderItem 
                                            Where OrderId =:orderId];
        return lstOrderItem; 
    }
}