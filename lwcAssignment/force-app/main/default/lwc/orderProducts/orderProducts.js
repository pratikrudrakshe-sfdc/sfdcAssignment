import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrderItemLst from '@salesforce/apex/OrderProductsController.getOrderItems';
import submitOrder from '@salesforce/apex/ConfirmOrderController.submitOrderToExtSystem';

import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';
import orderProductChannel from '@salesforce/messageChannel/OrderProduct__c';

// datatable columns
const columns = [
    {
        label: 'Name',
        fieldName: 'productUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'productName' }, target: '_blank', tooltip: 'Click to view Product details.' }
    }, {
        label: 'Unit Price',
        fieldName: 'UnitPrice',
        type: 'currency',
    }, {
        label: 'Quantity',
        fieldName: 'Quantity',
        type: 'number',
    }, {
        label: 'Total Price',
        fieldName: 'TotalPrice',
        type: 'currency',
    },
];
export default class OrderProducts extends LightningElement {
    @api recordId;
    @track searchData;
    @track columns = columns;
    subscription;

    @wire(MessageContext) messageContext;

    connectedCallback() {
        this.subscribeToMessageChannel();
        this.getOrderItemList();
    }

    getOrderItemList() {
        getOrderItemLst({ orderId: this.recordId })
            .then(result => {
                this.searchData = result.map(row => {
                    return { ...row, productName: row.Product2.Name, productUrl: '/' + row.Product2Id }
                })
            }).catch(error => {
                this.showToast(error.message, 'Unable to retrieve Order Products!', 'error');
            });
    }

    confirmOrder() {
        submitOrder({ orderId: this.recordId })
        .then(result => {
            if(result.success) {
                this.showToast(result.message, 'Success!', 'success');
            } else{
                this.showToast(result.message, 'Error!', 'error');
            }
        }).catch(error => {
            this.showToast(error.message, 'Error!', 'error');
        });
    }

    handleMessage(message) {
        console.log('Event catched here', message.recordData);
        if (message.type === 'Server Responded') {
            this.getOrderItemList();
            this.showToast('Order Products Updated!', 'Kudos', 'success');
        }
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                orderProductChannel,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }
    showToast(message, title, type) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                variant: type,
                message: message,
            })
        );
    }
}