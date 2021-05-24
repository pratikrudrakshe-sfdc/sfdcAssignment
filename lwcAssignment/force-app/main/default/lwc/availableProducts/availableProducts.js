import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchProducts from '@salesforce/apex/AvailableProductsController.getProducts';
import saveOrderProducts from '@salesforce/apex/AvailableProductsController.updateOrderProducts';
import { MessageContext, publish } from 'lightning/messageService';

import orderProductChannel from '@salesforce/messageChannel/OrderProduct__c';

// datatable columns
const columns = [
    {
        label: 'Product Name',
        fieldName: 'productLink',
        type: 'url',
        typeAttributes: { label: { fieldName: 'productName' }, target: '_blank', tooltip: 'Click to view Product details.' }
    }, {
        label: 'List Price',
        fieldName: 'listPrice',
        type: 'currency',
    },
];
export default class CustomSearchInLWC extends LightningElement {
    @api recordId;
    @track searchData;
    @track columns = columns;
    @track strSearchProdName;
    @track disableBtn = true;
    @track disableTable = true;
    @track rowNumberOffset;
    @track recordsToDisplay = []; //Records to be displayed on the page
    @wire(MessageContext) messageContext;
    rowLimit = 10;
    rowOffSet = 0;
    tableElement;

    connectedCallback() {
        searchProducts({ selectedOrderId: this.recordId, strProdName: this.strSearchProdName, limitSize: this.rowLimit, offset: this.rowOffSet })
            .then(result => {
                //this.searchData = result;
                /*let recs = [];
                for(let iIndex = 0; iIndex < result.length; iIndex++){
                    let opp = {};
                    opp.rowNumber = ''+(iIndex+1);
                    opp.oppLink = '/'+result[iIndex].Id;
                    opp = Object.assign(opp, result[iIndex]);
                    recs.push(opp);
                }*/
                console.log('result.length ==',result.length);
                if(result.length > 0) {
                    console.log('true ==')
                    this.disableTable = true;
                    this.searchData = result;
                } else {
                    this.disableTable = false;
                    this.showToast('No products available, please check your Pricebook associated with current Order', 'Error!', 'error');
                }
                //let updatedRecords = [...this.searchData, ...result];
                //console.log('updatedRecords==',updatedRecords);
                //this.searchData = updatedRecords;
                //console.log('this.searchData==',this.searchData);
            }).catch(error => {
                this.showToast(error.message, 'Error!', 'error');
            });
    }

    getProductInfo() {
        console.log('getProductInfo2==');
        searchProducts({ selectedOrderId: this.recordId, strProdName: this.strSearchProdName, limitSize: this.rowLimit, offset: this.rowOffSet })
            .then(result => {
                //this.searchData = result;
                /*let recs = [];
                for(let iIndex = 0; iIndex < result.length; iIndex++){
                    let opp = {};
                    opp.rowNumber = ''+(iIndex+1);
                    opp.oppLink = '/'+result[iIndex].Id;
                    opp = Object.assign(opp, result[iIndex]);
                    recs.push(opp);
                }
                console.log('recs2==',recs);*/
                //let updatedRecords = [...this.searchData, ...recs];
                const updatedRecords = [...this.searchData, ...result];
                this.searchData = updatedRecords;
            }).catch(error => {
                this.showToast(error.message, 'Error!', 'error');
            });
    }

    getSelectedProducts() {
        //const selectedRows = event.detail.selectedRows;
        publish(this.messageContext, orderProductChannel, { recordData: 'Save Order Product Initiated!' });
        const selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedRows==', selectedRows);
        let productIds = '';
        for (let iIndex = 0; iIndex < selectedRows.length; iIndex++) {
            productIds += selectedRows[iIndex].productId + ';';
        }
        console.log('productIds==', productIds);
        saveOrderProducts({ lstProductWrapper: selectedRows, orderId: this.recordId })
            .then(result => {
                console.log('success==' + result.success);
                if (result.success) {
                    let message = { recordData: this.recordId, type: 'Server Responded' };
                    publish(this.messageContext, orderProductChannel, message);
                }
                else {
                    this.showToast(result.message, 'Error!', 'error');
                }
            }).catch(error => {
                this.showToast(error.message, 'Error!', 'error');
            });
    }

    handleProductSearch(event) {
        //this.tableElement = event.target;
        //this.tableElement.enableInfiniteLoading = false;
        let searchStringName = event.detail.value;
        console.log('searchStringName==',searchStringName);
        searchProducts({ selectedOrderId: this.recordId, strProdName: searchStringName, limitSize: this.rowLimit, offset: this.rowOffSet })
            .then(result => {
                this.searchData = result;
                console.log('searchData2222==',searchData);
            }).catch(error => {
                this.showToast(error.message, 'Error!', 'error');
            });
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.disableBtn = selectedRows.length < 1;
    }

    loadMoreData(event) {
        console.log('loadMoreData==');
        const currentRecord = this.searchData;
        event.target.isLoading = true;
        const tableElement = event.target;

        this.rowOffSet = this.rowOffSet + this.rowLimit;
        console.log('this.rowOffSet==' + this.rowOffSet);
        searchProducts({ selectedOrderId: this.recordId, strProdName: this.strSearchProdName, limitSize: this.rowLimit, offset: this.rowOffSet })
            .then((data) => {
                if (data.length < 1) {
                    tableElement.enableInfiniteLoading = false;
                } else {
                    const currentData = this.searchData;
                    //Appends new data to the end of the table
                    const newData = currentData.concat(data);
                    this.searchData = newData;
                }
                tableElement.isLoading = false;
            }).catch((error) => {
                console.log(error.message);
            });
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