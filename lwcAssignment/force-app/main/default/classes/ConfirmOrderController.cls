/*
 * Helper class for order submission to external system and update the Order status to “Activated” on success 
 * else will return proper error message for end user.
*/
public with sharing class ConfirmOrderController {
    @AuraEnabled
    public static Map<String,Object> submitOrderToExtSystem(String orderId) {
        Map<String,Object> resultMap = new Map<String,Object>();
        try {
            //get Order Products using orderId
            List<OrderItem> lstOrderItem = [Select Product2.Name, Product2.ProductCode, UnitPrice, Quantity, 
                                                Order.OrderNumber, Order.Account.AccountNumber, Order.Type, Order.Status 
                                                From OrderItem Where OrderId =:orderId];
            //stop the transaction if there are no Order Products, show proper error to end user.
            if(lstOrderItem.isEmpty()) {
                resultMap.put('success', false);
                resultMap.put('message', Label.Product_List_Empty_Error_Message);
                return resultMap;
            }
            else if(lstOrderItem[0].Order.Status == Label.Active_Order_Status) {
                //stop the transaction if Order is Active, show proper error to end user.
                resultMap.put('success', false);
                resultMap.put('message', Label.Order_Confirmation_Error_Message_for_Active_Order);
                return resultMap;
            }
			
            //Prepare request body for HTTP callout
            List<OrdertItemWrapper> lstOrdertItemWrapper = new List<OrdertItemWrapper>();
            for(OrderItem orderItem :lstOrderItem) {
                OrdertItemWrapper newOrdertItemWrapper = new OrdertItemWrapper();
                newOrdertItemWrapper.name = orderItem.Product2.Name;
                newOrdertItemWrapper.code = orderItem.Product2.ProductCode;
                newOrdertItemWrapper.unitPrice = orderItem.UnitPrice;
                newOrdertItemWrapper.quntity = orderItem.Quantity;
                lstOrdertItemWrapper.add(newOrdertItemWrapper);
            }
            OrdertWrapper newOrdertWrapper = new OrdertWrapper();
            newOrdertWrapper.accountNumber = lstOrderItem[0].Order.Account.AccountNumber;
            newOrdertWrapper.orderNumber = lstOrderItem[0].Order.OrderNumber;
            newOrdertWrapper.type = lstOrderItem[0].Order.Type;
            newOrdertWrapper.status = lstOrderItem[0].Order.Status;
            newOrdertWrapper.orderProducts = lstOrdertItemWrapper;
			
            //convert input list into json string to send as a request body.
            String jsonInput = JSON.serialize(newOrdertWrapper);
            resultMap = HttpUtility.makeCallout('POST', Label.Order_Endpoint, jsonInput);
            //on successfull response, Activate the Order
            if((Boolean) resultMap.get('success')) {
                Order newOrder = new Order(Id = orderId);
                newOrder.Status = 'Activated';
                update newOrder;
                resultMap.put('message', Label.Order_Success_Message);
            }
        }
        catch(Exception ex) {
            resultMap.put('success', false);
            resultMap.put('message', ex.getMessage());
        }
        return resultMap;
    }

    private class OrdertWrapper {
        String accountNumber;
        String orderNumber;
        String type;
        String status;
        List<OrdertItemWrapper> orderProducts;
    }

    private class OrdertItemWrapper {
        String name;
        String code;
        Decimal unitPrice;
        Decimal quntity;
    }
}